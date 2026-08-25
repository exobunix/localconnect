import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeStatus {
  open,
  closed,
  busy,
  pending,
  approved,
  rejected,
  active,
  inactive,
  urgent,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$3,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: config.$2, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            customLabel ?? config.$1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.$2,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _config() {
    switch (status) {
      case BadgeStatus.open:
        return ('Open Now', const Color(0xFF2E7D32), const Color(0xFFC8E6C9));
      case BadgeStatus.closed:
        return ('Closed', const Color(0xFFC62828), const Color(0xFFFFCDD2));
      case BadgeStatus.busy:
        return ('Busy', const Color(0xFFE65100), const Color(0xFFFFE0B2));
      case BadgeStatus.pending:
        return ('Pending', const Color(0xFFF57C00), const Color(0xFFFFE0B2));
      case BadgeStatus.approved:
        return ('Approved', const Color(0xFF1565C0), const Color(0xFFBBDEFB));
      case BadgeStatus.rejected:
        return ('Rejected', const Color(0xFFC62828), const Color(0xFFFFCDD2));
      case BadgeStatus.active:
        return ('Active', const Color(0xFF2E7D32), const Color(0xFFC8E6C9));
      case BadgeStatus.inactive:
        return ('Inactive', const Color(0xFF74777F), const Color(0xFFF0F0F0));
      case BadgeStatus.urgent:
        return ('Urgent', const Color(0xFFC62828), const Color(0xFFFFCDD2));
    }
  }
}

/// Resolves provider availability status from provider data map.
/// Returns BadgeStatus.open, .busy, or .closed based on is_open and is_busy fields.
BadgeStatus resolveProviderStatus(Map<String, dynamic> provider) {
  final isOpen = provider['is_open'] as bool? ?? true;
  final isBusy = provider['is_busy'] as bool? ?? false;
  if (!isOpen) return BadgeStatus.closed;
  if (isBusy) return BadgeStatus.busy;
  return BadgeStatus.open;
}
