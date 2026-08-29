import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:google_sign_in/google_sign_in.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../signup_screen/signup_screen.dart';
import '../../widgets/auth_left_banner.dart';
import '../../widgets/auth_features_footer.dart';

// ── Navigation ────────────────────────────────────────────────────────────

/// Fetches the user's role from Supabase user_profiles table.
/// Falls back to auth metadata if DB lookup fails.
/// Admin email env var provides a secondary admin check.
Future<String> _fetchUserRole() async {
  final user = SupabaseService.instance.currentUser;
  if (user == null) return 'customer';

  const adminEmail = String.fromEnvironment('ADMIN_EMAIL', defaultValue: '');
  if (adminEmail.isNotEmpty && user.email == adminEmail) return 'admin';

  try {
    final response = await SupabaseService.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (response != null && response['role'] != null) {
      return response['role'] as String;
    }
  } catch (_) {}

  // Fallback to auth metadata
  return user.userMetadata?['role'] as String? ?? 'customer';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  int _selectedRole = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadSavedCredentials();
    _checkPendingOAuthOrSession();
  }

  Future<void> _checkPendingOAuthOrSession() async {
    // If returning from Google OAuth, wait briefly for auth session to register
    if (!SupabaseService.instance.isLoggedIn) {
      try {
        await SupabaseService.instance.authStateChanges
            .firstWhere(
              (s) =>
                  s.event == AuthChangeEvent.signedIn ||
                  s.event == AuthChangeEvent.initialSession,
            )
            .timeout(const Duration(milliseconds: 1500));
      } catch (_) {}
    }

    if (!mounted) return;

    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    String? googleSignInRole;
    try {
      googleSignInRole = html.window.localStorage['google_signin_role'];
    } catch (_) {}

    if (googleSignInRole != null && googleSignInRole.isNotEmpty) {
      try {
        html.window.localStorage.remove('google_signin_role');
      } catch (_) {}

      if (googleSignInRole == 'customer') {
        final profile = await SupabaseService.instance.getUserProfile(user.id);
        if (profile == null) {
          final email = user.email;
          final name = user.userMetadata?['full_name'] as String? ?? '';
          await SupabaseService.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signupScreen,
              (route) => false,
              arguments: {'email': email, 'fullName': name},
            );
          }
          return;
        } else {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (route) => false,
            );
          }
          return;
        }
      } else if (googleSignInRole == 'provider') {
        final status = await SupabaseService.instance.getProviderRegistrationStatus(user.id);
        if (status == null) {
          final email = user.email;
          final name = user.userMetadata?['full_name'] as String? ?? '';
          await SupabaseService.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerRegistrationScreen,
              (route) => false,
              arguments: {'email': email, 'ownerName': name},
            );
          }
          return;
        } else {
          if (mounted) {
            if (status == 'approved') {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.providerDashboardScreen,
                (route) => false,
              );
            } else if (status == 'pending_approval' || status == 'rejected') {
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
          }
          return;
        }
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      final email = prefs.getString('saved_email') ?? '';
      final password = prefs.getString('saved_password') ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          _emailController.text = email;
          _passwordController.text = password;
        });
      }
    }
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }


  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateByRole() async {
    final user = SupabaseService.instance.currentUser;
    final userId = user?.id;
    final role = await _fetchUserRole();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminPanelScreen,
        (route) => false,
      );
      return;
    }

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

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.homeScreen,
      (route) => false,
    );
  }

  // ── Email/Password Auth ───────────────────────────────────────────────────

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      if (_rememberMe) {
        await _saveRememberMe(true);
        await _saveCredentials(email, password);
      } else {
        await _saveRememberMe(false);
      }

      if (mounted) {
        await _navigateByRole();
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    GoogleSignInAccount? googleUser;
    try {
      if (kIsWeb) {
        final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
        try {
          html.window.localStorage['google_signin_role'] = roleStr;
        } catch (_) {}
        await SupabaseService.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/',
          queryParams: {
            'role': roleStr,
          },
        );
        return;
      }

      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      final effectiveClientId = webClientId.isNotEmpty
          ? webClientId
          : '1053905240243-0olgtcdiieuu55s4qnm7792gg8fkndjr.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        serverClientId: effectiveClientId,
      );
      googleUser = await googleSignIn.signIn();
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
        final roleStr = _selectedRole == 0 ? 'customer' : 'provider';
        if (roleStr == 'customer') {
          final profile = await SupabaseService.instance.getUserProfile(user.id);
          if (profile == null) {
            final email = user.email ?? googleUser.email;
            final name = user.userMetadata?['full_name'] as String? ?? googleUser.displayName ?? '';
            if (mounted) {
              setState(() {
                _isGoogleLoading = false;
              });
              Navigator.pushNamed(
                context,
                AppRoutes.signupScreen,
                arguments: {'email': email, 'fullName': name},
              );
            }
            return;
          }
        } else {
          final status = await SupabaseService.instance.getProviderRegistrationStatus(user.id);
          if (status == null) {
            final email = user.email ?? googleUser.email;
            final name = user.userMetadata?['full_name'] as String? ?? googleUser.displayName ?? '';
            if (mounted) {
              setState(() {
                _isGoogleLoading = false;
              });
              Navigator.pushNamed(
                context,
                AppRoutes.providerRegistrationScreen,
                arguments: {'email': email, 'ownerName': name},
              );
            }
            return;
          }
        }

        final existingRole = user.userMetadata?['role'] as String?;
        if (existingRole == null || existingRole.isEmpty) {
          await SupabaseService.instance.client.auth.updateUser(
            UserAttributes(data: {'role': roleStr}),
          );
        }
      }

      if (_rememberMe) await _saveRememberMe(true);

      if (mounted) _navigateByRole();
    } catch (e) {
      if (e.toString().contains('USER_NOT_REGISTERED')) {
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = null;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignupScreen(
                initialEmail: googleUser?.email,
                initialFullName: googleUser?.displayName,
              ),
            ),
          );
        }
        return;
      }
      if (mounted) {
        final errStr = e.toString();
        String displayError = 'Google Sign-In failed. Please try again.';
        if (errStr.contains('network') || errStr.contains('SocketException')) {
          displayError = 'Network error. Please check your internet connection.';
        } else if (errStr.contains('sign_in_canceled') || errStr.contains('canceled')) {
          displayError = 'Google Sign-In was cancelled.';
        } else {
          displayError = 'Google Sign-In failed: $e';
        }
        setState(() {
          _errorMessage = displayError;
          _isGoogleLoading = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

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
                      // Split Screen Card for Desktop
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
                                      Text(
                                        'Welcome Back!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1A1C1E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Login to your account',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: const Color(0xFF74777F),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildRoleSelector(),
                                      const SizedBox(height: 16),
                                      _buildEmailPasswordForm(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Mobile View
                      SizedBox(height: 2.h),
                      _buildBranding(),
                      SizedBox(height: 3.h),
                      _buildLoginCard(),
                      SizedBox(height: 3.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'By continuing, you agree to our ',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.legalScreen,
                              arguments: {'tab': 1},
                            ),
                            child: Text(
                              'Terms',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: const Color(0xFF1A237E),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            ' & ',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.legalScreen,
                              arguments: {'tab': 0},
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: const Color(0xFF1A237E),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 1.5.h),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminLoginScreen,
                        ),
                        icon: const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFF5C6BC0),
                        ),
                        label: Text(
                          'Administrator Portal Access →',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3949AB),
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Image.asset(
              'assets/images/localconnect_app_icon.png',
              fit: BoxFit.cover,
              semanticLabel:
                  'LocalConnect app icon with location pin and Indian service provider silhouettes on deep navy background',
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A237E),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'LocalConnect',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 0.6.h),
        Text(
          'Connect with local service providers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF74777F),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Login to your account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: const Color(0xFF74777F),
              ),
            ),
            SizedBox(height: 2.5.h),
            _buildRoleSelector(),
            SizedBox(height: 2.h),
            _buildEmailPasswordForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login as',
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
              child: _RoleCard(
                icon: Icons.person_rounded,
                label: 'Customer',
                subtitle: 'Browse & book services',
                isSelected: _selectedRole == 0,
                color: AppTheme.primary,
                onTap: () => setState(() {
                  _selectedRole = 0;
                  _errorMessage = null;
                }),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _RoleCard(
                icon: Icons.handyman_rounded,
                label: 'Provider',
                subtitle: 'Manage your business',
                isSelected: _selectedRole == 1,
                color: AppTheme.secondary,
                onTap: () => setState(() {
                  _selectedRole = 1;
                  _errorMessage = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1D1B20),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
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
            hintText: 'Enter your password',
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

        SizedBox(height: 1.h),
        _buildRememberMe(),

        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],

        SizedBox(height: 2.5.h),

        GestureDetector(
          onTap: _isLoading ? null : _handleEmailAuth,
          child: Container(
            width: double.infinity,
            height: 6.5.h,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Login',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                'or',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: const Color(0xFF90A4AE),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          ],
        ),

        SizedBox(height: 2.h),

        _buildGoogleButton(),

        SizedBox(height: 2.h),

        if (_selectedRole == 1) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_rounded, color: AppTheme.secondary, size: 16),
                SizedBox(width: 2.w),
                Text(
                  'New provider? ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.providerRegistrationScreen,
                  ),
                  child: Text(
                    'Register here',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
        ],

        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.signupScreen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
                Text(
                  'Sign Up',
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
        SizedBox(height: 1.h),
      ],
    );
  }



  Widget _buildRememberMe() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _rememberMe ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                color: _rememberMe ? AppTheme.primary : const Color(0xFFBDBDBD),
                width: 2,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        SizedBox(width: 2.w),
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Text(
            'Remember me',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final email = _emailController.text.trim();
            if (email.isEmpty) {
              setState(() {
                _errorMessage = 'Please enter your email address first to reset your password.';
              });
              return;
            }
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            try {
              final redirectUrl = kIsWeb ? '${Uri.base.origin}/#${AppRoutes.resetPasswordScreen}' : null;
              await SupabaseService.instance.resetPassword(
                email,
                redirectTo: redirectUrl,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset email sent to $email. Please check your inbox.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                    ),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Failed to send reset email: $e';
                });
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          child: Text(
            'Forgot password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

