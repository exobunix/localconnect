import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ProviderActionBarWidget extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onBook;
  final VoidCallback onUpiQr;
  final VoidCallback? onMessage;
  final bool showBookNow;

  const ProviderActionBarWidget({
    super.key,
    required this.onCall,
    required this.onWhatsApp,
    required this.onBook,
    required this.onUpiQr,
    this.onMessage,
    this.showBookNow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Call button
          _ActionIconButton(
            icon: Icons.call_rounded,
            label: 'Call',
            color: AppTheme.success,
            onTap: onCall,
          ),
          const SizedBox(width: 8),
          // WhatsApp button
          _ActionIconButton(
            icon: Icons.chat_rounded,
            label: 'Chat',
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
          ),
          const SizedBox(width: 8),
          // Message button
          _ActionIconButton(
            icon: Icons.message_rounded,
            label: 'Message',
            color: AppTheme.primary,
            onTap: onMessage ?? () {},
          ),
          const SizedBox(width: 8),
          // UPI QR button
          _ActionIconButton(
            icon: Icons.qr_code_rounded,
            label: 'Pay',
            color: AppTheme.warning,
            onTap: onUpiQr,
          ),
          if (showBookNow) ...[
            const SizedBox(width: 10),
            // Book Now — gradient button
            Expanded(
              child: GestureDetector(
                onTap: onBook,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Book Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
