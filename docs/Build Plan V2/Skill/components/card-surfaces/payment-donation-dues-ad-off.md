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

## API Support

Requires `CommunityPaymentSurfaceApi`: `createPaymentIntent`, `confirmPayment`, `recordFailure`,
`retryPayment`, `refund`, `createRecurringPlan`, `manageRecurringPlan`, `setDonorVisibility`,
`getReceipt`, `getEntitlement`, `settlementStatus`.
