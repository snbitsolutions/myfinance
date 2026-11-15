import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoanApplicationState {
  final double amount;
  final String purpose;
  final String repaymentPlan;
  final DateTime preparedAt;
  final bool isSubmitted;
  final String? submissionMessage;

  const LoanApplicationState({
    required this.amount,
    required this.purpose,
    required this.repaymentPlan,
    required this.preparedAt,
    this.isSubmitted = false,
    this.submissionMessage,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'purpose': purpose,
    'repaymentPlan': repaymentPlan,
    'preparedAt': preparedAt.toIso8601String(),
    'isSubmitted': isSubmitted,
    if (submissionMessage != null) 'submissionMessage': submissionMessage,
  };

  factory LoanApplicationState.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final purpose = json['purpose'];
    final repaymentPlan = json['repaymentPlan'];
    final preparedAt = DateTime.tryParse(json['preparedAt']?.toString() ?? '');

    if (amount is! num ||
        purpose is! String ||
        repaymentPlan is! String ||
        preparedAt == null) {
      throw const FormatException('Invalid saved loan application draft.');
    }

    return LoanApplicationState(
      amount: amount.toDouble(),
      purpose: purpose,
      repaymentPlan: repaymentPlan,
      preparedAt: preparedAt,
      isSubmitted: json['isSubmitted'] == true,
      submissionMessage: json['submissionMessage'] as String?,
    );
  }

  LoanApplicationState copyWith({
    bool? isSubmitted,
    String? submissionMessage,
  }) {
    return LoanApplicationState(
      amount: amount,
      purpose: purpose,
      repaymentPlan: repaymentPlan,
      preparedAt: preparedAt,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submissionMessage: submissionMessage ?? this.submissionMessage,
    );
  }
}

class LoanApplicationNotifier extends StateNotifier<LoanApplicationState?> {
  static const _storageKey = 'loan_application_draft_v2';

  LoanApplicationNotifier() : super(null) {
    _restorePersistedDraft();
  }

  Future<void> prepareDraft({
    required double amount,
    required String purpose,
    required String repaymentPlan,
  }) async {
    final draft = LoanApplicationState(
      amount: amount,
      purpose: purpose.trim(),
      repaymentPlan: repaymentPlan,
      preparedAt: DateTime.now(),
    );
    state = draft;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(draft.toJson()));
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> markSubmitted({String? message}) async {
    final current = state;
    if (current == null) {
      throw StateError('Cannot mark a missing loan application as submitted.');
    }
    final submitted = current.copyWith(
      isSubmitted: true,
      submissionMessage: message,
    );
    state = submitted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(submitted.toJson()));
  }

  Future<void> _restorePersistedDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loan_application_state_v1');
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved loan application draft.');
      }
      state = LoanApplicationState.fromJson(decoded);
    } on FormatException {
      await prefs.remove(_storageKey);
    }
  }
}

final loanApplicationProvider =
    StateNotifierProvider<LoanApplicationNotifier, LoanApplicationState?>(
      (ref) => LoanApplicationNotifier(),
    );
