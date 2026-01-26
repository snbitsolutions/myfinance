class Payment {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String description;
  final PaymentType type;

  Payment({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description = '',
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'type': type.toString(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      description: json['description'] ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PaymentType.expense,
      ),
    );
  }
}

enum PaymentType {
  income,
  expense,
}
