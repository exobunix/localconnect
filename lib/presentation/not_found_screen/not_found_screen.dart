import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1C1E)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeScreen,
                (route) => false,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Page Not Found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The page you are looking for does not exist or may have been moved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF74777F),
                    height: 1.4,
                  ),
                ),
                if (routeName != null && routeName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      routeName!,
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: Text(
                    'Return to Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.homeScreen,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

