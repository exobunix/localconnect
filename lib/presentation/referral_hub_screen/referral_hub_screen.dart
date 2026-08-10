import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/referral_service.dart';

class ReferralHubScreen extends StatefulWidget {
  const ReferralHubScreen({super.key});

  @override
  State<ReferralHubScreen> createState() => _ReferralHubScreenState();
}

class _ReferralHubScreenState extends State<ReferralHubScreen>
    with SingleTickerProviderStateMixin {
  String? _referralCode;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _config;
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ReferralService.instance.getOrCreateReferralCode(),
      ReferralService.instance.getReferralStats(),
      ReferralService.instance.getReferralConfig(),
      ReferralService.instance.getReferralRegistrations(),
    ]);
    if (mounted) {
      setState(() {
        _referralCode = results[0] as String?;
        _stats = results[1] as Map<String, dynamic>?;
        _config = results[2] as Map<String, dynamic>?;
        _registrations = (results[3] as List<Map<String, dynamic>>?) ?? [];
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  String get _referralLink => _referralCode != null
      ? ReferralService.instance.getReferralLink(_referralCode!)
      : '';

  String get _shareMessage => _referralCode != null
      ? ReferralService.instance.getReferralShareMessage(_referralCode!)
      : ReferralService.instance.shareMessage;

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _copyCode() async {
    if (_referralCode == null) return;
    await Clipboard.setData(ClipboardData(text: _referralCode!));
    _showSnack('Referral code copied!');
    await ReferralService.instance.logShare(
      shareType: 'referral',
      platform: 'copy_code',
    );
  }

  Future<void> _copyLink() async {
    if (_referralLink.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _referralLink));
    _showSnack('Referral link copied!');
    await ReferralService.instance.logShare(
      shareType: 'referral',
      platform: 'copy_link',
    );
  }

  Future<void> _shareNative() async {
    await Share.share(_shareMessage, subject: 'Join LocalConnect!');
    await ReferralService.instance.logShare(
      shareType: 'referral',
      platform: 'native',
    );
  }

  Future<void> _shareWhatsApp() async {
    final encoded = Uri.encodeComponent(_shareMessage);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await ReferralService.instance.logShare(
        shareType: 'referral',
        platform: 'whatsapp',
      );
    } else {
      _showSnack('WhatsApp is not installed', isError: true);
    }
  }

  Future<void> _shareSms() async {
    final encoded = Uri.encodeComponent(_shareMessage);
    final uri = Uri.parse('sms:?body=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await ReferralService.instance.logShare(
        shareType: 'referral',
        platform: 'sms',
      );
    } else {
      _showSnack('Unable to open SMS app', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildReferralCodeCard(),
                      const SizedBox(height: 20),
                      _buildShareButtons(),
                      const SizedBox(height: 20),
                      if (_config?['is_enabled'] == true &&
                          _config?['reward_type'] != 'none')
                        _buildRewardCard(),
                      if (_config?['is_enabled'] == true &&
                          _config?['reward_type'] != 'none')
                        const SizedBox(height: 20),
                      if (_registrations.isNotEmpty) _buildReferralHistory(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppTheme.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Referral Hub',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1C1E),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Referral Hub',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invite friends, track referrals & earn rewards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalInvites = _stats?['total_clicks'] as int? ?? 0;
    final successfulReg = _stats?['total_registrations'] as int? ?? 0;
    final rewardsEarned =
        (_stats?['total_rewards_earned'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Invitations',
            value: '$totalInvites',
            icon: Icons.send_rounded,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Registered',
            value: '$successfulReg',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Earnings',
            value: rewardsEarned > 0
                ? '₹${rewardsEarned.toStringAsFixed(0)}'
                : '₹0',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Referral Code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode ?? '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _copyCode,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Referral link
          Row(
            children: [
              const Icon(Icons.link_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Shareable Link',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralLink.isNotEmpty ? _referralLink : 'Loading...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _copyLink,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.share_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Share Your Referral',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to invite friends',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          // WhatsApp button
          _buildShareButton(
            label: 'Share via WhatsApp',
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            bgColor: const Color(0xFFE8F8EE),
            onTap: _shareWhatsApp,
          ),
          const SizedBox(height: 10),
          // SMS button
          _buildShareButton(
            label: 'Share via SMS',
            icon: Icons.sms_rounded,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
            onTap: _shareSms,
          ),
          const SizedBox(height: 10),
          // Native share
          _buildShareButton(
            label: 'More Sharing Options',
            icon: Icons.ios_share_rounded,
            color: const Color(0xFF6D28D9),
            bgColor: const Color(0xFFF3E8FF),
            onTap: _shareNative,
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.6),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard() {
    final rewardDesc = _config?['reward_description'] as String? ?? '';
    final rewardValue = _config?['reward_value'] as num? ?? 0;
    final rewardType = _config?['reward_type'] as String? ?? 'none';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFE65100),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referral Reward',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rewardDesc.isNotEmpty
                      ? rewardDesc
                      : 'Earn ${rewardType == 'cash' ? '₹' : ''}${rewardValue.toStringAsFixed(0)} for every successful referral',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Referral History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              Text(
                '${_registrations.length} total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _registrations.length.clamp(0, 20),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final reg = _registrations[index];
              final status = reg['status'] as String? ?? 'registered';
              final createdAt = reg['created_at'] != null
                  ? DateTime.tryParse(reg['created_at'] as String)
                  : null;
              final isVerified = status == 'verified';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isVerified
                      ? const Color(0xFFE8F5E9)
                      : AppTheme.primaryContainer,
                  child: Icon(
                    isVerified
                        ? Icons.check_circle_rounded
                        : Icons.person_add_rounded,
                    color: isVerified
                        ? const Color(0xFF2E7D32)
                        : AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  reg['referred_email'] as String? ??
                      reg['referred_phone'] as String? ??
                      'New User',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                      : 'Recently joined',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isVerified ? 'Verified' : 'Registered',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isVerified
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
