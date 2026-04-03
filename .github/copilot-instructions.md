# MyFinance - AI Coding Agent Instructions

## Project Overview

MyFinance is a Flutter mobile app for personal finance management, featuring loan applications, savings tracking, and payment processing with a fintech theme (green-based color scheme).

## Architecture Patterns

### Routing & Navigation

- **Router**: [lib/router/app_router.dart](../../lib/router/app_router.dart) uses `GoRouter` v17 for all navigation
- **Structure**: Three main flow groups:
  1. **Pre-auth** (/, /onboarding) → Single screens
  2. **Auth flow** (/login, /otp, /set-pin) → Auth validation screens
  3. **Main app** (ShellRoute) → Bottom nav with 4 tabs + sub-pages
- **Key patterns**: Use `context.go()` for navigation, not `Navigator.push()`; always handle "canPop" gracefully in AppScaffold back button

### State Management

- Uses `SharedPreferences` for persistent onboarding flags and user prefs (see [lib/screens/onboarding/onboarding_screen.dart](../../lib/screens/onboarding/onboarding_screen.dart#L35))
- **Provider** and **path_provider** are available dependencies but currently not actively used
- **Current approach**: `StatefulWidget` with local state; no global state management yet
- For new features: Keep local state in StatefulWidget unless cross-screen data sharing is needed

### UI Components & Theming

- **Theme**: Defined in [lib/main.dart](../../lib/main.dart) with green primary (#2E8B57), light surface (#F6F8F7)
- **Custom components**:
  - [AppScaffold](../../lib/core/app_scaffold.dart): Reusable scaffold with back button, title, and optional bottom nav
  - [AppCard](../../lib/core/app_card.dart): Standard card wrapper with consistent padding/shadows
  - [ColorExt](../../lib/core/color_ext.dart): Safe opacity extension (replaces deprecated `.withOpacity()`)
- **Coding pattern**: Always use `AppCard` for grouped content; leverage `theme.textTheme` and `theme.colorScheme` for consistency

### Screen Organization

Located in [lib/screens/](../../lib/screens/), organized by feature:

- **auth/**: Login, OTP, PIN setup
- **dashboard/**: Main home screen with balance display and transaction history
- **loans/**: Apply, detail, status, repayment screens
- **savings/**: List, create, detail screens (passes `savingsId` via route params)
- **payment/**: Payment method selection and success/failure screens
- **transactions/**: Transaction history view
- **profile/**: User profile and KYC (Know Your Customer) screens
- **shell/**: MainShell wraps all bottom-nav screens

## Development Workflows

### Running the App

```sh
flutter run              # Debug build
flutter run -d <device> # Specify device
flutter pub get          # Install dependencies
```

### Common Build Tasks

- **Format**: `dart format lib/` (follows Flutter conventions)
- **Lint**: `flutter analyze` (uses flutter_lints)
- **Clean build**: `flutter clean && flutter pub get && flutter run`

## Project-Specific Conventions

### File Naming & Imports

- Dart files: snake_case (e.g., `login_screen.dart`)
- Always import from relative paths: `import '../../core/color_ext.dart';`
- Avoid circular imports; follow the folder hierarchy (screens import core, never vice versa)

### Widget Patterns

1. **Stateless for simple UI**: Use when no state changes needed
2. **Stateful for forms**: Manage TextEditingControllers locally; always dispose in `_dispose()`
3. **Back button behavior**: AppScaffold handles fallback to `/home` if no nav history
4. **Gradients**: Use `LinearGradient` with theme colors (see dashboard_screen.dart, login_screen.dart)

### Form & Input Handling

- **Validation**: Use computed getters like `bool get _isValid => ...` for button enable/disable
- **TextControllers**: Always dispose in `@override void dispose()`
- **Amounts**: Prefix with currency (cedis ₵) in TextFields; parse with `double.tryParse()`
- **Quick actions**: Use `ActionChip` for preset values (see repayment_screen.dart)

### Data Models

- Current approach: Simple dart classes (see [lib/screens/transactions/transaction_model.dart](../../lib/screens/transactions/transaction_model.dart))
- No ORM or database abstraction yet; mock data is hardcoded in screens
- For new models: Keep simple, use `enum` for types (e.g., `TransactionType.deposit`)

## Integration Points & Dependencies

### External Dependencies

- **go_router**: Navigation routing system
- **provider**: Available for state management (not yet utilized)
- **shared_preferences**: Persistent storage for flags/prefs
- **google_fonts**: Font support (included but not actively used)
- **path_provider**: File system access (included but unused)
- **cupertino_icons**: iOS icon set

### Platform-Specific (Minimal Customization)

- **Android**: [android/app/build.gradle.kts](../../android/app/build.gradle.kts) - standard Flutter config
- **iOS**: [ios/Runner/AppDelegate.swift](../../ios/Runner/AppDelegate.swift) - minimal setup
- **Web/Linux/Windows**: Generated plugin registrants; focus on Flutter code, not platform-specific

## Feature Flows: Loans, Savings & Payments

### Loan Flow

**Screens**: [apply_loan_screen.dart](../../lib/screens/loans/apply_loan_screen.dart) → loan_status_screen.dart → loan_detail_screen.dart → repayment_screen.dart → payment flow

**Sequence**:

1. User initiates loan application from dashboard action or loans menu
2. `ApplyLoanScreen` collects: amount (cedis ₵ currency), purpose, repayment plan dropdown
3. Button validation uses `bool get _canSubmit` to check amount > 0 and purpose not empty
4. Submit navigates to `/loan-status` (shows pending/approved state with mock approval)
5. From status, user can tap loan details → `/loan-detail` (displays terms, interest, due date)
6. Initiates repayment via `/repayment` which:
   - Shows amount-to-pay TextField with cedis ₵ prefix
   - Provides `ActionChip` quick amounts (50, 100, 200 cedis)
   - Calculates fee (1% of amount) shown dynamically
   - Routes to `/payment` for payment method selection
7. Payment flow routes to success/failure terminal screens

**Key patterns**:

- All amount inputs use `double.tryParse()` and display cedis (₵) currency
- Repayment uses `ActionChip` for preset values; updates controller on tap
- Fee calculation done inline in `build()` from parsed TextField value
- No state persistence between loan screens (mock data only)

### Savings Flow

**Screens**: [savings_screen.dart](../../lib/screens/savings/savings_screen.dart) → create_savings_screen.dart → savings_detail_screen.dart

**Sequence**:

1. Savings tab shows list of existing savings goals (mocked in screen)
2. FAB or "Create" button navigates to `/savings/create` (CreateSavingsScreen)
3. `CreateSavingsScreen` collects:
   - Savings name (TextField)
   - Target amount (cedis ₵ currency prefix)
   - Auto-save toggle (Switch)
4. Submit stores locally (no persistence yet) and navigates to `/savings`
5. Tap existing savings goal routes to `/savings/:id` with route param:
   ```dart
   GoRoute(
     path: '/savings/:id',
     builder: (context, state) {
       final id = state.pathParameters['id']!;
       return SavingsDetailScreen(savingsId: id);
     },
   )
   ```
6. Detail screen shows progress bar, interest earned, deposit/withdraw options

**Key patterns**:

- Savings list and detail are tabs within MainShell bottom nav
- Route params used for detail screen ID passing (see router.dart line ~111)
- TextControllers in create screen always disposed in `dispose()`
- Auto-save toggle uses `Switch` with `setState` on `onChanged`

### Payment Flow (Terminal Step)

**Screens**: payment_screen.dart → payment_success_screen.dart or payment_failed_screen.dart

**Triggered from**: Loan repayment, savings deposit, or direct payment action

**Sequence**:

1. Payment screen shows:
   - Amount TextField (cedis ₵ currency)
   - Payment method dropdown (Card, Bank, Mobile Money)
   - Submit button (disabled until amount > 0)
2. On submit → routes to `/payment-success` or `/payment-failed` (50/50 mock)
3. Success/failure screens are **terminal** (no back navigation within payment flow)
   - Success screen: Shows confirmation, next-step button
   - Failed screen: Shows error reason, retry button
4. Both terminal screens navigate back to dashboard or home on button tap

**Key patterns**:

- Payment validates amount > 0 before enabling button
- No state persistence (mock processing)
- Success/failed are decision screens, not continuations
- Payment method selection uses RadioListTile or DropdownButton pattern

## Cross-Component Communication Patterns

### Data Flow

1. **Navigation with parameters**: Use `state.pathParameters` for route params (e.g., savings/:id)
2. **Temporary data**: Pass via constructor (e.g., `SavingsDetailScreen(savingsId: id)`)
3. **Persistent data**: Use SharedPreferences (setup flags, user prefs)
4. **API/Backend**: Not yet implemented; mock data pattern shown in dashboard_screen.dart

### Screen Dependencies

- Dashboard aggregates data from multiple features (loans, savings, transactions)
- Profile/KYC may be accessed from multiple screens
- Payment success/failure screens are terminal nodes in payment flow
- Loans and savings can both trigger payment flow (reuse PaymentScreen)

## Testing Approach

- **flutter_test** is available but no tests written yet
- Focus on manual testing with `flutter run`
- Common debug: Use debugPrint() for console output; enable debug banner in AdepaTeachersApp

## File Structure Quick Reference

```
lib/
├── main.dart                 # App entry, theme definition
├── router/app_router.dart    # All routes, navigation logic
├── core/                     # Shared UI components
│   ├── app_scaffold.dart    # Reusable scaffold wrapper
│   ├── app_card.dart        # Card component
│   ├── color_ext.dart       # Color utilities
│   └── layout/main_shell.dart # Bottom nav shell
└── screens/                 # Feature-based organization
    ├── auth/               # Auth flow screens
    ├── dashboard/          # Home/dashboard
    ├── loans/              # Loan feature
    ├── savings/            # Savings feature
    ├── payment/            # Payment feature
    ├── transactions/       # Transaction history
    ├── profile/            # User profile
    └── splash/             # Startup screen
```

## Quick Tips for AI Agents

- **New screens**: Extend StatefulWidget, wrap child in AppScaffold, use AppCard for grouping
- **Navigation**: Always check router.dart for routes before creating new ones
- **Colors**: Reference `theme.colorScheme` and `theme.textTheme`, never hardcode
- **Disposal**: Always implement `dispose()` for TextEditingControllers and PageControllers
- **State**: Use computed getters for validation; setState for UI updates
