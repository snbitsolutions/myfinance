# Architecture Index

This index is not the full contract. Do not implement from this file alone; follow the artifact paths below.

## Global artifacts

- `unit_graph.yaml`: unit boundaries, route triggers, dependencies, exported signatures, and shared references.
- `migration_boundary.yaml`: analysis scope only; future implementation must define its own `must_rewrite` list.
- `wire_contracts.yaml`: external API request/response/status contracts. Filter by `unit`.
- `shared_modules.yaml`: shared router/provider/storage/UI modules. Filter by `used_by_units`.
- `cross_unit_state.yaml`: persisted auth, PIN, biometric, and notification flows. Filter by writer/reader unit.
- `seams.yaml`: inferred cuts at the external API and legacy PIN-dependent endpoints. Frozen-side rules are advisory until design confirms them.
- `project-structure.md`, `tech-stack.md`, `data-model.md`: global navigation and existing-stack views.

## Implementation Guide

Every unit has three required artifacts:

- `units/<unit>/behavior.yaml`: side effects, user-visible branches, errors, and async boundaries.
- `units/<unit>/bindings.yaml`: route/provider wiring and runtime configuration.
- `units/<unit>/unit_decomposition.yaml`: advisory split candidates only; `commit: false` means design owns the final structure.

### Unit: app-startup

- Trigger: application launch.
- Read `units/app-startup/*`; filter shared modules by `used_by_units` and state flows by writer/reader.
- Completion evidence: startup timeout behavior, secure initialization, redirect behavior, and runtime verification.

### Unit: onboarding

- Trigger: `/onboarding`.
- Read `units/onboarding/*`; preserve onboarding preference and redirect behavior.
- Completion evidence: first-run and returning-user navigation verification.

### Unit: authentication

- Trigger: `/login`, `/otp`, `/signup`, `/existing-member-enrollment`, `/set-pin`.
- Read `units/authentication/*`; filter `wire_contracts.yaml` for OTP rows and `cross_unit_state.yaml` for session/PIN/biometric flows.
- Completion evidence: phone → OTP → home, registration → PIN, logout/session restore, biometric restore, and backend error cases.

### Unit: dashboard

- Trigger: `/home`.
- Read `units/dashboard/*`; filter shared provider/UI rows and authenticated identity flow.
- Completion evidence: profile/balance/list loading, empty/error states, and shell navigation.

### Unit: loans

- Trigger: loan list, application, status, detail, and repayment routes.
- Read `units/loans/*`; filter payment seam and loan-related provider rows.
- Completion evidence: validation, application, repayment, failure, and receipt paths.

### Unit: savings

- Trigger: `/savings` and `/savings/:id/*`.
- Read `units/savings/*`; preserve route IDs, local storage, and mutation preconditions.
- Completion evidence: create/detail/deposit/withdraw/transfer flows and account selection.

### Unit: payments

- Trigger: payment hub, payment, bills, mobile purchase, success/failure, and receipt routes.
- Read `units/payments/*`; preserve method selection and terminal outcomes.
- Completion evidence: successful and failed provider responses with no false success state.

### Unit: investments-and-shares

- Trigger: investment and share routes.
- Read `units/investments-and-shares/*`; filter the PIN-dependent state flow.
- Completion evidence: authenticated data access with and without stored PIN, buy/sell/review paths.

### Unit: profile-and-settings

- Trigger: profile, settings, and KYC routes.
- Read `units/profile-and-settings/*`; preserve logout, security settings, and biometric preference.
- Completion evidence: settings persistence, unsupported biometric handling, logout cleanup, and KYC navigation.

### Unit: activity-and-notifications

- Trigger: transactions, activity, and notifications routes.
- Read `units/activity-and-notifications/*`; filter notification-store and transaction provider rows.
- Completion evidence: list loading, notification persistence/read state, OTP security notifications, and API failures.

## Required implementation report

Before DONE, report: `artifacts_read`, every implemented `must_preserve`/`must_appear_in_target` item, unresolved or deferred contracts, and build/test/runtime evidence. Use the decomposition files only as candidate evidence; do not treat candidate splits as committed architecture.
