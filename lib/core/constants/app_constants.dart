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
  static const bool disableApiAuthInDebug = true;
  static const String debugApiPhoneNumber = String.fromEnvironment(
    'DEBUG_API_PHONE',
    defaultValue: '',
  );
  static const String debugApiAccountNumber = String.fromEnvironment(
    'DEBUG_API_ACCOUNT',
    defaultValue: '',
  );
  static const String debugApiPin = String.fromEnvironment(
    'DEBUG_API_PIN',
    defaultValue: '',
  );

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
  static const double minimumSavingsBalanceAfterWithdrawal = 50;

  // UI
  static const double defaultPadding = 16;
  static const double defaultBorderRadius = 12;
  static const double defaultCardBorderRadius = 20;

  // Durations
  static const Duration splashDuration = Duration(seconds: 5);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const String termsOfServiceVersion = '1.0';

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
  static const String invalidCredentialsMessage =
      'Invalid phone number or password.';
  static const String invalidCredentialsErrorCode = 'invalid_credentials';
  static const int maxFailedLoginAttempts = 3;
  static const String loginAttemptsLockedMessage =
      'Sign-in is blocked on this device for this phone number after too many '
      'incorrect password attempts. Please contact your financial institution '
      'to reset your password.';
  static const String userNotFoundMessage = 'User account not found.';
  static const String accountLockedMessage =
      'Account is locked. Please contact support.';
  static const String invalidOtpMessage =
      'Invalid verification code. Please try again.';
  static const String pinMismatchMessage = 'PINs do not match.';
  static const String pinResetUnavailableMessage =
      'Forgot-PIN reset is not available because the backend does not document a PIN recovery endpoint.';
  static const String defaultMobileApiSKey = 'ArTM3c8yq0Lhlh';
  static const int defaultMobileApiImeiNumber = int.fromEnvironment(
    'DEBUG_API_IMEI',
    defaultValue: 100200300,
  );
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
  static const String sharedPrefKeyAcceptedTermsVersion =
      'acceptedTermsVersion';
  static const String sharedPrefKeyTermsAcceptedAt = 'termsAcceptedAt';
  static const String sharedPrefKeyDebugBypassAuth = 'debugBypassAuth';
  static const String sharedPrefKeyUserToken = 'userToken';
  static const String sharedPrefKeyUserRefreshToken = 'userRefreshToken';
  static const String sharedPrefKeyUserId = 'userId';
  static const String sharedPrefKeyUserEmail = 'userEmail';
  static const String sharedPrefKeyUserName = 'userName';
  static const String sharedPrefKeyDeviceInstallId = 'deviceInstallId';
  static const String sharedPrefKeyRememberMe = 'rememberMe';
  static const String sharedPrefKeyBiometricAuth = 'biometricAuth';
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
  static const String sharedPrefKeyCustomNotifications = 'customNotifications';

  // Secure storage keys
  static const String secureStorageKeyUserToken = 'secure.userToken';
  static const String secureStorageKeyUserRefreshToken =
      'secure.userRefreshToken';
  static const String secureStorageKeySessionDeviceFingerprint =
      'secure.sessionDeviceFingerprint';
  static const String secureStorageKeyDeviceVerifiedSession =
      'secure.deviceVerifiedSession';
  static const String secureStorageKeyDeviceInstallId =
      'secure.deviceInstallId';
  static const String secureStorageKeyUserPin = 'secure.userPin';
  static const String sharedPrefKeyUserPin = 'userPin';

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
  static const String baseUrl = 'https://adepaye.com/stccu-api';
  // Customer and member endpoints are hosted under the API-prefixed route.
  static const String mobileApiBaseUrl =
      'https://adepaye.com/api/mobileapp-api';

  // Documented ATCCU mobile app auth endpoints
  static const String confirmPhoneNumber =
      '$mobileApiBaseUrl/confirmPhoneNumber';
  static const String confirmAccountNumber =
      '$mobileApiBaseUrl/confirmAccountNumber';
  // Use the published mobile app OTP endpoints directly so they do not depend on
  // the older STCCU base URL.
  // OTP routes are hosted under the documented /api/mobileapp-api prefix.
  static const String sendLoginOtp =
      'https://adepaye.com/api/mobileapp-api/sendOtp';
  static const String verifyLoginOtp =
      'https://adepaye.com/api/mobileapp-api/verifyOtp';
  static const String confirmPin = '$mobileApiBaseUrl/verifyPin';
  static const String register = 'https://adepaye.com/mobileapp-api/register';
  static const String createMember = '$mobileApiBaseUrl/create';
  static const String changePin = '$mobileApiBaseUrl/changePin';
  static const String setPin = '$mobileApiBaseUrl/setPin';

  // STCCU account / data endpoints
  static const String getAccountBalance = '$mobileApiBaseUrl/getAccountBalance';
  static const String getLoans = '$mobileApiBaseUrl/getMemLoans';
  static const String miniStatement = '$mobileApiBaseUrl/miniStatement';
  static const String checkBalance = '$mobileApiBaseUrl/checkBalance';
  // The documented mobile-money funding endpoint is POST /deposit.
  static const String depositFunds = '/deposit';
  static const String withdrawFunds = '/withdraw';
  static const String stccuConfirmWithdrawal = '/confirmWithdrawal';
  static const String repayLoanStccu = '/repayLoan';
  // The documented Hubtel airtime request is POST /airtime.
  static const String buyAirtime = '/airtime';
  static const String getBranches = '/getBranch';
  static const String getSavingsProductsList =
      '$mobileApiBaseUrl/getMemSavings';
  static const String getFixedDeposits =
      '$mobileApiBaseUrl/getMemFixedDeposits';
  static const String getSavingsBalance = '$mobileApiBaseUrl/getSavingsBalance';
  static const String getLoanBalance = '$mobileApiBaseUrl/getLoanBalance';
  static const String getLoanProductsList = '$mobileApiBaseUrl/getLoanProducts';
  static const String applyLoan = '$mobileApiBaseUrl/loanApplication';
  static const String getShares = '$mobileApiBaseUrl/getMemShares';
  static const String getSavingsProducts = '$mobileApiBaseUrl/savings';
  static const String getSharesProducts = '$mobileApiBaseUrl/shares';
  static const String transferToSelf = '$mobileApiBaseUrl/transferToSelf';

  // Documented mobile app auth endpoints.
  static const String login = '$mobileApiBaseUrl/login';
  static const String logout = '$mobileApiBaseUrl/logout';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String legacySetPin = '/auth/set-pin';
  static const String refreshToken = '/auth/refresh-token';

  // User
  static const String getUserProfile = '/user/profile';
  static const String updateUserProfile = '/user/profile';
  static const String submitKyc = '/user/kyc';

  // Loans
  static const String getLoansList = '/loans';
  static const String getLoanDetail = '/loans/:id';
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
  static const String paymentServiceBaseUrl =
      'https://adepaye.com/api/payment-services';
  static const String initiatePayment = '/initiate';
  static const String verifyPayment = '/verify';

  // Settings
  static const String getSettings = '/settings';
  static const String updateSettings = '/settings';
}
