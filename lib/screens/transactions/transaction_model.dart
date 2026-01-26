enum TransactionType { deposit, withdrawal, repayment }

class AppTransaction {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? category;

  AppTransaction({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
  });
}
