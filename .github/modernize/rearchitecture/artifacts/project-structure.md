# Project Structure

## Classification

Flutter mobile application with shared web/desktop platform scaffolding. It is a client-side full-stack consumer: UI, local state, secure session storage, and HTTP integration are in this repository; the business system and persistence backend are external.

## Runtime entry points

- `lib/main.dart` initializes secure storage, HTTP preferences, network monitoring, device identity, and Riverpod before `runApp`.
- `lib/router/app_router.dart` is the single route registry and async authentication/onboarding redirect guard.
- `lib/core/providers/app_providers.dart` registers service providers, auth state, and feature data providers.

## Top-level layers

- `lib/screens/`: feature UI and user flows.
- `lib/core/`: reusable widgets, models, Riverpod providers, API services, secure storage, notifications, device identity, and utilities.
- `lib/router/`: GoRouter configuration and navigation history.
- `images/`: bundled application and service logos.
- `android/`, `ios/`, `macos/`, `windows/`, `web/`: Flutter platform hosts and generated plugin registration.

## Functional domains

1. Startup and onboarding
2. Authentication: phone login, OTP, registration, PIN management, biometrics
3. Dashboard and authenticated shell
4. Loans and repayments
5. Savings, deposits, withdrawals, transfers, and statements
6. Payments, bills, mobile purchases, and receipts
7. Investments and cooperative shares
8. Profile, settings, security, and KYC
9. Transactions and notifications

## Structural observations

- Routing, auth redirects, shell navigation, and all feature routes are concentrated in one large router.
- Provider registration, auth transitions, credential derivation, feature API providers, and diagnostics are concentrated in one large provider file.
- The UI is screen-oriented and uses local `StatefulWidget` state for forms, with Riverpod for cross-screen data.
- External API access is centralized through `HttpClient`/Dio and service classes, but endpoint contracts are distributed across `ApiService` subclasses and constants.
