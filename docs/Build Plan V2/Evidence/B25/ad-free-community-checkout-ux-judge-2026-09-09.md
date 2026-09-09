# UX judge verdict — Ad-Free Community, `ad-off-community-checkout`

**Workflow:** `ad-off-community-checkout` in Ad-Free Community
**Verdict:** PASS
**Judged:** 2026-09-09, model `fable`, from 38 frames of the same-day live walkthrough (`a0528ec7`)
**Frames:** gitignored; this verdict is the durable record of what they showed.
**Open finding carried forward:** the `ad-off-settlement-utility` instance the declared effect spawned is proven in Postgres but has NO visible consequence in any captured frame. The row meets its own bar; "the settlement visibly appears after funding" is unproven by pixels and needs one more captured screen.

---

**Verdict: PASS** on the B25 bar for `ad-off-community-checkout`, judged from the pixels — with one visibility finding on the `createInstance` effect, and several stale ticket specifics corrected against the manifest. Full verdict written to `evidence/b25-adfree-community-checkout-20260909/JUDGE-VERDICT.md` (not committed; commit it alongside the manifest if you want it durable — the frames themselves are gitignored).

**The ticket and the manifest disagreed, and the manifest wins.** The ticket's evidence path (`b25-ad-off-…`), frame count (14), frame roles (entry 29 / action 39 / result 40 / regression 42 / terminal 43), flow (`published → delisted`), and role (`member`) are all stale carryovers. The real run: directory `b25-adfree-community-checkout-20260909`, 38 frames ending at `39-funded.png` (frames 40–43 do not exist), flow `unfunded → reviewing → funding-pending → funded`, driven as `ad-off-owner` ("Owner"), which the pixels confirm on every community screen.

**Why it passes.** Every state shows a distinct primary plus at least one alternate/change/reject affordance, all matched on whole button labels:

- **Create** (frame 15/16): FAB "Fund community ad-off"; dialog with all 7 fields, Create + Cancel.
- **`unfunded`** (32): the card with every typed value visible, primary "Give community ad-off".
- **`reviewing`** (35): primary "Checkout funding", change "Change amount or payment", reject "Cancel funding" — all on one screen.
- **`funding-pending`** (36/37): primary "Record verified funding" (with a Coverage Ends At input dialog), alternate "Record funding failure", reject "Cancel funding".
- **`funded`** (39): success badge, "Funded 2026-09-09T19:51:58.411618Z" and "Coverage ends 2026-12-08" chips agreeing with the manifest's database read-back, sole exit "Request funding refund".

State badges are correctly toned and plain-language, and the Owner's on-screen role blurb matches the affordances offered — comprehensible to the persona.

**The finding worth acting on:** the `ad-off-settlement-utility` instance the effect spawned is proven in Postgres but **has no visible consequence in any frame**. The run ends at frame 39, which shows only the funded checkout and the entitlement card. The Owner's role text promises "audits settlement and utility allocation", so a surface may exist (Admin tab, perhaps), but it was never captured and I won't infer it. The row's own bar is met; "the settlement visibly appears after funding" remains unproven by pixels and would need one more captured screen in a future run.

Minor notes: frame 30 is named `created` but shows the tab header, not the new card (frame 32 carries that proof), and frame 31's "Suppression proof ready" card belongs to a pre-existing member instance, not this row.
