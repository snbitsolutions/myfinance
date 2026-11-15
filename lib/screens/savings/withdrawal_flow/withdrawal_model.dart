class WithdrawalData {
  final String? savingsId;
  final double amount;
  final String phoneNumber;
  final String method;
  final String channel;
  final String fromAccount;
  final double? availableBalance;
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
    this.availableBalance,
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
    double? availableBalance,
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
      availableBalance: availableBalance ?? this.availableBalance,
      transactionFee: transactionFee ?? this.transactionFee,
      reference: reference ?? this.reference,
      isPending: isPending ?? this.isPending,
      processedAt: processedAt ?? this.processedAt,
      newBalance: newBalance ?? this.newBalance,
      pin: pin ?? this.pin,
    );
  }
}
