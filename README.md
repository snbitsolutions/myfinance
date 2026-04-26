# ADEPA TEACHERS

A personal finance management Flutter mobile app featuring loan applications, savings tracking, and payment processing.

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

- User profile management
- KYC verification
- Security settings
- Notification preferences

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod (foundation ready)
- **Navigation**: GoRouter
- **Storage**: SharedPreferences
- **Architecture**: Provider pattern with service layer

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for Mac users)

### Installation

```bash
# Clone the repository
git clone https://github.com/snbitsolutions/adepa_teachers.git

# Navigate to project directory
cd adepa_teachers

# Install dependencies
flutter pub get

# Run the app
flutter run
```

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

### 🚧 Phase 2: Backend Integration (Next)

- API integration
- Hive database implementation
- Real-time data synchronization
- Token management

### 📋 Future Enhancements

- Biometric authentication
- Push notifications
- Dark mode
- Budget tracker
- Financial insights and analytics
- Investment tracking

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

**SNBitSolutions**

- GitHub: [@snbitsolutions](https://github.com/snbitsolutions)
- Project Link: [https://github.com/snbitsolutions/adepa_teachers](https://github.com/snbitsolutions/adepa_teachers)

## Acknowledgments

- Flutter team for the amazing framework
- The open-source community for inspiration and packages
