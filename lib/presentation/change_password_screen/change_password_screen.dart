import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _success = false;

  // Password strength
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'),
      );
    });
  }

  bool get _isPasswordStrong =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPwd = _currentPasswordCtrl.text.trim();
    final newPwd = _newPasswordCtrl.text.trim();

    if (!_isPasswordStrong) {
      setState(
        () =>
            _errorMessage = 'New password does not meet strength requirements.',
      );
      return;
    }

    if (currentPwd == newPwd) {
      setState(
        () => _errorMessage =
            'New password must be different from current password.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Re-authenticate with current password to verify it
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        // Phone-based user — cannot change password via email flow
        setState(() {
          _errorMessage =
              'Password change is only available for email-based accounts.';
          _isLoading = false;
        });
        return;
      }

      // Re-authenticate to verify current password
      try {
        await SupabaseService.instance.signInWithEmail(
          email: email,
          password: currentPwd,
        );
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.message.contains('Invalid login credentials')
              ? 'Current password is incorrect.'
              : 'Verification failed: ${e.message}';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Update password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPwd),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
          _errorMessage = null;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Change Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _success ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Password Changed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your password has been updated successfully. You can continue using the app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Password Change',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verify your current password before setting a new one.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Current Password
            _buildLabel('Current Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: !_showCurrent,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Current password is required';
                }
                return null;
              },
              decoration: _inputDecoration(
                hint: 'Enter your current password',
                suffixIcon: _toggleVisibilityIcon(
                  visible: _showCurrent,
                  onTap: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New Password
            _buildLabel('New Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: !_showNew,
              onChanged: _onNewPasswordChanged,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'New password is required';
                }
                if (!_isPasswordStrong) {
                  return 'Password does not meet requirements';
                }
                return null;
              },
              decoration: _inputDecoration(
                hint: 'Enter your new password',
                suffixIcon: _toggleVisibilityIcon(
                  visible: _showNew,
                  onTap: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password strength indicators
            _buildStrengthIndicators(),
            const SizedBox(height: 20),

            // Confirm New Password
            _buildLabel('Confirm New Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: !_showConfirm,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please confirm your new password';
                }
                if (v.trim() != _newPasswordCtrl.text.trim()) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: _inputDecoration(
                hint: 'Re-enter your new password',
                suffixIcon: _toggleVisibilityIcon(
                  visible: _showConfirm,
                  onTap: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFC62828),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Forgot password link
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _sendForgotPasswordEmail,
                child: Text(
                  'Forgot your password? Send reset email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF90A4AE),
      ),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _toggleVisibilityIcon({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: const Color(0xFF90A4AE),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStrengthIndicators() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 10),
          _strengthRow('At least 8 characters', _hasMinLength),
          _strengthRow('One uppercase letter (A-Z)', _hasUppercase),
          _strengthRow('One lowercase letter (a-z)', _hasLowercase),
          _strengthRow('One number (0-9)', _hasNumber),
          _strengthRow('One special character (!@#\$...)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _strengthRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: met ? const Color(0xFF2E7D32) : const Color(0xFF74777F),
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendForgotPasswordEmail() async {
    final email = SupabaseService.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No email address found for your account.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await SupabaseService.instance.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to $email',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset email. Please try again.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
