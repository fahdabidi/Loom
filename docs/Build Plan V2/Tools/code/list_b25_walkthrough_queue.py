"""List the B25 rows that already hold a judge artifact and lack only a live walkthrough.

Reuses check_b25_status.sh's own joining rules deliberately:
  * the denominator is each product doc's B25 addendum table, first column
  * `wf_`-prefixed and un-marked rows are excluded (test-harness ids, not workflows)
  * a manifest proves a row only if it carries the success phrase, not merely by naming it
  * the judge half joins on `workflowId`, never on the screenRowId slug
"""
import glob, os, re, subprocess, sys

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                      capture_output=True, text=True).stdout.strip()
DOCS = os.path.join(ROOT, "docs/references/communities")
EVID = os.path.join(ROOT, "docs/Build Plan V2/Evidence/B25")

# --- denominator ---------------------------------------------------------
rows = []          # (community, workflowType)
for f in sorted(glob.glob(os.path.join(DOCS, "*-product-experience.md"))):
    community = os.path.basename(f).replace("-product-experience.md", "")
    # Match check_b25_status.sh exactly: the table is keyed off this literal header
    # line, and the separator is "| --- |" WITH a space after the pipe -- a /^\|---/
    # pattern misses it and inflates every community by one (that bug produced 87).
    inb = False
    for line in open(f, encoding="utf-8"):
        if line.startswith("| Workflow | Persona | Expected decision |"):
            inb = True
            continue
        if inb:
            if re.match(r"^\| *-", line):
                continue
            if line.startswith("|"):
                rows.append((community, line.split("|")[1].strip().strip("`")))
            else:
                inb = False

real = [(c, w) for c, w in rows if not w.startswith("wf_") and not w.startswith("⛔")]

# --- walkthrough half: success phrase required ---------------------------
proven = set()
for m in glob.glob(os.path.join(EVID, "*live-write*.md")):
    text = open(m, encoding="utf-8", errors="replace").read()
    wf = re.search(r"\*\*Workflow:\*\* `([a-z0-9-]+)`", text)
    if not wf:
        continue
    if re.search(r"Both halves of the proof standard were met", text, re.I):
        proven.add(wf.group(1))

# --- judge half: join on workflowId --------------------------------------
# Restricted to the ACTUAL judge artifacts, matching check_b25_status.sh. A blanket
# *.json glob over this directory also picks up remediation plans, iteration
# scorecards, freshness gates and reconciliation reports, several of which carry a
# workflowId of their own -- that over-counts the judged half.
judged = set()
for pattern in ("llm-vision-ux-review*.json", "independent-production-ux-review*.json"):
    for j in glob.glob(os.path.join(EVID, pattern)):
        text = open(j, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'"workflowId": "([a-z0-9_-]+)"', text):
            judged.add(m.group(1))
# Judge verdicts also arrive as markdown outside that JSON glob -- a 2026-09-09 PASS
# for garden-tool-loan was invisible to a JSON-only scan.
for j in glob.glob(os.path.join(EVID, "*ux-judge*.md")):
    text = open(j, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r"\*\*Workflow:\*\* `([a-z0-9-]+)`", text):
        judged.add(m.group(1))

# --- control: the parse is suspect if a known-proven type is missing -----
if "garden-tool-loan" not in proven:
    print("WARNING: control 'garden-tool-loan' absent from proven set -- parse is suspect", file=sys.stderr)

seen, cands, need_both = set(), [], []
for c, w in real:
    if w in seen:
        continue
    seen.add(w)
    if w in proven:
        continue
    (cands if w in judged else need_both).append((c, w))

print(f"real rows (distinct workflow types): {len(seen)}")
print(f"  proven by a live walkthrough:      {len(seen) - len(cands) - len(need_both)}")
print(f"  JUDGED, need only a walkthrough:   {len(cands)}")
print(f"  need BOTH halves:                  {len(need_both)}")
print("\n=== need only a walkthrough (the campaign queue) ===")
for c, w in sorted(cands):
    print(f"  {c:34s} {w}")
print("\n=== need both halves ===")
for c, w in sorted(need_both):
    print(f"  {c:34s} {w}")
