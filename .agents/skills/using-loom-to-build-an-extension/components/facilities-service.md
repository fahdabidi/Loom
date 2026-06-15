# Facilities Service

Use `CommunityFacilitiesApi` for reserving rooms, fields, equipment, or other shared community assets.

## Extension Use

- Treat paid reservations as held until the wallet component confirms payment.
- Show the reservation status in the extension UI rather than assuming immediate confirmation.
- Use facility reservation events for notifications and workflows.

## Validation

- `vt_facilities_reservation` proves reservation creation and event behavior.
- `ct_facilities__wallet_reservation-payment` remains pending until A4b.
