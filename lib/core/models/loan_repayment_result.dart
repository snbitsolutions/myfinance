class LoanRepaymentResult {
  final String loanId;
  final String transactionId;
  final double amount;
  final double previousOutstanding;
  final double newOutstanding;
  final DateTime processedAt;
  final String message;
  final String paymentMethod;

  const LoanRepaymentResult({
    required this.loanId,
    required this.transactionId,
    required this.amount,
    required this.previousOutstanding,
    required this.newOutstanding,
    required this.processedAt,
    required this.message,
    required this.paymentMethod,
  });

  double get amountApplied => previousOutstanding - newOutstanding;

  factory LoanRepaymentResult.fromApiResponse(Map<String, dynamic> response) {
    final rawData = response['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return LoanRepaymentResult(
      loanId: (data['loan_id'] ?? data['loanId'] ?? '').toString(),
      transactionId: (data['transaction_id'] ?? data['transactionId'] ?? '')
          .toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      previousOutstanding:
          (data['previous_outstanding'] as num?)?.toDouble() ?? 0,
      newOutstanding: (data['new_outstanding'] as num?)?.toDouble() ?? 0,
      processedAt:
          DateTime.tryParse((data['processed_at'] ?? '').toString()) ??
          DateTime.now(),
      message: (response['message'] ?? data['message'] ?? '').toString(),
      paymentMethod:
          (data['payment_method'] ??
                  data['payment_method_label'] ??
                  'Mobile Money')
              .toString(),
    );
  }
}
