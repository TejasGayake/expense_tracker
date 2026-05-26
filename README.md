# GT Expenser

A privacy-focused, offline-first personal expense tracker built with Flutter. Track expenses, split bills with people, view statistics, and sync data between Android and Windows devices over WiFi — no cloud required.

---

## Features

### Expense Tracking
- Create, edit, and delete transactions with amount, description, date, category, and payment mode
- Attach photos from camera or gallery to transactions
- Search transactions with highlighted matching results
- 26 default expense categories with emoji icons and colors
- Custom category creation with icon and color picker

### People & Split Bills
- Add people with name, phone, and email
- Split transactions equally or with custom amounts
- Track who owes you and who you owe
- Mark settlements as pending, partial, or settled
- Send local reminders for pending payments

### Statistics & Insights
- Pie chart breakdown by category
- Bar chart trends (weekly, monthly, yearly)
- Category-wise spending insights
- Filter by time period

### Security
- 6-digit PIN lock with SHA-256 hashing and random salt
- Brute-force protection: 5-attempt lockout with 30-second cooldown
- Configurable auto-lock timer (immediate to 30 minutes)
- All PIN data stored in FlutterSecureStorage

### Device Sync (WiFi Direct)
- Windows acts as HTTP server, Android acts as client
- Automatic device discovery via mDNS (Bonjour/Bonsoir)
- Manual IP entry for direct connection
- Syncs transactions and people between devices
- No internet or cloud required

### UI & UX
- Apple-inspired glass morphism design
- Dark and light theme (persisted across restarts)
- Animated footer with shimmer and flowing gradient effects
- Pull-to-refresh on all data screens
- Custom iOS-style toggle switches with haptic feedback

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.16+ |
| Language | Dart (SDK >=3.2.0 <4.0.0) |
| Database | SQLite via sqflite |
| State Management | setState (StatefulWidget) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Service Discovery | bonsoir (mDNS) |
| Secure Storage | flutter_secure_storage |
| Image Picking | image_picker |
| Preferences | shared_preferences |
| Crypto | crypto (SHA-256) |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, auth gate, theme, lifecycle
├── models/
│   ├── category_model.dart            # Category model + icon/color constants + lookup maps
│   ├── person_model.dart              # Person + TransactionPerson models
│   └── transaction_model.dart         # Transaction + PersonShare models
├── services/
│   ├── database_service.dart          # SQLite CRUD, schema, migrations (v1-v5)
│   ├── security_service.dart          # PIN hashing (SHA-256), auto-lock, brute-force protection
│   ├── sync_service.dart              # HTTP server/client + Bonsoir mDNS sync
│   ├── reminder_service.dart          # Local notification scheduling
│   ├── attachment_service.dart        # Camera/gallery image picking + file management
│   └── animation_service.dart         # Footer animation preferences
├── screens/
│   ├── home_screen.dart               # Dashboard: summary cards, recent transactions, quick actions
│   ├── add_transaction_screen.dart    # Add/edit transaction form with splits and attachments
│   ├── transaction_detail_screen.dart # Full transaction view with attachments
│   ├── search_screen.dart             # Full-text search with highlighted results
│   ├── categories_screen.dart         # Category list with tabs (All / Most Used)
│   ├── add_edit_category_screen.dart  # Category create/edit form
│   ├── statistics_screen.dart         # Charts: pie, bar, insights
│   ├── people_screen.dart             # People list with 4 tabs (All / Owes Me / I Owe / Settled)
│   ├── person_details_screen.dart     # Person profile, transaction history, settle/remind
│   ├── add_person_screen.dart         # Add person form
│   ├── edit_person_screen.dart        # Edit person form
│   ├── split_transaction_screen.dart  # Split transaction among people
│   ├── pin_screen.dart                # 6-digit PIN keypad (setup + login modes)
│   ├── security_settings_screen.dart  # PIN toggle, auto-lock, reset security
│   ├── sync_screen.dart               # Sync UI with server/client mode
│   └── animation_settings_screen.dart # Footer animation picker
├── widgets/
│   ├── app_drawer.dart                # Navigation drawer with menu items
│   ├── transaction_card.dart          # Transaction list item card
│   ├── ios_switch.dart                # Custom iOS-style toggle switch
│   ├── attachment_picker.dart         # Camera/gallery image picker widget
│   └── footers/
│       ├── footer_manager.dart        # Routes to correct footer animation
│       ├── shimmer_footer.dart        # Shimmer gradient text animation
│       └── flowing_footer.dart        # Flowing gradient text animation
├── theme/
│   └── app_theme.dart                 # Light/dark ThemeData definitions
└── utils/
    ├── performance_monitor.dart       # Debug performance timing
    └── image_utils.dart               # Image provider helper
