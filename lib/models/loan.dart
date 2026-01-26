class Loan {
  final String id;
  final String name;
  final double amount;
  final double interestRate;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyPayment;
  final String description;

  Loan({
    required this.id,
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.startDate,
    this.endDate,
    required this.monthlyPayment,
    this.description = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'monthlyPayment': monthlyPayment,
      'description': description,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      amount: json['amount'],
      interestRate: json['interestRate'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      monthlyPayment: json['monthlyPayment'],
      description: json['description'] ?? '',
    );
  }
}
