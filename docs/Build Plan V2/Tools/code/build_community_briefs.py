import io, json, re, os

REPO = "/home/fahd/Loom/"
DOCS = REPO + "docs/references/communities/"
ASSETS = REPO + "app/packages/core/loom_communities_app_shell/assets/"
OUT = REPO + "data/"

PAIRS = {
    "neighborhood-book-club-product-experience.md": "BookClub",
    "garden-club-product-experience.md":            "GardenClub",
    "chess-club-product-experience.md":             "ChessClub",
    "riverside-youth-soccer-product-experience.md": "YouthSoccer",
    "masjid-nur-product-experience.md":             "Mosque",
    "cedar-commons-hoa-product-experience.md":      "CedarCommonsHOA",
    "camera-club-product-experience.md":            "CameraClub",
    "ad-free-community-product-experience.md":      "AdFreeCommunity",
    "member-social-space-product-experience.md":    "MemberSocialSpace",
    "data-portability-community-product-experience.md": "DataPortabilityCommunity",
}

def strip(t):
    t = re.sub(r'(?<!:)//[^\n]*', '', t)
    return re.sub(r'/\*.*?\*/', '', t, flags=re.S)

for doc, pkgname in sorted(PAIRS.items()):
    src = DOCS + doc
    pkgpath = ASSETS + "Loom_Communities_Workflow_Engine_%s_Example.jsonc" % pkgname
    if not (os.path.exists(src) and os.path.exists(pkgpath)):
        print("SKIP %s" % doc); continue

    pkg = json.loads(strip(io.open(pkgpath, encoding="utf-8").read()))
    exp = pkg.get("experience") or {}
    wfs = sorted((exp.get("workflowDefinitions") or {}).keys())
    tabs = [t["tabId"] for t in (pkg.get("appShell") or {}).get("tabs") or [] if t.get("tabId")]
    roles = [r["roleId"] for r in (exp.get("roles") or []) if isinstance(r, dict) and r.get("roleId")]

    rows = ["| Field | Value |", "| --- | --- |"]
    for k in ("specVersion", "packageId", "communityId", "communityHandle", "displayName", "extensionId"):
        if pkg.get(k) is not None:
            rows.append("| `%s` | `%s` |" % (k, pkg[k]))

    block = ["", "---", "", "## Existing identifiers - preserve these exactly", ""] + rows
    block += ["", "**Role ids:** " + ", ".join("`%s`" % r for r in roles)]
    block += ["", "**Tab ids:** " + ", ".join("`%s`" % t for t in tabs)]
    block += ["", "**Workflow type ids:** " + ", ".join("`%s`" % w for w in wfs)]
    block += ["",
        "This package already ships. Preserve every identifier above, every workflow,",
        "and every tab. Apply the reference materials you fetch from GitHub - the",
        "grammar, archetype and validation docs are authoritative and current.", ""]

    text = io.open(src, encoding="utf-8").read() + "\n".join(block)
    dst = OUT + "%s_brief.md" % pkgname.lower()
    io.open(dst, "w", encoding="utf-8", newline="\n").write(text)
    print("%-18s %2d wf  %d tabs  %d roles  -> %s" % (pkgname, len(wfs), len(tabs), len(roles), os.path.basename(dst)))
