import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthFeaturesFooter extends StatelessWidget {
  const AuthFeaturesFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          
          final items = [
            _buildFeatureItem(
              Icons.verified_user_rounded,
              'Trusted & Verified',
              'All providers are\nbackground verified',
            ),
            _buildFeatureItem(
              Icons.workspace_premium_rounded,
              'Quality Services',
              'Get the best local\nservices near you',
            ),
            _buildFeatureItem(
              Icons.lock_rounded,
              'Secure & Safe',
              'Your data is protected\nwith top security',
            ),
            _buildFeatureItem(
              Icons.headset_mic_rounded,
              '24/7 Support',
              'We\'re here to help\nanytime, anywhere',
            ),
          ];

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...items.map((item) => Expanded(child: item)),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF74777F),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: items.map((item) => SizedBox(width: 140, child: item)).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE0E0E0)),
                const SizedBox(height: 8),
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF3F51B5), size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF74777F),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
