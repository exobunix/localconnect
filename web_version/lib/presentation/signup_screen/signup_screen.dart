import 'dart:async';
import 'dart:math';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_left_banner.dart';
import '../../widgets/auth_features_footer.dart';

/// Signup steps:
/// 0 = Basic Info (name, email, role, password)
/// 1 = CAPTCHA verification
/// 2 = Email verification (check inbox for Supabase confirmation link/OTP)
class SignupScreen extends StatefulWidget {
  final String? initialEmail;
  const SignupScreen({super.key, this.initialEmail});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  int _selectedRole = 0; // 0 = customer, 1 = provider

  // Step 0 - Basic Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 1 - CAPTCHA
  String _captchaQuestion = '';
  int _captchaAnswer = 0;
  final _captchaController = TextEditingController();
  bool _captchaVerified = false;

  // Step 2 - Email verification (Supabase sends a 6-digit OTP to email)
  final List<TextEditingController> _emailOtpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _emailOtpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  bool _emailOtpVerified = false;
  int _emailResendSeconds = 60;
  Timer? _emailResendTimer;
  bool _canResendEmail = false;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _captchaController.dispose();
    for (final c in _emailOtpControllers) {
      c.dispose();
    }
    for (final f in _emailOtpFocusNodes) {
      f.dispose();
    }
    _emailResendTimer?.cancel();
    super.dispose();
  }

  void _generateCaptcha() {
    final rng = Random();
    final a = rng.nextInt(9) + 1;
    final b = rng.nextInt(9) + 1;
    _captchaQuestion = '$a + $b = ?';
    _captchaAnswer = a + b;
    _captchaController.clear();
  }

  void _animateToNextStep() {
    _fadeController.reset();
    _fadeController.forward();
  }

  // ── Step 0: Validate basic info ──────────────────────────────────────────
  void _proceedFromBasicInfo() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (name.length < 2 || name.length > 100) {
      setState(
        () => _errorMessage = 'Name must be between 2 and 100 characters.',
      );
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    // Strong password policy: min 8 chars, uppercase, lowercase, digit
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(
        () => _errorMessage =
            'Password must contain at least one uppercase letter.',
      );
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(
        () => _errorMessage =
            'Password must contain at least one lowercase letter.',
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(
        () => _errorMessage = 'Password must contain at least one number.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    // XSS/injection check on name
    if (RegExp(
      r'<[^>]*>|javascript:|on\w+\s*=',
      caseSensitive: false,
    ).hasMatch(name)) {
      setState(() => _errorMessage = 'Name contains invalid characters.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _step = 1;
    });
    _animateToNextStep();
  }

  // ── Step 1: Verify CAPTCHA ────────────────────────────────────────────────
  void _verifyCaptcha() {
    final input = int.tryParse(_captchaController.text.trim());
    if (input == null || input != _captchaAnswer) {
      setState(() {
        _errorMessage = 'Incorrect answer. Please try again.';
        _generateCaptcha();
      });
      return;
    }
    setState(() {
      _captchaVerified = true;
      _errorMessage = null;
    });
    _createAccountAndSendVerification();
  }

  Future<void> _createAccountAndSendVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
      await SupabaseService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: roleStr,
      );

      if (!mounted) return;

      setState(() {
        _step = 2;
        _isLoading = false;
      });
      _animateToNextStep();
      _startEmailResendTimer();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _step = 0; // Go back to basic info on error
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Account creation failed. Please try again.';
        _isLoading = false;
        _step = 0;
      });
    }
  }

  // ── Step 2: Verify email OTP sent by Supabase ─────────────────────────────
  Future<void> _verifyEmailOtp() async {
    final otp = _emailOtpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: otp,
        type: OtpType.signup,
      );

      if (!mounted) return;

      // Role metadata is already set during signUp — no need to updateUser

      if (!mounted) return;

      setState(() {
        _emailOtpVerified = true;
        _isLoading = false;
      });

      // Navigate based on role
      final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
      if (roleStr == 'provider') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.providerOnboardingScreen,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.message.contains('expired') || e.message.contains('invalid')
            ? 'Invalid or expired code. Please request a new one.'
            : e.message;
        _isLoading = false;
        for (final c in _emailOtpControllers) {
          c.clear();
        }
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _emailOtpFocusNodes[0].requestFocus();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onEmailOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _emailOtpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _emailOtpFocusNodes[index - 1].requestFocus();
    }
    final otp = _emailOtpControllers.map((c) => c.text).join();
    if (otp.length == 6) _verifyEmailOtp();
  }

  void _startEmailResendTimer() {
    _emailResendSeconds = 60;
    _canResendEmail = false;
    _emailResendTimer?.cancel();
    _emailResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_emailResendSeconds > 0) {
          _emailResendSeconds--;
        } else {
          _canResendEmail = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendEmailVerification() async {
    if (!_canResendEmail) return;
    setState(() {
      for (final c in _emailOtpControllers) {
        c.clear();
      }
      _errorMessage = null;
    });
    try {
      final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
      await SupabaseService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: roleStr,
      );
    } catch (_) {
      // Silently handle
    }
    _startEmailResendTimer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _emailOtpFocusNodes[0].requestFocus();
    });
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        try {
          html.window.localStorage['google_signin_role'] = 'customer';
        } catch (_) {}
        await SupabaseService.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.toString(),
          queryParams: {
            'role': 'customer',
          },
        );
        return;
      }

      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? (webClientId.isEmpty ? '1053905240243-0olgtcdiieuu55s4qnm7792gg8fkndjr.apps.googleusercontent.com' : webClientId) : null,
        serverClientId: kIsWeb ? null : (webClientId.isEmpty ? '1053905240243-0olgtcdiieuu55s4qnm7792gg8fkndjr.apps.googleusercontent.com' : webClientId),
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleUser.id;
      await SupabaseService.instance.signInWithGoogleIdToken(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
        email: googleUser.email,
        name: googleUser.displayName,
      );

      if (!mounted) return;

      // Set role metadata if not already set
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final existingRole = user.userMetadata?['role'] as String?;
        if (existingRole == null || existingRole.isEmpty) {
          final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
          await SupabaseService.instance.client.auth.updateUser(
            UserAttributes(data: {'role': roleStr}),
          );
        }
      }

      if (!mounted) return;
      _navigateAfterAuth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = 'Google Sign-In failed: $e';
      });
    }
  }

  Future<void> _navigateAfterAuth() async {
    final user = SupabaseService.instance.currentUser;
    final userId = user?.id;
    final role = user?.userMetadata?['role'] as String? ?? 'customer';
    
    if (role == 'provider' && userId != null) {
      final onboardingDone = await SupabaseService.instance
          .isProviderOnboardingComplete(userId);
      if (!mounted) return;
      if (!onboardingDone) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.providerOnboardingScreen,
          (route) => false,
        );
        return;
      }
      final regStatus = await SupabaseService.instance
          .getProviderRegistrationStatus(userId);
      if (!mounted) return;
      if (regStatus == 'approved') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.providerDashboardScreen,
          (route) => false,
        );
      } else if (regStatus == 'pending_approval' || regStatus == 'rejected') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.providerPendingApprovalScreen,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_step > 0) {
                  setState(() {
                    _step--;
                    _errorMessage = null;
                  });
                  _animateToNextStep();
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: isWide ? 40 : 10.w,
                height: isWide ? 40 : 10.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1A1C1E),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 22 : 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    _stepLabel(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 12 : 9.5.sp,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Step ${_step + 1}/3',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isWide ? 12 : 10.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildProgressBar() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: LinearProgressIndicator(
          value: (_step + 1) / 3,
          backgroundColor: const Color(0xFFE0E0E0),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 4,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  children: [
                    if (isWide) ...[
                      // Split Screen Layout for Desktop
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AuthLeftBanner(),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      buildHeader(),
                                      const SizedBox(height: 8),
                                      buildProgressBar(),
                                      const SizedBox(height: 24),
                                      _buildCurrentStep(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Mobile Layout
                      buildHeader(),
                      const SizedBox(height: 8),
                      buildProgressBar(),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 24,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(5.w),
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ],
                    const AuthFeaturesFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stepLabel() {
    switch (_step) {
      case 0:
        return 'Basic information & password';
      case 1:
        return 'Security verification';
      case 2:
        return 'Email verification';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildCaptchaStep();
      case 2:
        return _buildEmailVerificationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.person_add_rounded,
          title: 'Your Information',
          subtitle: 'Tell us a bit about yourself',
          color: AppTheme.primary,
        ),
        SizedBox(height: 2.5.h),

        // Role selector
        Text(
          'I want to',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF44474E),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: 'Book Services',
                icon: Icons.person_rounded,
                isSelected: _selectedRole == 0,
                color: AppTheme.primary,
                onTap: () => setState(() => _selectedRole = 0),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _RoleChip(
                label: 'Offer Services',
                icon: Icons.handyman_rounded,
                isSelected: _selectedRole == 1,
                color: AppTheme.secondary,
                onTap: () => setState(() => _selectedRole = 1),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1D1B20),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
            ),
            labelText: 'Full Name',
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primary,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1D1B20),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
            ),
            labelText: 'Email Address',
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primary),
          ),
        ),
        SizedBox(height: 1.5.h),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1D1B20),
          ),
          decoration: InputDecoration(
            hintText: 'Minimum 8 characters',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
            ),
            labelText: 'Password',
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.outline,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1D1B20),
          ),
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
            ),
            labelText: 'Confirm Password',
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.outline,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        SizedBox(height: 2.5.h),
        _buildPrimaryButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onTap: _proceedFromBasicInfo,
          color: AppTheme.primary,
        ),
        SizedBox(height: 2.h),
        _buildDivider(),
        SizedBox(height: 2.h),
        _buildGoogleButton(),
        SizedBox(height: 2.h),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
                Text(
                  'Sign In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptchaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.security_rounded,
          title: 'Security Check',
          subtitle: 'Prove you\'re human to continue',
          color: const Color(0xFF00897B),
        ),
        SizedBox(height: 2.5.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.calculate_rounded,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 1.h),
              Text(
                'Solve this:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                _captchaQuestion,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _captchaController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00897B),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _generateCaptcha()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF00897B),
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'New question',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF00897B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        SizedBox(height: 2.5.h),
        _isLoading
            ? _buildLoadingButton('Creating account...')
            : _buildPrimaryButton(
                label: 'Verify & Create Account',
                icon: Icons.verified_rounded,
                onTap: _verifyCaptcha,
                color: const Color(0xFF00897B),
              ),
      ],
    );
  }

  Widget _buildEmailVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.mark_email_read_rounded,
          title: 'Verify Your Email',
          subtitle: _emailController.text.trim(),
          color: AppTheme.primary,
        ),
        SizedBox(height: 2.5.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.email_rounded, color: AppTheme.primary, size: 16),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'We\'ve sent a 6-digit verification code to your email. Enter it below to activate your account.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w),
              child: SizedBox(
                width: 11.w,
                child: TextFormField(
                  controller: _emailOtpControllers[index],
                  focusNode: _emailOtpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: false,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primary,
                        width: 2.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.only(bottom: 0.5.h),
                  ),
                  onChanged: (value) => _onEmailOtpChanged(index, value),
                ),
              ),
            );
          }),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Didn\'t receive email?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: const Color(0xFF74777F),
              ),
            ),
            _canResendEmail
                ? GestureDetector(
                    onTap: _resendEmailVerification,
                    child: Text(
                      'Resend',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    'Resend in ${_emailResendSeconds}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: const Color(0xFF90A4AE),
                    ),
                  ),
          ],
        ),
        SizedBox(height: 2.5.h),
        _isLoading
            ? _buildLoadingButton('Verifying...')
            : _buildPrimaryButton(
                label: 'Verify & Activate Account',
                icon: Icons.verified_rounded,
                onTap: _verifyEmailOtp,
                color: AppTheme.primary,
              ),
      ],
    );
  }



  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5.sp,
                  color: const Color(0xFF74777F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 6.5.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 2.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton(String label) {
    return Container(
      width: double.infinity,
      height: 6.5.h,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Text(
            'or continue with',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        height: 6.5.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _isGoogleLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 28,
                      color: Color(0xFF4285F4),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF90A4AE),
              size: 18,
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF74777F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

