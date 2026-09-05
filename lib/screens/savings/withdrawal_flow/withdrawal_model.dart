class WithdrawalData {
  final String? savingsId;
  final double amount;
  final String phoneNumber;
  final String method;
  final String fromAccount;
  final double usedDailyLimit;
  final double usedMonthlyLimit;
  final String? transactionFee;
  final String? reference;
  final DateTime? processedAt;
  final double? newBalance;

  WithdrawalData({
    this.savingsId,
    required this.amount,
    required this.phoneNumber,
    required this.method,
    required this.fromAccount,
    required this.usedDailyLimit,
    required this.usedMonthlyLimit,
    this.transactionFee,
    this.reference,
    this.processedAt,
    this.newBalance,
  });

  WithdrawalData copyWith({
    String? savingsId,
    double? amount,
    String? phoneNumber,
    String? method,
    String? fromAccount,
    double? usedDailyLimit,
    double? usedMonthlyLimit,
    String? transactionFee,
    String? reference,
    DateTime? processedAt,
    double? newBalance,
  }) {
    return WithdrawalData(
      savingsId: savingsId ?? this.savingsId,
      amount: amount ?? this.amount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      method: method ?? this.method,
      fromAccount: fromAccount ?? this.fromAccount,
      usedDailyLimit: usedDailyLimit ?? this.usedDailyLimit,
      usedMonthlyLimit: usedMonthlyLimit ?? this.usedMonthlyLimit,
      transactionFee: transactionFee ?? this.transactionFee,
      reference: reference ?? this.reference,
      processedAt: processedAt ?? this.processedAt,
      newBalance: newBalance ?? this.newBalance,
    );
  }
}
