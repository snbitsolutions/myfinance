class Savings {
  final String id;
  final String name;
  final double balance;
  final double targetAmount;
  final DateTime createdDate;
  final String description;

  Savings({
    required this.id,
    required this.name,
    required this.balance,
    required this.targetAmount,
    required this.createdDate,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'targetAmount': targetAmount,
      'createdDate': createdDate.toIso8601String(),
      'description': description,
    };
  }

  factory Savings.fromJson(Map<String, dynamic> json) {
    return Savings(
      id: json['id'],
      name: json['name'],
      balance: json['balance'],
      targetAmount: json['targetAmount'],
      createdDate: DateTime.parse(json['createdDate']),
      description: json['description'] ?? '',
    );
  }

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (balance / targetAmount * 100).clamp(0, 100);
  }
}
