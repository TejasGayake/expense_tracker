# GT Expenser — Improvement Roadmap

All planned features and improvements for GT Expenser. Smart/AI features excluded (except Transaction Templates).

---

## High Priority (Technical)

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

## Medium Priority (Technical)

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

## Low Priority (Technical / Polish)

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

## Financial Features

### Budgeting
- Set monthly/weekly budgets per category
- Visual progress bars showing budget vs actual spending
- Alerts when approaching or exceeding budget (80%, 100% thresholds)
- Budget history and trend comparison month-over-month
- Rollover unused budget to next month (optional)

### Bill Reminders & Recurring Payments
- Set up recurring bills (rent, subscriptions, EMIs)
- Push notifications before due dates (1 day, 3 days, 1 week)
- Calendar view showing upcoming bills
- Auto-mark as paid when a matching transaction is added
- Overdue bill highlighting

### Financial Goals
- Set savings goals (e.g., "Save ₹50,000 for vacation")
- Track progress with visual indicators (progress ring/bar)
- Link goal to a specific category or "Savings" bucket
- Celebrate milestones (25%, 50%, 75%, 100%)
- Multiple active goals with priority ranking

### Transaction Templates
- Save frequent transactions as templates (e.g., "Morning Coffee - ₹50 - Food")
- One-tap add for regular expenses from a templates list
- Template categories (morning coffee, daily commute, gym, groceries)
- Edit/delete saved templates
- Auto-suggest template based on time of day and past patterns

### Income Tracking
- Separate income from expenses with a transaction type toggle
- Net balance (income - expenses) on dashboard
- Income categories (Salary, Freelance, Gifts, Refunds, Interest)
- Cash flow chart (income vs expenses over time)
- Monthly income vs expense ratio

### Multi-Account Support
- Multiple wallets/accounts (Cash, Bank Account, Credit Card, UPI Wallet)
- Transfer between accounts (internal transfers, not counted as expense)
- Per-account balance tracking
- Account-wise filtering in reports and statistics
- Default account selection

### Debt Tracker
- Track loans given and received separately
- EMI calculator with amortization schedule
- Interest tracking (simple and compound)
- Payment schedule with push notification reminders
- Debt-free countdown

### Subscription Tracker
- List all active subscriptions (Netflix, Spotify, gym, etc.)
- Monthly and yearly cost breakdown
- Renewal date reminders
- Total monthly subscription burn rate
- Cancel suggestion when total exceeds threshold

### Expense Limits
- Set daily/weekly spending limits
- Real-time tracking: "₹350 left today" indicator on home screen
- Warning notification at 80% of limit
- Block or warn when limit exceeded
- Per-category or global limits

### Tax Deductions
- Mark transactions as tax-deductible with a toggle
- Deductible categories (Medical, Education, Donations, Business)
- Annual tax report summary
- Export tax-deductible transactions separately
- Financial year wise filtering (April to March for India)

### Savings Challenges
- 52-week savings challenge (₹1 to ₹52 incrementing weekly)
- No-spend day challenge (track days with zero spending)
- Custom challenge creation
- Progress tracking with streak counter
- Reward/badge system for completing challenges

### Bill Comparison
- Compare utility bills month-over-month (electricity, water, gas)
- Visual diff showing increase/decrease percentage
- Alerts when a bill is significantly higher than average
- Historical chart for each recurring bill

### Emergency Fund Tracker
- Set emergency fund target (e.g., 6 months of expenses)
- Track contributions to emergency fund
- Auto-calculate target based on average monthly spending
- Progress ring on dashboard

### Investment Tracker (Basic)
- Track SIPs, RDs, FDs, mutual funds
- Add investment with amount, date, expected return
- Total investment value on dashboard
- Maturity date reminders
- Investment vs expense allocation pie chart

### Warranty Tracker
- Track product warranties (purchase date, warranty period, expiry)
- Push notification before warranty expires
- Attach purchase receipt/bill photo
- Category-wise warranty list (electronics, appliances, furniture)

---

## UX Features

### Swipe Actions on Transactions
- Swipe left: quick delete (with undo snackbar)
- Swipe right: quick edit or duplicate
- Visual feedback with colored background and icons
- Configurable swipe actions in settings

### Pin/Favorite Transactions
- Star or pin important transactions to the top of the list
- Separate "Pinned" section on home screen
- Quick access to pinned items

