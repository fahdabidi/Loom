#!/bin/bash
# check_spec_parity.sh -- are the OpenAPI spec twins identical across the two repos?
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
if [ "$differ" -eq 0 ] && [ "$missing" -eq 0 ]; then
  echo "  spec twins are in parity"
  exit 0
fi
echo "  DRIFT -- sync before trusting either copy. The backend is the implementation, so"
echo "  it is usually authoritative, but check which side actually changed before copying."
exit 1
