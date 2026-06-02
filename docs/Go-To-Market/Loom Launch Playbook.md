# Loom Launch Playbook

Status: Draft for review
Type: Go-to-market strategy
Audience: Founders, growth, creator partnerships

## Purpose

This document does two things:

1. **Analyzes social platforms launched in the last ~3 years** — how they differentiated,
   how they marketed, and how they acquired users — separating what scaled from what died.
2. **Translates those lessons into a reusable playbook** to launch Loom and drive both
   **creator** and **fan** adoption.

It is a strategic playbook (principles + strategy), not a dated rollout plan. It is grounded
in the platform research cited in [Sources](#sources) and in Loom's own product definition
([Loom Product Pitch](../MVP%20Planning/Loom%20Product%20Pitch.md),
[Core Thesis](../Product%20Docs/01-core-thesis-and-platform-principles.md),
[Migration Strategy](../Product%20Docs/21-migration-strategy-from-existing-platforms.md)).

The single most important fact about Loom's launch: **a creator can get value on Loom before any
network effect exists.** Its wedge thesis is that *creators bring their own audience to a better
home* — but be precise about what "bring" means. Loom **cannot import a follower graph** from
Twitch/YouTube/X (third parties don't expose it); the graph is **rebuilt on Loom** as fans choose
to re-follow, and ownership/portability is the reward earned *after* switching (and it applies
across Loom apps, not as an import from incumbents). What makes this tractable is **single-player
utility** — Loom is 10x better on day one for a single creator and their fans *before* the audience
finishes migrating. Almost every recommendation below follows from these two facts.

---

## Part 1 — Analysis: social platforms launched in the last ~3 years

### Teardown table

| Platform (launch) | Core differentiation | Marketing / positioning | How it acquired users | Outcome & lesson |
| --- | --- | --- | --- | --- |
| **Threads** (Jul 2023) | Thin — a text-first Twitter clone | "The friendly alternative to Twitter," ridden on the Musk/X backlash | **Borrowed the Instagram graph** — required an IG login; one-tap import of follows | 100M users in 5 days (fastest app ever), ~275M MAU in year one. *An existing audience is the strongest growth lever — but **Loom can't copy the method**: Meta owned both graphs; Loom can't extract follows from incumbents (see Pattern 1).* |
| **Bluesky** (public Feb 2024) | **User control as the product**: AT Protocol, 50,000+ choosable feed algorithms, user-owned identity & moderation | "The social web should be a protocol, not a platform; you own your experience" | Invite-only scarcity early; **Starter Packs** (one-tap follow a curated community + feeds); **event-driven spikes** on X controversies | ~41M users by end-2025, $100M Series B. *Ownership + control is a real wedge; frictionless community onboarding and defection moments drive the bursts.* |
| **Substack / Patreon** (creator-economy wars, 2023–25) | **Direct-to-fan ownership** of audience + recurring revenue | "Own your list, own your revenue, escape the algorithm" | Substack's **$20M Creator Accelerator Fund** literally pays creators to migrate paid subscribers off rivals | Substack $100M raise at $1.1B; Patreon $10B+ lifetime to creators (podcasts the top category). *On two-sided creator platforms you win by subsidizing supply-side migration and selling predictable, owned revenue.* |
| **Lemon8** (US, 2023) | Lifestyle photo-blog niche (Pinterest × IG) | Aesthetic, aspirational lifestyle content | **Cross-promotion from TikTok** + paid creator seeding | Millions of downloads on launch. *An owned adjacent distribution channel is a cold-start cheat code.* |
| **Noplace** (Jul 2024) | **Anti-algorithm + identity expression** (Twitter × MySpace, profile customization) | "Make the internet fun again," Gen-Z, no opaque feed | Waitlist hype → opened to public | Hit #1 US App Store, $19M raised. *A sharp values/aesthetic wedge can win a demographic fast.* |
| **BeReal** (peaked 2022–23) | Authenticity gimmick: one daily prompt, dual camera | "Your friends for real, no filter" | Campus ambassadors, viral novelty | 73M → ~23M users. *Killed by forced engagement, brand/celebrity dilution of the core promise, and trivially copied features. A novelty mechanic is not retention.* |
| **Post.news / Artifact** (both shut 2024) | "Better Twitter" / AI news reader | News-quality, anti-toxicity | Press + waitlists | Shut down — "market not big enough" / couldn't reach viable scale. *A better-Twitter with no structural advantage and no owned graph dies.* |
| **Farcaster / Nostr** (protocol-first) | Decentralized protocols; token incentives ($DEGEN), wallet identity | "Sufficiently decentralized social" | Crypto-native communities, token rewards | Strong tech (Snapchain 10k+ TPS) but MAU peaked ~80k and fell below ~20k. *Protocol purity ≠ adoption; token incentives attract speculators, not durable fans.* |

### What the cases say, in one paragraph each

**Threads** proves an existing audience beats everything: a mediocre clone became the fastest-growing app in history purely because Meta could import the Instagram graph with one tap. **But Loom cannot copy this** — Threads worked *because Meta owned both graphs*; Loom is a third party and cannot extract follows from Twitch/YouTube/X. So Threads is a lesson about the *power* of an existing audience, not a *method* Loom can use. Loom's replicable model is Bluesky/Substack: the creator announces and fans **re-follow manually**. The flip side — weak differentiation — also gave Threads a steep early retention cliff once novelty faded.

**Bluesky** is the closest analog to Loom's *values*. It turned "you own your identity and choose your own feed" into the product, not a footnote. Crucially, its growth was not steady marketing — it came in **bursts tied to incumbent pain** (every time X changed something unpopular), captured by two pieces of frictionless onboarding: invite scarcity (early) and **Starter Packs** that let a newcomer follow an entire curated community in one tap.

**Substack and Patreon** are the creator-economy reference. The decisive 2024–25 move was Substack **paying creators to migrate their paying fans** via a $20M guarantee fund. The selling point to creators was never features — it was *owning the audience relationship and predictable recurring revenue* instead of renting reach from an algorithm.

**Lemon8** shows that an owned adjacent channel (TikTok) collapses the cost of cold start — you import distribution instead of buying it.

**Noplace** shows a sharp values/aesthetic wedge can capture a demographic quickly, but also that novelty-led apps must convert hype into a durable reason to stay.

**BeReal, Post, Artifact, Farcaster/Nostr** are the cautionary set. BeReal: protect the core promise and never force engagement. Post/Artifact: "better Twitter" with no structural edge and no owned graph is a dead end. Farcaster/Nostr: leading with protocol and tokens recruits enthusiasts and speculators, not the mainstream fans creators actually have — a direct warning for any open-protocol product.

---

## Part 2 — Extracted patterns

Seven cross-cutting principles, each tied to the evidence above. These are the load-bearing
rules for the Loom playbook.

1. **Channel an existing audience; don't market to strangers.** *(Bluesky, Substack — not
   Threads)* The fastest growth comes from creators pointing an audience they already have at a new
   home. **Crucial constraint for Loom:** unlike Threads (Meta owned *both* graphs and could import
   Instagram follows with one tap), Loom is a third party and **cannot import anyone's follower
   graph** out of Twitch/YouTube/TikTok/X — those platforms don't expose it. So Loom's graph is
   **rebuilt from scratch on Loom**: the creator announces, and each fan must **manually re-follow**.
   The replicable model is Bluesky ("I'm here now," posted on X) and Substack (driving an audience
   to re-subscribe) — *not* Threads' one-tap import. The asset a creator brings is **reach + their
   owned contact channels** (email list, Discord, live chat), not a portable follower list.
   Ownership/portability of the graph is the **reward earned after switching**, and it applies
   *within* Loom (across Loom apps/providers via the fan passport) — never as a migration import
   from an incumbent.

2. **Single-player utility first.** *(Cold-start research; Substack standalone publishing)* The
   product must deliver value to a creator with **zero Loom fans**. If a creator only benefits
   once their audience arrives, you have a chicken-and-egg deadlock. Loom's owned hub + archive
   AI must be worth it on day one, alone.

3. **Subsidize the hard side (supply).** *(Substack $20M fund)* Creators are the scarce,
   expensive side. Use migration guarantees / revenue floors to de-risk the switch for a small
   number of anchor creators — they pull the fans for free.

4. **Make community onboarding one tap.** *(Bluesky Starter Packs)* When a fan arrives, don't
   drop them into an empty feed. Let them follow their creator *and that creator's recommended
   creators* in a single action, and land on a feed that is immediately full.

5. **Engineer defection moments.** *(Bluesky's X-exodus spikes)* Growth comes in bursts timed to
   incumbent pain. Be ready to capitalize on demonetization waves, ad-targeting/privacy backlash,
   and AI-scraping controversy with pre-built migration tooling and messaging.

6. **Lead with a values + ownership wedge, not a feature gimmick.** *(Bluesky won; BeReal lost)*
   Durable differentiation is structural (who owns the audience, the revenue, the data), not a
   novel mechanic that competitors copy in a quarter.

7. **Keep the protocol invisible; never go token-first.** *(Farcaster/Nostr)* Open protocol and
   portability are the moat, but they are *back-of-house*. Users see mainstream UX and real
   creator revenue. Decentralization is a promise you redeem, not a pitch you lead with.

---

## Part 3 — The Loom Launch Playbook

### 3.1 Positioning & messaging

Two audiences, two one-liners — each backed by a verified Loom differentiator.

- **To creators:** **"Own your audience, your archive, and your revenue — and take it all with
  you."**
  Backed by: portable creator channel, AI archive Q&A with source royalties, keep-more economics
  (you get paid directly, then pay your chosen provider), and the export/migration right.

- **To fans:** **"You pick why you're here. The algorithm doesn't."**
  Backed by: glass-box intent tiles + a fan-owned interest profile, bring-your-own-AI ranking,
  the one no-ad pass, and no behavioral ad targeting by default.

Messaging discipline (from Pattern 6 & 7): lead with **ownership and control**, demonstrate with
**the magic loop** (owned archive AI, intent feed, aligned ads), and keep "open protocol /
certified providers / portability" as the *proof* that ownership is real — never the headline.

### 3.2 Differentiation vs. incumbents

| Dimension | YouTube | Patreon | Substack | Bluesky | **Loom** |
| --- | --- | --- | --- | --- | --- |
| Who owns the audience | Platform | Platform (gated) | **Creator (list)** | User (protocol) | **Creator + portable fan passport** |
| Revenue cut to creator | ~45% kept by YT on watch-page ads | ~8–12% + fees | ~10% + fees | n/a (no native monetization) | **Creator paid directly, then pays chosen provider** |
| Ads | Behavioral targeting | n/a | n/a | n/a | **Creator-curated, contextual, no surveillance; fan no-ad pass** |
| AI / archive | Scrapes archives for free | none | none | none | **Archive Q&A that pays the creator source royalties** |
| Discovery | Opaque engagement algorithm | none | none | **Choosable feeds** | **Fan-chosen intent tiles + creator-led recommendations + neutral search** |
| Portability / exit | Locked in | Locked in | Email export only | Protocol-portable | **Full channel + audience + receipts export; provider exit button** |

The honest competitive read: **Bluesky is the closest on values** (ownership/control), but it has
no creator monetization and no archive economy; **Substack/Patreon own the revenue story** but
lock format and don't give fans portability or control. Loom's defensible space is the
**intersection — creator ownership *and* fan ownership *and* a new archive/AI revenue line** — that
no incumbent occupies.

### 3.3 The launch wedge — five candidates, overlap map, and a sequenced recommendation

The wedge is the single most important launch decision, so this section evaluates **five candidate
wedges** against four tests, maps where they **overlap** (Loom's cross-app fan passport makes
overlap the decisive sequencing factor), and ends with a recommended **wedge sequence**.

The four tests:

1. **Acquisition ceiling** — total-user potential (TAM × fan intensity × **conversion yield**:
   how reliably a creator can drive their *existing* audience to manually re-follow on Loom).
   Conversion yield is highest where fans are loyal **and** the creator has a *direct line* to them
   (live chat, Discord, email list) rather than algorithm-fed reach they don't control.
2. **Incumbents & how Loom compares** — who owns the vertical today and where Loom is structurally
   better.
3. **Switch likelihood** — how acute the creator/fan pain is, and whether creators in the vertical
   have *demonstrably* switched platforms before.
4. **Loom feature fit** — how many of Loom's differentiators (archive AI + royalties, intent tiles,
   contextual ads, campaigns, owned audience, portability, neutral search) actually fire.

> **Reality check — the graph is rebuilt, not imported (Pattern 1).** Loom cannot pull a creator's
> followers out of an incumbent; every fan must choose to re-follow on Loom. So the initial
> incumbent→Loom hop is a genuine, manual cold start, and wedge value hinges on **conversion yield**
> above. The good news: this cost is paid **once**. After a fan is on Loom, their follows/identity
> are portable *across Loom apps and verticals* via the fan passport — so expanding along the
> overlap chain (§3.3.3) is a **warm** start. Sequence accordingly.

#### 3.3.1 Scorecard

| Wedge | Acquisition ceiling | Switch likelihood (incumbent pain) | Loom feature fit | Overlap with other wedges |
| --- | --- | --- | --- | --- |
| **1. Gaming & esports** (live + VOD + community) | **High** | **High** — proven | **Very high** | **High** (→ tech, → sports via esports) |
| **2. Tech / hardware / dev / finance creators** | **High** | **Med–High** | **Very high** (archive AI) | **Very high** (↔ gaming, ↔ podcasts) |
| **3. Podcasters** (treat as a *format*, not an island) | **High** | **Med** | **High** (transcript Q&A, ads) | **Very high** (cross-cuts every wedge) |
| **4. Sports fandom & analysis** | **Very high** | **Med** | **High** (intent tiles, campaigns) | **Med** (← esports bridge) |
| **5. Fitness & wellness coaching** | **Med–High** | **Med** | **High** (program library, challenges) | **Low** (separate lifestyle cluster) |

*(Deliberately deferred: **adult / creator monetization** — OnlyFans/Fanvue-style. It has the
**highest** switch motivation, revenue-per-fan, and ownership resonance of any vertical, and Loom's
portability pitch is tailor-made for it. But payment-processor, app-store, brand-safety, and
trust/safety risk make it a dangerous *first* wedge for a platform that needs mainstream creators,
endemic sponsors, and app-store distribution. Revisit only after the core is established.)*

#### 3.3.2 The five candidates

**1. Gaming & esports.**
*Incumbents:* Twitch, YouTube Gaming, Kick, Discord, Patreon — and they're fragmented: a creator
streams on Twitch/Kick, posts VODs to YouTube, runs community on Discord, and sells membership on
Patreon ("tool sprawl"). *How Loom compares:* it collapses that stack into one owned home and pays
the creator directly. *Highest conversion yield of any wedge:* streamers have the strongest **direct
line** to their fans — live chat, Discord, loyal subscribers — so when they say "re-follow me on
Loom," a large share actually do. That direct relationship (not a follower export, which is
impossible) is what makes the manual cold start cheap here. *Switch likelihood is the highest of any
wedge, and it's proven:* Twitch's
50/50 split (only ~2.5% of partners reach 70/30 via Partner Plus) triggered a visible exodus to
Kick's 95/5 — Adin Ross said he made more on Kick "with half the viewers." Gamers demonstrably move
platforms for economics + ownership, which is exactly Loom's pitch. *Feature fit is the best of all
five:* archive Q&A → build guides, patch histories, searchable VOD lore; campaigns/giveaways → native
to gaming; contextual endemic ads → how gaming sponsorship already works; super-fan data → drops,
tournaments, perks; and the intent feed is literally the pitch's "Reviews: Video Games" tile.

