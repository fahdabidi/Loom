# Loom MVP — Executive Pitch, Long-Term Vision, and Scope

## Context

The product definition has matured substantially (reviewed via the current uncommitted working tree). Discovery now centers on **Session Intent + Startup Tiles** (fan-chosen `PlatformIntent` × fan-owned `FanInterestProfile`), **summary-first / bring-your-own-AI ranking** (`ContentManifest.summary`), **trending without surveillance** (`HostingTrendingStatsAPI`), **creator-controlled contextual ads** (`CreatorAdPolicy`, no behavioral targeting), and **data-for-value** consent (`CreatorInterestDataGrant`). Combined with the existing pillars — fan-owned identity/wallet/vaults, creator-owned portable channels, AI archive value + source royalties, neutral search, receipts/settlement, and an open certified-provider protocol — Loom is now coherent enough to define a concrete MVP.

This document delivers, in order: **(1)** a killer MVP-only executive pitch, **(2)** the long-term investor vision, **(3)** the MVP scope, and **(4)** a delivery plan. Parts 1–3 are drafted here for review; on approval they become real docs (`docs/Product Docs/00-mvp-pitch-and-vision.md` and an updated `20-mvp-prototype-roadmap.md`).

---

## Part 1 — The MVP Executive Pitch ("killer" pitch)

### Positioning (one line)
**Loom is the single social media platform built for creators and their fans to engage in new ways. Where fans, not an algorithm, choose why they are here — and creators own the fan relationship, not the platform.**

### The problem
Today's platforms optimize for time-on-app, not for creators or fans. Creators don't own their audience and hand a large, compounding cut of their earnings to platforms and intermediaries — YouTube keeps 45% of watch-page ad revenue (and creators get just 45% on Shorts), Patreon and similar tools take roughly 8–12% plus payment fees, and app stores take 15–30% on top. They interact with their fans in limited ways, watch their reach and revenue swing on opaque, ever-changing platform algorithms, can be demonetized by rules they don't control, and watch AI scrape their archives for free. Fans, meanwhile, are dropped into engagement-maximizing feeds engineered to be addictive with clickbait/ragebait by design, with little control or privacy.

### The product (what the MVP is)
A polished **Fan App + Creator Studio** experience with an open pluggable backend, proving the best creator to follower relationship and experience in a single app, replaces multiple social media platforms used by creators and their fans to connect, and allows creators the flexibility to tailor their fan engagement experience.

- A fan opens the app and **picks a tile** — "Fans tell Loom why they are here, their current intent and their current interest: Tennis," "Reviews: Video Games," "Entertainment: Comedy," "Catch up with my creators." Loom never decides for them.
- The provided feed is **glass-box and fan-owned**, the content is provided by the creators the fan trusts: Every item shows why it's there; the fan likes/dislikes/mutes to shape the fans interest profile. **Fans own their profile and can edit, export, or delete**; they can even point **their own AI agent** at it to rank by creator-approved summaries and ignore clickbait titles.
- Ads are **creator-curated and contextual** — host-read-style brand alignment, *no surveillance* — the fan buys **one no-ad pass**.
- The creator runs it all from **a channel they own**: import their catalog, publish with AI-ready summaries, turn their archive into **AI Q&A that earns royalties**, set their **own ad policy**, sell memberships, and **export everything, anytime**.

### Why creators choose Loom
- **You own the fan relationship and the content and can leave.** Portable channel + audience + export to your choice of provider; Loom earns your stay, it doesn't trap it.
- **Your ad environment is yours.** Creators can block what conflicts with their values, no creepy targeting required.
- **You can create your fan experience.** You own your fan data to identify super fans, and using custom plugins you can create unique giveaways or promotional campaigns or rewards.
- **Your archive becomes a product.** AI archive Q&A + **source royalties** — get paid if a Platform AI uses your work. Get paid when you recommend trusted content to your Fans, revenue lines no incumbent offers.
- **Keep more.** You get paid directly for ads and views, then you pay your chosen platform hosting provider. Meaning you keep your content and keep more of the revenue generated from your content.

### Why fans choose Loom
- **Best Rewards and Engagements from Creators.** Easier engagement with creators, going straight from viewing content, to commenting, to viewing their blogs and posts, to engaging with them on their forums, to connecting with them via live promotions, giveaways, and contests.
- **You control the algorithm.** Intent tiles + an interest profile you own = a feed with a purpose, not a slot machine. Lean-back Entertainment/Trending still exists — but only because *you* asked for it.
- **Bring your own AI.** Rank by substance (summaries), strip out ragebait, on your terms.
- **Privacy that pays you back.** No behavioral ad targeting by default; *opt in* to share interests only for a better creator offer (data-for-value), and revoke anytime.
- **One identity, one wallet** for follows, memberships, and entitlements.

### Why Providers choose Loom
Providers are the businesses that run the backend roles behind Loom — hosting, CDN/delivery, AI, ad decisioning, search/index, settlement, vaults, and metadata.

