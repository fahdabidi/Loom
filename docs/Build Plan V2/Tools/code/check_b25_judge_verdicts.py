#!/usr/bin/env python3
"""Verdict-check the B25 judge half, and report STALENESS — which is the real disqualifier.

Three iterations of this script, and the first two each produced a number that agreed
with whatever I already believed. Worth recording, because the failure mode is the
point:

  v1  "is there SOME artifact where every screen for this row passed?"
      -> 66 of 66. Useless: across 41 artifacts from a long iteration campaign,
         almost every row has a lucky all-pass somewhere.

  v2  "latest artifact wins" -> 66 pass, 0 fail. Also suspicious, and the reason is
      NOT a bug: the July campaign genuinely ended on pass-39, 204 screens all pass.
      The earlier failing artifacts are earlier iterations of that same campaign.
      Counting artifacts (10 fail vs 5 pass) had made the judge half look broken. It
      is not broken.

  v3  this one. The judge half is not FAILING, it is STALE. pass-39 is dated
      2026-07-02 against its own appCommitSha. Since then the packages have been
      regenerated, the app shell and engine have changed repeatedly, and the real row
      set moved 79 -> 77 -> 72. A passing judgement of a July build says nothing about
      today's build.

So the number to report is not "how many passed" but "how many passed AGAINST THE
BUILD WE SHIP NOW". The walkthrough half already solves this: every manifest records
skillVersion + sha256 precisely so a later package regeneration invalidates it. The
judge half records appCommitSha and nobody checks it.
"""
import json, glob, os, sys, subprocess, collections

EVID = sys.argv[1] if len(sys.argv) > 1 else \
    "/home/fahd/Loom/docs/Build Plan V2/Evidence/B25"
PATTERNS = ["llm-vision-ux-review*.json", "independent-production-ux-review*.json"]

files = []
for p in PATTERNS:
    files.extend(glob.glob(os.path.join(EVID, "**", p), recursive=True))
files = sorted(set(files))

latest = {}
for f in files:
    try:
        d = json.load(open(f, encoding="utf-8-sig"))
    except Exception:
        continue
    reviews = d.get("screenReviews")
    if not isinstance(reviews, list) or not reviews:
        continue
    key = (str(d.get("generatedAt") or ""), os.path.getmtime(f))
    meta = (d.get("generatedAt"), d.get("appCommitSha"), os.path.basename(f))
    by_wf = collections.defaultdict(list)
    for r in reviews:
        if isinstance(r, dict) and r.get("workflowId"):
            by_wf[r["workflowId"]].append(r.get("verdict"))
    for wf, verdicts in by_wf.items():
        if wf not in latest or key > latest[wf][0]:
            latest[wf] = (key, verdicts, meta)

passed, failed = set(), set()
commits = collections.Counter()
dates = collections.Counter()
for wf, (_k, verdicts, meta) in latest.items():
    real = [v for v in verdicts if v is not None]
    (passed if real and all(v == "pass" for v in real) else failed).add(wf)
    commits[str(meta[1])] += 1
    dates[str(meta[0])[:10]] += 1

try:
    head = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                          capture_output=True, text=True,
                          cwd="/home/fahd/Loom").stdout.strip()
except Exception:
    head = "?"

print("=" * 76)
print("  B25 JUDGE HALF — VERDICT AND STALENESS")
print("=" * 76)
print(f"  workflows with a latest verdict      {len(latest)}")
print(f"    latest verdict ALL PASS            {len(passed)}")
print(f"    latest verdict has a FAIL          {len(failed)}")
print()
print("  The judge half is not failing. It is STALE — and staleness is what")
print("  disqualifies it, not the verdict.")
print()
print(f"  current repo HEAD                    {head}")
print("  commit each latest verdict was made against:")
for c, n in commits.most_common():
    stale = "  <-- NOT current" if c != head else "  <-- current"
    print(f"    {c:12} {n:>3} workflows{stale}")
print("  date of each latest verdict:")
for d_, n in dates.most_common():
    print(f"    {d_:12} {n:>3} workflows")
print()
print("  A passing judgement of a build we no longer ship is coverage with extra")
print("  steps. The walkthrough half records skillVersion + sha256 so a regeneration")
print("  invalidates it; the judge half records appCommitSha and nobody checks it.")
print("  VERDICT-CHECKED AND CURRENT is the only figure worth quoting as the bar.")

out = os.environ.get("B25_VERDICT_OUT")
if out:
    json.dump({"passed": sorted(passed), "failed": sorted(failed),
               "commits": dict(commits), "head": head},
              open(out, "w", encoding="utf-8"), indent=1)
    print(f"\n  wrote {out}")
