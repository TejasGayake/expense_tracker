# GT Expenser — Improvement Roadmap

Suggestions to make GT Expenser a production-ready, feature-rich expense tracker.

---

## High Priority

### 1. Add Tests
There are zero tests. Start with:
- Unit tests for `DatabaseService` (CRUD, migrations)
- Unit tests for `SecurityService` (PIN hashing, lockout)
- Widget tests for critical screens (add transaction, PIN screen)
- Integration test for the sync flow

### 2. Use a State Management Solution
The entire app uses raw `setState()`. This causes:
- Screens independently reload data from DB
- No shared state between screens (e.g., adding a transaction doesn't auto-update the home screen stats)
- Code duplication across screens

**Recommendation:** Introduce `Provider` or `Riverpod` — minimal learning curve, big payoff for this app size.

### 3. Encrypt Sync Traffic
Sync uses plain HTTP — anyone on the same WiFi can intercept transaction data. Options:
- Use HTTPS with self-signed certificates
- Add AES encryption to the payload before sending
- At minimum, add a shared secret/PIN for pairing devices

### 4. Add Biometric Auth
`local_auth` is commented out in pubspec.yaml. Implementing it would give users a faster unlock option alongside PIN.

---

## Medium Priority

### 5. Split `DatabaseService` (986 lines)
It's a god class. Split into:
- `TransactionRepository`
- `PersonRepository`
- `CategoryRepository`
- `SettlementRepository`

### 6. Use Models Consistently
`TransactionModel`, `PersonModel`, `CategoryModel` exist but are barely used — screens pass raw `Map<String, dynamic>` everywhere. Using models would give type safety and catch bugs at compile time.

### 7. Add Delta Sync
Current sync sends ALL data every time. For large databases this is slow. Implement:
- Track `lastSyncedAt` timestamp
- Only send records modified since last sync
- Add conflict resolution (last-write-wins or merge)

### 8. Export Data
The "Export Data" drawer item is a stub. Users expect:
- CSV export of transactions
- PDF report with charts
- Share via email/messaging

### 9. Fix Category Relational Integrity
Transactions store `categoryId` AND `category` (name string). If a category is renamed, the name in old transactions becomes stale. Consider:
- Only store `categoryId`
- Resolve name at display time via a JOIN or lookup

---

## Low Priority / Polish

### 10. Onboarding Flow
First-time users land on an empty home screen. Add:
- Quick setup wizard (currency, first category, optional PIN)
- Sample data toggle for demo purposes

### 11. Recurring Transactions
Auto-generate next occurrence for repeating expenses:
- Mark a transaction as recurring (daily/weekly/monthly)
- Auto-create next transaction via notification or on app open

### 12. Multi-Currency Support
Currently hardcoded to ₹ (INR). Add:
- Currency selector in settings
- Store currency symbol per transaction or globally
- Format amounts accordingly

### 13. Accessibility
- Add `Semantics` widgets for screen readers
- Ensure color contrast meets WCAG AA
- Add `tooltip` to all icon-only buttons

### 14. CI/CD Pipeline
Set up GitHub Actions:
- `flutter analyze` on every push
- `flutter test` on every PR
- Auto-build APK on release tags

---

## Quick Wins (can do now)

| # | What | Effort |
|---|------|--------|
| 1 | Add `.github/workflows/analyze.yml` for CI | 15 min |
| 2 | Uncomment `local_auth` and wire biometrics | 1 hour |
| 3 | Add CSV export to Export Data stub | 2 hours |
| 4 | Add currency setting to SharedPreferences | 1 hour |
| 5 | Add `flutter_test` for SecurityService | 1 hour |

---

## Feature Suggestions

### Budgeting
- Set monthly/weekly budgets per category
- Visual progress bars showing budget vs actual spending
- Alerts when approaching or exceeding budget (80%, 100% thresholds)
- Budget history and trend comparison month-over-month

### Bill Reminders & Recurring Payments
- Set up recurring bills (rent, subscriptions, EMIs)
- Push notifications before due dates (1 day, 3 days, 1 week)
- Calendar view showing upcoming bills
- Auto-mark as paid when a matching transaction is added

### Financial Goals
- Set savings goals (e.g., "Save ₹50,000 for vacation")
- Track progress with visual indicators
- Link goal to a specific category or "Savings" bucket
- Celebrate milestones (25%, 50%, 75%, 100%)

### Receipt OCR / Smart Entry
- Scan receipts using camera
- Extract amount, merchant, date using OCR (Google ML Kit or Tesseract)
- Auto-fill transaction form with extracted data
- Store original receipt image as attachment

### Widgets (Android Home Screen)
- Quick-add expense widget
- Today's spending summary widget
- Monthly total widget
- Pending dues widget

### Tags & Labels
- Add custom tags to transactions (e.g., "work lunch", "personal", "tax deductible")
- Filter/search by tag
- Tag-based reports in statistics

### Income Tracking
- Separate income from expenses
- Net balance (income - expenses) on dashboard
- Income categories (salary, freelance, gifts, refunds)
- Cash flow chart (income vs expenses over time)

### Multi-Account Support
- Multiple wallets/accounts (Cash, Bank, Credit Card, UPI)
- Transfer between accounts
- Per-account balance tracking
- Account-wise filtering in reports

### Debt Tracker
- Track loans given and received
- EMI calculator
- Interest tracking
- Payment schedule with reminders

### Currency Conversion
- Real-time exchange rates (when online)
- Multi-currency transactions
- Default currency per account

### Travel Mode
- Tag transactions as "travel" with destination
- Travel-specific categories (flights, hotels, food abroad)
- Trip summary with total spend
- Multi-currency support per trip

### Shared Expenses (Group Split)
- Create groups (roommates, trip buddies, office lunch)
- Split bills among group members
- Track group-level balances
- Settle up within the group
- Similar to Splitwise functionality

### Data Insights & AI
- Spending predictions based on history
- "You spent 30% more on food this month" alerts
- Anomaly detection (unusual large transactions)
- Monthly spending report card
- Best day/week to spend based on patterns

### Backup & Restore
- Local backup to device storage
- Backup to Google Drive / OneDrive
- Restore from backup file
- Auto-backup on schedule (weekly/monthly)

### Transaction Templates
- Save frequent transactions as templates
- One-tap add for regular expenses
- Template categories (morning coffee, daily commute, gym)

### Dark Mode Improvements
- AMOLED true black option
- Schedule dark mode (sunset to sunrise)
- Per-theme accent color customization

### Language & Localization
- Support multiple languages
- Hindi, Marathi, Tamil, etc. for Indian users
- RTL support for Arabic/Hebrew
- Date format preferences (DD/MM/YYYY vs MM/DD/YYYY)

### Advanced Statistics
- Heatmap calendar (GitHub-style spending visualization)
- Top 5 merchants/vendors
- Weekday vs weekend spending comparison
- Spending velocity (rate of spending over time)
- Year-in-review summary

### Notification Center
- In-app notification history
- Categorized alerts (budget, reminders, sync, settlements)
- Mark as read/unread
- Notification preferences per type

### Voice Input
- "Add ₹250 for lunch" voice command
- Voice search for transactions
- Hands-free expense logging while driving

---

## Architecture Improvements

### Migration to Clean Architecture
```
lib/
├── core/                    # Shared utilities, constants, themes
├── data/
│   ├── models/              # Data classes with JSON serialization
│   ├── repositories/        # Repository implementations
│   └── datasources/         # SQLite, SharedPreferences, SecureStorage
├── domain/
│   ├── entities/            # Business objects
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Business logic
└── presentation/
    ├── screens/             # Pages
    ├── widgets/             # Reusable UI components
    └── providers/           # State management (Riverpod/Provider)
```

### Recommended Package Additions
| Package | Purpose |
|---------|---------|
| `riverpod` | State management |
| `freezed` | Immutable models with code generation |
| `go_router` | Declarative routing |
| `local_auth` | Biometric authentication |
| `csv` | CSV export |
| `pdf` | PDF report generation |
| `google_mlkit_text_recognition` | Receipt OCR |
| `home_widget` | Android home screen widgets |
| `flutter_localizations` | Multi-language support |
| `firebase_crashlytics` | Crash reporting (optional) |

---

*Last updated: 2026-05-26*
