import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// PhoneProfileSetupScreen is no longer used.
/// Phone OTP (Twilio) authentication has been replaced with
/// Supabase Email Authentication + Google Sign-In.
/// This screen redirects to the home screen.
class PhoneProfileSetupScreen extends StatelessWidget {
  const PhoneProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
    });
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'Redirecting...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
