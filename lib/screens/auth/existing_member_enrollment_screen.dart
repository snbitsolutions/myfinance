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
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final prefixLength = raw.startsWith('GHA')
        ? 3
        : 'GHA'.startsWith(raw)
        ? raw.length
        : 0;
    final hasInvalidLetters = raw
        .substring(prefixLength)
        .contains(RegExp(r'[A-Z]'));
    if (hasInvalidLetters) return oldValue;

    if (prefixLength > 0 && raw.length == prefixLength) {
      return TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }

    final digits = raw.substring(prefixLength).replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.substring(0, digits.length.clamp(0, 10));
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ghanaCardController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  int? _selectedSavingsProductId;
  int? _selectedSharesProductId;
  String? _fundingMethod;
  bool _isSubmittingRegistration = false;
  bool _isVerifyingMembership = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _currentStep = 0;
  bool get _isNewMember => widget.memberType.trim().toLowerCase() == 'new';

  String get _normalizedMemberId =>
      _memberIdController.text.replaceAll(RegExp(r'\D'), '');

  bool get _isValidExistingPhoneNumber {
    final phone = _existingPhoneController.text.replaceAll(RegExp(r'\D'), '');
    return (phone.length == 10 && phone.startsWith('0')) ||
        (phone.length == 12 && phone.startsWith('233'));
  }

  bool get _isValidExistingBirthDate {
    return _isValidBirthDate(_birthDateController.text);
  }

  bool get _isValidGhanaCard {
    return RegExp(r'^GHA-\d{8,9}-\d$').hasMatch(_ghanaCardController.text);
  }

  bool _isValidBirthDate(String input) {
    final value = input.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    final today = DateTime.now();
    return date.year == year &&
        date.month == month &&
        date.day == day &&
        !date.isAfter(DateTime(today.year, today.month, today.day));
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Select date of birth',
    );
    if (selectedDate == null || !mounted) return;

    _birthDateController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  late final List<_EnrollmentStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
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
          subtitle: 'Create a password',
          description:
              'Use a secure password to sign in with your phone number.',
          label: 'Create Login Credentials',
          body: _buildCredentialsBody,
        ),
        _EnrollmentStep(
          number: 7,
          title: 'Set Transfer PIN',
          subtitle: 'Secure your transfers',
          description: 'Create a 4-digit PIN to authorize transfers.',
          label: 'Set Transfer PIN',
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
        title: 'Create Login Credentials',
        subtitle: 'Create a password',
        description: 'Use a secure password to sign in with your phone number.',
        label: 'Create Login Credentials',
        body: _buildCredentialsBody,
      ),
      _EnrollmentStep(
        number: 4,
        title: 'Set Transfer PIN',
        subtitle: 'Secure your transfers',
        description: 'Create a 4-digit PIN to authorize transfers.',
        label: 'Set Transfer PIN',
        body: _buildExistingMemberPinsBody,
      ),
      _EnrollmentStep(
        number: 5,
        title: 'Review & Confirm',
        subtitle: 'Review your information',
        description: 'Please confirm your details before continuing.',
        label: 'Review & Confirm',
        body: _buildReviewBody,
      ),
    ];
  }

  bool get _canContinue {
    final current = _steps[_currentStep];
    final title = current.title;
    if (title == 'Set Transfer PIN') {
      final transferPin = _pinController.text.trim();
      return RegExp(r'^\d{4}$').hasMatch(transferPin) &&
          _confirmPinController.text.trim() == transferPin;
    }

    if (title == 'Personal Information') {
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      return fullName.isNotEmpty && phone.length >= 9;
    }
    if (title == 'Verify Identity (KYC)') {
      return _isValidGhanaCard && _isValidBirthDate(_birthDateController.text);
    }
    if (title == 'Additional Information') {
      return _genderController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty;
    }
    if (title == 'Verify Membership') {
      return _normalizedMemberId.length >= 5 &&
          _isValidExistingPhoneNumber &&
          _isValidExistingBirthDate;
    }
    if (title == 'Create Login Credentials') {
      return _passwordController.text.trim().length >= 8 &&
          _confirmPasswordController.text.trim() ==
              _passwordController.text.trim();
    }
    if (title == 'Choose Products') {
      return _selectedSavingsProductId != null ||
          _selectedSharesProductId != null;
    }
    if (title == 'Fund Your Account') {
      return _fundingMethod != null;
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
    if (_currentStep >= _steps.length - 1 &&
        _steps[_currentStep].title != 'Review & Confirm') {
      context.go('/home');
      return;
    }

    if (!_canContinue) {
      final message = switch (_steps[_currentStep].title) {
        'Verify Identity (KYC)' when !_isValidGhanaCard =>
          'Enter a valid Ghana Card number in the format GHA-XXXXXXXXX-X.',
        'Verify Identity (KYC)'
            when !_isValidBirthDate(_birthDateController.text) =>
          'Enter a valid date of birth in YYYY-MM-DD format.',
        'Verify Membership' when _normalizedMemberId.length < 5 =>
          'Enter the account number shown on your ADEPA records.',
        'Verify Membership' when !_isValidExistingPhoneNumber =>
          'Enter the registered Ghana phone number as 0XXXXXXXXX or '
              '233XXXXXXXXX.',
        'Verify Membership' when !_isValidExistingBirthDate =>
          'Enter a valid date of birth in YYYY-MM-DD format.',
        'Create Login Credentials' =>
          'Enter a password with at least 8 characters and confirm it.',
        'Set Transfer PIN' =>
          'Enter and confirm the same 4-digit transfer PIN.',
        'Choose Products' => 'Select at least one product to continue.',
        _ => 'Please complete the required information.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (_steps[_currentStep].title == 'Verify Membership') {
      if (_isVerifyingMembership) return;
      setState(() => _isVerifyingMembership = true);
      try {
        await ref
            .read(authProvider.notifier)
            .confirmAccountNumber(
              phoneNumber: _existingPhoneController.text.replaceAll(
                RegExp(r'\D'),
                '',
              ),
              accountNumber: _normalizedMemberId,
              birthDate: _birthDateController.text.trim(),
            );
        if (!mounted) return;
        _goToStep(_currentStep + 1);
      } on AppException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } finally {
        if (mounted) {
          setState(() => _isVerifyingMembership = false);
        }
      }
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
                phoneNumber: _phoneController.text.replaceAll(
                  RegExp(r'\D'),
                  '',
                ),
                birthDate: _birthDateController.text.trim(),
                gender: _genderController.text.trim(),
                address: _addressController.text.trim(),
                email: _emailController.text.trim(),
                savingsProduct: _selectedSavingsProductId ?? 0,
                sharesProduct: _selectedSharesProductId ?? 0,
                password: _passwordController.text.trim(),
                transactionPin: _pinController.text.trim(),
              )
            : await ref
                  .read(authProvider.notifier)
                  .submitRegistration(
                    accountNumber: _normalizedMemberId,
                    phoneNumber: _existingPhoneController.text.replaceAll(
                      RegExp(r'\D'),
                      '',
                    ),
                    birthDate: _birthDateController.text.trim(),
                    password: _passwordController.text.trim(),
                    pin: null,
                    transactionPin: _pinController.text.trim(),
                  );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        // Persist phone/account for OTP flow and navigate to OTP screen
        final prefs = await SharedPreferences.getInstance();
        final normalizedPhone =
            (_isNewMember
                    ? _phoneController.text
                    : _existingPhoneController.text)
                .replaceAll(RegExp(r'\D'), '');
        final accountNumber = _isNewMember
            ? (authNotifier.lastRegisteredAccountNumber?.trim().isNotEmpty ==
                      true
                  ? authNotifier.lastRegisteredAccountNumber!.trim()
                  : prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ??
                        '')
            : _normalizedMemberId;
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
            'isRegistration': true,
            'transactionPinAlreadyProvisioned': true,
            'requiresPinSetup': false,
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

  Widget _buildContentCard(
    BuildContext context,
    ThemeData theme,
    int stepIndex,
  ) {
    final step = _steps[stepIndex];
    final primary = theme.colorScheme.primary;
    final formTheme = theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        titleLarge: theme.textTheme.titleLarge?.copyWith(
          fontSize: 23,
          letterSpacing: -0.35,
          height: 1.2,
        ),
        titleSmall: theme.textTheme.titleSmall?.copyWith(
          fontSize: 19,
          letterSpacing: -0.2,
          height: 1.2,
        ),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.45,
        ),
        bodySmall: theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
    final bodyWidget = step.body(context, formTheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8E4C8), Color(0xFFD8F0EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.2),
            blurRadius: 26,
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
    _pageController.dispose();
    _memberIdController.dispose();
    _existingPhoneController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _ghanaCardController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
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
        backgroundColor: primary,
        foregroundColor: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
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
                  color: Colors.white,
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
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _steps[_currentStep].label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: primary,
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
                                  return _buildContentCard(
                                    context,
                                    theme,
                                    index,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_currentStep < lastStepIndex)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmittingRegistration ||
                                          _isVerifyingMembership
                                      ? null
                                      : _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child:
                                      _isSubmittingRegistration ||
                                          _isVerifyingMembership
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
                                    _steps[_currentStep].title ==
                                            'Review & Confirm'
                                        ? 'Confirm & Continue'
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
          fieldKey: const ValueKey('new-member-full-name'),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Phone Number',
          controller: _phoneController,
          hint: 'Enter your active phone number',
          icon: Icons.phone_rounded,
          fieldKey: const ValueKey('new-member-phone-number'),
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
          fieldKey: const ValueKey('ghana-card-number'),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [_GhanaCardInputFormatter()],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Date of Birth',
          controller: _birthDateController,
          hint: 'YYYY-MM-DD',
          icon: Icons.calendar_today_outlined,
          fieldKey: const ValueKey('new-member-date-of-birth'),
          readOnly: true,
          onTap: () => _pickBirthDate(),
          suffixIcon: IconButton(
            tooltip: 'Choose date of birth',
            onPressed: () => _pickBirthDate(),
            icon: const Icon(Icons.calendar_today_outlined),
          ),
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
    final savingsProducts = ref.watch(savingsProductsCatalogProvider);
    final sharesProducts = ref.watch(sharesProductsCatalogProvider);

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
          'Select up to one product from each category.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        _buildCatalogProductOptions(
          title: 'Savings Products',
          products: savingsProducts,
          selectedProductId: _selectedSavingsProductId,
          onSelected: (id) => setState(() => _selectedSavingsProductId = id),
          onRetry: () => ref.invalidate(savingsProductsCatalogProvider),
        ),
        const SizedBox(height: 14),
        _buildCatalogProductOptions(
          title: 'Shares Products',
          products: sharesProducts,
          selectedProductId: _selectedSharesProductId,
          onSelected: (id) => setState(() => _selectedSharesProductId = id),
          onRetry: () => ref.invalidate(sharesProductsCatalogProvider),
        ),
        const SizedBox(height: 8),
        Text(
          'You can apply for a loan after your membership is active.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogProductOptions({
    required String title,
    required AsyncValue<List<Map<String, dynamic>>> products,
    required int? selectedProductId,
    required ValueChanged<int?> onSelected,
    required VoidCallback onRetry,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0E2B28),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        products.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Card(
            child: ListTile(
              title: const Text('Could not load products.'),
              trailing: TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (items) {
            final availableProducts = items
                .map((item) {
                  final id = int.tryParse(item['id']?.toString() ?? '');
                  final name = (item['name'] ?? item['product_name'])
                      ?.toString()
                      .trim();
                  if (id == null || name == null || name.isEmpty) return null;
                  return (id: id, name: name);
                })
                .whereType<({int id, String name})>()
                .toList();

            if (availableProducts.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No products are currently available.'),
                ),
              );
            }

            return Column(
              children: availableProducts
                  .map(
                    (product) => Card(
                      child: CheckboxListTile(
                        value: selectedProductId == product.id,
                        title: Text(product.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (selected) => onSelected(
                          selected == true && selectedProductId != product.id
                              ? product.id
                              : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
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
          label: 'Account Number',
          controller: _memberIdController,
          hint: 'Enter your account number (spaces and dashes are okay)',
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
          fieldKey: const ValueKey('existing-member-date-of-birth'),
          readOnly: true,
          onTap: () => _pickBirthDate(),
          suffixIcon: IconButton(
            tooltip: 'Choose date of birth',
            onPressed: () => _pickBirthDate(),
            icon: const Icon(Icons.calendar_today_outlined),
          ),
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
          'Create a password to sign in with your phone number',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Password',
          controller: _passwordController,
          hint: 'Create a strong password',
          icon: Icons.lock_outline_rounded,
          obscureText: !_isPasswordVisible,
          suffixIcon: IconButton(
            tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Confirm your password',
          icon: Icons.lock_outline_rounded,
          obscureText: !_isConfirmPasswordVisible,
          suffixIcon: IconButton(
            tooltip: _isConfirmPasswordVisible
                ? 'Hide confirmation password'
                : 'Show confirmation password',
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPinBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Transfer PIN',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This 4-digit PIN will authorize transfers. Sign in to the app with '
          'your password.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Transfer PIN',
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
          label: 'Confirm Transfer PIN',
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

  Widget _buildExistingMemberPinsBody(BuildContext context, ThemeData theme) {
    Widget pinField({
      required String label,
      required TextEditingController controller,
    }) {
      return _buildTextField(
        label: label,
        controller: controller,
        hint: 'Enter 4-digit PIN',
        icon: Icons.pin_rounded,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Transfer PIN',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0E2B28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This 4-digit PIN will authorize transfers. Sign in to the app with '
          'your password.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 14),
        pinField(label: 'Transfer PIN', controller: _pinController),
        const SizedBox(height: 14),
        pinField(
          label: 'Confirm Transfer PIN',
          controller: _confirmPinController,
        ),
      ],
    );
  }

  Widget _buildReviewBody(BuildContext context, ThemeData theme) {
    final memberId = _normalizedMemberId;
    final phone = _phoneController.text.trim();
    final fullName = _fullNameController.text.trim();
    final ghanaCard = _ghanaCardController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final gender = _genderController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Key? fieldKey,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
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
            key: fieldKey,
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
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
              suffixIcon: suffixIcon,
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
