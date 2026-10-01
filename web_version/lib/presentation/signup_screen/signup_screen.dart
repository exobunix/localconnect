import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGoogleEmailLocked = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  StreamSubscription<AuthState>? _authSub;

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

    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser != null) {
      if (_emailController.text.isEmpty && currentUser.email != null) {
        _emailController.text = currentUser.email!;
      }
      if (_nameController.text.isEmpty) {
        final metaName = currentUser.userMetadata?['full_name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          _nameController.text = metaName;
        }
      }
      _isGoogleEmailLocked = true;
    }

    _authSub = SupabaseService.instance.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        final user = data.session?.user ?? SupabaseService.instance.currentUser;
        if (user != null) {
          setState(() {
            _emailController.text = user.email ?? '';
            final metaName = user.userMetadata?['full_name'] as String?;
            if (metaName != null &&
                metaName.isNotEmpty &&
                _nameController.text.isEmpty) {
              _nameController.text = metaName;
            }
            _isGoogleEmailLocked = true;
            _isGoogleLoading = false;
            _errorMessage = null;
          });
        }
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleCustomerRegistration() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    // 1. Validation
    if (!_isGoogleEmailLocked || email.isEmpty) {
      setState(() => _errorMessage = 'Please connect your Google account to set and verify your email.');
      await _handleGoogleSignIn();
      return;
    }

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (name.length < 2 || name.length > 100) {
      setState(() => _errorMessage = 'Name must be between 2 and 100 characters.');
      return;
    }

    if (phone.isEmpty || phone.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetRole = _selectedRole == 0 ? 'customer' : 'provider';

    try {
      final currentUser = SupabaseService.instance.currentUser;

      // 2. Duplicate mobile check strictly for the same role
      // This allows one customer account and one provider account on the same phone & email
      final isPhoneTaken = await SupabaseService.instance.isPhoneRegistered(
        phone,
        excludeUserId: currentUser?.id,
        targetRole: targetRole,
      );
      if (isPhoneTaken) {
        setState(() {
          _errorMessage =
              'A $targetRole account with this mobile number already exists. Please log in or use another number.';
          _isLoading = false;
        });
        return;
      }

      // Check if user is authenticated (via Google OAuth or active session)
      if (currentUser != null) {
        await SupabaseService.instance.upsertUserProfile(
          userId: currentUser.id,
          email: currentUser.email ?? email,
          fullName: name,
          phone: phone,
          role: targetRole,
          city: SupabaseService.instance.selectedCity.isNotEmpty ? SupabaseService.instance.selectedCity : '',
        );

        if (mounted) {
          if (_selectedRole == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerRegistrationScreen,
              (route) => false,
              arguments: {
                'email': currentUser.email ?? email,
                'ownerName': name,
                'phone': phone,
                'isGoogleAuth': true,
              },
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (route) => false,
            );
          }
        }
        return;
      } else {
        // If session was lost, trigger Google sign-in again
        await _handleGoogleSignIn();
        return;
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
          _errorMessage = 'Registration failed. Please check your details or sign up with Google.';
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
          final targetRole = _selectedRole == 0 ? 'customer' : 'provider';
          html.window.localStorage['google_signin_role'] = targetRole;
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
              '78703580798-ga1vsmbjl90te533l9imt84ub1l12p4d.apps.googleusercontent.com',
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
      final targetRole = _selectedRole == 0 ? 'customer' : 'provider';
      final email = user?.email ?? googleUser.email;
      final name = user?.userMetadata?['full_name'] as String? ?? googleUser.displayName ?? '';

      // Check if existing profile has phone number already
      Map<String, dynamic>? existingProfile;
      if (user != null) {
        existingProfile = await SupabaseService.instance.getUserProfile(user.id);
      }

      final existingPhone = existingProfile?['phone'] as String?;

      if (mounted) {
        setState(() {
          _emailController.text = email;
          if (_nameController.text.trim().isEmpty && name.isNotEmpty) {
            _nameController.text = name;
          }
          if (existingPhone != null && existingPhone.isNotEmpty && _phoneController.text.trim().isEmpty) {
            _phoneController.text = existingPhone.replaceAll(RegExp(r'\D'), '');
          }
          _isGoogleEmailLocked = true;
          _isGoogleLoading = false;
        });

        // If phone is already present and valid, finish registration immediately
        if (_phoneController.text.trim().length == 10 && user != null) {
          await SupabaseService.instance.upsertUserProfile(
            userId: user.id,
            email: email,
            fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : name,
            phone: _phoneController.text.trim(),
            role: targetRole,
            city: SupabaseService.instance.selectedCity.isNotEmpty ? SupabaseService.instance.selectedCity : '',
          );

          if (!mounted) return;

          if (targetRole == 'provider') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerRegistrationScreen,
              (route) => false,
              arguments: {
                'email': email,
                'ownerName': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : name,
                'phone': _phoneController.text.trim(),
                'isGoogleAuth': true,
              },
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (route) => false,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('GOOGLE_SIGN_IN_ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      final errStr = e.toString();
      if (!kIsWeb &&
          (errStr.contains('10') ||
              errStr.contains('ApiException') ||
              errStr.contains('DEVELOPER_ERROR') ||
              errStr.contains('sign_in_failed'))) {
        debugPrint(
            'Native Google Sign-In failed with configuration error ($e). Falling back to Supabase OAuth in signup...');
        try {
          final targetRole = _selectedRole == 0 ? 'customer' : 'provider';
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('google_signin_role', targetRole);
            await prefs.setString('google_signin_flow', 'signup');
          } catch (_) {}

          await SupabaseService.instance.client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'io.supabase.localconnect://login-callback',
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
          return;
        } catch (oauthError) {
          debugPrint('OAuth fallback error: $oauthError');
        }
      }

      if (mounted) {
        String displayError = 'Google Sign-In failed. Please try again.';
        if (errStr.contains('ApiException: 10') || errStr.contains('10:')) {
          displayError = kDebugMode
              ? 'Google Sign-In setup error (ApiException 10): Ensure SHA-1 & Web Client ID match Google Cloud / Firebase Console. Detail: $e'
              : 'Google Sign-In configuration error (Code 10). Please verify Google Cloud SHA-1 and OAuth client settings.';
        } else if (errStr.contains('sign_in_canceled') || errStr.contains('canceled')) {
          displayError = 'Google Sign-In was cancelled.';
        } else {
          displayError = kDebugMode ? 'Google Sign-In error: $e' : 'Google Sign-In failed. Please try again.';
        }
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = displayError;
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
          SizedBox(height: 2.h),
          _buildRoleSelector(),
          SizedBox(height: 2.h),
          if (_errorMessage != null) ...[
            _buildErrorBox(_errorMessage!),
            SizedBox(height: 1.5.h),
          ],
          _buildGoogleButton(),
          SizedBox(height: 2.h),
          _buildSignupForm(),
          SizedBox(height: 2.5.h),
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
            // Select the provider role in-form; the actual provider
            // registration screen is opened after successful signup.
            onTap: () => setState(() => _selectedRole = 1),
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
          if (_isGoogleEmailLocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google account verified! Enter your mobile number to complete your profile.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Full Name
          _buildFieldLabel('Full Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Email Address (Exclusively set via Google Account - Never manual)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Email Address (Google Verified)'),
              if (_isGoogleEmailLocked && _emailController.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                  child: Text(
                    'Change Google Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _isGoogleLoading
                ? null
                : () {
                    if (!_isGoogleEmailLocked || _emailController.text.trim().isEmpty) {
                      _handleGoogleSignIn();
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              ignoring: true,
              child: TextFormField(
                controller: _emailController,
                readOnly: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: _isGoogleEmailLocked ? FontWeight.w600 : FontWeight.w400,
                  color: _isGoogleEmailLocked ? const Color(0xFF1A1C1E) : const Color(0xFF94A3B8),
                ),
                decoration: _inputDecoration(
                  hint: 'Connect Google account to set email',
                  icon: Icons.email_outlined,
                  suffixIcon: _isGoogleEmailLocked && _emailController.text.trim().isNotEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.account_circle_outlined, size: 16, color: Color(0xFF1E3A8A)),
                          label: const Text(
                            'Connect',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Mobile Number
          _buildFieldLabel('Mobile Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: _inputDecoration(
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              prefixText: '+91 ',
            ),
          ),
          const SizedBox(height: 20),

          // Create / Complete Account Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading || _isGoogleLoading ? null : _handleCustomerRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
                      _isGoogleEmailLocked ? 'Complete Registration' : 'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
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

  Widget _buildGoogleButton() {
    final isConnected = _isGoogleEmailLocked && _emailController.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: isConnected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isConnected ? const Color(0xFF22C55E) : const Color(0xFF4285F4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isConnected ? const Color(0xFF22C55E) : const Color(0xFF4285F4)).withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    Icon(
                      isConnected ? Icons.check_circle_rounded : Icons.g_mobiledata_rounded,
                      size: isConnected ? 24 : 32,
                      color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF4285F4),
                    ),
                    SizedBox(width: 2.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isConnected
                              ? 'Google Account Connected'
                              : 'Continue with Google (Required)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          isConnected
                              ? '${_emailController.text.trim()} (Tap to switch)'
                              : 'Auto-fill verified email with Google',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5.sp,
                            color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            fontWeight: isConnected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
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
