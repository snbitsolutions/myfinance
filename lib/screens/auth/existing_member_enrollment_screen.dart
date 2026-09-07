import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExistingMemberEnrollmentScreen extends StatefulWidget {
  const ExistingMemberEnrollmentScreen({
    super.key,
    this.memberType = 'existing',
  });

  final String memberType;

  @override
  State<ExistingMemberEnrollmentScreen> createState() =>
      _ExistingMemberEnrollmentScreenState();
}

class _ExistingMemberEnrollmentScreenState
    extends State<ExistingMemberEnrollmentScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _finalOtpController = TextEditingController();

  bool _biometricsEnabled = true;
  int _currentStep = 0;

  bool get _isNewMember => widget.memberType == 'new';

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
              'We sent a 6-digit code to your registered phone number.',
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
        description: 'We sent a 6-digit code to the registered phone number.',
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

    if (title == 'Verify Membership') {
      return _memberIdController.text.trim().isNotEmpty;
    }
    if (title == 'Verify Identity (OTP)' || title == 'Verify Phone Number') {
      return _otpController.text.trim().length == 6;
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
    if (title == 'Verify Final Authentication') {
      return _finalOtpController.text.trim().length == 6;
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

  void _nextStep() {
    if (_currentStep >= _steps.length - 1) {
      context.go('/home');
      return;
    }

    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required information.'),
        ),
      );
      return;
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
        color: theme.colorScheme.primary,
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
    _pageController.dispose();
    _memberIdController.dispose();
    _otpController.dispose();
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
        backgroundColor: Colors.transparent,
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
                color: Colors.white,
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
                  Icons.arrow_back,
                  color: Color(0xFF0E2B28),
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
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _steps[_currentStep].label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
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
                                  onPressed: _canContinue ? _nextStep : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep == 0
                                        ? 'Get Started'
                                        : 'Continue',
                                    style: theme.textTheme.labelLarge?.copyWith(
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
          controller: _memberIdController,
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
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Email Address (Optional)',
          controller: _usernameController,
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
          label: 'ID Type',
          controller: _memberIdController,
          hint: 'Select ID Type',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'ID Number',
          controller: _otpController,
          hint: 'Enter your ID number',
          icon: Icons.numbers_outlined,
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
        _buildTextField(
          label: 'Employment Status',
          controller: _memberIdController,
          hint: 'Select your employment status',
          icon: Icons.work_outline_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Occupation',
          controller: _otpController,
          hint: 'Enter your occupation',
          icon: Icons.business_center_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Source of Income',
          controller: _usernameController,
          hint: 'Select your income source',
          icon: Icons.account_balance_wallet_rounded,
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
        _productCheckRow(label: 'Savings Account'),
        _productCheckRow(label: 'Member Savings', isSelected: true),
        _productCheckRow(label: 'Fixed Deposit'),
        _productCheckRow(label: 'Loan Product'),
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
        _productCheckRow(label: 'Mobile Money', isSelected: true),
        _productCheckRow(label: 'Bank Transfer'),
        _productCheckRow(label: 'Debit/Credit Card'),
        _productCheckRow(label: 'Pay in Branch'),
      ],
    );
  }

  Widget _buildWelcomeBody(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF1D7A52),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Adepa',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0E2B28),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enroll for mobile banking and access your account anytime, anywhere.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color.fromARGB(255, 239, 240, 240),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 68),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F7EE),
            ),
            child: const Icon(
              Icons.smartphone_rounded,
              size: 72,
              color: Color(0xFF1D7A52),
            ),
          ),
        ),
      ],
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
            color: const Color.fromARGB(255, 250, 251, 250),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Member ID or Account Number',
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF0E2B28),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memberIdController,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter your member ID or account number',
            filled: true,
            fillColor: const Color(0xFFF5F7F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
          'We sent a 6-digit code to +233 123 4567',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5E59),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Enter verification code',
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF0E2B28),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '123456',
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF5F7F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
            Text(
              'Resend in 00:45',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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
    final phone = '+233 123 4567';

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
        _infoRow(label: 'Member Name', value: 'John Mensah'),
        _infoRow(
          label: 'Member ID',
          value: memberId.isEmpty ? 'ADEP123456' : memberId,
        ),
        _infoRow(label: 'Phone Number', value: phone),
        _infoRow(
          label: 'Username',
          value: _usernameController.text.trim().isEmpty
              ? 'johnmensah'
              : _usernameController.text.trim(),
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
          hint: '123456',
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 8, right: 6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 1.1),
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

  Widget _productCheckRow({required String label, bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D7A52) : const Color(0xFFE3E8E5),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) {},
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
