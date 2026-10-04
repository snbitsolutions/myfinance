# Tech Stack

- Language/runtime: Dart with Flutter; SDK constraint `^3.10.4`.
- UI framework: Flutter Material.
- Routing: `go_router ^17.0.1`.
- State management: `flutter_riverpod ^2.4.0` and `riverpod ^2.4.0`; `provider ^6.0.5` is also declared.
- Networking: Dio `^5.4.0`, `pretty_dio_logger`, and a custom singleton `HttpClient`.
- Persistence: SharedPreferences for flags/preferences; Flutter Secure Storage for session tokens, PIN, refresh token, and device fingerprint.
- Device integrations: `local_auth`, `device_info_plus`, `connectivity_plus`.
- Presentation/support: `google_fonts`, `intl`, `cupertino_icons`.
- Testing/linting: `flutter_test`, `test`, `flutter_lints`.
- Backend integration: Adepa/STCCU mobile API endpoints under `https://adepaye.com/api/mobileapp-api` plus legacy STCCU endpoints.

## Existing constraints and blockers

- The app accepts several backend status conventions (`0`, `1`, `200`, strings, booleans) and normalizes response payloads dynamically.
- OTP login stores a session without necessarily storing a PIN, but investments and some legacy customer APIs explicitly read a PIN.
- `disableApiAuthInDebug` is a compile-time constant and debug bypass identity is environment-driven.
- `HttpClient` retries a request after a 401 when token refresh succeeds; the refresh behavior must remain contract-compatible.
- The repository currently contains a large number of feature screens and a centralized router/provider architecture, so changes should be scoped by feature flow rather than broad rewrites.
