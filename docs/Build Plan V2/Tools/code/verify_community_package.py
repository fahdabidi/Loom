import io, json, re, sys

# ARGUMENT ORDER: <new> then <old>. argv[1] is the CANDIDATE, argv[2] is the SHIPPED
# file. Passing them the other way round was done on three packages before anyone
# noticed, on 2026-08-29. Most checks are equality comparisons and so read the same
# either way, which is exactly why it went unnoticed -- but the writer-declaration
# line prints its direction, and the reminder check below is genuinely one-way:
# reversed, "old had reminders and new does not" cannot catch a LOST reminder block,
# only a gained one.
new_path, old_path = sys.argv[1], sys.argv[2]
if len(sys.argv) > 1 and sys.argv[1] in ('-h', '--help'):
    print(__doc__ or 'usage: verify_community_package.py <new-candidate> <shipped-original>')
    raise SystemExit(0)

def strip(t):
    t = re.sub(r'(?<!:)//[^\n]*', '', t)
    return re.sub(r'/\*.*?\*/', '', t, flags=re.S)

def load(p): return json.loads(strip(io.open(p, encoding="utf-8").read())) 
new, old = load(new_path), load(old_path)
ok = True

def facts(pkg):
    exp = pkg.get("experience") or {}
    return {
        "ids": {k: pkg.get(k) for k in ("specVersion","packageId","communityId","communityHandle","displayName","extensionId")},
        "roles": sorted(r["roleId"] for r in (exp.get("roles") or []) if r.get("roleId")),
        "tabs": [t["tabId"] for t in (pkg.get("appShell") or {}).get("tabs") or []],
        "wfs": sorted((exp.get("workflowDefinitions") or {}).keys()),
        "reminders": sorted(n for n,w in (exp.get("workflowDefinitions") or {}).items() if w.get("reminder")),
        "seeds": len(exp.get("workflowInstances") or []),
    }

f_new, f_old = facts(new), facts(old)
for key in ("ids","roles","tabs","wfs"):
    if f_new[key] != f_old[key]:
        ok = False; print("!! %s CHANGED" % key.upper())
        if isinstance(f_old[key], list):
            lost = [x for x in f_old[key] if x not in f_new[key]]
            added = [x for x in f_new[key] if x not in f_old[key]]
            if lost: print("     LOST:  %s" % lost)
            if added: print("     ADDED: %s" % added)
        else:
            for k in f_old[key]:
                if f_old[key][k] != f_new[key].get(k): print("     %s: %r -> %r" % (k, f_old[key][k], f_new[key].get(k)))
    else:
        print("OK  %-9s preserved (%s)" % (key, len(f_new[key]) if isinstance(f_new[key], list) else "all"))

print("OK  reminders: %s -> %s" % (f_old["reminders"], f_new["reminders"]))
if f_old["reminders"] and not f_new["reminders"]: ok = False; print("!! REMINDER BLOCK LOST")
print("    seeds: %d -> %d" % (f_old["seeds"], f_new["seeds"]))

# ---- transitions: added 2026-08-27 after a lost transition would have gone unnoticed ----
def transitions(pkg):
    out = {}
    for n, w in ((pkg.get("experience") or {}).get("workflowDefinitions") or {}).items():
        for t in w.get("transitions") or []:
            tid = t.get("id")
            if not tid: continue
            out["%s.%s" % (n, tid)] = {
                "action": t.get("action"),
                "from": tuple(t.get("from") or []),
                "to": t.get("to"),
                "guard": json.dumps(t.get("guard"), sort_keys=True),
            }
    return out

tn, to = transitions(new), transitions(old)
lost = sorted(set(to) - set(tn))
added = sorted(set(tn) - set(to))
if lost: ok = False; print("\n!! TRANSITIONS LOST: %s" % lost)
if added: print("\n   transitions added: %s" % added)
if not lost and not added: print("OK  transitions preserved (%d)" % len(tn))

rewired = [k for k in tn if k in to and (tn[k]["from"], tn[k]["to"]) != (to[k]["from"], to[k]["to"])]
if rewired:
    ok = False; print("!! TRANSITIONS REWIRED (from/to changed):")
    for k in rewired: print("     %-44s %s->%s  became  %s->%s" % (k, to[k]["from"], to[k]["to"], tn[k]["from"], tn[k]["to"]))
guarded = [k for k in tn if k in to and tn[k]["guard"] != to[k]["guard"]]
if guarded:
    print("   guards changed (review each):")
    for k in guarded: print("     %-44s %s\n%s-> %s" % (k, to[k]["guard"][:90], " "*52, tn[k]["guard"][:90]))
acts = [k for k in tn if k in to and tn[k]["action"] != to[k]["action"]]
if acts:
    ok = False; print("!! ACTION CHANGED (permission-relevant):")
    for k in acts: print("     %-44s %r -> %r" % (k, to[k]["action"], tn[k]["action"]))

def writers(pkg):
    out = {}
    for n, w in ((pkg.get("experience") or {}).get("workflowDefinitions") or {}).items():
        for f, s in (w.get("instanceDataSchema") or {}).items():
            if isinstance(s, dict): out["%s.%s" % (n,f)] = s.get("writableBy")
    return out
wn, wo = writers(new), writers(old)
changed = {k: (wo.get(k), wn[k]) for k in wn if k in wo and wn[k] != wo[k]}
print("\nwriter declarations changed: %d" % len(changed))
for k in sorted(changed): print("    %-52s %r -> %r" % (k, changed[k][0], changed[k][1]))
gone = [k for k in wo if k not in wn]
if gone: print("\n!! fields REMOVED: %s" % sorted(gone)[:12]); ok = False
newf = [k for k in wn if k not in wo]
if newf: print("   fields added: %s" % sorted(newf)[:12])

print("\n%s" % ("VERIFY PASS" if ok else "VERIFY FAIL"))