- **Reach the whole market without building a network.** Implement one certified API and instantly serve every creator and app on Loom. Providers win infrastructure revenue without having to own a social platform or fight for an audience first.
- **Compete on merit, not lock-in.** APIs are published and conformance-tested, so providers compete on price, quality, reliability, and data terms. Standardized integration lowers build cost, and the marketplace routes creators and apps to certified providers — low customer-acquisition cost compared with selling infrastructure cold.
- **Recurring, auditable revenue.** Every service rendered emits a signed receipt and settles transparently through `ProviderPayoutStatement` — providers get paid for real usage, with disputes handled on evidence, not goodwill.
- **Ride ecosystem growth.** As creators and certified apps multiply on a shared identity, demand for hosting, AI, ads, and search compounds — providers grow with the network instead of competing to bootstrap one.

**Our wedge: be the first provider and capture the initial share.** At launch, we will operate the default Loom managed backend, so we capture the initial provider revenue (hosting, metadata, ads, AI, settlement) while proving the model end-to-end. We build against — and publish — the same certified APIs everyone else will use, so when a second provider joins, the marketplace becomes real and competitive. But by then we already hold the initial share, the reference implementation, the operational track record, and the trust that makes us the provider to beat. We will continue to implement new Loom Opensource APIs, and expose those as features in the Loom Fan Apps and Creator Portal. While we expose the APIs for the backend, the code that implements the backend will remain proprietary to us in many cases, so other providers will need to "catch-up". And ccreators that choose to use us as the hosting provider will have the best most feature complete platform available. Which can help creators monetize their content better compared to creators using other backend platforms. 

### Why it wins / why now
Creator and fan discontent with engagement-maxing, demonetization, AI scraping, and privacy erosion is at an all-time high — and AI now makes **archive Q&A** and **bring-your-own-agent ranking** genuinely possible for the first time. Loom is the first platform whose incentives are *structurally* aligned with creators and fans rather than with watch-time. The wedge needs no network effect to be 10x: creators bring their own audience to a better home, and the magic (owned archive AI, glass-box intent feed, aligned ads) lands on day one.

---

## Part 2 — The Long-Term Vision (to excite an investor)

### The big idea
**Loom is the open operating system for the creator internet — one fan identity that powers an entire ecosystem of certified social apps.**

Today every social app is a walled garden that re-collects your identity, follows, payments, and data from scratch. Loom inverts this: the **Fan Passport** (identity + wallet + interest profile + entitlements + follow graph) is owned by the fan and **shared across every certified app**. A video app, an audio app, a news app, a learning app, a shopping app, a kids app, a live-events app — each built by a different community developer — all plug into the same identity and economic rails. Fans carry one self everywhere; creators reach them once and keep the relationship; and developers and providers build focused apps and services instead of entire networks. Because they all share the same identity, follow graph, and settlement rails, **developers and providers compete in an open marketplace to win creators' business and to deliver fans a better experience** — so the apps and infrastructure keep improving while no single company owns the network.

### The flywheel
1. Creators bring audiences to owned homes → fans adopt the Fan Passport.
2. Providers + Developers create the Fan Apps and compete for Creators business
3. A shared identity makes the *next* certified app instantly valuable (the fan's follows, wallet, and interests are already there) → developers build more apps.
4. More apps → more reasons for fans and creators to stay → more demand for backend providers (hosting, AI, ads, search) who **compete on price and quality** → costs fall, quality rises, no single party can capture the network.
5. Every transaction emits a **signed receipt** → transparent settlement → trust compounds. Network effects accrue to the *ecosystem*, not to one app.

### Why it's a category-defining platform (the moat)
- **The identity graph + portability standard** become the default rails of the creator economy — the hardest thing to replicate and the thing everything else plugs into.
- **The receipts/settlement layer** is the economic clearinghouse for creator payments, ads, AI royalties, and referrals.
- **Certification + governance** keep it open and trusted, attracting developers and providers the way an app store attracts builders — but without a 30% gatekeeper tax.
- Backend APIs are all published and it starts centralized with our provided backend but **decentralizes the moment a second provider joins**, turning an open-protocol promise into a live, competitive marketplace.

### The market
The creator economy (>$250B and growing fast), plus the digital-advertising, subscription, and social-platform markets it spans. Loom doesn't pick one slice — it becomes the **identity, discovery, and economic layer beneath all of them**, monetizing through transparent utility/marketplace fees rather than monopoly extraction. The comparable isn't "another social app"; it's **"Shopify for your audience meets an app store of social apps, unified by one fan identity."**

### Trajectory
MVP (creator+fan target, our backend with published open APIs, the magic loop) → multi-format creator home + no-ad premium + AI archive economy → **second backend provider (decentralization begins)** → open certified app ecosystem + developer marketplace → the shared-identity standard for the creator internet.

---