**2. Tech / hardware / dev / finance "knowledge" creators.**
*Incumbents:* YouTube, X, Substack, Patreon, podcast apps. *How Loom compares:* this is where
**archive AI is most valuable** — fans query a creator's entire back-catalog ("which GPU did they
recommend for X?", "summarize their thesis on Y"), with source royalties to the creator.
*Switch likelihood Med–High:* these creators are early adopters and ideologically aligned with
Loom's thesis (own your data, anti-surveillance, anti-AI-scraping); many already run newsletters,
signalling they already value owning the audience. *Feature fit very high:* archive Q&A, neutral
search, bring-your-own-AI ranking (their audience *wants* this), and data-for-value.

**3. Podcasters — treat as a format layer, not a standalone wedge.**
*Incumbents:* Spotify, Apple, YouTube, Patreon. Podcasts are Patreon's top-earning category, and
Spotify payout discontent is loud (Björk: "the worst thing that has happened to musicians"; Ek's
"not everyone can live off it" sports analogy). *How Loom compares:* transcript archive Q&A is a
goldmine, host-read contextual ads map natively to Loom's ad model, and memberships are portable.
*But* podcasting cross-cuts gaming, tech, sports, and comedy — it is a **format every other wedge's
creators already use**, not an island. *Strategic use:* don't run "podcasters" as a cold-start
wedge; light up podcast features so they ride along inside wedges 1 and 2, where the creators
already podcast.

