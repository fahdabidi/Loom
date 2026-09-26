# check_orphan_summary_bindings.py -- which states are bound ONLY as `summary`,
# with live outgoing transitions, in no `primary` binding anywhere in their
# workflow?
#
# WHY THIS IS A GATE AND NOT A NOTE. `SHELL-implement-bindingkind-summary` makes
# `summary` mean what render-bindings.md:553-560 already says it means -- a
# compact, READ-ONLY card. Today the renderer ignores `bindingKind` entirely, so
# a `summary` binding renders a fully interactive card and those states keep
# their actions by accident. The moment the shell honours the key, any state
# bound only as `summary` loses every user-reachable action, with nothing to fall
# back on. This script is that ticket's exit condition: it must print 0.
#
# Exit 1 when any orphan remains, 2 when the sweep could not run at all -- an
# empty glob is a broken query, not a clean result.
#
# IT PARSES, IT DOES NOT GREP. Render bindings span multiple lines, and a
# single-line regex over them returns nothing while looking exactly like a clean
# sweep -- which is how an earlier sweep of mine reported "no change" after a
# binding had in fact moved. The `.jsonc` assets carry comments and trailing
# commas, so they are stripped (string-aware, so a `//` inside a string survives)
# and then parsed as real JSON.
#
# READ THE CONTROLS, NOT JUST THE COUNT. It prints the total number of `summary`
# bindings found; if that is 0 the query is broken rather than the corpus clean,
# and anything it could not parse is PRINTED rather than skipped, because a
# silently dropped package hides exactly the case that would disprove the gate.
#
# Measured 2026-09-25 after the Book Club regeneration `d87f9875`: 115 summary
# bindings, 4 orphans -- Ad-Free `funded`, Cedar `approved`/`denied` and
# `changes-needed`. It was 5 before that commit; Book Club's
# `book-search-ai-digest`/`saved` was moved into its tab's primary binding, which
# is what this sweep independently confirmed.
#
#   cd ~/Loom && python3 "docs/Build Plan V2/Tools/code/check_orphan_summary_bindings.py"
import json, re, glob, os, sys

BS = chr(92)

def strip_jsonc(t):
    t = re.sub(r'/[*].*?[*]/', '', t, flags=re.S)
    out = []
    for line in t.split('\n'):
        r, inq, esc = [], False, False
        i = 0
        while i < len(line):
            c = line[i]
            if esc:
                r.append(c); esc = False; i += 1; continue
            if c == BS and inq:
                r.append(c); esc = True; i += 1; continue
            if c == '"':
                inq = not inq; r.append(c); i += 1; continue
            if (not inq) and c == '/' and i + 1 < len(line) and line[i+1] == '/':
                break
            r.append(c); i += 1
        out.append(''.join(r))
    t = '\n'.join(out)
    t = re.sub(r',(\s*[}\]])', r'\1', t)
    return t

ASSETS = sorted(glob.glob("app/packages/core/loom_communities_app_shell/assets/*.jsonc"))
if not ASSETS:
    print("FAIL: no assets matched -- broken query, not a clean sweep"); sys.exit(2)

total_summary = 0
total_primary_cov = 0
orphans = []
parsed = 0

for path in ASSETS:
    pkg = os.path.basename(path)
    try:
        doc = json.loads(strip_jsonc(open(path, encoding="utf-8").read()))
    except Exception as e:
        print("UNPARSED " + pkg + ": " + str(e))
        continue
    parsed += 1
    root = doc.get("experience") or doc
    defs = root.get("workflowDefinitions") or {}
    for wf, d in defs.items():
        if not isinstance(d, dict): continue
        binds = d.get("renderBindings") or []
        trans = d.get("transitions") or []
        froms = set()
        for t in trans:
            f = t.get("from")
            if isinstance(f, list): froms.update(f)
            elif isinstance(f, str): froms.add(f)
        primary, summary = set(), set()
        for b in binds:
            if not isinstance(b, dict): continue
            st = b.get("states") or []
            if not isinstance(st, list): continue
            k = b.get("bindingKind")
            if k == "primary": primary.update(st)
            elif k == "summary": summary.update(st)
        total_summary += sum(1 for b in binds
                             if isinstance(b, dict) and b.get("bindingKind") == "summary")
        total_primary_cov += len(summary & primary)
        for s in sorted(summary - primary):
            if s in froms:
                exits = []
                for t in trans:
                    f = t.get("from")
                    fl = f if isinstance(f, list) else ([f] if f else [])
                    if s in fl:
                        exits.append(t.get("id") or t.get("action") or "?")
                orphans.append((pkg, wf, s, exits))

print("packages parsed: " + str(parsed) + "/" + str(len(ASSETS)))
print("CONTROL total summary bindings: " + str(total_summary) + "  (a 0 here means the query is broken)")
print("CONTROL summary states ALSO covered by a primary in the same workflow: " + str(total_primary_cov) + "  (these are the correct status views, not defects)")
print("")
print("ORPHANED summary states WITH live exits: " + str(len(orphans)))
for pkg, wf, s, ex in orphans:
    short = pkg.replace('Loom_Communities_Workflow_Engine_','').replace('_Example.jsonc','')
    print("  " + short + " / " + wf + " / " + s + "  exits=" + str(ex))

if orphans:
    sys.exit(1)
