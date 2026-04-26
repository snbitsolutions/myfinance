// App-wide constants and configuration values

class AppConstants {
  // Currency
  static const String currencySymbol = '₵';
  static const String currencyCode = 'GHS';

  // App Info
  static const String appName = 'ADEPA TEACHERS';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration networkTimeout = Duration(seconds: 15);

  // Feature Flags
  static const bool enableBiometric = false;
  static const bool enableNotifications = false;
  static const bool enableOfflineMode = false;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int pinLength = 4;
  static const int otpLength = 4;

  // Loan
  static const double loanMinAmount = 100;
  static const double loanMaxAmount = 10000;
  static const double defaultInterestRate = 5.0; // 5% p.a.
  static const double repaymentFeePercentage = 1.0; // 1% processing fee

  // Savings
  static const double savingsMinTarget = 50;
  static const double savingsMaxTarget = 1000000;
  static const double savingsInterestRate = 2.5; // 2.5% p.a.

  // UI
  static const double defaultPadding = 16;
  static const double defaultBorderRadius = 12;
  static const double defaultCardBorderRadius = 20;

  // Durations
  static const Duration splashDuration = Duration(seconds: 5);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'No internet connection. Please check your connection.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String validationErrorMessage =
      'Please check your input and try again.';

  // Auth Messages
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String userNotFoundMessage = 'User account not found.';
  static const String accountLockedMessage =
      'Account is locked. Please contact support.';
  static const String invalidOtpMessage =
      'Invalid verification code. Please try again.';
  static const String pinMismatchMessage = 'PINs do not match.';
  static const String pinTooSimpleMessage =
      'PIN is too simple. Please choose a different PIN.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String logoutSuccessMessage = 'Logged out successfully.';
  static const String loanApplicationSuccessMessage =
      'Loan application submitted successfully.';
  static const String savingsCreatedSuccessMessage =
      'Savings goal created successfully.';
  static const String transactionSuccessMessage =
      'Transaction completed successfully.';

  // Shared Preferences Keys
  static const String sharedPrefKeyOnboarding = 'seenOnboarding';
  static const String sharedPrefKeyUserToken = 'userToken';
  static const String sharedPrefKeyUserRefreshToken = 'userRefreshToken';
  static const String sharedPrefKeyUserId = 'userId';
  static const String sharedPrefKeyUserEmail = 'userEmail';
  static const String sharedPrefKeyDeviceInstallId = 'deviceInstallId';
  static const String sharedPrefKeyRememberMe = 'rememberMe';
  static const String sharedPrefKeyDarkMode = 'darkMode';
  static const String sharedPrefKeyLanguage = 'language';
  static const String sharedPrefKeyTransferFavorites = 'transferFavorites';
  static const String sharedPrefKeyNotificationsEnabled =
      'notificationsEnabled';
  static const String sharedPrefKeyTransactionAlerts = 'transactionAlerts';
  static const String sharedPrefKeyLoanUpdates = 'loanUpdates';
  static const String sharedPrefKeySavingsReminders = 'savingsReminders';
  static const String sharedPrefKeyMarketingUpdates = 'marketingUpdates';
  static const String sharedPrefKeyReadNotificationIds = 'readNotificationIds';

  // Secure storage keys
  static const String secureStorageKeyUserToken = 'secure.userToken';
  static const String secureStorageKeyUserRefreshToken =
      'secure.userRefreshToken';
  static const String secureStorageKeySessionDeviceFingerprint =
      'secure.sessionDeviceFingerprint';

  // Loan Status
  static const String loanStatusPending = 'Pending';
  static const String loanStatusApproved = 'Approved';
  static const String loanStatusRejected = 'Rejected';
  static const String loanStatusRepayingPending = 'Repaying - Pending';
  static const String loanStatusRepayingCompleted = 'Repayed';

  // Transaction Types
  static const String transactionTypeDeposit = 'Deposit';
  static const String transactionTypeWithdrawal = 'Withdrawal';
  static const String transactionTypeRepayment = 'Repayment';

  // KYC Status
  static const String kycStatusNotStarted = 'Not Started';
  static const String kycStatusPending = 'Pending';
  static const String kycStatusVerified = 'Verified';
}

class ApiEndpoints {
  static const String baseUrl = 'https://api.adepa_teachers.local';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String setPin = '/auth/set-pin';
  static const String refreshToken = '/auth/refresh-token';

  // User
  static const String getUserProfile = '/user/profile';
  static const String updateUserProfile = '/user/profile';
  static const String submitKyc = '/user/kyc';

  // Loans
  static const String getLoansList = '/loans';
  static const String getLoanDetail = '/loans/:id';
  static const String applyLoan = '/loans/apply';
  static const String repayLoan = '/loans/:id/repay';
  static const String getLoanHistory = '/loans/history';

  // Savings
  static const String getSavingsList = '/savings';
  static const String getSavingDetail = '/savings/:id';
  static const String createSavings = '/savings';
  static const String depositSavings = '/savings/:id/deposit';
  static const String withdrawSavings = '/savings/:id/withdraw';

  // Transactions
  static const String getTransactions = '/transactions';
  static const String getTransactionDetail = '/transactions/:id';

  // Payments
  static const String initiatePayment = '/payments/initiate';
  static const String verifyPayment = '/payments/verify';

  // Settings
  static const String getSettings = '/settings';
  static const String updateSettings = '/settings';
}
