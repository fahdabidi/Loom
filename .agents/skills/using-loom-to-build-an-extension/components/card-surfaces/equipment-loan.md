# Equipment Loan Surface

## Supported Interactions

- Member offers equipment, requests a loan, approves/declines loan, schedules pickup, checks item out,
  extends loan, returns item, marks damaged, cancels, and sees availability.
- Supports personally owned gear and community-owned inventory.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Lender | `community.surface.equipment.loan.write` | Offer item, approve/decline, schedule pickup, mark returned/damaged. |
| Borrower | `community.surface.equipment.loan.request` | Request, cancel, extend, return. |
| Equipment steward | `community.surface.equipment.loan.admin` | Moderate inventory, visibility, disputes. |

## Custom Experience Guidance

Customize equipment category, condition, deposit/fee, pickup windows, loan duration, privacy-safe
contact, care instructions, and return checklist. A tennis club can let a member loan a spare racquet
with grip size, string tension, pickup court, and return date.

## API Support

Requires `CommunityEquipmentLoanApi`: `offerEquipment`, `requestLoan`, `approveLoan`, `declineLoan`,
`schedulePickup`, `checkOut`, `extendLoan`, `returnItem`, `markDamaged`, `cancelLoan`,
`listAvailability`, `privacyScopedContact`.
