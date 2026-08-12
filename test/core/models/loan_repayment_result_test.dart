import 'package:adepa_teachers/core/models/loan_repayment_result.dart';
import 'package:test/test.dart';

void main() {
  group('LoanRepaymentResult.fromApiResponse', () {
    test('uses a payment method from the API payload when present', () {
      final result = LoanRepaymentResult.fromApiResponse({
        'status': 'success',
        'message': 'Payment accepted',
        'data': {
          'loan_id': 'loan-123',
          'transaction_id': 'txn-456',
          'amount': 120.0,
          'previous_outstanding': 500.0,
          'new_outstanding': 380.0,
          'processed_at': '2026-08-08T12:00:00Z',
          'payment_method': 'MoMo',
        },
      });

      expect(result.paymentMethod, 'MoMo');
      expect(result.amountApplied, 120.0);
      expect(result.transactionId, 'txn-456');
    });
  });
}
