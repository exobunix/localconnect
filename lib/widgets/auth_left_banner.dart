import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLeftBanner extends StatelessWidget {
  const AuthLeftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1128), Color(0xFF1C274C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1128).withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & App Name
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/localconnect_app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF6C63FF),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LocalConnect',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Local Services Marketplace',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFB0BEC5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Catchphrase
              Text(
                'Everything your home\n& life needs, nearby.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect directly with trusted neighborhood providers\nfor home services, transport, rentals, events & more.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Feature Badges
              _buildFeatureItem(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF00E676),
                title: '100% Verified Partners',
                subtitle: 'Background-checked local experts & technicians',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFFFD54F),
                title: 'Book Now & Direct Enquiry',
                subtitle: 'Instant booking or custom quotation with vendor',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF64B5F6),
                title: 'Transparent Pricing',
                subtitle: 'No hidden charges with direct vendor chats',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFFCE93D8),
                title: 'Direct Vendor Connect',
                subtitle: 'Real-time booking updates & push notifications',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bottom Trust Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD54F),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trusted by 10,000+ Customers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Rated 4.9/5 across Pune & Maharashtra',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