```

---

## Database Schema

The app uses SQLite with 5 tables and automatic migrations (currently at schema v5):

### `transactions`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Timestamp-based unique ID |
| amount | REAL | Transaction amount |
| date | INTEGER | Unix timestamp (milliseconds) |
| description | TEXT | Transaction description |
| category | TEXT | Category name (denormalized) |
| categoryId | TEXT | FK to categories.id |
| paymentMode | TEXT | Cash, UPI, Credit Card, etc. |
| location | TEXT | Optional location |
| notes | TEXT | Optional notes |
| createdAt | INTEGER | Creation timestamp |
| updatedAt | INTEGER | Last update timestamp |

### `people`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique ID |
| name | TEXT | Person name (required) |
| phone | TEXT | Phone number |
| email | TEXT | Email address |
| createdAt | INTEGER | Creation timestamp |

### `categories`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique ID |
| name | TEXT | Category name (required) |
| icon | TEXT | Emoji icon |
| color | INTEGER | Color value |
| isDefault | INTEGER | 1 if system default |
| usageCount | INTEGER | Times used in transactions |
| createdAt | INTEGER | Creation timestamp |

### `transaction_people` (splits)
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique ID |
| transactionId | TEXT FK | References transactions.id |
| personId | TEXT FK | References people.id |
| amount | REAL | Split amount |
| direction | TEXT | "paid", "owes", "lent" |
| status | TEXT | "pending", "settled", "partial" |
| settledAmount | REAL | Amount already settled |
| dueDate | INTEGER | Optional due date |

### `attachments`
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT PK | Unique ID |
| transactionId | TEXT FK | References transactions.id |
| filePath | TEXT | Local file path |
| type | TEXT | Attachment type |
| caption | TEXT | Optional caption |
| createdAt | INTEGER | Creation timestamp |

---

## Getting Started

### Prerequisites
- Flutter 3.16+ installed ([Flutter installation guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter plugin
- For Windows desktop: Visual Studio 2022 with C++ desktop workload

### Installation

```bash
# Clone the repository
git clone https://github.com/TejasGayake/expense_tracker.git
cd expense_tracker

# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run on Windows
flutter run -d windows
```

### Build

```bash
# Android APK
flutter build apk --release

# Windows executable
flutter build windows --release
```

---

## How Sync Works

The sync feature allows direct data transfer between Android and Windows devices over a local WiFi network — no internet or cloud involved.

```
┌──────────────┐         WiFi (HTTP)         ┌──────────────┐
│   Android    │ ◄──────────────────────────► │   Windows    │
│   (Client)   │    mDNS auto-discovery       │   (Server)   │
│              │    Port 8080                 │              │
│  SQLite DB   │                              │  SQLite DB   │
└──────────────┘                              └──────────────┘
```

1. **Windows** starts an HTTP server on port 8080 and advertises via mDNS
2. **Android** discovers the server automatically (or user enters IP manually)
3. On sync, both devices exchange all transactions and people
4. Records are merged by ID — existing records are skipped, new ones are inserted

### Sync API Endpoints (Windows server)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/sync` | Exchange data (send transactions, receive peer's) |
| POST | `/ping` | Connectivity check (returns "pong") |
| GET | `/status` | Device info, transaction count, last sync time |

---

## Security Model

### PIN Protection
- 6-digit PIN hashed with SHA-256 and a random per-user salt
- Stored in `FlutterSecureStorage` (encrypted at rest by the OS)
- 5-attempt lockout with 30-second cooldown after failures
- Configurable auto-lock: immediate, 1 min, 5 min, 10 min, 30 min

### What is NOT stored securely
- Transaction data (stored in plain SQLite)
- Sync traffic (plain HTTP — no TLS between devices)
- No biometric authentication (planned)

---

## Architecture Notes

- **No formal architecture pattern** — the app uses a service-layer approach with `StatefulWidget` + `setState()` for all state management
- **Services are singletons** — `DatabaseService`, `SecurityService`, `SyncService`, etc. use `factory` constructors
- **Models are defined but lightly used** — most screens work with raw `Map<String, dynamic>` from SQLite
- **No dependency injection** — services are instantiated directly where needed

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| sqflite | ^2.3.0 | SQLite database |
| path / path_provider | ^1.9.0 / ^2.1.1 | File system paths |
| intl | ^0.18.1 | Date/number formatting |
| image_picker | ^1.0.5 | Camera/gallery images |
| flutter_secure_storage | ^9.0.0 | Encrypted key-value storage |
| fl_chart | ^0.64.0 | Pie and bar charts |
| bonsoir | ^5.1.0 | mDNS service discovery |
| network_info_plus | ^4.1.0 | Device IP retrieval |
| connectivity_plus | ^5.0.2 | WiFi connectivity check |
| shared_preferences | ^2.2.2 | Key-value preferences |
| flutter_local_notifications | ^18.0.1 | Local notifications |
| timezone | ^0.10.0 | Timezone for scheduled notifications |
| crypto | ^3.0.7 | SHA-256 hashing |

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | Supported | Primary target, tested on Android 10+ |
| Windows | Supported | Desktop sync server, tested on Windows 10/11 |
| iOS | Not configured | Would work with minor setup |
| Web | Not supported | SQLite and platform plugins unavailable |

---

## License

This project is for personal use. See the repository for license details.

---

## Author

**Tejas Gayake**
