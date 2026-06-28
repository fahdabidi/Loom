# B25 Production UX Blueprint

Status: current for `b25-production-ux-v3`. This blueprint is the product bar used by the independent UX review before any pass decision.

## Review Standard

B25 reviews the actual Loom Communities Demo App as a mobile product, not as a workflow-test artifact. Every community must show a domain-native home, meaningful actions, realistic state, shell-owned navigation, messages/connections access, and no visible validation or implementation taxonomy.

## Cross-App Requirements

- Community list cards show domain identity, readable name/tagline, and a shell-owned add-community action that does not cover the final card.
- Opened community screens preserve Loom App Shell structure: back, messages, connections, and required platform surfaces.
- Workflow cards read as product tasks with semantic action labels and product confirmations.
- Sensitive, payment, export, and moderation flows visibly communicate privacy, receipt, audit, or rollback state where applicable.
- No production screen may expose raw extension IDs, workflow harness copy, workflow/category/surface taxonomy, debug banners, or single-letter placeholder identity when richer identity is available.

## Community Blueprints

| Community | Target personas | Required production surfaces | Identity and IA bar | Status |
| --- | --- | --- | --- | --- |
| Loom Communities shell | Owner/member installing local communities | Empty state, add-community flow, installed card list, shell messages/connections/ad slots | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Garden Club | Member/coordinator | Events, plant exchange, member forms, export | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Neighborhood Book Club | Organizer/member | Reading schedule, discussion prompts, member notifications | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Riverside Youth Soccer | Coach/parent | Schedules, RSVP/availability, announcements, forms | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Cedar Commons HOA | Board member/homeowner | Requests, approvals, dues, documents, export | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Masjid Nur | Admin/member/volunteer | Announcements, donations, care requests, volunteers, prayer/community updates | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Chess Club | Organizer/player | Club home, matches/events, member actions | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Camera Club | Organizer/member | Photo walks, critique submissions, announcements, generated prompt workflows | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Platform Social | Member/moderator | Messages, connections, blocking, in-stream ads | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Ad-Off | Member/owner | Subscription/ad suppression, receipt, entitlement state | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |
| Export and Migration | Owner/admin | Export scope, redaction, verification, rollback | Visible community identity must use domain-relevant name, icon/branding, and tagline rather than raw extension IDs or single-letter placeholders. Mobile hierarchy, semantic actions, realistic task content, shell-owned navigation/messages/connections, and no exposed validation machinery. | pass |

## Screen Review Method

1. Walk every screenshot-backed workflow row from B12-B20.
2. Add B25 live shell rows for the community list and representative opened homes.
3. For each row, review the visible screenshot/state against the blueprint.
4. File blocker or major findings for exposed harness copy, missing domain IA, placeholder identity, visible debug/test chrome, overlapping controls, or missing required state.
5. Remediate, rebuild, recapture evidence, regenerate schema v3 JSON, and repeat until unresolved blocker and major counts are zero.
