import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> isAvailable() async {
    try {
      return await _localAuthentication.canCheckBiometrics &&
          await _localAuthentication.isDeviceSupported();
    } on LocalAuthException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!await isAvailable()) return false;
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Verify your identity to sign in to Adepa Teachers',
      );
    } on LocalAuthException {
      return false;
    }
  }
}
