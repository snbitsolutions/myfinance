import 'package:flutter/material.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Privacy Policy',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADEPA TEACHERS’ CO-OPERATIVE CREDIT UNION LTD',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ADEPA TEACHERS mobile application · Version 1.0',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Effective date: 9 November 2026',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'This Privacy Policy explains how ADEPA Teachers’ '
                  'Co-operative Credit Union Ltd (“ADEPA”, “we”, “us” or '
                  '“our”) handles personal information when you use the '
                  'ADEPA TEACHERS mobile application (“App”).',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final section in _privacySections) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(section.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy contact',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ADEPA Teachers’ Co-operative Credit Union Ltd\n'
                  'Akim Oda Road, Agona Swedru, Ghana\n'
                  'Email: swedruteachers@yahoo.com',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection {
  const _PrivacySection(this.title, this.body);

  final String title;
  final String body;
}

const _privacySections = <_PrivacySection>[
  _PrivacySection(
    '1. Information handled by the App',
    'Depending on the features you use, the App may handle information you '
        'provide, such as your name, phone number, email address, member or '
        'account identifiers, registration details and information submitted '
        'for identity verification. It may also display or send account '
        'balances, savings, loan and share details, applications, transfers, '
        'payment instructions, transaction records and related references. '
        'Authentication information, including PINs, passwords, one-time '
        'codes and session tokens, is used to verify and secure access. The '
        'App also creates an installation identifier and may send device '
        'details such as platform, model, manufacturer and operating-system '
        'version for device recognition and security.',
  ),
  _PrivacySection(
    '2. How information is used',
    'ADEPA uses information to register and identify members, authenticate '
        'users and devices, provide account and financial services, display '
        'account and transaction information, process or verify service '
        'requests and payments, protect accounts, respond to support requests, '
        'maintain business records and meet legal or regulatory obligations.',
  ),
  _PrivacySection(
    '3. Where information is sent and who may receive it',
    'The App communicates with ADEPA’s online services hosted at adepaye.com '
        'to authenticate users and provide financial-service features. '
        'Information needed to complete a payment or other requested service '
        'may be shared with the relevant payment, mobile-money, banking or '
        'other service provider. ADEPA may also disclose information to its '
        'authorized service providers, professional advisers, regulators or '
        'other parties when required or permitted by law. Their handling of '
        'information is subject to their own applicable terms and privacy '
        'practices.',
  ),
  _PrivacySection(
    '4. Storage and security',
    'Some settings and app preferences are stored on your device. The App '
        'uses the device’s secure storage facilities for authentication '
        'secrets and sends requests to ADEPA services over HTTPS. Information '
        'held by ADEPA’s services is subject to the safeguards and access '
        'controls maintained by ADEPA and its service providers. No method of '
        'storage or transmission can be guaranteed to be completely secure. '
        'Keep your device and credentials secure and contact ADEPA promptly '
        'if you suspect unauthorized access.',
  ),
  _PrivacySection(
    '5. Retention',
    'ADEPA retains information for as long as it is needed to provide '
        'services, protect accounts, resolve disputes and meet applicable '
        'financial-recordkeeping and legal obligations. Retention periods '
        'depend on the type of information and the applicable requirements. '
        'Removing the App from your device does not delete records held by '
        'ADEPA or its service providers.',
  ),
  _PrivacySection(
    '6. Your choices and privacy requests',
    'You may contact ADEPA to ask about personal information associated with '
        'your account, request correction of inaccurate information or raise '
        'a privacy concern. Requests may require identity verification and '
        'may be limited where ADEPA must retain records or comply with law. '
        'Account closure or deletion requests should be sent to ADEPA using '
        'the contact details below; uninstalling the App does not close your '
        'account.',
  ),
  _PrivacySection(
    '7. Legal basis and applicable law',
    'ADEPA handles personal information for the purposes described in this '
        'Policy and in accordance with applicable laws, including Ghana’s '
        'Data Protection Act, 2012 (Act 843), where applicable.',
  ),
  _PrivacySection(
    '8. Changes to this Policy',
    'ADEPA may update this Policy when the App, services or applicable '
        'requirements change. The latest version and its effective date will '
        'be made available through ADEPA’s official channels. Please review '
        'it periodically.',
  ),
];
