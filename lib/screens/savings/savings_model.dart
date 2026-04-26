import 'package:flutter/material.dart';

enum SavingsType { memberSaving, currentSaving, kiddySaving, fixedDeposit }

extension SavingsTypeExt on SavingsType {
  String get label {
    switch (this) {
      case SavingsType.memberSaving:
        return 'Member Saving';
      case SavingsType.currentSaving:
        return 'Current Saving';
      case SavingsType.kiddySaving:
        return 'Kiddy Saving';
      case SavingsType.fixedDeposit:
        return 'Fixed Deposit';
    }
  }

  String get description {
    switch (this) {
      case SavingsType.memberSaving:
        return 'Flexible savings for members';
      case SavingsType.currentSaving:
        return 'Daily transaction savings';
      case SavingsType.kiddySaving:
        return 'Savings account for children';
      case SavingsType.fixedDeposit:
        return 'Fixed rate deposit with term';
    }
  }

  IconData get icon {
    switch (this) {
      case SavingsType.memberSaving:
        return Icons.group;
      case SavingsType.currentSaving:
        return Icons.account_balance;
      case SavingsType.kiddySaving:
        return Icons.child_care;
      case SavingsType.fixedDeposit:
        return Icons.lock_clock;
    }
  }
}

class Savings {
  final String id;
  final String title;
  final double balance;
  final double target;
  final SavingsType type;
  final DateTime createdAt;
  final double? interestRate;
  final DateTime? maturityDate;

  Savings({
    required this.id,
    required this.title,
    required this.balance,
    required this.target,
    required this.type,
    DateTime? createdAt,
    this.interestRate,
    this.maturityDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'balance': balance,
      'target': target,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'interestRate': interestRate,
      'maturityDate': maturityDate?.toIso8601String(),
    };
  }

  factory Savings.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final parsedType = SavingsType.values.where((t) => t.name == typeName);

    return Savings(
      id: json['id'] as String,
      title: json['title'] as String,
      balance: (json['balance'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      type: parsedType.isNotEmpty ? parsedType.first : SavingsType.memberSaving,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      maturityDate: json['maturityDate'] != null
          ? DateTime.tryParse(json['maturityDate'] as String)
          : null,
    );
  }
}