### Quick Add from Notification
- Persistent notification with "+" button
- Tap to open add transaction screen directly
- Quick-add widget in notification shade
- Configurable in settings (enable/disable)

### Expense Calendar View
- Calendar widget showing each day's spending
- Color-coded dots (green = low, yellow = medium, red = high spending)
- Tap a day to see that day's transactions
- Monthly overview with total per day

### Quick Filters on Home Screen
- Filter chips below summary cards: Today, This Week, This Month, All
- Instant filtering without navigating to search
- Remembers last selected filter

### Undo Delete
- Show SnackBar with "Undo" button after deleting a transaction
- 5-second window to undo
- Transaction restored with all relationships (splits, attachments)

### Bulk Operations
- Long-press to enter selection mode
- Select multiple transactions with checkboxes
- Bulk actions: delete, change category, change date, export selected
- Select all / deselect all

### Duplicate Transaction
- Long-press or swipe to duplicate a transaction
- Opens pre-filled add transaction screen
- Adjust date to today automatically

### Photo Gallery / Receipt Viewer
- Dedicated screen showing all receipt/attachment photos
- Grid view with transaction info overlay
- Tap to view full screen with zoom
- Filter by date range or category

### Spending Streak (Gamification)
- Track consecutive days of expense logging
- Show current streak and best streak on dashboard
- Milestone badges (7 days, 30 days, 100 days, 365 days)
- Gentle reminder notification if streak is about to break

### Category Quick Reorder
- Drag-and-drop to reorder categories in the categories screen
- Most-used categories float to top (auto or manual)
- Custom category order persisted in SharedPreferences

### Expense Notes with Checklist
- Checklist format for shopping lists or trip packing
- Check/uncheck items within transaction notes
- Useful for grocery runs, trip planning

### Location-based Category Suggestion
- Auto-suggest category based on GPS location
- Learn from past transactions at same location
- "You usually categorize transactions here as Food"
- Requires location permission (optional)

### Duplicate Detection Warning
- Warn when adding a transaction similar to a recent one
- Match on amount + category + date proximity
- "Did you already add this? Similar transaction found 2 hours ago"
- Allow user to dismiss or confirm duplicate

### Spending Heatmap on Dashboard
- Small GitHub-style calendar heatmap on home screen
- Last 3 months visible
- Darker color = more spending that day
- Tap a day to see details

### Custom Accent Colors
- Let users pick their own accent/primary color
- Preset palette + custom hex input
- Applies to buttons, charts, highlights
- Persist in SharedPreferences

### Monthly Summary Cards
- Swipeable cards on home screen showing month summary
- Total spent, top category, biggest transaction, savings rate
- Compare with previous month (+12% or -8% indicator)
- Share summary as image

### Transaction Sorting Options
- Sort by: date, amount (high/low), category, alphabetical
- Sort toggle on home screen and search results
- Persist sort preference

### Expense Split History
- Dedicated view showing all past splits with people
- Timeline of settlements
- Who paid what and when
- Outstanding balance summary across all people

### Haptic Feedback Customization
- Different vibration patterns for different actions
- Light tap for toggle, medium for button press, heavy for delete
- Enable/disable haptics in settings

### Pull-down Quick Stats
- Pull down on home screen to reveal quick stats panel
- Today's total, this week, this month
- Top spending category this month
- Number of transactions this month

### Animated Page Transitions
- Smooth shared element transitions between screens
- Hero animations on transaction cards
- Fade/slide transitions for navigation

### App Lock Timeout Indicator
- Show remaining time before auto-lock
- Visual indicator in app bar or bottom bar
- "Locking in 2:30" countdown when app is backgrounded

### Expense Reminders
- "Don't forget to log today's expenses" evening reminder
- Configurable reminder time
- Only fires if no transactions logged today
- Smart: learns user's typical logging pattern

### Favorite/Pinned Categories
- Pin 3-5 most-used categories to the top of category picker
- Quick access when adding transactions
- Auto-suggest based on usage frequency

---

## Animation Overhaul (Premium & Smooth)

Style: 60fps glass morphism feel, smooth curves, subtle depth. Like a premium banking app.

### Current State Audit