**4. Sports fandom & analysis.**
*Incumbents:* YouTube, X, The Athletic/Bleacher, Discord, league/team apps. *How Loom compares:*
the most intense fans of any wedge and a perfect fit for intent tiles
(the pitch's literal "Tennis" tile), live + archive, and prediction/fantasy campaigns.
*Switch likelihood Med:* fan intensity is enormous but independent-creator monetization pain is less
acute than gaming/Spotify, league rights complicate official content, and much sports reach is
algorithm-fed rather than a direct creator→fan line — so **conversion yield is lower** than the raw
fan intensity suggests. *Feature fit high:* intent
tiles, campaigns, contextual (incl. betting-endemic) ads. Best reached **via the esports bridge**
rather than cold.

**5. Fitness & wellness coaching.**
*Incumbents:* Instagram, YouTube, Patreon, niche apps (Future, Playbook). *How Loom compares:*
memberships + "ask my coach's library" archive Q&A + challenge campaigns + super-fan tools beat the
IG-algorithm-then-DM-to-sell status quo. *Switch likelihood Med:* real conversion pain, but the
audience is more casual/lifestyle and less "switch-prone," and trust matters a lot. *Feature fit
high* but it's a **separate cluster** with little creator/fan overlap with wedges 1–3 — so it would
be a near-fresh cold start. A good *later* expansion, not a seed.

#### 3.3.3 Overlap map (why sequence beats raw TAM)

Loom's defining advantage is that **a fan keeps their identity, wallet, and follows across apps and
verticals.** That means the right way to sequence is *by overlap* — never start a fresh cold-start
when an adjacent, overlapping one is available. The wedges cluster like this:

- **Cluster A (the dense core):** **Gaming → Tech/Hardware → broader edutainment/knowledge**, with
  **podcasting as a format layer riding the whole way.** These share both *fans* (gamers are
  tech-literate; tech/finance audiences game) and *creators* ("bridge creators" who stream **and**
  do a tech/finance podcast are common). Overlap here is High-to-Very-High.
- **Cluster B:** **Sports → betting / fantasy**, reachable from Cluster A through the **esports
  bridge** (esports sits between gaming and sports fandom).
- **Cluster C:** **Fitness → wellness → lifestyle** — a separate cluster with little overlap with A.

Because the fan passport monetizes overlap, Cluster A is worth far more than its raw TAM suggests:
each new wedge inside it inherits live follows and a non-empty feed from the previous one, so the
*second* and *third* cold starts are barely cold at all.

#### 3.3.4 Recommended wedge & sequence

**Seed Cluster A, in this order; expand to B and C only after the core is dense.**

1. **Wedge 1 — Gaming & esports (the seed).** Pick **one game's community** and concierge-recruit
   mid-tier creators (≈10k–500k followers) to a network flip before widening. *Why first:* fastest
   flip (most intense fans), the **only wedge with proven switch behavior** (Twitch→Kick), and it
   exercises *every* Loom feature on day one.
2. **Wedge 2 — Tech / hardware / dev creators.** *Why second, specifically:* it has the **highest
   creator-and-fan overlap with gaming**, so the fan passport pays off immediately — a gamer's
   follow of a tech creator carries over, and bridge-creators who do both make this cold start
   nearly free. It also unlocks the audience where **archive AI is most valuable**, deepening the
   core retention loop.
3. **Wedge 3 — Broader knowledge / edutainment, with podcasting switched on as a format.** *Why
   third:* archive AI's best home, and wedges 1–2 creators already podcast, so the format rides
   along rather than requiring a new push. This is the point Loom becomes a general knowledge-creator
   platform rather than a gaming app.
4. **Then Cluster B (sports, via the esports bridge) and Cluster C (fitness/lifestyle)** as parallel
   new expansions once Cluster A is self-sustaining. These have lower overlap with the seed, so treat
   each as its own (now well-resourced) mini cold start.

The principle to hold onto: **sequence by overlap, not by raw TAM.** Sports has the biggest
standalone audience, but starting there would waste Loom's cross-app superpower; starting with
gaming and walking the overlap chain turns each subsequent wedge into a warm start.

Validation gate before committing spend on Wedge 1: choose the single game community with (a) the
densest creator-to-creator referral graph, (b) the most acute monetization pain on incumbents, and
(c) endemic sponsors already spending — then seed it to a flip before opening Wedge 2.

### 3.4 Creator acquisition strategy

Sequence creators **first** (they bring the fans):

1. **Concierge recruit <100 anchor creators** in the chosen sub-vertical (cold-start "concierge
   under 100 pairs"). Hand-onboard them; treat each like a partnership, not a signup.
2. **De-risk the switch with a migration guarantee / revenue floor** for anchors (the Substack
   $20M-fund pattern, scaled to the wedge). They should face *no downside* to making Loom their
   owned home.
3. **Deliver single-player utility immediately (Pattern 2).** Before any fan migrates, a creator
   already gets: an owned hub + link-in-bio, public-metadata import of their existing catalog, and
   **archive AI Q&A** turning their back-catalog into a product. This is the "aha" that makes Loom
   worth it alone. (Tooling already specced in
   [Migration Strategy](../Product%20Docs/21-migration-strategy-from-existing-platforms.md).)
4. **Turn recommendations into a growth loop.** Creator-led recommendations + referral revenue
   mean each anchor creator has a paid incentive to pull in the next creator — supply-side
   compounding inside the wedge.
5. **Arm them to re-acquire their audience (it can't be imported).** The follower graph cannot be
   exported from incumbents, so every fan must be *converted* by the creator. Give them the funnel:
   announcement templates, link-in-bio, QR, pinned cross-posts, and — highest-yield — direct
   pushes through channels the creator **owns** (email list, Discord, live-stream call-outs). Make
   re-following one frictionless tap on landing, and let creators cross-post so they drive the
   audience without abandoning the platforms that still feed them reach.

### 3.5 Fan acquisition strategy

Fans are **not** acquired by cold marketing — they arrive **through a creator they already
follow** (Pattern 1). The job is to make that arrival frictionless and sticky:

- **One-tap community onboarding (Pattern 4 / Bluesky Starter Packs):** follow this creator *and*
  their recommended creators in a single action, and land on a feed that is already full —
  pre-populated by the creator's intent tiles and recommendations. Never show an empty feed.
- **Fan hooks unique to Loom:** the **glass-box intent tiles + owned interest profile** ("a feed
  with a purpose, not a slot machine"), **bring-your-own-AI ranking** — now extended to **AI search
  across the open web** (a fan's own agent ranks creator content *and* external results like YouTube,
  with ragebait titles de-emphasized and creator content preferred), the **one no-ad pass**, and
  **privacy that pays you back** (opt-in data-for-value). *(Roadmap: Phases 21–26.)*
- **Retention differentiator:** the intent feed is the explicit antidote to the engagement-maxing
  slot-machine feed fans say they're tired of — this is the *reason to stay*, not just to arrive.

### 3.6 Retention & moats

- **Switching cost earned, not trapped.** Owned identity/wallet + portability raise switching cost
  *for the right reason* — "Loom earns your stay, it doesn't trap it." The export/exit button is a
  trust feature, not a leak.
- **Trust compounds via receipts.** Transparent, auditable settlement ("no receipt, no payout")
  builds the trust incumbents have burned.
- **Two compounding loops:** archive-AI royalties grow as the back-catalog grows; the shared fan
  passport + cross-creator follow graph make each new creator and each new community more valuable
  than the last.
- **Protect the core promise (BeReal's lesson):** never bolt on forced-engagement mechanics, and
  don't dilute the creator/fan-aligned positioning with brand-first features too early.

### 3.7 Anti-patterns to avoid (explicit)

- **Protocol-first / token-first marketing.** *(Farcaster/Nostr)* Keep the protocol invisible;
  never recruit with tokens or "decentralization" as the headline.
- **Thin "better Twitter/YouTube" differentiation.** *(Post, Artifact)* If the pitch is "same
  thing, nicer," there's no structural edge — and no reason to defect.
- **Forced engagement mechanics.** *(BeReal)* Streaks, mandatory prompts, and dark patterns
  contradict the fan-control promise and don't retain.
- **Diluting the core promise too early.** *(BeReal)* Don't flood the wedge with brands/celebrities
  before the creator-fan culture is established.
- **Seeding both sides cold.** Don't market to fans before creators; import creator graphs instead
  of buying fan installs.
- **Going broad before density.** Resist expanding to a second vertical before the first one hits a
  network flip — breadth before density is how cold-start dies.

### 3.8 What to measure (leading indicators)

No dated plan — watch these signals to know whether the playbook is working:

- **Anchor-creator count & retention** in the wedge vertical (are the <100 sticking?).
- **Conversion yield = fans re-followed per creator** (existing audience → actual Loom follows;
  the core lever, since the graph is rebuilt manually, not imported).
- **% of creators reaching the single-player "aha"** (archive AI live + catalog imported) *before*
  fan migration.
- **Referral-driven follow rate** (is the creator-recommendation loop compounding supply?).
- **Network-flip density within the wedge** (fan-to-fan and creator-to-creator overlap reaching
  self-sustaining levels) — the gate to open the next vertical.
- **Defection-moment capture** (sign-up spikes converted during incumbent-pain events).

---

## Sources

- Threads growth — [CNBC](https://www.cnbc.com/video/2023/07/10/threads-becomes-fastest-growing-app-in-history-hitting-100-million-users-in-five-days.html), [TIME](https://time.com/6292957/threads-fastest-growing-apps/), [Wikipedia](https://en.wikipedia.org/wiki/Threads_(social_network))
- Bluesky — [Starter Packs](https://bsky.social/about/blog/06-26-2024-starter-packs), [Series B / growth (TechCrunch)](https://techcrunch.com/2026/03/19/bluesky-announces-100m-series-b-after-ceo-transition/), [Sprout Social stats](https://sproutsocial.com/insights/bluesky-statistics/)
- Noplace & Airchat — [Hootsuite](https://blog.hootsuite.com/new-social-media-apps-platforms/), [Backlinko](https://backlinko.com/new-social-media-platforms)
- BeReal decline — [EM360](https://em360tech.com/tech-articles/what-happened-bereal-authenticity-obscurity), [Dazed](https://www.dazeddigital.com/life-culture/article/61166/1/why-did-bereal-fail-social-media-instagram-authenticity)
- Post / Artifact shutdowns — [The National](https://www.thenationalnews.com/future/technology/2024/04/22/post-social-platform/)
- Substack / Patreon creator wars — [TechCrunch ($20M fund)](https://techcrunch.com/2025/01/23/substack-introduces-a-20m-funding-guarantee-to-entice-creators-to-migrate-to-its-platform/), [Contrary Research (Patreon)](https://research.contrary.com/company/patreon)
- Farcaster / Nostr — [BlockEden "protocol paradox"](https://blockeden.xyz/blog/2025/10/28/farcaster-in-2025-the-protocol-paradox/), [arXiv: pluralistic incentives](https://arxiv.org/pdf/2511.00827)
- Cold-start tactics — [Two-sided cold-start playbook (Forkoff)](https://forkoff.xyz/blog/founder-growth/two-sided-marketplace-cold-start-2026), [David Ciccarelli: product-marketing for two-sided platforms](https://www.davidciccarelli.com/articles/product-marketing-playbook-for-two-sided-platforms/)
- Gaming switch behavior (Twitch 50/50, Partner Plus, Kick 95/5, Adin Ross) — [Dot Esports](https://dotesports.com/streaming/news/why-are-so-many-streamers-leaving-twitch-explained), [Creator Handbook](https://www.creatorhandbook.net/the-new-twitch-50-50-revenue-split-should-twitch-streamers-abandon-ship/)
- Creator "tool sprawl" / multi-platform fragmentation — [Digiday](https://digiday.com/media/not-all-creators-are-the-same-how-the-creator-economy-breaks-down-by-business-model/), [Passion.io](https://passion.io/blog/patreon-vs-branded-app-own-your-audience-and-revenue), [Podnews (direct-to-fan podcasting)](https://podnews.net/press-release/podcasting-629mn-patreon)
- Spotify payout discontent (musicians/podcasters) — [MusicTech](https://musictech.com/news/music/spotify-2024-first-full-year-profitability/)
