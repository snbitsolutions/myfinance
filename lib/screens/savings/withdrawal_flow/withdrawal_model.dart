class WithdrawalData {
  final String? savingsId;
  final double amount;
  final String phoneNumber;
  final String method;
  final String channel;
  final String fromAccount;
  final double usedDailyLimit;
  final double usedMonthlyLimit;
  final double? availableBalance;
  final double? dailyLimit;
  final double? monthlyLimit;
  final String? transactionFee;
  final String? reference;
  final bool isPending;
  final DateTime? processedAt;
  final double? newBalance;
  final String? pin;

  WithdrawalData({
    this.savingsId,
    required this.amount,
    required this.phoneNumber,
    required this.method,
    this.channel = 'mtn-gh',
    required this.fromAccount,
    required this.usedDailyLimit,
    required this.usedMonthlyLimit,
    this.availableBalance,
    this.dailyLimit,
    this.monthlyLimit,
    this.transactionFee,
    this.reference,
    this.isPending = false,
    this.processedAt,
    this.newBalance,
    this.pin,
  });

  WithdrawalData copyWith({
    String? savingsId,
    double? amount,
    String? phoneNumber,
    String? method,
    String? channel,
    String? fromAccount,
    double? usedDailyLimit,
    double? usedMonthlyLimit,
    double? availableBalance,
    double? dailyLimit,
    double? monthlyLimit,
    String? transactionFee,
    String? reference,
    bool? isPending,
    DateTime? processedAt,
    double? newBalance,
    String? pin,
  }) {
    return WithdrawalData(
      savingsId: savingsId ?? this.savingsId,
      amount: amount ?? this.amount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      method: method ?? this.method,
      channel: channel ?? this.channel,
      fromAccount: fromAccount ?? this.fromAccount,
      usedDailyLimit: usedDailyLimit ?? this.usedDailyLimit,
      usedMonthlyLimit: usedMonthlyLimit ?? this.usedMonthlyLimit,
      availableBalance: availableBalance ?? this.availableBalance,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      transactionFee: transactionFee ?? this.transactionFee,
      reference: reference ?? this.reference,
      isPending: isPending ?? this.isPending,
      processedAt: processedAt ?? this.processedAt,
      newBalance: newBalance ?? this.newBalance,
      pin: pin ?? this.pin,
    );
  }
}
