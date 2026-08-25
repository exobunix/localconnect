import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ProviderInfoCardWidget extends StatelessWidget {
  final String ownerName;
  final String address;
  final String openHours;
  final String responseTime;
  final int completedOrders;
  final String memberSince;
  final String priceRange;
  final String phone;

  const ProviderInfoCardWidget({
    super.key,
    required this.ownerName,
    required this.address,
    required this.openHours,
    required this.responseTime,
    required this.completedOrders,
    required this.memberSince,
    required this.priceRange,
    this.phone = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: const BorderSide(color: AppTheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner + stats row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    ownerName.substring(0, 2).toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Business Owner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceRange,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                  Text(
                    'Price Range',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _StatChip(
                value: '$completedOrders+',
                label: 'Orders',
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: responseTime,
                label: 'Response',
                icon: Icons.access_time_rounded,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: 'Since $memberSince',
                label: 'Member',
                icon: Icons.verified_rounded,
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Address
          _InfoRow(
            icon: Icons.location_on_rounded,
            text: address,
            color: AppTheme.error,
          ),
          const SizedBox(height: 8),
          // Hours
          _InfoRow(
            icon: Icons.schedule_rounded,
            text: openHours,
            color: AppTheme.success,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_rounded,
              text: phone,
              color: AppTheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF44474E),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
