import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/providers/app_providers.dart';

class _GhanaCardInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9-]'),
      '',
    );
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final hasPrefix =
        raw.isEmpty || 'GHA'.startsWith(raw) || raw.startsWith('GHA');

    if (!hasPrefix) {
      return oldValue;
    }

    // Preserve the partial prefix while the user types G, then GH, then GHA.
    if (raw.length <= 3 && digits.isEmpty) {
      return TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }

    final limitedDigits = digits.substring(
      0,
      digits.length > 10 ? 10 : digits.length,
    );
    var formatted = limitedDigits.isEmpty ? '' : 'GHA-$limitedDigits';
    if (limitedDigits.length > 9) {
      formatted =
          'GHA-${limitedDigits.substring(0, 9)}-${limitedDigits.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExistingMemberEnrollmentScreen extends ConsumerStatefulWidget {
  const ExistingMemberEnrollmentScreen({
    super.key,
    this.memberType = 'existing',
  });

  final String memberType;

  @override
  ConsumerState<ExistingMemberEnrollmentScreen> createState() =>
      _ExistingMemberEnrollmentScreenState();
}

class _ExistingMemberEnrollmentScreenState
    extends ConsumerState<ExistingMemberEnrollmentScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _existingPhoneController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ghanaCardController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _finalOtpController = TextEditingController();

  bool _biometricsEnabled = true;
  bool _savingsProductSelected = true;
  bool _sharesProductSelected = false;
  bool _fixedDepositSelected = false;
  bool _loanProductSelected = false;
  String? _fundingMethod;
  bool _isSubmittingRegistration = false;
  int _currentStep = 0;
  int _otpResendSecondsRemaining = 45;
  Timer? _otpResendTimer;

  bool get _isNewMember => widget.memberType == 'new';

  late final List<_EnrollmentStep> _steps;

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _resolvedPhoneNumber() {
    if (!_isNewMember) {
      return _existingPhoneController.text.replaceAll(RegExp(r'\D'), '');
    }
    final digits = _otpController.text.replaceAll(RegExp(r'\D'), '');
    return digits.isNotEmpty
        ? digits
        : _memberIdController.text.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _resendOtpCode() async {
    if (_otpResendSecondsRemaining > 0) {
      return;
    }

    final phoneNumber = _resolvedPhoneNumber();
    final accountNumber = _memberIdController.text.trim().isNotEmpty
        ? _memberIdController.text.trim()
        : (await SharedPreferences.getInstance())
                  .getString(AppConstants.sharedPrefKeyUserId)
                  ?.trim() ??
              '';

    if (phoneNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid phone number before resending the code.',
          ),
        ),
      );
      return;
    }

    try {
      await ref
          .read(authProvider.notifier)
          .sendLoginOtp(phoneNumber: phoneNumber, accountNumber: accountNumber);
      if (!mounted) return;
      _startOtpResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification code has been sent.')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resend the OTP right now.')),
      );
    }
  }

  void _startOtpResendCountdown() {
    _otpResendTimer?.cancel();
    setState(() => _otpResendSecondsRemaining = 45);
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _otpResendSecondsRemaining = 0);
        return;
      }
      setState(() => _otpResendSecondsRemaining--);
    });
  }

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _startOtpResendCountdown();
  }

  List<_EnrollmentStep> _buildSteps() {
    if (_isNewMember) {
      return [
        _EnrollmentStep(
          number: 1,
          title: 'Personal Information',
          subtitle: 'Tell us about yourself',
          description:
              'Complete your profile details to begin your account setup.',
          label: 'Personal Information',
          body: _buildNewPersonalInfoBody,
        ),
        _EnrollmentStep(
          number: 2,
          title: 'Verify Identity (KYC)',
          subtitle: 'Verify your identity',
          description: 'Add your required ID and verification details.',
          label: 'Verify Identity',
          body: _buildNewKycBody,
        ),
        _EnrollmentStep(
          number: 3,
          title: 'Additional Information',
          subtitle: 'Complete your profile',
          description: 'Share your employment and source-of-income details.',
          label: 'Additional Information',
          body: _buildNewAdditionalInfoBody,
        ),
        _EnrollmentStep(
          number: 4,
          title: 'Choose Products',
          subtitle: 'Select the products you need',
          description:
              'Choose the account types and product options you want to open.',
          label: 'Choose Products',
          body: _buildNewChooseProductsBody,
        ),
        _EnrollmentStep(
          number: 5,
          title: 'Fund Your Account',
          subtitle: 'How would you like to fund?',
          description: 'Choose your preferred funding method.',
          label: 'Fund Your Account',
          body: _buildNewFundingBody,
        ),
        _EnrollmentStep(
          number: 6,
          title: 'Create Login Credentials',
          subtitle: 'Create a username and password',
          description: 'Use a secure username and password.',
          label: 'Create Login Credentials',
          body: _buildCredentialsBody,
        ),
        _EnrollmentStep(
          number: 7,
          title: 'Set Transaction PIN',
          subtitle: 'Secure your transactions',
          description: 'Create a 4-digit PIN for transaction authorization.',
          label: 'Set Transaction PIN',
          body: _buildPinBody,
        ),
        _EnrollmentStep(
          number: 8,
          title: 'Review & Confirm',
          subtitle: 'Review your information',
          description: 'Please confirm your details before continuing.',
          label: 'Review & Confirm',
          body: _buildReviewBody,
        ),
        _EnrollmentStep(
          number: 9,
          title: 'Verify Phone Number',
          subtitle: 'Confirm your phone number',
          description:
              'We sent a ${AppConstants.otpLength}-digit code to your registered phone number.',
          label: 'Verify Phone Number',
          body: _buildOtpBody,
        ),
        _EnrollmentStep(
          number: 10,
          title: 'Account Created',
          subtitle: 'Your account is ready',
          description: 'Welcome to Adepa Credit Union.',
          label: 'Account Created',
          body: _buildSuccessBody,
        ),
        _EnrollmentStep(
          number: 11,
          title: 'Enable Biometrics',
          subtitle: 'Use biometric log-in',
          description: 'Enable fingerprint or face ID for faster access.',
          label: 'Enable Biometrics',
          body: _buildBiometricsBody,
        ),
        _EnrollmentStep(
          number: 12,
          title: 'Registration Complete',
          subtitle: 'You are all set!',
          description: 'Start banking and enjoy the features of Adepa.',
          label: 'Registration Complete',
          body: _buildReadyBody,
        ),
      ];
    }

    return [
      _EnrollmentStep(
        number: 1,
        title: 'Welcome',
        subtitle: 'Enroll for mobile banking',
        description: 'Get started with mobile banking access.',
        label: 'Welcome',
        body: _buildWelcomeBody,
      ),
      _EnrollmentStep(
        number: 2,
        title: 'Verify Membership',
        subtitle: 'Let’s find your membership',
        description: 'Enter your member ID or account number.',
        label: 'Verify Membership',
        body: _buildMembershipBody,
      ),
      _EnrollmentStep(
        number: 3,
        title: 'Verify Identity (OTP)',
        subtitle: 'Confirm your phone number',
        description:
            'We sent a ${AppConstants.otpLength}-digit code to the registered phone number.',
        label: 'Verify Identity',
        body: _buildOtpBody,
      ),
      _EnrollmentStep(
        number: 4,
        title: 'Create Login Credentials',
        subtitle: 'Create a username and password',
        description: 'Use a secure username and password.',
        label: 'Create Login Credentials',
        body: _buildCredentialsBody,
      ),
      _EnrollmentStep(
        number: 5,
        title: 'Set Transaction PIN',
        subtitle: 'Secure your transactions',
        description: 'Create a 4-digit PIN for transaction authorization.',
        label: 'Set Transaction PIN',
        body: _buildPinBody,
      ),
      _EnrollmentStep(
        number: 6,
        title: 'Enable Biometrics',
        subtitle: 'Use biometric log-in',
        description: 'Enable fingerprint or face ID for faster access.',
        label: 'Enable Biometrics',
        body: _buildBiometricsBody,
      ),
      _EnrollmentStep(
        number: 7,
        title: 'Review & Confirm',
        subtitle: 'Review your information',
        description: 'Please confirm your details before continuing.',
        label: 'Review & Confirm',
        body: _buildReviewBody,
      ),
      _EnrollmentStep(
        number: 8,
        title: 'Verify Final Authentication',
        subtitle: 'Complete enrollment',
        description: 'Enter the final OTP to complete your enrollment.',
        label: 'Verify Final Authentication',
        body: _buildFinalOtpBody,
      ),
      _EnrollmentStep(
        number: 9,
        title: 'Enrollment Successful',
        subtitle: 'You are ready to use mobile banking',
        description: 'Your enrollment has been completed successfully.',
        label: 'Enrollment Successful',
        body: _buildSuccessBody,
      ),
      _EnrollmentStep(
        number: 10,
        title: 'Ready to Use',
        subtitle: 'Step into your account',
        description: 'Your account is ready for everyday banking.',
        label: 'Ready to Use',
        body: _buildReadyBody,
      ),
    ];
  }

  bool get _canContinue {
    final current = _steps[_currentStep];
    final title = current.title;

    if (title == 'Personal Information') {
      final fullName = _fullNameController.text.trim();
      final phone = _otpController.text.replaceAll(RegExp(r'\D'), '');
      return fullName.isNotEmpty && phone.length >= 9;
    }
    if (title == 'Verify Identity (KYC)') {
      return _ghanaCardController.text.trim().isNotEmpty &&
          _birthDateController.text.trim().isNotEmpty;
    }
    if (title == 'Additional Information') {
      return _genderController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty;
    }
    if (title == 'Verify Membership') {
      final phone = _existingPhoneController.text.replaceAll(RegExp(r'\D'), '');
      return _memberIdController.text.trim().isNotEmpty &&
          phone.length >= 9 &&
          _birthDateController.text.trim().isNotEmpty;
    }
    if (title == 'Verify Identity (OTP)' || title == 'Verify Phone Number') {
      return _otpController.text.trim().length == AppConstants.otpLength;
    }
    if (title == 'Create Login Credentials') {
      return _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.trim().length >= 8 &&
          _confirmPasswordController.text.trim() ==
              _passwordController.text.trim();
    }
    if (title == 'Set Transaction PIN') {
      return _pinController.text.trim().length == 4 &&
          _confirmPinController.text.trim() == _pinController.text.trim();
    }
    if (title == 'Choose Products') {
      return _savingsProductSelected ||
          _sharesProductSelected ||
          _fixedDepositSelected ||
          _loanProductSelected;
    }
    if (title == 'Fund Your Account') {
      return _fundingMethod != null;
    }
    if (title == 'Verify Final Authentication') {
      return _finalOtpController.text.trim().length == AppConstants.otpLength;
    }
    return true;
  }

  void _goToStep(int index) {
    if (index < 0 || index >= _steps.length) return;
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep >= _steps.length - 1) {
      context.go('/home');
      return;
    }

    if (!_canContinue) {
      final message = switch (_steps[_currentStep].title) {
        'Create Login Credentials' =>
          'Enter a username, a password with at least 8 characters, and matching passwords.',
        'Set Transaction PIN' =>
          'Enter a 4-digit PIN and confirm that both PINs match.',
        'Choose Products' => 'Select at least one product to continue.',
        _ => 'Please complete the required information.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (_steps[_currentStep].title == 'Review & Confirm') {
      if (_isSubmittingRegistration) return;
      setState(() => _isSubmittingRegistration = true);
      try {
        final authNotifier = ref.read(authProvider.notifier);
        final message = _isNewMember
            ? await authNotifier.submitNewMemberRegistration(
                fullName: _fullNameController.text.trim(),
                ghanaCard: _ghanaCardController.text.trim(),
                phoneNumber: _otpController.text.replaceAll(RegExp(r'\D'), ''),
                birthDate: _birthDateController.text.trim(),
                gender: _genderController.text.trim(),
                address: _addressController.text.trim(),
                email: _emailController.text.trim(),
                savingsProduct: _savingsProductSelected || _fixedDepositSelected
                    ? 1
                    : 0,
                sharesProduct: _sharesProductSelected ? 5 : 0,
                password: _passwordController.text.trim(),
                transactionPin: _pinController.text.trim(),
                imeiNumber: '0',
                phoneMake: 'Flutter mobile app',
              )
            : await ref
                  .read(authProvider.notifier)
                  .submitRegistration(
                    accountNumber: _memberIdController.text.trim(),
                    phoneNumber: _existingPhoneController.text.replaceAll(
                      RegExp(r'\D'),
                      '',
                    ),
                    birthDate: _birthDateController.text.trim(),
                    imeiNumber: '0',
                    phoneMake: 'Flutter mobile app',
                  );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        // Persist phone/account for OTP flow and navigate to OTP screen
        final prefs = await SharedPreferences.getInstance();
        final normalizedPhone =
            (_isNewMember ? _otpController.text : _existingPhoneController.text)
                .replaceAll(RegExp(r'\D'), '');
        final accountNumber = _isNewMember
            ? (authNotifier.lastRegisteredAccountNumber?.trim().isNotEmpty ==
                      true
                  ? authNotifier.lastRegisteredAccountNumber!.trim()
                  : prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ??
                        '')
            : _memberIdController.text.trim();
        await prefs.setString(
          AppConstants.sharedPrefKeyUserEmail,
          normalizedPhone,
        );
        if (accountNumber.isNotEmpty) {
          await prefs.setString(
            AppConstants.sharedPrefKeyUserId,
            accountNumber,
          );
        }
        if (!mounted) return;
        final otpRoute = Uri(
          path: '/otp',
          queryParameters: {
            'phoneNumber': normalizedPhone,
            'accountNumber': accountNumber,
          },
        ).toString();
        context.go(
          otpRoute,
          extra: {
            'phoneNumber': normalizedPhone,
            'accountNumber': accountNumber,
            'isRegistration': _isNewMember,
          },
        );
        return;
      } on AppException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } finally {
        if (mounted) {
          setState(() => _isSubmittingRegistration = false);
        }
      }
    }

    _goToStep(_currentStep + 1);
  }

  Widget _buildContentCard(BuildContext context, ThemeData theme) {
    final step = _steps[_currentStep];
    final bodyWidget = step.body(context, theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFA),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: bodyWidget),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _otpResendTimer?.cancel();
    _pageController.dispose();
    _memberIdController.dispose();
    _existingPhoneController.dispose();
    _otpController.dispose();
    _fullNameController.dispose();
    _ghanaCardController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _finalOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final lastStepIndex = _steps.length - 1;

    return Scaffold(
      backgroundColor: theme.colorScheme.secondary,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF173D32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE7E2)),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_currentStep == 0) {
                    context.go('/signup');
                    return;
                  }
                  _goToStep(_currentStep - 1);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF2E8B57),
                  size: 18,
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 12),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                _isNewMember
                                    ? 'New member registration'
                                    : 'Existing member registration',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                _isNewMember
                                    ? 'Open your account and start your financial journey with Adepa Credit Union'
                                    : 'Quick and secure enrollment for existing Adepa Credit Union members',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _steps[_currentStep].label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF1D6B49),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _steps.length,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) =>
                                    setState(() => _currentStep = index),
                                itemBuilder: (context, index) {
                                  return _buildContentCard(context, theme);
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_currentStep < lastStepIndex)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSubmittingRegistration
                                      ? null
                                      : _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSubmittingRegistration
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Continue',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                ),
                              ),
                            if (_currentStep == lastStepIndex)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _isNewMember
                                        ? 'Go to Dashboard'
                                        : 'Go to Dashboard',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPersonalInfoBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about yourself',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          label: 'Full Name',
          controller: _fullNameController,
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Phone Number',
          controller: _otpController,
          hint: 'Enter your active phone number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Email Address (Optional)',
          controller: _emailController,
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildNewKycBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Identity (KYC)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verify your identity',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          label: 'Ghana Card Number',
          controller: _ghanaCardController,
          hint: 'GHA-XXXXXXXXX-X',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
          inputFormatters: [_GhanaCardInputFormatter()],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Date of Birth',
          controller: _birthDateController,
          hint: 'YYYY-MM-DD',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  Widget _buildNewAdditionalInfoBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your profile',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildGenderField(theme),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Address',
          controller: _addressController,
          hint: 'Enter your residential address',
          icon: Icons.account_balance_wallet_rounded,
        ),
      ],
    );
  }

  Widget _buildGenderField(ThemeData theme) {
    final selectedGender = _genderController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            color: Color(0xFF173D32),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5E5DD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.wc_outlined,
                color: Color(0xFF2E8B57),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD5E5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD5E5DD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E8B57),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedGender.isEmpty ? null : selectedGender,
                isExpanded: true,
                hint: const Text(
                  'Select gender',
                  style: TextStyle(
                    color: Color(0xFF789188),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _genderController.text = value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewChooseProductsBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Products',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the products you need',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 22),
        _productCheckRow(
          label: 'Savings Account',
          isSelected: _savingsProductSelected,
          onChanged: (selected) {
            setState(() => _savingsProductSelected = selected);
          },
        ),
        _productCheckRow(
          label: 'Member Savings',
          isSelected: _sharesProductSelected,
          onChanged: (selected) {
            setState(() => _sharesProductSelected = selected);
          },
        ),
        _productCheckRow(
          label: 'Fixed Deposit',
          isSelected: _fixedDepositSelected,
          onChanged: (selected) {
            setState(() => _fixedDepositSelected = selected);
          },
        ),
        _productCheckRow(
          label: 'Loan Product',
          isSelected: _loanProductSelected,
          onChanged: (selected) {
            setState(() => _loanProductSelected = selected);
          },
        ),
      ],
    );
  }

  Widget _buildNewFundingBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fund Your Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How would you like to fund your account?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 20),
        _productCheckRow(
          label: 'Mobile Money',
          isSelected: _fundingMethod == 'Mobile Money',
          onChanged: (_) => setState(() => _fundingMethod = 'Mobile Money'),
        ),
        _productCheckRow(
          label: 'Bank Transfer',
          isSelected: _fundingMethod == 'Bank Transfer',
          onChanged: (_) => setState(() => _fundingMethod = 'Bank Transfer'),
        ),
        _productCheckRow(
          label: 'Debit/Credit Card',
          isSelected: _fundingMethod == 'Debit/Credit Card',
          onChanged: (_) =>
              setState(() => _fundingMethod = 'Debit/Credit Card'),
        ),
        _productCheckRow(
          label: 'Pay in Branch',
          isSelected: _fundingMethod == 'Pay in Branch',
          onChanged: (_) => setState(() => _fundingMethod = 'Pay in Branch'),
        ),
      ],
    );
  }

  Widget _buildWelcomeBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F5EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Color(0xFF1D7A52),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Activate mobile banking',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0E2B28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your existing Adepa account to the mobile app securely.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Have these details ready',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 12),
        _welcomeRequirement(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Your Adepa account number',
        ),
        _welcomeRequirement(
          icon: Icons.phone_outlined,
          text: 'The phone number registered with Adepa',
        ),
        _welcomeRequirement(
          icon: Icons.calendar_today_outlined,
          text: 'Your date of birth',
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF1D7A52),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your details are used only to verify your membership and send a one-time code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF4B5E59),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _welcomeRequirement({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F5EE),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF1D7A52), size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF173D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Membership',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let’s find your membership',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          label: 'Member ID or Account Number',
          controller: _memberIdController,
          hint: 'Enter your member ID or account number',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Registered Phone Number',
          controller: _existingPhoneController,
          hint: 'Enter the phone number registered with Adepa',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Date of Birth',
          controller: _birthDateController,
          hint: 'YYYY-MM-DD',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.datetime,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Identity (OTP)',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a ${AppConstants.otpLength}-digit code to your registered mobile number.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          label: 'Enter verification code',
          controller: _otpController,
          hint: 'Enter ${AppConstants.otpLength}-digit code',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
          maxLength: AppConstants.otpLength,
          obscureText: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConstants.otpLength),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Didn’t receive the code?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF4B5E59),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: _otpResendSecondsRemaining > 0 ? null : _resendOtpCode,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _otpResendSecondsRemaining > 0
                    ? 'Resend in ${_formatCountdown(_otpResendSecondsRemaining)}'
                    : 'Resend code',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCredentialsBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Login Credentials',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create a username and password',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Username',
          controller: _usernameController,
          hint: 'Choose a username',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Password',
          controller: _passwordController,
          hint: 'Create a strong password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Confirm your password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildPinBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Transaction PIN',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This PIN will be used to authorize transactions',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'PIN',
          controller: _pinController,
          hint: 'Enter 4-digit PIN',
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Confirm PIN',
          controller: _confirmPinController,
          hint: 'Re-enter PIN',
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometricsBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enable Biometrics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use biometrics to log in quickly and securely',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 134,
            height: 134,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF7F0),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 64,
              color: Color(0xFF1D7A52),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable biometrics login',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use your fingerprint or face ID for faster login.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4B5E59),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _biometricsEnabled,
                onChanged: (value) =>
                    setState(() => _biometricsEnabled = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBody(BuildContext context, ThemeData theme) {
    final memberId = _memberIdController.text.trim();
    final phone = _otpController.text.trim();
    final fullName = _fullNameController.text.trim();
    final ghanaCard = _ghanaCardController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final gender = _genderController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Information',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please confirm your details',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 16),
        if (_isNewMember) ...[
          _infoRow(
            label: 'Full Name',
            value: fullName.isEmpty ? 'Not provided' : fullName,
          ),
          _infoRow(
            label: 'Ghana Card',
            value: ghanaCard.isEmpty ? 'Not provided' : ghanaCard,
          ),
          _infoRow(
            label: 'Date of Birth',
            value: birthDate.isEmpty ? 'Not provided' : birthDate,
          ),
          _infoRow(
            label: 'Gender',
            value: gender.isEmpty ? 'Not provided' : gender,
          ),
          _infoRow(
            label: 'Address',
            value: address.isEmpty ? 'Not provided' : address,
          ),
          _infoRow(
            label: 'Phone Number',
            value: phone.isEmpty ? 'Not provided' : phone,
          ),
          _infoRow(
            label: 'Email',
            value: email.isEmpty ? 'Not provided' : email,
          ),
        ] else ...[
          _infoRow(
            label: 'Member ID',
            value: memberId.isEmpty ? 'Not provided' : memberId,
          ),
          _infoRow(
            label: 'Phone Number',
            value: _existingPhoneController.text.trim().isEmpty
                ? 'Not provided'
                : _existingPhoneController.text.trim(),
          ),
          _infoRow(
            label: 'Date of Birth',
            value: birthDate.isEmpty ? 'Not provided' : birthDate,
          ),
        ],
        _infoRow(
          label: 'Username',
          value: username.isEmpty ? 'Not provided' : username,
        ),
        const SizedBox(height: 18),
        Text(
          'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalOtpBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Verification',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the final OTP to complete signup.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'One-time password',
          controller: _finalOtpController,
          hint: 'Enter ${AppConstants.otpLength}-digit code',
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
          maxLength: AppConstants.otpLength,
          obscureText: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConstants.otpLength),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 14),
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEAF7F0),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: Color(0xFF1D7A52),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Enrollment Successful!',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You have successfully enrolled for Adepa Mobile Banking.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to use',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1D7A52),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John Mensah',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Total Account Balance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'GH¢ 45,000.00',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _miniMetric(icon: Icons.home_rounded, label: 'Home'),
            const SizedBox(width: 12),
            _miniMetric(icon: Icons.savings_rounded, label: 'Savings'),
            const SizedBox(width: 12),
            _miniMetric(icon: Icons.send_rounded, label: 'Transfer'),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF173D32),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5E5DD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Color(0xFF173D32),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 8, right: 6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2E8B57), size: 16),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF789188),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD5E5DD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD5E5DD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E8B57),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5E59),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0E2B28),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCheckRow({
    required String label,
    bool isSelected = false,
    ValueChanged<bool>? onChanged,
  }) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D7A52)
                : const Color(0xFFE3E8E5),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged(value ?? false),
              activeColor: const Color(0xFF1D7A52),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0E2B28),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1D7A52)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0E2B28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentStep {
  final int number;
  final String title;
  final String subtitle;
  final String description;
  final String label;
  final Widget Function(BuildContext, ThemeData) body;

  const _EnrollmentStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.label,
    required this.body,
  });
}
