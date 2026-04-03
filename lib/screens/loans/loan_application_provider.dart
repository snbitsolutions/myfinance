import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class LoanApplicationNotifier extends StateNotifier<LoanApplicationState?> {
  LoanApplicationNotifier() : super(null);

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
  }

  void recordPayment(double paid) {
    if (state == null) return;
    state = state!.copyWith(
      repaidAmount: (state!.repaidAmount + paid).clamp(
        0,
        state!.totalWithInterest,
      ),
    );
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
