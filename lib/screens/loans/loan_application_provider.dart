import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoanApplicationState {
  final double amount;
  final String purpose;
  final String repaymentPlan;
  final int planMonths;
  final double effectiveRate;
  final DateTime submittedAt;
  final String referenceNumber;
  final double repaidAmount;

  const LoanApplicationState({
    required this.amount,
    required this.purpose,
    required this.repaymentPlan,
    required this.planMonths,
    required this.effectiveRate,
    required this.submittedAt,
    required this.referenceNumber,
    this.repaidAmount = 0.0,
  });

  double get totalInterest => amount * effectiveRate;
  double get totalWithInterest => amount + totalInterest;
  double get outstandingBalance =>
      (totalWithInterest - repaidAmount).clamp(0, totalWithInterest);
  double get monthlyInstallment => totalWithInterest / planMonths;
  DateTime get dueDate => submittedAt.add(Duration(days: planMonths * 30));
  double get progressFraction =>
      totalWithInterest > 0 ? repaidAmount / totalWithInterest : 0.0;

  LoanApplicationState copyWith({double? repaidAmount}) {
    return LoanApplicationState(
      amount: amount,
      purpose: purpose,
      repaymentPlan: repaymentPlan,
      planMonths: planMonths,
      effectiveRate: effectiveRate,
      submittedAt: submittedAt,
      referenceNumber: referenceNumber,
      repaidAmount: repaidAmount ?? this.repaidAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'purpose': purpose,
      'repaymentPlan': repaymentPlan,
      'planMonths': planMonths,
      'effectiveRate': effectiveRate,
      'submittedAt': submittedAt.toIso8601String(),
      'referenceNumber': referenceNumber,
      'repaidAmount': repaidAmount,
    };
  }

  factory LoanApplicationState.fromJson(Map<String, dynamic> json) {
    return LoanApplicationState(
      amount: (json['amount'] as num).toDouble(),
      purpose: json['purpose'] as String,
      repaymentPlan: json['repaymentPlan'] as String,
      planMonths: json['planMonths'] as int,
      effectiveRate: (json['effectiveRate'] as num).toDouble(),
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      referenceNumber: json['referenceNumber'] as String,
      repaidAmount: (json['repaidAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LoanApplicationNotifier extends StateNotifier<LoanApplicationState?> {
  static const _storageKey = 'loan_application_state_v1';

  LoanApplicationNotifier() : super(null) {
    _restorePersistedState();
  }

  void submit({
    required double amount,
    required String purpose,
    required String repaymentPlan,
  }) {
    final months = int.tryParse(repaymentPlan.split(' ').first) ?? 3;
    final rate = _rateForMonths(months);
    final now = DateTime.now();
    final seed = (now.millisecondsSinceEpoch % 9000 + 1000).toString().padLeft(
      4,
      '0',
    );
    final ref = 'LN-${now.year}-$seed';
    state = LoanApplicationState(
      amount: amount,
      purpose: purpose,
      repaymentPlan: repaymentPlan,
      planMonths: months,
      effectiveRate: rate,
      submittedAt: now,
      referenceNumber: ref,
    );
    _persistState();
  }

  void recordPayment(double paid) {
    if (state == null) return;
    state = state!.copyWith(
      repaidAmount: (state!.repaidAmount + paid).clamp(
        0,
        state!.totalWithInterest,
      ),
    );
    _persistState();
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _restorePersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      state = LoanApplicationState.fromJson(data);
    } catch (_) {
      // Ignore invalid cached payloads.
    }
  }

  Future<void> _persistState() async {
    final current = state;
    if (current == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(current.toJson()));
  }

  static double _rateForMonths(int months) {
    switch (months) {
      case 3:
        return 0.06;
      case 6:
        return 0.10;
      default:
        return 0.12;
    }
  }
}

final loanApplicationProvider =
    StateNotifierProvider<LoanApplicationNotifier, LoanApplicationState?>(
      (ref) => LoanApplicationNotifier(),
    );
