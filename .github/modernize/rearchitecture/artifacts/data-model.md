# Data Model

## Persistence model

There is no local ORM or database schema in the repository. Persisted local data is held in SharedPreferences and Flutter Secure Storage. Remote entities are represented as dynamic `Map<String, dynamic>` payloads returned by the external mobile API.

## Local persisted fields

- `seenOnboarding`: onboarding completion flag.
- `userId`: full account identifier after successful authentication.
- `userEmail`: phone number used as the authenticated contact identity.
- `userName`: optional member display name.
- Secure session token and refresh token.
- Secure session device fingerprint.
- Secure/fallback PIN.
- `biometricAuth`: biometric login preference.
- Notification preferences, read notification IDs, custom notifications, and transfer favorites.

## Remote entity inventory

- Member/profile: account number, phone, name, balance, branch, status, KYC status.
- Savings account: savings ID, balance/current balance, product/type, target/progress values.
- Loan: loan ID, amount, status, interest, repayment terms, due date.
- Transaction: transaction ID, type, amount, timestamp, status, description.
- Payment: amount, payment method, reference, receipt/result status.
- Share holding: share/product identifiers, units, price/value, dividend/activity data.
- Investment: investment/product identifiers, balances, activity and statement data.

## Relationship evidence

- Authenticated member identity is the parent context for loans, savings, transactions, shares, investments, and payments.
- Savings detail and mutation routes are keyed by `/savings/:id`.
- Investment and share detail/mutation routes are keyed by nested route IDs.
- Loan repayment and savings mutations enter shared payment/authentication flows.

## Transaction boundaries

No database transaction annotations or local transaction engine were found. Atomicity is implemented as async sequences around remote requests plus secure/local preference writes; these sequences must be verified at runtime.
