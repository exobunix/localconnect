import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/referral_service.dart';

/// A reusable widget that provides a share button for the app
class ShareAppButton extends StatelessWidget {
  final bool compact;
  final String? label;

  const ShareAppButton({super.key, this.compact = false, this.label});

  Future<void> _share(BuildContext context) async {
    final message = ReferralService.instance.shareMessage;
    await Share.share(message, subject: 'LocalConnect - Local Services App');
    await ReferralService.instance.logShare(
      shareType: 'app',
      platform: 'native',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => _share(context),
        icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
        tooltip: 'Share LocalConnect',
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _share(context),
      icon: const Icon(Icons.share_rounded, size: 16),
      label: Text(
        label ?? 'Share LocalConnect',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Provider promotion tools widget — QR code, social sharing, copy link
class ProviderShareWidget extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String businessName;
  final String category;

  const ProviderShareWidget({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.businessName,
    required this.category,
  });

  @override
  State<ProviderShareWidget> createState() => _ProviderShareWidgetState();
}

class _ProviderShareWidgetState extends State<ProviderShareWidget> {
  bool _showQr = false;

  String get _profileLink =>
      ReferralService.instance.getProviderProfileLink(widget.providerId);

  String get _shareMessage => ReferralService.instance.getProviderShareMessage(
    providerName: widget.providerName,
    businessName: widget.businessName,
    category: widget.category,
    providerId: widget.providerId,
  );

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _profileLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile link copied!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    await ReferralService.instance.logShare(
      shareType: 'provider_profile',
      platform: 'copy',
      providerId: widget.providerId,
    );
  }

  Future<void> _shareNative() async {
    await Share.share(_shareMessage, subject: widget.businessName);
    await ReferralService.instance.logShare(
      shareType: 'provider_profile',
      platform: 'native',
      providerId: widget.providerId,
    );
  }

  Future<void> _shareVia(String platform) async {
    String url;
    final encoded = Uri.encodeComponent(_shareMessage);
    switch (platform) {
      case 'whatsapp':
        url = 'https://wa.me/?text=$encoded';
        break;
      case 'telegram':
        url =
            'https://t.me/share/url?url=${Uri.encodeComponent(_profileLink)}&text=${Uri.encodeComponent(_shareMessage)}';
        break;
      case 'facebook':
        url =
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_profileLink)}';
        break;
      case 'email':
        url =
            'mailto:?subject=${Uri.encodeComponent('Check out ${widget.businessName} on LocalConnect')}&body=$encoded';
        break;
      case 'sms':
        url = 'sms:?body=$encoded';
        break;
      default:
        await _shareNative();
        return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _shareNative();
    }
    await ReferralService.instance.logShare(
      shareType: 'provider_profile',
      platform: platform,
      providerId: widget.providerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promote My Business',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      'Share your profile to get more customers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Social platform buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialBtn(
                'WhatsApp',
                Icons.chat_rounded,
                const Color(0xFF25D366),
                'whatsapp',
              ),
              _buildSocialBtn(
                'Facebook',
                Icons.facebook_rounded,
                const Color(0xFF1877F2),
                'facebook',
              ),
              _buildSocialBtn(
                'Telegram',
                Icons.send_rounded,
                const Color(0xFF0088CC),
                'telegram',
              ),
              _buildSocialBtn(
                'SMS',
                Icons.sms_rounded,
                const Color(0xFF4CAF50),
                'sms',
              ),
              _buildSocialBtn(
                'Email',
                Icons.email_rounded,
                const Color(0xFFEA4335),
                'email',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Copy link + Share buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: Text(
                    'Copy Link',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareNative,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    'Share',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // QR Code toggle
          GestureDetector(
            onTap: () => setState(() => _showQr = !_showQr),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _showQr ? 'Hide QR Code' : 'Show My QR Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showQr
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_showQr) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: PrettyQrView.data(
                        data: _profileLink,
                        decoration: const PrettyQrDecoration(
                          shape: PrettyQrSmoothSymbol(color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to view my profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'Powered by LocalConnect',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialBtn(
    String label,
    IconData icon,
    Color color,
    String platform,
  ) {
    return GestureDetector(
      onTap: () => _shareVia(platform),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success screen share prompt widget
class SuccessSharePromptWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onShareApp;
  final VoidCallback? onInviteFriends;

  const SuccessSharePromptWidget({
    super.key,
    this.title = 'Enjoying LocalConnect?',
    this.onShareApp,
    this.onInviteFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFE91E63),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Help your friends discover trusted local services.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      onShareApp ??
                      () async {
                        final message = ReferralService.instance.shareMessage;
                        await Share.share(message, subject: 'LocalConnect App');
                        await ReferralService.instance.logShare(
                          shareType: 'app',
                          platform: 'native',
                        );
                      },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    'Share App',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      onInviteFriends ??
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.inviteFriendsScreen,
                      ),
                  icon: const Icon(Icons.people_rounded, size: 16),
                  label: Text(
                    'Invite Friends',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
