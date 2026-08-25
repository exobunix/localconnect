import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  // Steps: 0 = method selection, 1 = phone entry (mobile), 2 = OTP entry
  // For email: step 0 → directly step 2 (OTP sent to fixed email)
  int _step = 0;

  // 'mobile' or 'email'
  String _selectedMethod = 'mobile';

  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(8, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';
  String? _otpHint; // shown when email delivery is uncertain

  // Fixed admin email — loaded from environment variable, not hardcoded
  static final String _adminEmail = const String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: '',
  );

  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  // OTP rate limiting
  int _otpSendCount = 0;
  DateTime? _firstOtpSentAt;
  static const int _maxOtpPerHour = 5;

  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;

  // Twilio removed — admin uses email OTP only via send-admin-email-otp edge function

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _formattedPhone {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }

  bool _isRateLimited() {
    if (_firstOtpSentAt == null) return false;
    final elapsed = DateTime.now().difference(_firstOtpSentAt!);
    if (elapsed.inHours >= 1) {
      _otpSendCount = 0;
      _firstOtpSentAt = null;
      return false;
    }
    return _otpSendCount >= _maxOtpPerHour;
  }

  // ─── Mobile OTP (Twilio) ───────────────────────────────────────────────────

  Future<void> _sendMobileOtp() async {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      setState(
        () => _errorMessage = 'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    if (_isRateLimited()) {
      setState(
        () => _errorMessage =
            'Too many OTP requests. Please wait before trying again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _phoneNumber = _formattedPhone;

    const String registeredAdminPhone = String.fromEnvironment(
      'ADMIN_PHONE',
      defaultValue: '+919209205923',
    );

    bool isAdminPhone = false;
    final normalizedInput = _phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final normalizedAdmin = registeredAdminPhone.replaceAll(RegExp(r'\s+'), '');
    if (normalizedInput == normalizedAdmin) {
      isAdminPhone = true;
    }

    if (!isAdminPhone) {
      try {
        final adminCheck = await SupabaseService.instance.client
            .from('user_profiles')
            .select('id, role')
            .eq('phone', _phoneNumber)
            .eq('role', 'admin')
            .maybeSingle();

        if (!mounted) return;
        if (adminCheck != null) isAdminPhone = true;
      } catch (_) {}
    }

    if (!isAdminPhone) {
      setState(() {
        _errorMessage = 'No admin account found with this mobile number.';
        _isLoading = false;
      });
      return;
    }

    // Mobile OTP (Twilio) has been removed. Admin must use email OTP.
    setState(() {
      _errorMessage =
          'Mobile OTP is no longer supported. Please use Email OTP.';
      _isLoading = false;
      _selectedMethod = 'email';
    });
  }

  Future<void> _verifyMobileOtp() async {
    // Mobile OTP removed — redirect to email OTP
    setState(() {
      _selectedMethod = 'email';
      _errorMessage = null;
      _step = 0;
    });
  }

  // ─── Email OTP (Edge Function — bypasses signup restriction) ──────────────

  Future<void> _sendEmailOtp() async {
    if (_isRateLimited()) {
      setState(
        () => _errorMessage =
            'Too many OTP requests. Please wait before trying again.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _otpHint = null;
    });

    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'send-admin-email-otp',
        body: {'email': _adminEmail, 'action': 'send'},
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        final errMsg = data?['error'] as String? ?? 'Failed to send email OTP.';
        setState(() {
          _errorMessage = errMsg;
          _isLoading = false;
        });
        return;
      }

      _otpSendCount++;
      _firstOtpSentAt ??= DateTime.now();

      // Capture OTP hint from response (shown if email delivery is uncertain)
      final emailSent = data['email_sent'] as bool? ?? true;
      final otpCode = data['otp_code'] as String?;
      if (otpCode != null) {
        _otpHint = otpCode;
      }

      setState(() {
        _step = 2;
        _isLoading = false;
      });
      _animateStep();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send email OTP. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 8) {
      setState(() => _errorMessage = 'Please enter the complete 8-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'send-admin-email-otp',
        body: {'email': _adminEmail, 'action': 'verify', 'otp': otp},
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        final errMsg = data?['error'] as String? ?? 'Verification failed.';
        _triggerShake();
        setState(() {
          _errorMessage = errMsg;
          _isLoading = false;
          for (final c in _otpControllers) {
            c.clear();
          }
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
        return;
      }

      // OTP verified — navigate directly to admin panel (no Supabase auth session needed)
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminPanelScreen,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _triggerShake();
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
        _isLoading = false;
        for (final c in _otpControllers) {
          c.clear();
        }
      });
    }
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Future<void> _grantAdminAccess() async {
    // For email OTP path, verify admin role via DB since Supabase auth may not
    // have role metadata set
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Verification failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      final role = user.userMetadata?['role'] as String? ?? '';

      // For email-based admin, also check DB profile
      if (role != 'admin') {
        final profileCheck = await SupabaseService.instance.client
            .from('user_profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        final dbRole = profileCheck?['role'] as String? ?? '';
        if (dbRole != 'admin') {
          // For email OTP, the admin email itself is the authorisation
          // If email matches admin email, allow access
          if (_selectedMethod == 'email' && user.email == _adminEmail) {
            // Proceed to admin panel
          } else {
            await SupabaseService.instance.signOut();
            if (!mounted) return;
            setState(() {
              _errorMessage =
                  'Access denied. This account does not have admin privileges.';
              _isLoading = false;
              _step = 0;
              for (final c in _otpControllers) {
                c.clear();
              }
              _phoneController.clear();
            });
            return;
          }
        }
      }
    } catch (_) {
      // If role check fails for email method, still allow if email matches
      if (_selectedMethod != 'email') {
        setState(() {
          _errorMessage = 'Role verification failed. Please try again.';
          _isLoading = false;
        });
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.adminPanelScreen,
      (route) => false,
    );
  }

  void _animateStep() {
    _startResendTimer();
    _fadeController.reset();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 7) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 8) {
      if (_selectedMethod == 'mobile') {
        _verifyMobileOtp();
      } else {
        _verifyEmailOtp();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    if (_isRateLimited()) {
      setState(
        () => _errorMessage =
            'Too many OTP requests. Please wait before trying again.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      for (final c in _otpControllers) {
        c.clear();
      }
    });

    if (_selectedMethod == 'mobile') {
      // Mobile OTP removed — use email OTP
      setState(() {
        _isLoading = false;
        _selectedMethod = 'email';
        _step = 0;
      });
      return;
    } else {
      try {
        final response = await SupabaseService.instance.client.functions.invoke(
          'send-admin-email-otp',
          body: {'email': _adminEmail, 'action': 'send'},
        );
        if (mounted) {
          final data = response.data as Map<String, dynamic>?;
          final otpCode = data?['otp_code'] as String?;
          if (otpCode != null) {
            setState(() => _otpHint = otpCode);
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to resend OTP. Please try again.';
          _isLoading = false;
        });
        return;
      }
    }

    if (!mounted) return;
    _otpSendCount++;
    setState(() => _isLoading = false);
    _startResendTimer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFFCE93D8),
                          size: 14,
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          'Admin Access',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFCE93D8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          SizedBox(height: 2.h),
                          // Logo
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9C27B0,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Image.asset(
                                'assets/images/localconnect_app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Admin Portal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Verify your identity to continue',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: 3.h),

                          // Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(5.w),
                            child: _buildCurrentStep(),
                          ),
                          SizedBox(height: 3.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_step == 0) return _buildMethodSelectionStep();
    if (_step == 1) return _buildPhoneStep();
    return _buildOtpStep();
  }

  // ─── Step 0: Method Selection ──────────────────────────────────────────────

  Widget _buildMethodSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF6A1B9A),
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Verification',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  'Choose your OTP method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.5.h),

        // Info banner
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFCE93D8)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: Color(0xFF6A1B9A),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Select how you want to receive your admin OTP.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF4A148C),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.5.h),

        // Mobile OTP option
        _buildMethodCard(
          method: 'mobile',
          icon: Icons.phone_android_rounded,
          title: 'Mobile OTP',
          subtitle: 'Receive OTP on your registered\nadmin mobile number',
        ),
        SizedBox(height: 1.5.h),

        // Email OTP option
        _buildMethodCard(
          method: 'email',
          icon: Icons.email_rounded,
          title: 'Email OTP',
          subtitle: 'Receive OTP at\n${_maskedEmail(_adminEmail)}',
        ),

        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        SizedBox(height: 2.5.h),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _proceedWithMethod,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              elevation: 0,
            ),
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
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                      SizedBox(width: 2.w),
                      Text(
                        'Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMethod = method;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E5F5) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6A1B9A)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6A1B9A)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF757575),
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF4A148C)
                          : const Color(0xFF1A1C1E),
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      color: const Color(0xFF74777F),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6A1B9A),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _proceedWithMethod() {
    setState(() => _errorMessage = null);
    if (_selectedMethod == 'mobile') {
      setState(() {
        _step = 1;
      });
      _fadeController.reset();
      _fadeController.forward();
    } else {
      _sendEmailOtp();
    }
  }

  // ─── Step 1: Phone Entry (Mobile only) ────────────────────────────────────

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _step = 0;
                _errorMessage = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF6A1B9A),
                  size: 18,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobile OTP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  'Enter your registered admin number',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.5.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFCE93D8)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: Color(0xFF6A1B9A),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'OTP will be sent to your registered admin mobile number only.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF4A148C),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'e.g. 9876543210',
            labelText: 'Admin Mobile Number',
            prefixIcon: const Icon(
              Icons.phone_rounded,
              color: Color(0xFF6A1B9A),
            ),
            prefixText: '+91  ',
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF44474E),
              fontWeight: FontWeight.w600,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        SizedBox(height: 2.5.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendMobileOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              elevation: 0,
            ),
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
                      const Icon(Icons.sms_rounded, size: 18),
                      SizedBox(width: 2.w),
                      Text(
                        'Send OTP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: OTP Entry ─────────────────────────────────────────────────────

  Widget _buildOtpStep() {
    final isEmail = _selectedMethod == 'email';
    final sentTo = isEmail
        ? _maskedEmail(_adminEmail)
        : _maskedPhone(_phoneNumber);
    final sentVia = isEmail ? 'email' : 'SMS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF6A1B9A),
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter OTP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    'Sent via $sentVia to $sentTo',
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
        ),
        SizedBox(height: 2.5.h),

        // Method badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isEmail ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEmail ? Icons.email_rounded : Icons.phone_android_rounded,
                color: isEmail
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF2E7D32),
                size: 14,
              ),
              SizedBox(width: 1.5.w),
              Text(
                isEmail ? 'Email OTP' : 'Mobile OTP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: isEmail
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            final offset = _shakeController.isAnimating
                ? _shakeAnim.value * 8
                : 0.0;
            return Transform.translate(
              offset: Offset(
                offset * ((_shakeAnim.value * 10).round().isEven ? 1 : -1),
                0,
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (index) {
              return SizedBox(
                width: 9.5.w,
                height: 7.h,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6A1B9A),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF3E5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF6A1B9A),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => _onOtpChanged(index, value),
                ),
              );
            }),
          ),
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: 1.5.h),
          _buildErrorBox(_errorMessage!),
        ],
        if (_otpHint != null) ...[
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B4B),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF6A1B9A), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      color: Color(0xFFCE93D8),
                      size: 16,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      'Your OTP Code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFCE93D8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  _otpHint!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Enter this code in the boxes above',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _step = isEmail ? 0 : 1;
                _errorMessage = null;
                for (final c in _otpControllers) {
                  c.clear();
                }
                _resendTimer?.cancel();
              }),
              child: Text(
                isEmail ? 'Change method' : 'Change number',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: const Color(0xFF74777F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            _canResend
                ? GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6A1B9A),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    'Resend in ${_resendSeconds}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: const Color(0xFF90A4AE),
                    ),
                  ),
          ],
        ),
        SizedBox(height: 2.5.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_selectedMethod == 'mobile') {
                      _verifyMobileOtp();
                    } else {
                      _verifyEmailOtp();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              elevation: 0,
            ),
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
                      const Icon(Icons.verified_rounded, size: 18),
                      SizedBox(width: 2.w),
                      Text(
                        'Verify & Access Admin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Utility widgets ───────────────────────────────────────────────────────

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

  String _maskedPhone(String phone) {
    if (phone.length > 4) {
      final visible = phone.substring(phone.length - 4);
      final masked = phone
          .substring(0, phone.length - 4)
          .replaceAll(RegExp(r'\d'), '*');
      return '$masked$visible';
    }
    return phone;
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return '${name[0]}***@$domain';
    return '${name.substring(0, 3)}***@$domain';
  }
}
