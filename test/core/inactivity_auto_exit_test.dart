import 'package:adepa_teachers/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closes after 60 seconds without activity', (tester) async {
    var timeoutCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: InactivityAutoExit(
          timeout: const Duration(seconds: 60),
          onTimeout: () => timeoutCount++,
          child: const Scaffold(body: Text('Active app')),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    expect(timeoutCount, 1);
  });

  testWidgets('pointer activity resets the inactivity timer', (tester) async {
    var timeoutCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: InactivityAutoExit(
          timeout: const Duration(seconds: 60),
          onTimeout: () => timeoutCount++,
          child: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: const Center(child: Text('Active app')),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 59));
    await tester.tap(find.text('Active app'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 59));
    expect(timeoutCount, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(timeoutCount, 1);
  });
}
