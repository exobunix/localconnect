import 'dart:async';
import 'package:universal_html/html.dart' as html;
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

class SignupScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialFullName;
  const SignupScreen({super.key, this.initialEmail, this.initialFullName});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  int _selectedRole = 0; // 0 = Customer, 1 = Provider

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGoogleEmailLocked = false;
  String? _errorMessage;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _isGoogleEmailLocked = true;
    }
    if (widget.initialFullName != null && widget.initialFullName!.isNotEmpty) {
      _nameController.text = widget.initialFullName!;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'));
    });
  }

  bool get _isPasswordStrong =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial;

  Future<void> _handleCustomerRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // 1. Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (name.length < 2 || name.length > 100) {
      setState(() => _errorMessage = 'Name must be between 2 and 100 characters.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    if (!_isPasswordStrong) {
      setState(() => _errorMessage = 'Password must meet all security requirements.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Duplicate mobile check
      final isPhoneTaken = await SupabaseService.instance.isPhoneRegistered(phone);
      if (isPhoneTaken) {
        setState(() {
          _errorMessage = 'This mobile number is already registered. Please log in or use another number.';
          _isLoading = false;
        });
        return;
      }

      // Check if user is already authenticated (via Google OAuth or active session)
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser != null && (currentUser.email == email || _isGoogleEmailLocked)) {
        try {
          await SupabaseService.instance.client.auth.updateUser(
            UserAttributes(
              password: password,
              data: {
                'full_name': name,
                'phone': phone,
                'role': 'customer',
              },
            ),
          );
        } catch (_) {}

        await SupabaseService.instance.upsertUserProfile(
          userId: currentUser.id,
          email: email,
          fullName: name,
          phone: phone,
          role: 'customer',
          city: 'Pune',
        );

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.homeScreen,
            (route) => false,
          );
        }
        return;
      }

      // 3. Normal signup with email & password
      try {
        final authResponse = await SupabaseService.instance.signUpWithEmail(
          email: email,
          password: password,
          fullName: name,
          phone: phone,
          role: 'customer',
        );

        final newUserId = authResponse.user?.id;
        if (newUserId != null) {
          await SupabaseService.instance.upsertUserProfile(
            userId: newUserId,
            email: email,
            fullName: name,
            phone: phone,
            role: 'customer',
            city: 'Pune',
          );
        }

        if (authResponse.session == null) {
          try {
            await SupabaseService.instance.signInWithEmail(
              email: email,
              password: password,
            );
          } catch (_) {}
        }
      } on AuthException catch (authEx) {
        if (authEx.message.contains('User already registered') || authEx.message.contains('already exists')) {
          try {
            final signInRes = await SupabaseService.instance.signInWithEmail(
              email: email,
              password: password,
            );
            if (signInRes.user != null) {
              await SupabaseService.instance.upsertUserProfile(
                userId: signInRes.user!.id,
                email: email,
                fullName: name,
                phone: phone,
                role: 'customer',
                city: 'Pune',
              );
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (r) => false);
              }
              return;
            }
          } catch (_) {
            final profile = await SupabaseService.instance.getUserProfileByEmail(email);
            if (profile == null) {
              setState(() {
                _errorMessage = 'Google sign-up detected. Please tap "Continue with Google" below to complete sign-in.';
                _isLoading = false;
              });
              return;
            } else {
              setState(() {
                _errorMessage = 'An account with this email already exists. Please log in.';
                _isLoading = false;
              });
              return;
            }
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Registration failed. Please check your details and try again.';
          _isLoading = false;
        });
      }
    }
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
          html.window.localStorage['google_signin_flow'] = 'signup';
        } catch (_) {}

        await SupabaseService.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/',
        );
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue:
              '1053905240243-0olgtcdiieuu55s4qnm7792gg8fkndjr.apps.googleusercontent.com',
        ),
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleUser.id;
      final accessToken = googleAuth.accessToken;

      await SupabaseService.instance.signInWithGoogleIdToken(
        idToken: idToken,
        accessToken: accessToken,
        email: googleUser.email,
        name: googleUser.displayName,
      );

      if (!mounted) return;

      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final profile = await SupabaseService.instance.getUserProfile(user.id);
        if (!mounted) return;
        if (profile != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.homeScreen,
            (route) => false,
          );
          return;
        }

        setState(() {
          _isGoogleLoading = false;
          _emailController.text = user.email ?? googleUser.email;
          _nameController.text = user.userMetadata?['full_name'] as String? ?? googleUser.displayName ?? '';
          _isGoogleEmailLocked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Google Sign-In failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 850;

    Widget formContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 6.w,
        vertical: isWide ? 40 : 3.5.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          SizedBox(height: 2.5.h),
          _buildRoleSelector(),
          SizedBox(height: 2.5.h),
          if (_errorMessage != null) ...[
            _buildErrorBox(_errorMessage!),
            SizedBox(height: 2.h),
          ],
          _buildSignupForm(),
          SizedBox(height: 2.5.h),
          _buildOrDivider(),
          SizedBox(height: 2.5.h),
          _buildGoogleButton(),
          SizedBox(height: 3.h),
          _buildLoginLink(),
        ],
      ),
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2FF),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: AuthLeftBanner(),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40.0,
                            vertical: 36.0,
                          ),
                          child: formContent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: formContent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B4B), Color(0xFF1E3A8A)],
                ),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LocalConnect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D1B4B),
                  ),
                ),
                Text(
                  'Connect with local service providers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          _isGoogleEmailLocked
              ? 'Complete your profile to finish registration'
              : 'Sign up to browse and book services',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            color: const Color(0xFF74777F),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            subtitle: 'Browse & book services',
            isSelected: _selectedRole == 0,
            color: AppTheme.primary,
            onTap: () => setState(() => _selectedRole = 0),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _RoleCard(
            icon: Icons.handyman_outlined,
            label: 'Provider',
            subtitle: 'Manage your business',
            isSelected: _selectedRole == 1,
            color: const Color(0xFFE65100),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.providerRegistrationScreen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          _buildFieldLabel('Full Name'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
            ),
          ),
          SizedBox(height: 1.8.h),

          // Email Address
          _buildFieldLabel('Email Address'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: _isGoogleEmailLocked,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: _isGoogleEmailLocked ? const Color(0xFF44474E) : const Color(0xFF1A1C1E),
            ),
            decoration: _inputDecoration(
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              suffixIcon: _isGoogleEmailLocked
                  ? const Icon(Icons.lock_outline_rounded, color: Color(0xFFB0BEC5), size: 18)
                  : null,
            ),
          ),
          SizedBox(height: 1.8.h),

          // Mobile Number
          _buildFieldLabel('Mobile Number'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              prefixText: '+91 ',
            ),
          ),
          SizedBox(height: 1.8.h),

          // Password
          _buildFieldLabel('Password'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: _onPasswordChanged,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: 'Create password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF90A4AE),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          SizedBox(height: 1.2.h),

          // Password Strength Indicators
          _buildStrengthBox(),
          SizedBox(height: 1.8.h),

          // Confirm Password
          _buildFieldLabel('Confirm Password'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF90A4AE),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            height: 6.5.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCustomerRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 10.5.sp,
        color: const Color(0xFF90A4AE),
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _isGoogleEmailLocked && hint.contains('email') ? const Color(0xFFF1F3F9) : const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildStrengthBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _strengthItem('At least 8 characters', _hasMinLength),
          _strengthItem('One uppercase & lowercase letter', _hasUppercase && _hasLowercase),
          _strengthItem('One number (0-9)', _hasNumber),
          _strengthItem('One special character (!@#\$...)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _strengthItem(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5.sp,
              color: met ? const Color(0xFF2E7D32) : const Color(0xFF74777F),
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: const Color(0xFFC62828),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Text(
            'or',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFF90A4AE),
              fontWeight: FontWeight.w500,
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
                        fontSize: 11.5.sp,
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

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.loginScreen,
            (route) => false,
          );
        },
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5.sp,
              color: const Color(0xFF74777F),
            ),
            children: [
              TextSpan(
                text: 'Login',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role Card Widget ──────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
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
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF90A4AE),
              size: 20,
            ),
            SizedBox(height: 0.8.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : const Color(0xFF44474E),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5.sp,
                color: const Color(0xFF90A4AE),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
