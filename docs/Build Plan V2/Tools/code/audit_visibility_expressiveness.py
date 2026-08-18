#!/usr/bin/env python3
"""Audit whether every workflow can actually EXPRESS its intended readers under
the specVersion-4 visibility models.

For each shipped community fixture, for every workflow whose archetype uses a
visibility model that reads instance-data identities, report:
  - the archetype family and its required visibility.fields key
  - every identity-typed field the workflow declares (the only things nameable)
  - the readGuard the community actually wrote (its real intent)
  - whether the required key can be satisfied at all

The question being answered is not "which findings exist" (the validator already
says that) but "which findings are UNSATISFIABLE as the grammar stands" -- i.e.
where the spec cannot express the community's real access rule.
"""
import json, re, sys, pathlib

# archetype family -> (visibility model, required visibility.fields key, arity)
# Mirrors ArchetypeResolver.contracts + the validator's requiredKey switch.
MODEL = {
    'documentLibrary':   ('owner_and_shared', 'sharedWith',   1),
    'discussionThread':  ('participants',     'participants', None),  # no arity rule
    'approvalQueueItem': ('parties',          'parties',      2),
    'paymentCheckout':   ('parties',          'parties',      2),
    'notificationInbox': ('recipient',        'recipient',    1),
}

IDENTITY_TYPE = re.compile(r'^(personaId|fanId|roleId)(\[\])?\??$')


def strip_jsonc(text):
    out, i, n = [], 0, len(text)
    in_str = esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == '\\':
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            while i < n and text[i] != '\n':
                i += 1
            continue
        if c == '/' and i + 1 < n and text[i + 1] == '*':
            i += 2
            while i + 1 < n and not (text[i] == '*' and text[i + 1] == '/'):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def families(wf):
    fams = set()
    for b in wf.get('renderBindings') or []:
        f = b.get('cardSurfaceFamily')
        if f:
            fams.add(f)
    return fams


def identity_fields(wf):
    found = []
    for name, spec in (wf.get('instanceDataSchema') or {}).items():
        if isinstance(spec, dict) and IDENTITY_TYPE.match(str(spec.get('type', ''))):
            found.append((name, spec['type']))
    return found


def describe_guard(g):
    if not isinstance(g, dict):
        return '(none)'
    if 'formula' in g:
        return f"formula: {g['formula']}"
    if 'actorEqualsField' in g:
        return f"actorEqualsField: {g['actorEqualsField'].get('key')}"
    for k in ('allowedRoleIds', 'allowedPersonaIds'):
        if k in g:
            return f"{k}: {g[k]}"
    return str(g)[:90]


def main(paths):
    rows = []
    for p in paths:
        path = pathlib.Path(p)
        name = path.name.replace('Loom_Communities_Workflow_Engine_', '').replace('_Example.jsonc', '')
        try:
            pkg = json.loads(strip_jsonc(path.read_text(encoding='utf-8')))
        except Exception as e:
            print(f"!! {name}: parse failed: {e}", file=sys.stderr)
            continue
        for wtype, wf in ((pkg.get('experience') or {}).get('workflowDefinitions') or {}).items():
            if not isinstance(wf, dict):
                continue
            fams = families(wf)
            bespoke = [f for f in fams if f in MODEL]
            if not bespoke:
                continue
            fam = bespoke[0]
            model, key, arity = MODEL[fam]
            vis = wf.get('visibility') or {}
            declared = (vis.get('fields') or {})
            if key in declared:
                continue  # already satisfied
            ids = identity_fields(wf)
            satisfiable = (arity is None) or (len(ids) >= arity)
            rows.append({
                'community': name, 'workflow': wtype, 'family': fam, 'model': model,
                'key': key, 'arity': arity, 'identity_fields': ids,
                'readGuard': describe_guard(vis.get('readGuard')),
                'default': vis.get('default'), 'satisfiable': satisfiable,
            })

    unsat = [r for r in rows if not r['satisfiable']]
    print(f"TOTAL findings needing visibility.fields: {len(rows)}")
    print(f"  SATISFIABLE (enough identity fields exist): {len(rows) - len(unsat)}")
    print(f"  UNSATISFIABLE (cannot be expressed today): {len(unsat)}")
    print()
    for label, subset in (('UNSATISFIABLE', unsat),
                          ('SATISFIABLE', [r for r in rows if r['satisfiable']])):
        print(f"===== {label} =====")
        for r in sorted(subset, key=lambda r: (r['community'], r['workflow'])):
            names = ', '.join(f"{n}:{t}" for n, t in r['identity_fields']) or '(NONE)'
            need = f"needs {r['arity']}" if r['arity'] else 'no arity rule'
            print(f"{r['community']:<26} {r['workflow']:<32} {r['family']:<18} "
                  f"{r['key']:<13} {need:<12} has {len(r['identity_fields'])}: {names}")
            print(f"{'':<26} readGuard -> {r['readGuard']}  (default: {r['default']})")
        print()


if __name__ == '__main__':
    main(sys.argv[1:])
