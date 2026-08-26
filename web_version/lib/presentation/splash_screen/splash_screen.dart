import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../core/testing_mode.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _navigate();
    });
  }

  void _navigate() async {
    // Wait for Supabase to restore any persisted session from local storage.
    // The SDK emits an initialSession event synchronously if a session exists,
    // but we give it a short grace period to finish token refresh if needed.
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) {
        // No in-memory session yet — wait for the first auth state event
        // (initialSession or signedIn) with a short timeout.
        await SupabaseService.instance.authStateChanges
            .firstWhere(
              (state) =>
                  state.event == AuthChangeEvent.initialSession ||
                  state.event == AuthChangeEvent.signedIn ||
                  state.event == AuthChangeEvent.signedOut,
            )
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                // Timeout — treat as no session
                return AuthState(AuthChangeEvent.signedOut, null);
              },
            );
      }
    } catch (_) {
      // Ignore errors — proceed with whatever state is available
    }

    final isLoggedIn = SupabaseService.instance.isLoggedIn;
    if (!isLoggedIn) {
      // Check if first-time user — show onboarding
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
      if (!onboardingDone && !kIsWeb) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.onboardingScreen,
            (route) => false,
          );
        }
        return;
      }
      if (kIsWeb) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loginScreen,
          (route) => false,
        );
      }
      return;
    }

    // Keep user logged in once authenticated.

    final user = SupabaseService.instance.currentUser;
    final userId = user?.id;

    // Check if there is a pending google sign in role
    String? googleSignInRole;
    try {
      googleSignInRole = html.window.localStorage['google_signin_role'];
    } catch (_) {}

    if (userId != null && googleSignInRole != null && googleSignInRole.isNotEmpty) {
      // Clear it so it doesn't run again on next app reload
      try {
        html.window.localStorage.remove('google_signin_role');
      } catch (_) {}

      if (googleSignInRole == 'customer') {
        final profile = await SupabaseService.instance.getUserProfile(userId);
        if (profile == null) {
          // Customer does NOT exist in DB!
          // Sign out of auth and redirect to signup pre-filled with email!
          final email = user?.email;
          await SupabaseService.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signupScreen,
              (route) => false,
              arguments: {'email': email},
            );
          }
          return;
        }
      } else if (googleSignInRole == 'provider') {
        final status = await SupabaseService.instance.getProviderRegistrationStatus(userId);
        if (status == null) {
          // Provider does NOT exist in DB!
          // Sign out of auth and redirect to provider registration pre-filled with email!
          final email = user?.email;
          await SupabaseService.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerRegistrationScreen,
              (route) => false,
              arguments: {'email': email},
            );
          }
          return;
        }
      }
    }

    // SECURITY: Always fetch role from DB (user_profiles), never from user metadata.
    // user_metadata is user-writable and can be spoofed. DB role is server-controlled.
    String role = 'customer';
    if (userId != null) {
      try {
        final profile = await SupabaseService.instance.getUserProfile(userId);
        final dbRole = profile?['role'] as String? ?? 'customer';
        const validRoles = {'customer', 'provider', 'admin'};
        role = validRoles.contains(dbRole) ? dbRole : 'customer';
      } catch (_) {
        role = 'customer';
      }
    }

    // Admin routing
    if (role == 'admin') {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.adminPanelScreen,
          (route) => false,
        );
      }
      return;
    }

    if (role == 'provider' && userId != null) {
      // ── TESTING MODE: demo provider bypass ──────────────────────────────
      // When TESTING_MODE=true and the current user is the demo provider,
      // skip the approval check and go straight to the dashboard.
      final email = SupabaseService.instance.currentUser?.email ?? '';
      if (TestingMode.isDemoProvider(email)) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerDashboardScreen,
            (route) => false,
          );
        }
        return;
      }
      // ── END TESTING MODE ────────────────────────────────────────────────

      final onboardingDone = await SupabaseService.instance
          .isProviderOnboardingComplete(userId);

      if (!onboardingDone) {
        if (kIsWeb) {
          await SupabaseService.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.loginScreen,
              (route) => false,
            );
          }
          return;
        }
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerOnboardingScreen,
            (route) => false,
          );
        }
        return;
      }

      final regStatus = await SupabaseService.instance
          .getProviderRegistrationStatus(userId);

      if (mounted) {
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
      }
    } else {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B4B), Color(0xFF1A237E), Color(0xFF283593)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App Icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(scale: _scaleAnim, child: child),
                  );
                },
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3F51B5).withAlpha(128),
                        blurRadius: 32,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Image.asset(
                      'assets/images/localconnect_app_icon-1785844943052.png',
                      fit: BoxFit.cover,
                      semanticLabel:
                          'LocalConnect app logo with location pin on deep navy background',
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
              ),
              SizedBox(height: 3.h),
              // App Name
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(opacity: _textFadeAnim, child: child);
                },
                child: Column(
                  children: [
                    Text(
                      'LocalConnect',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Your trusted local services platform',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withAlpha(179),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Loading indicator
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(opacity: _textFadeAnim, child: child);
                },
                child: Column(
                  children: [
                    SizedBox(
                      width: 6.w,
                      height: 6.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6F00),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Loading...',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}

