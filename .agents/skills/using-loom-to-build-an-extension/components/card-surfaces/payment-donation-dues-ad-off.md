# Payment, Donation, Dues, and Ad-Off Surface

## Supported Interactions

- Create payment intent, confirm payment, record failure, retry, refund, create/manage recurring plan,
  set donor visibility, view receipt, inspect entitlement, and settlement status.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Payer/donor/member | `community.surface.payment.pay` | Pay, donate, retry, view receipt, manage visibility. |
| Treasurer/owner | `community.surface.payment.admin` | View aggregate status, refunds where allowed, settlement. |
| Viewer | `community.surface.payment.read` | Read own balance/receipt/entitlement state. |

## Custom Experience Guidance

Customize amount presets, fund/purpose, donor visibility, recurring copy, due date, fee disclosure,
receipt copy, refund policy, and ad-off scope. Payment credential entry remains Loom-owned.

## Giving Payment JSON

The Giving tab is gated on a per-workflow `givingPayment` block. When declared on any workflow
in the community's `experience.workflows`, the Giving tab renders the real payment UI; otherwise it
shows a "coming soon" placeholder.

```json
"workflows": [
  {
    "workflowId": "club-dues-payment",
    "title": "Quarterly club dues",
    "givingPayment": {
      "amountLabel": "$15",
      "purpose": "Quarterly club dues",
      "cadence": "recurring",
      "entitlement": "Voting member badge"
    }
  }
]
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `amountLabel` | string | **yes** | Human-readable amount (e.g. `"$15"`, `"$120/year"`) |
| `purpose` | string | no | What the payment is for |
| `cadence` | string | no | When present, renders a recurrence badge (e.g. `"recurring"`, `"one-time"`) |
| `entitlement` | string | no | When present, renders an entitlement badge showing what the payer receives |

`cadence` and `entitlement` are **conditional** — they render only when declared. A giving
workflow without them still renders the full amount/purpose/checkout/receipt surface; only the
extra rows are omitted.

**State machine:**
- **Unpaid**: amount/purpose summary + checkout CTA button → fires the resolved real workflow via
  `onConfirmWorkflow`. Completing the workflow marks it paid.
- **Paid** (`completedWorkflowIds` contains the giving workflow ID): receipt card replaces the
  checkout button. No retry button is shown (the original workflow remains accessible via Home).

## API Support

Requires `CommunityPaymentSurfaceApi`: `createPaymentIntent`, `confirmPayment`, `recordFailure`,
`retryPayment`, `refund`, `createRecurringPlan`, `manageRecurringPlan`, `setDonorVisibility`,
`getReceipt`, `getEntitlement`, `settlementStatus`.
