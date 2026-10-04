import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvestmentActivityEntry {
  final String reference;
  final String planName;
  final double amount;
  final DateTime startedAt;

  const InvestmentActivityEntry({
    required this.reference,
    required this.planName,
    required this.amount,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'planName': planName,
      'amount': amount,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory InvestmentActivityEntry.fromJson(Map<String, dynamic> json) {
    return InvestmentActivityEntry(
      reference: json['reference'] as String,
      planName: json['planName'] as String,
      amount: (json['amount'] as num).toDouble(),
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class InvestmentState {
  final String? selectedPlanName;
  final int activePlans;
  final double totalInvested;
  final DateTime? lastStartedAt;
  final List<InvestmentActivityEntry> activities;

  const InvestmentState({
    this.selectedPlanName,
    this.activePlans = 0,
    this.totalInvested = 0,
    this.lastStartedAt,
    this.activities = const [],
  });

  InvestmentState copyWith({
    String? selectedPlanName,
    int? activePlans,
    double? totalInvested,
    DateTime? lastStartedAt,
    List<InvestmentActivityEntry>? activities,
  }) {
    return InvestmentState(
      selectedPlanName: selectedPlanName ?? this.selectedPlanName,
      activePlans: activePlans ?? this.activePlans,
      totalInvested: totalInvested ?? this.totalInvested,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedPlanName': selectedPlanName,
      'activePlans': activePlans,
      'totalInvested': totalInvested,
      'lastStartedAt': lastStartedAt?.toIso8601String(),
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }

  factory InvestmentState.fromJson(Map<String, dynamic> json) {
    return InvestmentState(
      selectedPlanName: json['selectedPlanName'] as String?,
      activePlans: (json['activePlans'] as num?)?.toInt() ?? 0,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0,
      lastStartedAt: json['lastStartedAt'] == null
          ? null
          : DateTime.tryParse(json['lastStartedAt'] as String),
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InvestmentActivityEntry.fromJson)
          .toList(),
    );
  }
}

class InvestmentNotifier extends StateNotifier<InvestmentState> {
  static const _storageKey = 'investment_state_v1';

  InvestmentNotifier()
      : super(const InvestmentState()) {
    _restore();
  }

  void selectPlan(String planName) {
    state = state.copyWith(selectedPlanName: planName);
    _persist();
  }

  void recordStart({required String planName, required double amount}) {
    final now = DateTime.now();
    final seed = (now.millisecondsSinceEpoch % 9000 + 1000).toString().padLeft(
      4,
      '0',
    );
    final entry = InvestmentActivityEntry(
      reference: 'INV-${now.year}-$seed',
      planName: planName,
      amount: amount,
      startedAt: now,
    );

    state = state.copyWith(
      selectedPlanName: planName,
      activePlans: state.activePlans + 1,
      totalInvested: state.totalInvested + amount,
      lastStartedAt: now,
      activities: [entry, ...state.activities],
    );
    _persist();
  }

  Future<void> clear() async {
    state = const InvestmentState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      state = InvestmentState.fromJson(data);
    } catch (_) {
      // Ignore invalid cached payloads.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }
}

final investmentProvider =
    StateNotifierProvider<InvestmentNotifier, InvestmentState>(
      (ref) => InvestmentNotifier(),
    );
