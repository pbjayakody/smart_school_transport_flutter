# Smart School Transport Manager — Flutter v4.0

Flutter/SQLite rewrite of the supplied Python v3.9 system. The app is designed
for Windows desktop first and uses one offline database. The same Dart code can
later be adapted for Android.

## Included modules

- Login and Administrator / Manager / Cashier roles
- Dashboard, alerts and recent collections
- Students, bus grouping, student codes, barcode IDs and transfers
- Monthly ledger, arrears, additional charges and oldest-month-first payments
- Payment history, receipt PDF/print and WhatsApp hand-off
- Vehicles, documents, service history and fuel efficiency
- Hiring bookings, conflict warning, expenses, balance and profit
- Reports with CSV export
- Broadcast messages through WhatsApp
- Company, billing and appearance settings
- Database backup, restore and optional legacy database import
- Audit log

## Run on Windows

### No local Flutter installation (recommended)

Upload this project to a private GitHub repository. The included GitHub Actions
workflow builds both a portable ZIP and a Windows installer. See
`GITHUB_BUILD_GUIDE_SI.md` for Sinhala instructions.

### Local Flutter installation

1. Install Flutter and enable Windows desktop:

   `flutter config --enable-windows-desktop`

2. In this folder run:

   `flutter create --platforms=windows .`

   `flutter pub get`

   `flutter run -d windows`

Default login: **admin / admin123**. Change it after the first login.

## Existing v3.9 data

The supplied `nethsara.db` is included under `assets/database`. On the Login
screen choose **Import v3.9 database**, or use Settings > Data & backup. A
backup is created before every restore/import.

## Notes

- WhatsApp opens the official `wa.me` composer; the user confirms sending.
- SMS API credentials are intentionally not embedded. Configure an approved
  provider before enabling direct SMS.
- PDF receipts are generated locally; no internet is required.
