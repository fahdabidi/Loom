#!/bin/bash
# check_spec_parity.sh -- are the cross-repo twins identical? (OpenAPI specs + generated artifacts)
#
# The service contracts live twice: once in Loom (docs/API/OpenAPI/**) where the app
# writes clients against them, once in loom-backend (spec/**) where the services
# implement them. They are meant to be byte-identical, and nothing enforces it --
# the reference-doc mirror test works only because both its copies live in one repo.
#
# On 2026-08-30 the Loom copy was found dated 13 August and behind by FOUR operations
# (deleteRole, getInvitation, issueInvite, redeemInvite) -- 168 lines, drifted for two
# weeks. Nothing failed, because nothing compares them.
#
# The comparison set is the BACKEND's specs. Loom carries ~50 and the backend 8; the
# 42 Loom-only files are app-side contracts with no service counterpart and are NOT
# drift. A spec present in the backend and absent from Loom IS.
#
# Covers two families that drift the same way: the OpenAPI spec twins, and generated
# artifacts copied between repos (permissions-vocabulary.json).
#
# Usage:  bash check_spec_parity.sh [loom-repo] [backend-repo]
# Exit:   0 all twins identical, 1 drift found, 2 a repo was not found.
set -uo pipefail
LOOM="${1:-$HOME/Loom}"
BE="${2:-$HOME/loom-backend}"
[ -d "$LOOM/docs/API/OpenAPI" ] || { echo "not found: $LOOM/docs/API/OpenAPI"; exit 2; }
[ -d "$BE/spec" ]               || { echo "not found: $BE/spec"; exit 2; }

same=0; differ=0; missing=0
while IFS= read -r rel; do
  a="$BE/spec/$rel"; b="$LOOM/docs/API/OpenAPI/$rel"
  if [ ! -f "$b" ]; then
    printf "  MISSING in Loom   %s\n" "$rel"; missing=$((missing+1))
  elif cmp -s "$a" "$b"; then
    same=$((same+1))
  else
    d=$(diff "$b" "$a" | grep -c '^[<>]')
    printf "  DIFFER (%s lines)  %s\n" "$d" "$rel"; differ=$((differ+1))
  fi
done < <(cd "$BE/spec" && find . -name '*.yaml' | sed 's|^\./||' | sort)

echo "  ---"
printf "  identical: %s   differ: %s   missing: %s\n" "$same" "$differ" "$missing"

# ---------------------------------------------------------------------------
# Generated-artifact twins. Same failure mode as the specs above, found
# 2026-08-31: permissions-vocabulary.json is generated in Loom from
# ArchetypeResolver and COPIED into the backend, where app-access loads it from
# the classpath. The backend copy had 97 ids and no calendar.* at all while
# Loom's had 106, so every calendar-archetype workflow was uncreatable by
# anyone -- CommunityPermissionDeriver can only grant what its bundled copy
# names. Both files carry the same "GENERATED -- do not edit by hand" header,
# so they are meant to be byte-identical and nothing compared them.
gen_same=0; gen_differ=0; gen_missing=0
check_generated_twin() {
  local rel_loom="$1" rel_be="$2" label="$3"
  local a="$LOOM/$rel_loom" b="$BE/$rel_be"
  if [ ! -f "$a" ]; then
    printf "  MISSING in Loom     %s\n" "$label"; gen_missing=$((gen_missing+1)); return
  fi
  if [ ! -f "$b" ]; then
    printf "  MISSING in backend  %s\n" "$label"; gen_missing=$((gen_missing+1)); return
  fi
  if cmp -s "$a" "$b"; then
    gen_same=$((gen_same+1))
  else
    local d only_loom only_be
    d=$(diff "$a" "$b" | grep -c '^[<>]')
    only_loom=$(comm -23 <(grep -oE '"[a-z_]+\.[a-z_]+"' "$a" | sort -u) \
                         <(grep -oE '"[a-z_]+\.[a-z_]+"' "$b" | sort -u) | tr '\n' ' ')
    only_be=$(comm -13 <(grep -oE '"[a-z_]+\.[a-z_]+"' "$a" | sort -u) \
                       <(grep -oE '"[a-z_]+\.[a-z_]+"' "$b" | sort -u) | tr '\n' ' ')
    printf "  DIFFER (%s lines)    %s\n" "$d" "$label"
    [ -n "$only_loom" ] && printf "      only in Loom:    %s\n" "$only_loom"
    [ -n "$only_be" ]   && printf "      only in backend: %s\n" "$only_be"
    gen_differ=$((gen_differ+1))
  fi
}

echo
echo "  generated artifacts:"
check_generated_twin \
  "docs/references/generated/permissions-vocabulary.json" \
  "services/app-access/src/main/resources/permissions-vocabulary.json" \
  "permissions-vocabulary.json"

echo "  ---"
printf "  identical: %s   differ: %s   missing: %s\n" "$gen_same" "$gen_differ" "$gen_missing"

if [ "$differ" -eq 0 ] && [ "$missing" -eq 0 ] && [ "$gen_differ" -eq 0 ] && [ "$gen_missing" -eq 0 ]; then
  echo "  spec twins and generated artifacts are in parity"
  exit 0
fi
echo
echo "  DRIFT -- sync before trusting either copy."
echo "  Specs: the backend is the implementation, so it is usually authoritative, but"
echo "  check which side actually changed before copying."
echo "  Generated artifacts: LOOM is authoritative -- it is where they are generated."
echo "  Regenerate there, copy into the backend, then REBUILD the service, because"
echo "  app-access reads this file from its classpath at startup, not from disk."
exit 1
