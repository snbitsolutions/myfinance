import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import '../models/savings.dart';
import '../models/payment.dart';

class DataService {
  static const String _loansKey = 'loans';
  static const String _savingsKey = 'savings';
  static const String _paymentsKey = 'payments';

  // Loans
  Future<List<Loan>> getLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loansJson = prefs.getString(_loansKey);
      if (loansJson == null) return [];
      
      final List<dynamic> decoded = json.decode(loansJson);
      return decoded.map((item) => Loan.fromJson(item)).toList();
    } catch (e) {
      // Return empty list if JSON is corrupted
      return [];
    }
  }

  Future<void> saveLoans(List<Loan> loans) async {
    final prefs = await SharedPreferences.getInstance();
    final loansJson = json.encode(loans.map((loan) => loan.toJson()).toList());
    await prefs.setString(_loansKey, loansJson);
  }

  Future<void> addLoan(Loan loan) async {
    final loans = await getLoans();
    loans.add(loan);
    await saveLoans(loans);
  }

  Future<void> deleteLoan(String id) async {
    final loans = await getLoans();
    loans.removeWhere((loan) => loan.id == id);
    await saveLoans(loans);
  }

  // Savings
  Future<List<Savings>> getSavings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savingsJson = prefs.getString(_savingsKey);
      if (savingsJson == null) return [];
      
      final List<dynamic> decoded = json.decode(savingsJson);
      return decoded.map((item) => Savings.fromJson(item)).toList();
    } catch (e) {
      // Return empty list if JSON is corrupted
      return [];
    }
  }

  Future<void> saveSavings(List<Savings> savings) async {
    final prefs = await SharedPreferences.getInstance();
    final savingsJson = json.encode(savings.map((s) => s.toJson()).toList());
    await prefs.setString(_savingsKey, savingsJson);
  }

  Future<void> addSavings(Savings savings) async {
    final savingsList = await getSavings();
    savingsList.add(savings);
    await saveSavings(savingsList);
  }

  Future<void> deleteSavings(String id) async {
    final savingsList = await getSavings();
    savingsList.removeWhere((s) => s.id == id);
    await saveSavings(savingsList);
  }

  Future<void> updateSavings(Savings updatedSavings) async {
    final savingsList = await getSavings();
    final index = savingsList.indexWhere((s) => s.id == updatedSavings.id);
    if (index != -1) {
      savingsList[index] = updatedSavings;
      await saveSavings(savingsList);
    }
  }

  // Payments
  Future<List<Payment>> getPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = prefs.getString(_paymentsKey);
      if (paymentsJson == null) return [];
      
      final List<dynamic> decoded = json.decode(paymentsJson);
      return decoded.map((item) => Payment.fromJson(item)).toList();
    } catch (e) {
      // Return empty list if JSON is corrupted
      return [];
    }
  }

  Future<void> savePayments(List<Payment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = json.encode(payments.map((p) => p.toJson()).toList());
    await prefs.setString(_paymentsKey, paymentsJson);
  }

  Future<void> addPayment(Payment payment) async {
    final payments = await getPayments();
    payments.add(payment);
    await savePayments(payments);
  }

  Future<void> deletePayment(String id) async {
    final payments = await getPayments();
    payments.removeWhere((p) => p.id == id);
    await savePayments(payments);
  }
}
