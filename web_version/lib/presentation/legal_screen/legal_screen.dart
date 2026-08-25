import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _loadingPrefs = true;

  static const _keyPrivacy = 'legal_privacy_accepted';
  static const _keyTerms = 'legal_terms_accepted';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAcceptance();
  }

  Future<void> _loadAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _privacyAccepted = prefs.getBool(_keyPrivacy) ?? false;
        _termsAccepted = prefs.getBool(_keyTerms) ?? false;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _setPrivacyAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacy, value);
    if (mounted) setState(() => _privacyAccepted = value);
  }

  Future<void> _setTermsAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTerms, value);
    if (mounted) setState(() => _termsAccepted = value);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['tab'] as int? ?? 0;
    if (_tabController.index != initialTab) {
      _tabController.animateTo(initialTab);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Legal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_loadingPrefs)
            Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: Row(
                children: [
                  _AcceptanceDot(accepted: _privacyAccepted, label: 'PP'),
                  SizedBox(width: 1.5.w),
                  _AcceptanceDot(accepted: _termsAccepted, label: 'ToS'),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6F00),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Privacy Policy'),
                  if (_privacyAccepted) ...[
                    SizedBox(width: 1.w),
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Terms of Service'),
                  if (_termsAccepted) ...[
                    SizedBox(width: 1.w),
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PrivacyPolicyContent(
                  accepted: _privacyAccepted,
                  onAcceptChanged: _setPrivacyAccepted,
                ),
                _TermsOfServiceContent(
                  accepted: _termsAccepted,
                  onAcceptChanged: _setTermsAccepted,
                ),
              ],
            ),
    );
  }
}

class _AcceptanceDot extends StatelessWidget {
  final bool accepted;
  final String label;

