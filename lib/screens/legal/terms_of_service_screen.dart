import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/app_card.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key, this.reviewOnly = false});

  final bool reviewOnly;

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _isAccepting = false;

  Future<void> _acceptTerms() async {
    if (_isAccepting) return;

    setState(() => _isAccepting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final acceptedAt = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(
        AppConstants.sharedPrefKeyTermsAcceptedAt,
        acceptedAt,
      );
      await prefs.setString(
        AppConstants.sharedPrefKeyAcceptedTermsVersion,
        AppConstants.termsOfServiceVersion,
      );
      final seenOnboarding =
          prefs.getBool(AppConstants.sharedPrefKeyOnboarding) ?? false;
      if (!mounted) return;
      context.go(seenOnboarding ? '/login' : '/onboarding');
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isAccepting = false);
      debugPrint('Terms acceptance could not be saved: $error');
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your acceptance. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        automaticallyImplyLeading: false,
        leading: widget.reviewOnly
            ? IconButton(
                tooltip: 'Back to settings',
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                          'ADEPA Mobile Application · Version '
                          '${AppConstants.termsOfServiceVersion}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Effective date: To be confirmed',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final section in _termsSections) ...[
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.go('/privacy-policy'),
                    child: const Text('Read Privacy Policy'),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: widget.reviewOnly
                        ? OutlinedButton(
                            onPressed: () => context.go('/settings'),
                            child: const Text('Close'),
                          )
                        : FilledButton(
                            onPressed: _isAccepting ? null : _acceptTerms,
                            child: _isAccepting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('I Agree'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.title, this.body);

  final String title;
  final String body;
}

const _termsSections = <_TermsSection>[
  _TermsSection(
    '1. About These Terms',
    'These Terms of Service (“Terms”) govern your access to and use of the '
        'ADEPA Teachers’ Co-operative Credit Union Ltd mobile application '
        '(“App”), operated by ADEPA Teachers’ Co-operative Credit Union Ltd'
        '. The App may provide access to '
        'services such as account balances, transaction history, savings '
        'information, loan information, transfers, payments, profile '
        'management and notifications, depending on available features. By '
        'registering for, accessing or using the App, you agree to these '
        'Terms. If you do not agree, do not use the App.',
  ),
  _TermsSection(
    '2. Eligibility and Registration',
    'You must provide accurate, current and complete information when '
        'registering and keep it up to date. Member-specific services may be '
        'restricted to verified ADEPA members or other persons authorised by '
        'ADEPA. Registration does not guarantee membership approval, loan '
        'approval, credit eligibility or access to every service.',
  ),
  _TermsSection(
    '3. Account Security and Your Responsibilities',
    'You are responsible for protecting your device, login credentials, PIN, '
        'password and verification codes. Do not share these details. Notify '
        'ADEPA promptly through its official support channels if your device '
        'or account may have been lost, compromised or accessed without '
        'permission. ADEPA may temporarily restrict access when reasonably '
        'necessary to protect your account or investigate suspected '
        'unauthorised activity.',
  ),
  _TermsSection(
    '4. Account Information and Records',
    'Information displayed in the App helps you access ADEPA services. '
        'Review your account information and transactions and report errors '
        'or unfamiliar activity promptly. Information may be delayed or '
        'unavailable because of processing, maintenance, connectivity or '
        'technical problems. Disputed information may need to be verified '
        'against ADEPA’s official records.',
  ),
  _TermsSection(
    '5. Transfers and Payments',
    'Where transfers or payments are available, verify the recipient, '
        'destination details, amount and applicable charges before confirming. '
        'Transactions may be subject to authentication, processing times, '
        'limits, fraud checks, network availability and participating '
        'providers’ rules. A submitted transaction may not be immediately '
        'reversible. Contact ADEPA promptly about errors or unauthorised '
        'transactions. Do not assume a transaction succeeded until its status '
        'is confirmed by the App or ADEPA’s official records.',
  ),
  _TermsSection(
    '6. Savings and Loans',
    'The App may display savings information, loan balances, repayment '
        'information or loan application services where available. Displaying '
        'loan information or submitting an application does not guarantee '
        'approval or disbursement. Interest rates, fees, repayment schedules, '
        'eligibility requirements and other product conditions are governed '
        'by the applicable product terms, agreement and ADEPA policies.',
  ),
  _TermsSection(
    '7. Fees, Charges and Transaction Limits',
    'Use of the App may be free or may involve charges for particular '
        'transactions or services. Applicable ADEPA fees, transaction limits '
        'and service conditions should be communicated through relevant '
        'service information or official notices. Your mobile network '
        'operator or another third-party provider may charge separate fees.',
  ),
  _TermsSection(
    '8. Electronic Communications and Notifications',
    'You may receive transaction alerts, security notices and service '
        'messages through the App, SMS, email or other contact details you '
        'provided. Delivery may be affected by networks, device settings or '
        'third-party systems. Keep your contact details up to date. '
        'Notifications are a convenience and are not necessarily the sole '
        'record of a transaction.',
  ),
  _TermsSection(
    '9. Privacy and Personal Information',
    'ADEPA may process personal information to register and verify users, '
        'provide App services, secure accounts, process transactions, respond '
        'to requests, comply with legal obligations and improve its services. '
        'ADEPA should provide a separate Privacy Policy explaining its data '
        'practices. Personal information must be handled in accordance with '
        'applicable Ghanaian data-protection law, including the Data '
        'Protection Act, 2012 (Act 843), where applicable.',
  ),
  _TermsSection(
    '10. Acceptable Use',
    'You must not use the App for unlawful, fraudulent or unauthorised '
        'activities; access another person’s account without permission; '
        'bypass security controls; interfere with the App, its servers or '
        'security features; introduce malware or harmful code; submit false '
        'information or misuse another person’s identity; copy, resell or '
        'exploit the App without permission except where law permits; or use '
        'the App in a way that harms ADEPA or its users. ADEPA may investigate '
        'suspected misuse and take appropriate action, subject to applicable '
        'law.',
  ),
  _TermsSection(
    '11. Availability, Maintenance and Changes',
    'ADEPA will make reasonable efforts to maintain the App, but '
        'uninterrupted availability cannot be guaranteed. Access may be '
        'suspended or limited for maintenance, updates, security concerns, '
        'network failures, third-party outages, legal requirements or events '
        'beyond ADEPA’s reasonable control. ADEPA may add, change, suspend or '
        'discontinue features and, where reasonably practicable, provide '
        'notice of material changes.',
  ),
  _TermsSection(
    '12. Suspension and Termination',
    'ADEPA may suspend, restrict or terminate access where reasonably '
        'necessary because of suspected fraud, misuse, security concerns, '
        'breach of these Terms, legal requirements or the need to protect '
        'ADEPA and its users. Where appropriate and legally permitted, ADEPA '
        'may provide notice and an opportunity to resolve the issue. Removing '
        'the App or stopping its use does not automatically close your ADEPA '
        'membership, financial account, loan or other financial relationship.',
  ),
  _TermsSection(
    '13. Intellectual Property',
    'The App, its software, design, branding, text, graphics and related '
        'materials are owned by ADEPA or its licensors, except where stated '
        'otherwise. You receive a limited, personal, revocable and '
        'non-transferable right to use the App for its intended purposes and '
        'in accordance with these Terms. You may not use ADEPA’s name, logo '
        'or protected materials without permission, except as permitted by '
        'applicable law.',
  ),
  _TermsSection(
    '14. Third-Party Services',
    'The App may depend on mobile networks, payment processors, financial '
        'institutions, app stores and other third-party services. Those '
        'services may have their own terms and privacy notices. ADEPA is not '
        'responsible for matters outside its reasonable control, but nothing '
        'in these Terms excludes responsibilities that cannot legally be '
        'excluded.',
  ),
  _TermsSection(
    '15. Disclaimers and Limitation of Liability',
    'ADEPA will make reasonable efforts to provide reliable App services, '
        'but cannot guarantee the App will always be uninterrupted, '
        'error-free or compatible with every device. To the extent permitted '
        'by applicable law, ADEPA will not be liable for indirect or '
        'consequential loss arising from inability to access the App, '
        'third-party network failures or events beyond its reasonable '
        'control. Nothing in these Terms excludes or limits liability, rights '
        'or remedies that cannot lawfully be excluded or limited under '
        'Ghanaian law. This section requires legal review before publication.',
  ),
  _TermsSection(
    '16. Complaints and Disputes',
    'For questions, complaints, suspected unauthorised transactions or '
        'concerns about the App, contact ADEPA using its official support '
        'channels. Provide enough information for ADEPA to investigate, but '
        'never send your password, PIN or one-time verification code. ADEPA '
        'will handle complaints according to applicable procedures and legal '
        'obligations. Other complaint or dispute-resolution channels may be '
        'available under applicable law.',
  ),
  _TermsSection(
    '17. Changes to These Terms',
    'ADEPA may update these Terms to reflect changes to the App, services, '
        'security practices or applicable law. The latest version should be '
        'made available through the App or another appropriate channel, with '
        'an updated effective date. Where required by law, ADEPA will provide '
        'notice or seek consent before changes take effect. If you do not '
        'agree to revised Terms, stop using the App and contact ADEPA about '
        'available alternatives.',
  ),
  _TermsSection(
    '18. Governing Law',
    'These Terms are governed by the laws of the Republic of Ghana, subject '
        'to mandatory legal protections and dispute-resolution requirements '
        'that apply to the user or relevant service.',
  ),
  _TermsSection(
    '19. Contact Details',
    'Organisation: ADEPA Teachers’ Co-operative Credit Union Ltd\n'
        'Support email: swedruteachers@yahoo.com\n'
        'Support telephone: +233596921255\n'
        'Office address: Akim Oda Road, Agona Swedru, Ghana\n'
        'Website: atccugh.com\n\n'
        'For questions about these Terms or the App, contact ADEPA using '
        'the details above.',
  ),
  _TermsSection(
    '20. Acceptance',
    'By selecting “I Agree”, registering or using the App where an '
        'acceptance mechanism is provided, you confirm that you have had an '
        'opportunity to read these Terms and agree to them, subject to '
        'applicable law. The App records the accepted version and the date '
        'and time of acceptance.',
  ),
];
