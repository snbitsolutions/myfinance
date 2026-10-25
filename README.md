# ADEPA TEACHERS

A Flutter personal-finance app for Adepa members. The app uses documented ATCCU mobile API contracts where available and explicitly reports unsupported operations instead of displaying fabricated financial data.

## Features

### 🏦 Loans

- Quick loan application
- Flexible repayment plans
- Loan status tracking
- Repayment history

### 💰 Savings

- Multiple savings types (Member, Fixed Deposit, Emergency Fund, Target)
- Progress tracking with visual indicators
- Interest calculation
- 30+ actionable savings tips
- Interactive tip details with action steps

### 💳 Payments

- Multiple payment methods (Card, Bank, Mobile Money)
- Payment confirmation
- Transaction history

### 👤 Profile & Settings

- Account details
- KYC form validation and submission attempt
- Security settings
- Notification preferences

### 🔐 Authentication

- Onboarding and protected routes
- Phone and 4-digit PIN login; the documented login response verifies the PIN
  but does not issue a session token, so the app stores a device-bound
  verification marker and requires a previously linked full account number
- New-member and existing-member registration
- Phone and 4-digit PIN sign-in; three invalid-credential responses block
  sign-in for that phone on the device until support resets the PIN and the
  user confirms that reset in the app (which only clears the local block)
- Sign-up collects an account password separately; login uses the 4-digit PIN
- PIN recovery is not available in the app because the backend does not
  document a PIN-reset endpoint
- OTP verification and resend
- Device-bound sessions
- Secure PIN creation and storage

### 📊 Shares & Investments

- Live portfolio balances from the documented customer API
- Loading, error, and unavailable states
- Share and investment detail screens that only display returned data

Share purchases, share sales, dividend history, portfolio statements, investment
details, and investment actions are currently unavailable because no documented
backend contracts exist for those operations. The UI does not simulate success
for these actions.

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Storage**: SharedPreferences and secure storage
- **Architecture**: Riverpod providers with an API service layer

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for Mac users)

### Installation

```bash
# Clone the repository
git clone https://github.com/snbitsolutions/myfinance.git

# Navigate to project directory
cd myfinance

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Android release signing

Create an upload keystore locally. `keytool` prompts for the keystore and key
passwords; keep them private and make a secure backup of the keystore.

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Create `android/key.properties` (this file and `.jks` files are ignored by
Git), and set its values to match the keystore:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

Build a Google Play upload bundle with:

```bash
flutter build appbundle
```

Release builds fail if signing is not configured; debug builds do not require
the keystore. The Android application ID is `com.adepa.teachers`; confirm it
matches the package name registered for the app in Google Play. Do not change
that ID after publishing.

## Project Structure

```
lib/
├── core/                      # Core utilities and shared components
│   ├── app_card.dart         # Reusable card component
│   ├── app_scaffold.dart     # Custom scaffold wrapper
│   ├── color_ext.dart        # Color extensions
│   ├── constants/            # App-wide constants
│   ├── exceptions/           # Custom exception handling
│   ├── layout/               # Layout components
│   ├── models/               # Data models
│   ├── providers/            # Riverpod providers
│   ├── services/             # API and business logic services
│   └── utils/                # Utility functions
├── router/                    # App navigation
│   └── app_router.dart       # GoRouter configuration
├── screens/                   # Feature screens
│   ├── auth/                 # Authentication screens
│   ├── dashboard/            # Main dashboard
│   ├── loans/                # Loan management
│   ├── savings/              # Savings features
│   ├── payment/              # Payment processing
│   ├── transactions/         # Transaction history
│   ├── profile/              # User profile
│   └── onboarding/           # App onboarding
└── main.dart                 # App entry point
```

## Key Features Details

### Animated Onboarding

- 4 beautiful pages with smooth animations
- Icon scale and fade transitions
- Page parallax effects
- Back navigation support

### Savings Tips System

- 30+ curated tips across 8 categories
- Random tip selection with refresh
- Interactive tap for detailed information
- Action steps and estimated savings
- Related tips navigation

### Clean UI/UX

- Fintech green theme
- Consistent design system
- Smooth animations and transitions
- Responsive layouts

## Development Phases

### ✅ Phase 1: Foundation (Complete)

- Core architecture setup
- Service layer implementation
- State management foundation
- Error handling system
- Logging utilities

### ✅ Phase 2: Backend Integration (In Progress)

- Authentication, registration, OTP, and secure PIN flows
- Live loans, savings, shares, and transaction retrieval where documented
- Backend-gated loan and savings submissions
- Payment processing with transaction-reference validation
- Honest unavailable states for undocumented operations
- API response normalization and contract regression tests

### 🔎 Current Backend Limitations

The available documentation does not define endpoints for profile updates,
KYC persistence, loan details, savings-goal creation, recipient
lookup, investments, share buy/sell, dividends, portfolio statements, or
receipt downloads. These flows remain visible only where useful, but they
cannot complete until the corresponding backend contracts are provided.

The app keeps these screens available for future integration. It disables
unsupported submissions and shows unavailable terms instead of inventing loan
rates, savings returns, transfer fees, recipient matches, or application
statuses. Loan applications now submit to `POST /loanApplication`; the
preferred duration remains a planning-only value because it is not part of
that endpoint's request contract. Loan repayment also waits for a backend loan
record rather than using a locally saved draft.

### 📋 Future Enhancements

- Biometric authentication
- Push notifications
- Dark mode
- Budget tracker
- Financial insights and analytics
- Investment tracking when a documented API is available

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

**SNBitSolutions**

- GitHub: [@snbitsolutions](https://github.com/snbitsolutions)
- Project Link: [https://github.com/snbitsolutions/myfinance](https://github.com/snbitsolutions/myfinance)

## Acknowledgments

- Flutter team for the amazing framework
- The open-source community for inspiration and packages
