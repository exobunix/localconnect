import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // Password strength criteria
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _initUserEmail();
  }

  void _initUserEmail() {
    final user = SupabaseService.instance.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) {
      _emailController.text = user.email!;
    } else if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    } else {
      // Check if there is an active session
      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) {
        // May be loaded without auth recovery session
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
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

  Future<void> _handleUpdatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password.');
      return;
    }

    if (!_isPasswordStrong) {
      setState(() => _errorMessage = 'Password must meet all security requirements.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null && _emailController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Reset link has expired or is invalid. Please request a new password reset email.';
        });
        return;
      }

      // Update the user password in Supabase Auth
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Invalidate the recovery session by signing out
      await SupabaseService.instance.signOut();

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message.contains('expired') || e.message.contains('invalid')
              ? 'Reset link is invalid or expired. Please request a new password reset.'
              : e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update password: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSuccess ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 44,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Password Updated!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Your password has been reset successfully. You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF74777F),
            height: 1.5,
          ),
        ),
        SizedBox(height: 3.h),
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginScreen,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Go to Login',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Center(
            child: Text(
              'Reset Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
          SizedBox(height: 0.8.h),
          Center(
            child: Text(
              'Enter your new secure password below to regain access to your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5.sp,
                color: const Color(0xFF74777F),
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Error Box
          if (_errorMessage != null) ...[
            Container(
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
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Email Field (Read-only pre-filled)
          _buildFieldLabel('EMAIL'),
          SizedBox(height: 0.8.h),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF90A4AE), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _emailController.text.isNotEmpty ? _emailController.text : 'Account Email Detected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF44474E),
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline_rounded, color: Color(0xFFB0BEC5), size: 16),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // New Password
          _buildFieldLabel('NEW PASSWORD'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            onChanged: _onPasswordChanged,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: 'Enter new password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF90A4AE),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Password Strength Box
          _buildStrengthBox(),
          SizedBox(height: 2.h),

          // Confirm Password
          _buildFieldLabel('CONFIRM PASSWORD'),
          SizedBox(height: 0.8.h),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: _inputDecoration(
              hint: 'Confirm new password',
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

          // UPDATE PASSWORD Button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      'UPDATE PASSWORD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),

          // Back to login
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (route) => false,
                );
              },
              child: Text(
                'Back to Login',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
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
        fontSize: 9.5.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF74777F),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        color: const Color(0xFF90A4AE),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _strengthItem('At least 8 characters', _hasMinLength),
          _strengthItem('One uppercase letter (A-Z)', _hasUppercase),
          _strengthItem('One lowercase letter (a-z)', _hasLowercase),
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
              fontSize: 9.sp,
              color: met ? const Color(0xFF2E7D32) : const Color(0xFF74777F),
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
