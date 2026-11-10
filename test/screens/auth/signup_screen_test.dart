import 'package:adepa_teachers/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('sign-in prompt fits on narrow screens and navigates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login destination')),
        ),
        GoRoute(
          path: '/existing-member-enrollment',
          builder: (context, state) => const Scaffold(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Already enrolled for mobile banking?'), findsOneWidget);

    final signInButton = find.widgetWithText(TextButton, 'Sign in');
    await tester.ensureVisible(signInButton);
    expect(tester.takeException(), isNull);
    final signInStyle = tester.widget<TextButton>(signInButton).style;
    expect(signInStyle?.foregroundColor?.resolve({}), Colors.white);
    expect(
      tester.widget<Text>(find.text('Sign in')).style?.fontWeight,
      FontWeight.w700,
    );
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
  });

  testWidgets('shows descriptions for both account options', (tester) async {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/existing-member-enrollment',
          builder: (context, state) => const Scaffold(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(
      find.text('Proceed if you already have an account with us.'),
      findsOneWidget,
    );
    expect(
      find.text('Open a new account and start your journey with us.'),
      findsOneWidget,
    );
  });
}
