bool shouldRedirectToSignup(String message) {
  final normalized = message.toLowerCase();

  const signupSignals = <String>[
    'not registered',
    'no account',
    'account not found',
    'account does not exist',
    'account not exist',
    'phone number not found',
    'user not found',
    'member not found',
    'unknown account',
    'no record',
  ];

  for (final signal in signupSignals) {
    if (normalized.contains(signal)) {
      return true;
    }
  }

  return false;
}