  const _AcceptanceDot({required this.accepted, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accepted
            ? const Color(0xFF4CAF50).withAlpha(51)
            : Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: accepted
              ? const Color(0xFF4CAF50)
              : Colors.white.withAlpha(77),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
          color: accepted ? const Color(0xFF4CAF50) : Colors.white60,
        ),
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onAcceptChanged;

  const _PrivacyPolicyContent({
    required this.accepted,
    required this.onAcceptChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Privacy Policy', 'Last updated: June 24, 2025'),
          _buildSection(
            'Introduction',
            'LocalConnect ("we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
          ),
          _buildSection(
            'Information We Collect',
            '• Personal Information: Name, email address, phone number, and profile photo when you register.\n\n'
                '• Location Data: We collect your location to show nearby service providers. Location access is only used while the app is in use.\n\n'
                '• Usage Data: Information about how you interact with the app, including pages visited, features used, and time spent.\n\n'
                '• Device Information: Device type, operating system, and unique device identifiers.\n\n'
                '• Payment Information: We do not store payment card details. Payments are processed securely through UPI and other payment gateways.',
          ),
          _buildSection(
            'How We Use Your Information',
            '• To provide and maintain our service\n'
                '• To match customers with local service providers\n'
                '• To process bookings and payments\n'
                '• To send notifications about your bookings\n'
                '• To improve our app and user experience\n'
                '• To comply with legal obligations',
          ),
          _buildSection(
            'Data Sharing',
            'We do not sell your personal data. We may share your information with:\n\n'
                '• Service Providers: To fulfill your service requests\n'
                '• Payment Processors: To complete transactions\n'
                '• Legal Authorities: When required by law',
          ),
          _buildSection(
            'Data Security',
            'We implement industry-standard security measures including encryption in transit (TLS) and at rest. Your data is stored on secure Supabase servers.',
          ),
          _buildSection(
            'Your Rights',
            '• Access and update your personal information\n'
                '• Request deletion of your account and data\n'
                '• Opt out of marketing communications\n'
                '• Data portability upon request',
          ),
          _buildSection(
            'Children\'s Privacy',
            'LocalConnect is not intended for users under 18 years of age. We do not knowingly collect personal information from minors.',
          ),
          _buildSection(
            'Contact Us',
            'For privacy-related questions, contact us at:\nsupport@localconnect.app',
          ),
          SizedBox(height: 2.h),
          _AcceptanceCard(
            accepted: accepted,
            onChanged: onAcceptChanged,
            title: 'Accept Privacy Policy',
            description:
                'I have read and agree to the LocalConnect Privacy Policy, including how my personal data is collected, used, and protected.',
            acceptedLabel: 'Privacy Policy Accepted',
            pendingLabel: 'Accept Privacy Policy',
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

class _TermsOfServiceContent extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onAcceptChanged;

  const _TermsOfServiceContent({
    required this.accepted,
    required this.onAcceptChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Terms of Service', 'Last updated: June 24, 2025'),
          _buildSection(
            'Acceptance of Terms',
            'By downloading, installing, or using LocalConnect, you agree to be bound by these Terms of Service. If you do not agree, please do not use our application.',
          ),
          _buildSection(
            'Description of Service',
            'LocalConnect is a platform that connects customers with local service providers including plumbers, electricians, cleaners, tutors, and other professionals in your area.',
          ),
          _buildSection(
            'User Accounts',
            '• You must be at least 18 years old to create an account\n'
                '• You are responsible for maintaining the confidentiality of your account credentials\n'
                '• You agree to provide accurate and complete information\n'
                '• You are responsible for all activities under your account',
          ),
          _buildSection(
            'Service Provider Terms',
            '• Providers must complete identity verification before offering services\n'
                '• Providers are independent contractors, not employees of LocalConnect\n'
                '• Providers must maintain appropriate licenses and certifications\n'
                '• LocalConnect reserves the right to suspend providers for policy violations',
          ),
          _buildSection(
            'Booking and Payments',
            '• All bookings are subject to provider availability and confirmation\n'
                '• Payments are processed securely through our payment partners\n'
                '• Cancellation policies vary by service provider\n'
                '• LocalConnect charges a platform fee on each transaction',
          ),
          _buildSection(
            'Prohibited Activities',
            '• Fraudulent bookings or payments\n'
                '• Harassment or abuse of other users\n'
                '• Sharing false or misleading information\n'
                '• Attempting to circumvent the platform for direct payments\n'
                '• Reverse engineering or tampering with the application',
          ),
          _buildSection(
            'Limitation of Liability',
            'LocalConnect acts as an intermediary platform. We are not liable for the quality of services provided by independent service providers. Our liability is limited to the platform fee charged for the transaction.',
          ),
          _buildSection(
            'Dispute Resolution',
            'In case of disputes between customers and providers, LocalConnect offers a mediation service. Unresolved disputes shall be subject to arbitration under Indian law.',
          ),
          _buildSection(
            'Governing Law',
            'These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in India.',
          ),
          _buildSection(
            'Changes to Terms',
            'We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.',
          ),
          _buildSection(
            'Contact Us',
            'For questions about these Terms, contact us at:\nsupport@localconnect.app',
          ),
          SizedBox(height: 2.h),
          _AcceptanceCard(
            accepted: accepted,
            onChanged: onAcceptChanged,
            title: 'Accept Terms of Service',
            description:
                'I have read and agree to the LocalConnect Terms of Service, including the rules, responsibilities, and limitations described above.',
            acceptedLabel: 'Terms of Service Accepted',
            pendingLabel: 'Accept Terms of Service',
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

class _AcceptanceCard extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final String title;
  final String description;
  final String acceptedLabel;
  final String pendingLabel;

  const _AcceptanceCard({
    required this.accepted,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.acceptedLabel,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFF4CAF50).withAlpha(15) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: accepted ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
          width: accepted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accepted ? Icons.verified_rounded : Icons.gavel_rounded,
                color: accepted
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF0D1B4B),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: accepted
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF0D1B4B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFF555555),
              height: 1.5,
            ),
          ),
          SizedBox(height: 2.h),
          InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: accepted
                    ? const Color(0xFF4CAF50).withAlpha(26)
                    : const Color(0xFF0D1B4B).withAlpha(13),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      accepted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      key: ValueKey(accepted),
                      color: accepted
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF0D1B4B),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      accepted ? acceptedLabel : pendingLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: accepted
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF0D1B4B),
                      ),
                    ),
                  ),
                  if (accepted)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          if (accepted) ...[
            SizedBox(height: 1.h),
            Text(
              'Tap the checkbox above to withdraw your acceptance.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: const Color(0xFF888888),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildHeader(String title, String subtitle) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(4.w),
    margin: EdgeInsets.only(bottom: 3.h),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D1B4B), Color(0xFF1A237E)],
      ),
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSection(String title, String content) {
  return Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: 2.h),
    padding: EdgeInsets.all(4.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D1B4B),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5.sp,
            color: const Color(0xFF555555),
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
