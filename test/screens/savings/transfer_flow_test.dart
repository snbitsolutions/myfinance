import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/screens/savings/transfer_flow/enter_recipient_details_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/enter_transfer_amount_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/processing_transfer_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/review_transfer_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/select_recipient_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/transfer_destination_screen.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/transfer_model.dart';
import 'package:adepa_teachers/screens/savings/transfer_flow/verify_recipient_screen.dart';

void main() {
  testWidgets('prepares transfer details without submitting a transfer', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/transfer',
      routes: [
        GoRoute(
          path: '/transfer',
          builder: (context, state) => const TransferDestinationScreen(),
        ),
        GoRoute(
          path: '/transfer/select-recipient',
          builder: (context, state) =>
              SelectRecipientScreen(initialData: state.extra as TransferData),
        ),
        GoRoute(
          path: '/transfer/enter-details',
          builder: (context, state) => EnterRecipientDetailsScreen(
            initialData: state.extra as TransferData,
          ),
        ),
        GoRoute(
          path: '/transfer/verify-recipient',
          builder: (context, state) =>
              VerifyRecipientScreen(initialData: state.extra as TransferData),
        ),
        GoRoute(
          path: '/transfer/enter-amount',
          builder: (context, state) => EnterTransferAmountScreen(
            initialData: state.extra as TransferData,
          ),
        ),
        GoRoute(
          path: '/transfer/review',
          builder: (context, state) =>
              ReviewTransferScreen(initialData: state.extra as TransferData),
        ),
        GoRoute(
          path: '/transfer/processing',
          builder: (context, state) => ProcessingTransferScreen(
            initialData: state.extra as TransferData?,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Adepa Member'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ama Mensah');
    await tester.pump();
    await tester.tap(find.text('Enter Recipient Phone'));
    await tester.pumpAndSettle();

    expect(find.text('Recipient Details'), findsOneWidget);
    final phoneField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.controller?.text.isEmpty == true,
    );
    await tester.enterText(phoneField, '0241234567');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Recipient'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not been verified'), findsOneWidget);

    await tester.tap(find.text('Continue to Amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '250');
    await tester.pump();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finish Preparing'));
    await tester.tap(find.text('Finish Preparing'));
    await tester.pumpAndSettle();

    expect(find.text('No money was moved'), findsOneWidget);
    expect(find.text('GH₵250.00'), findsOneWidget);
    expect(find.text('Ama Mensah'), findsOneWidget);
  });
}