| File | Animation | Status |
|------|-----------|--------|
| `shimmer_footer.dart` | 1500ms shimmer gradient sweep (easeInOutSine) | Works, basic |
| `flowing_footer.dart` | 8000ms flowing gradient loop (linear) | Works, basic |
| `ios_switch.dart` | 200ms thumb slide + color change | Works, dead controller |
| `statistics_screen.dart` | fl_chart built-in chart animations | Works |
| `people_screen.dart` | TabBar swipe transitions | Works, setState on every swipe |
| All other screens | **No animations** | Static |

### Issues to Fix First
- `AnimationController` in ios_switch is dead code (created but never listened to)
- `AnimationService` not singleton, async race in constructor
- No `AnimatedSwitcher` for footer type switching
- `GestureDetector` instead of `InkWell` in pin_screen and transaction_card (no ripple)
- `setState(() {})` fires on every tab swipe gesture in people_screen
- Missing `RepaintBoundary` on chart containers

### Page Transitions
- Custom `PageRouteBuilder` with slide-from-right + fade (300ms, Curves.easeOutCubic)
- Hero animations on transaction cards → detail screen (amount text, category icon)
- Shared element on person avatar → person details
- Cross-fade for bottom sheet presentations

### Home Screen Animations
- Staggered entrance for summary cards (slide up 40px + fade, 200ms delay per card)
- Number counting animation for totals (₹0 → ₹45,230 over 800ms)
- `AnimatedList` for transaction cards (slide in from right, 150ms stagger)
- FAB scale-in animation on screen load (0 → 1 with Curves.elasticOut)
- Animated "People who owe you" section expand/collapse

### PIN Screen Animations
- Dot scale-up when digit entered (1.0 → 1.3 → 1.0 bounce)
- Horizontal shake on wrong PIN (8px oscillation, 300ms)
- Checkmark draw animation on success (CustomPainter, 500ms)
- `InkWell` ripple on keypad buttons
- Error message fade-in / fade-out

### Transaction Card Animations
- `InkWell` with Material ripple splash
- Scale-down on press (1.0 → 0.97 with Curves.easeOut)
- `Dismissible` for swipe-to-delete (red background + trash icon)
- Staggered entrance when list loads (50ms delay per card, slide from bottom + fade)
- Hero tag on amount text and category icon for detail transition

### People Screen Animations
- Staggered card entrance (same as transaction cards)
- `AnimatedSwitcher` for FAB show/hide between tabs
- Fix `setState` on every tab swipe (check `indexIsChanging`)
- Avatar pulse animation when new person is added

### Statistics Screen Animations
- Explicit `swapAnimationDuration` (800ms, Curves.easeOutCubic) on PieChart and BarChart
- Animated period selector highlight (sliding indicator)
- Staggered category list entrance
- Value counting animation on insight numbers

### Add Transaction Screen Animations
- Staggered form field reveal on screen open (slide up + fade, 100ms per field)
- Save button loading animation (circular progress inside button)
- Success checkmark before navigation

### General / Cross-cutting
- Loading skeletons instead of `CircularProgressIndicator` (shimmer boxes)
- `AnimatedSwitcher` for footer type switching with crossfade
- Fix `AnimationService` → proper singleton with `ChangeNotifier`
- Remove dead `AnimationController` from ios_switch
- Add `RepaintBoundary` on chart containers, summary cards
- Replace all `GestureDetector` (no feedback) with `InkWell` where appropriate
- Custom shimmer loading effect for data-loading states

### Animation Constants (to be defined in app_theme.dart or new animation_constants.dart)
```dart
// Durations
const Duration kFastDuration = Duration(milliseconds: 150);
const Duration kNormalDuration = Duration(milliseconds: 250);
const Duration kSlowDuration = Duration(milliseconds: 400);
const Duration kEntranceDuration = Duration(milliseconds: 300);

// Curves
const Curve kDefaultCurve = Curves.easeOutCubic;
const Curve kEntranceCurve = Curves.easeOutQuart;
const Curve kBounceCurve = Curves.elasticOut;

// Stagger
const Duration kStaggerDelay = Duration(milliseconds: 50);
const Duration kCardStaggerDelay = Duration(milliseconds: 80);
```

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
| `home_widget` | Android home screen widgets |
| `flutter_localizations` | Multi-language support |

---

## Feature Count Summary

| Category | Count |
|----------|-------|
| Technical Improvements | 14 |
| Quick Wins | 5 |
| Financial Features | 15 |
| UX Features | 24 |
| Architecture | 2 |
| **Total** | **60** |

---

*Last updated: 2026-05-26*
