# MyFinance - Personal Finance Management App

A comprehensive Flutter application for managing personal finances with support for loans, savings, and payment tracking.

## Features

### 💰 Loans Management
- Track multiple loans with detailed information
- Record loan amounts, interest rates, and monthly payments
- Set start and end dates for each loan
- View total outstanding loans
- Add descriptions and notes for each loan

### 🏦 Savings Management
- Create multiple savings goals
- Set target amounts for each savings account
- Track progress with visual indicators
- Update balances easily
- Monitor progress percentage
- Add descriptions for savings goals

### 💳 Payment Tracking
- Record income and expenses
- Categorize payments (Food, Transportation, Utilities, etc.)
- Filter by payment type (Income/Expense)
- Track monthly income and expenses
- Add detailed descriptions
- View payment history sorted by date

### 📊 Dashboard
- Overview of total savings and loans
- Monthly income and expense summary
- Recent payment history
- Quick access to all features
- Visual summary cards

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- An IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/snbitsolutions/myfinance.git
cd myfinance
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── loan.dart            # Loan model
│   ├── savings.dart         # Savings model
│   └── payment.dart         # Payment model
├── screens/                  # UI screens
│   ├── home_screen.dart     # Dashboard/home screen
│   ├── loans_screen.dart    # Loans management
│   ├── savings_screen.dart  # Savings management
│   └── payments_screen.dart # Payment tracking
└── services/                 # Business logic
    └── data_service.dart    # Data persistence service
```

## Dependencies

- **flutter**: Framework for building the app
- **shared_preferences**: Local data persistence
- **intl**: Internationalization and date formatting
- **cupertino_icons**: iOS-style icons
- **flutter_lints**: Linting rules for code quality

## Data Persistence

The app uses `shared_preferences` to store data locally on the device. All loans, savings, and payments are persisted and will be available when you restart the app.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue on GitHub.