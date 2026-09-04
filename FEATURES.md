# Feature coverage

| Area | Flutter v4 implementation |
|---|---|
| Authentication | Offline login; compatible with both the original PBKDF2 hashes and new SHA-256 records |
| Roles | Administrator, Manager, Cashier; destructive actions restricted |
| Dashboard | Today collection, outstanding, students, vehicles, trips, recent payments |
| Students | Add/edit, search, bus filter, deactivate/reactivate, soft delete, grade helper, opening arrears, profile ledger |
| Student IDs | Per-bus letter and sequence; permanent barcode identifier; transfer trail |
| Billing | Monthly ledger generation and oldest-month-first allocations |
| Payments | Back-date, method, notes, history, reversal, receipt data and PDF/print service |
| Vehicles | CRUD, expiry fields, seating, service history, fuel log, derived km/L |
| Hiring | Booking conflict prevention, advance/balance, status, expenses and derived profit |
| Messaging | Sri Lankan phone normalization and WhatsApp composer hand-off |
| Reports | Student, payment, vehicle, hiring/profit and audit CSV exports |
| Settings | Company/receipt/invoice settings and light/dark mode |
| Data safety | Dated backup, restore with safety backup, bundled v3.9 database import |
| Sinhala | Bundled Noto Sans Sinhala font |

Direct unattended WhatsApp/SMS sending is deliberately excluded because it
requires an approved provider/API account. The app opens the official WhatsApp
composer so the operator remains in control of each message.
