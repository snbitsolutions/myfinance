enum KycStatus { notStarted, pending, verified }

class AppUser {
  final String name;
  final String email;
  final String phone;
  final String accountNumber;
  final KycStatus kycStatus;

  AppUser({
    required this.name,
    required this.email,
    required this.phone,
    this.accountNumber = '',
    required this.kycStatus,
  });
}
