import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:adepa_teachers/core/constants/app_constants.dart';
import 'package:adepa_teachers/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding is one page with a full-screen city background', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 100));

    final imageFinder = find.byKey(const ValueKey('onboarding-background-0'));
    expect(find.byType(PageView), findsNothing);
    expect(imageFinder, findsOneWidget);
    expect(tester.widget<Image>(imageFinder).fit, BoxFit.cover);
    expect(tester.getSize(imageFinder), tester.getSize(find.byType(Scaffold)));
    expect(find.text('Welcome to ${AppConstants.appName}'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Quick Loans'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    await tester.pump(const Duration(seconds: 9));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 18));
    expect(tester.takeException(), isNull);
  });
}
