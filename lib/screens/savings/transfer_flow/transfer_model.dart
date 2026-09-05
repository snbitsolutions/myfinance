class TransferData {
  final String? savingsId;
  final String? destination;
  final String? recipientId;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientEmail;
  final double amount;
  final String? method;
  final String? reference;
  final String? processedAt;
  final double newBalance;
  final double transactionFee;

  TransferData({
    this.savingsId,
    this.destination,
    this.recipientId,
    this.recipientName,
    this.recipientPhone,
    this.recipientEmail,
    this.amount = 0.0,
    this.method,
    this.reference,
    this.processedAt,
    this.newBalance = 0.0,
    this.transactionFee = 0.0,
  });

  TransferData copyWith({
    String? savingsId,
    String? destination,
    String? recipientId,
    String? recipientName,
    String? recipientPhone,
    String? recipientEmail,
    double? amount,
    String? method,
    String? reference,
    String? processedAt,
    double? newBalance,
    double? transactionFee,
  }) {
    return TransferData(
      savingsId: savingsId ?? this.savingsId,
      destination: destination ?? this.destination,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      reference: reference ?? this.reference,
      processedAt: processedAt ?? this.processedAt,
      newBalance: newBalance ?? this.newBalance,
      transactionFee: transactionFee ?? this.transactionFee,
    );
  }
}
