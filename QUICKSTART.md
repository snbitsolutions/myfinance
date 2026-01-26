# Quick Start Guide - MyFinance App

## For Developers

### 1. Prerequisites
Make sure you have the following installed:
- Flutter SDK (3.0.0 or higher)
- Dart SDK (comes with Flutter)
- An IDE (VS Code with Flutter extension, or Android Studio)
- Android Studio / Xcode for emulators/simulators

### 2. Initial Setup

```bash
# Clone the repository
git clone https://github.com/snbitsolutions/myfinance.git
cd myfinance

# Install dependencies
flutter pub get

# Check your Flutter installation
flutter doctor
```

### 3. Running the App

**On an emulator/simulator:**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or simply run (Flutter will pick a device)
flutter run
```

**Hot Reload:** Press `r` in the terminal while the app is running
**Hot Restart:** Press `R` in the terminal while the app is running
**Quit:** Press `q` in the terminal

### 4. Building for Production

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (for Google Play):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS:**
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode and archive
```

### 5. Testing Your Changes

**Run Dart analyzer:**
```bash
flutter analyze
```

**Format code:**
```bash
flutter format lib/
```

**Run tests (if any):**
```bash
flutter test
```

## For End Users

### First Time Setup

1. Install the app on your device (download APK for Android or install from App Store for iOS)
2. Open the app - you'll see the dashboard with all metrics showing $0.00
3. Start adding your financial data!

### Getting Started with Features

#### Track Your Loans
1. Tap "Loans" button on the home screen
2. Tap the "+" button at the bottom right
3. Fill in loan details:
   - Name (e.g., "Car Loan", "Student Loan")
   - Amount borrowed
   - Interest rate percentage
   - Monthly payment amount
   - Start date
   - Optional: End date and description
4. Tap "Add"
5. View your loan details by tapping on the card
6. Delete by tapping the trash icon

#### Manage Your Savings
1. Tap "Savings" button on the home screen
2. Tap the "+" button
3. Create a savings goal:
   - Name (e.g., "Emergency Fund", "Vacation")
   - Current balance
   - Target amount
   - Optional: Description
4. Tap "Add"
5. Update balance by tapping "Update" button on any savings card
6. Watch your progress bar grow!

#### Record Payments
1. Tap "Payments" button on the home screen
2. Tap the "+" button
3. Select type: Income or Expense
4. Fill in details:
   - Title (e.g., "Salary", "Groceries")
   - Amount
   - Category (dropdown with common options)
   - Date
   - Optional: Description
5. Tap "Add"
6. Filter by type using the filter icon in the top right
7. Delete payments by tapping the trash icon

### Tips for Best Results

1. **Be Consistent**: Update your data regularly
2. **Use Categories**: Choose appropriate categories for easy tracking
3. **Set Realistic Goals**: Make your savings targets achievable
4. **Update Balances**: Keep your savings balances current
5. **Review Monthly**: Check your dashboard monthly to track progress

### Understanding the Dashboard

The home screen shows:
- **Total Savings**: Sum of all your savings account balances
- **Total Loans**: Sum of all outstanding loan amounts
- **Monthly Income**: All income payments for the current month
- **Monthly Expenses**: All expense payments for the current month
- **Recent Payments**: Last 5 transactions (newest first)

### Data Privacy

- All your data is stored locally on your device
- No data is sent to any server
- No internet connection required
- Your financial information is private and secure
- Data persists even if you close the app

### Troubleshooting

**App won't start:**
- Ensure your device meets minimum requirements
- Try restarting your device
- Reinstall the app

**Data not saving:**
- Check if you have storage space available
- Ensure you're tapping "Add" or "Update" buttons
- Try closing and reopening the app

**Can't add items:**
- Make sure all required fields are filled
- Check that amounts are valid numbers
- Ensure dates are properly selected

**App looks broken:**
- Make sure you're on a supported Android (5.0+) or iOS (11.0+) version
- Try rotating your device and back
- Close and reopen the app

### Getting Help

If you encounter issues:
1. Check this guide first
2. Look at the README.md for technical details
3. Open an issue on GitHub with:
   - Description of the problem
   - Steps to reproduce
   - Screenshots if applicable
   - Device information

## Development Tips

### Project Structure Understanding

```
lib/
├── main.dart              # Entry point
├── models/                # Data structures
├── services/              # Business logic
└── screens/               # UI components
```

### Common Development Tasks

**Add a new payment category:**
1. Open `lib/screens/payments_screen.dart`
2. Find the `_commonCategories` list
3. Add your category to the list

**Change currency symbol:**
1. Search for `NumberFormat.currency(symbol: '\$')`
2. Replace `\$` with your desired symbol

**Modify colors:**
1. Open `lib/main.dart`
2. Change `seedColor` in `ColorScheme.fromSeed()`
3. Or modify individual screen colors in their respective files

### Before Submitting a PR

1. Run `flutter analyze` - fix all issues
2. Run `flutter format lib/` - ensure consistent formatting
3. Test on both Android and iOS if possible
4. Update documentation if adding features
5. Add screenshots for UI changes

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design Guidelines](https://material.io/design)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)

## License

This project is open source under the MIT License.