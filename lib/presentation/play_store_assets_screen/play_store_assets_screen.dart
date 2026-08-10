import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class PlayStoreAssetsScreen extends StatefulWidget {
  const PlayStoreAssetsScreen({super.key});

  @override
  State<PlayStoreAssetsScreen> createState() => _PlayStoreAssetsScreenState();
}

class _PlayStoreAssetsScreenState extends State<PlayStoreAssetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primaryBlue = Color(0xFF1A237E);
  static const Color _accentBlue = Color(0xFF1565C0);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied!'),
        backgroundColor: _accentBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Play Store Assets',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 11.sp,
          ),
          tabs: const [
            Tab(text: 'Listing'),
            Tab(text: 'Screenshots'),
            Tab(text: 'Legal'),
            Tab(text: 'Promo'),
            Tab(text: 'Social'),
            Tab(text: 'QR Poster'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingTab(),
          _buildScreenshotsTab(),
          _buildLegalTab(),
          _buildPromoTab(),
          _buildSocialTab(),
          _buildQrPosterTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Play Store Listing Content ─────────────────────────────────────
  Widget _buildListingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('📱 App Title', Icons.title),
          _copyCard('LocalConnect – Local Services App', 'App Title'),
          SizedBox(height: 2.h),
          _sectionHeader('📝 Short Description (80 chars)', Icons.short_text),
          _copyCard(
            'Find trusted electricians, plumbers, transport & more near you.',
            'Short Description',
          ),
          SizedBox(height: 2.h),
          _sectionHeader('📄 Full Description', Icons.description),
          _copyCard(_fullDescription, 'Full Description', maxLines: 8),
          SizedBox(height: 2.h),
          _sectionHeader('✨ App Highlights', Icons.star),
          _highlightsList(),
          SizedBox(height: 2.h),
          _sectionHeader('🔑 Keywords', Icons.tag),
          _copyCard(
            'local services, electrician, plumber, carpenter, transport, event management, grocery delivery, rent, home maintenance, service booking, local business, India',
            'Keywords',
          ),
          SizedBox(height: 2.h),
          _sectionHeader("🆕 What's New Template", Icons.new_releases),
          _copyCard(_whatsNewTemplate, "What's New", maxLines: 6),
        ],
      ),
    );
  }

  // ── TAB 2: Screenshots ────────────────────────────────────────────────────
  Widget _buildScreenshotsTab() {
    final screenshots = [
      {
        'asset': 'assets/images/screenshot_01_login.png',
        'title': 'Login Screen',
        'caption': 'Secure OTP & Google Sign-In',
      },
      {
        'asset': 'assets/images/screenshot_02_home_dashboard.png',
        'title': 'Home Dashboard',
        'caption': 'All Services at Your Fingertips',
      },
      {
        'asset': 'assets/images/screenshot_03_search.png',
        'title': 'Smart Search',
        'caption': 'Find Providers Near You Instantly',
      },
      {
        'asset': 'assets/images/screenshot_04_categories.png',
        'title': 'All Categories',
        'caption': '15+ Service Categories Available',
      },
      {
        'asset': 'assets/images/screenshot_05_provider_listing.png',
        'title': 'Provider Listing',
        'caption': 'Verified & Rated Local Providers',
      },
      {
        'asset': 'assets/images/screenshot_06_provider_dashboard.png',
        'title': 'Provider Dashboard',
        'caption': 'Manage Your Business Easily',
      },
      {
        'asset': 'assets/images/screenshot_07_customer_profile.png',
        'title': 'Customer Profile',
        'caption': 'Track Bookings & Referrals',
      },
      {
        'asset': 'assets/images/screenshot_08_subscription.png',
        'title': 'Subscription Plans',
        'caption': 'Flexible Plans for Every Need',
      },
      {
        'asset': 'assets/images/screenshot_09_booking_flow.png',
        'title': 'Booking Flow',
        'caption': 'Book in 3 Simple Steps',
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            '📸 Play Store Screenshots',
            '9 high-quality screenshots generated. Upload these to Google Play Console under "Phone Screenshots" section.',
          ),
          SizedBox(height: 2.h),
          ...screenshots.map((s) => _screenshotCard(s)),
        ],
      ),
    );
  }

  // ── TAB 3: Legal Pages ────────────────────────────────────────────────────
  Widget _buildLegalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🔒 Privacy Policy', Icons.privacy_tip),
          _copyCard(_privacyPolicy, 'Privacy Policy', maxLines: 8),
          SizedBox(height: 2.h),
          _sectionHeader('📋 Terms & Conditions', Icons.gavel),
          _copyCard(_termsConditions, 'Terms & Conditions', maxLines: 8),
          SizedBox(height: 2.h),
          _sectionHeader('❓ Help & FAQ', Icons.help),
          _faqList(),
          SizedBox(height: 2.h),
          _sectionHeader('📞 Support & Contact', Icons.support_agent),
          _contactInfo(),
          SizedBox(height: 2.h),
          _sectionHeader('ℹ️ About Us', Icons.info),
          _copyCard(_aboutUs, 'About Us', maxLines: 6),
        ],
      ),
    );
  }

  // ── TAB 4: Promotional Graphics ───────────────────────────────────────────
  Widget _buildPromoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎨 Feature Graphic (1024×500)', Icons.image),
          _assetPreviewCard(
            'assets/images/localconnect_feature_graphic_1024x500.png',
            'Feature Graphic',
            '1024 × 500 px — Upload to Play Console',
          ),
          SizedBox(height: 2.h),
          _sectionHeader('📢 Google Play Banner', Icons.campaign),
          _assetPreviewCard(
            'assets/images/promo_google_play_banner.png',
            'Now Available on Google Play',
            '1200 × 628 px — For social sharing',
          ),
          SizedBox(height: 2.h),
          _sectionHeader('📣 Referral Campaign Banner', Icons.people),
          _promoMessageCard(
            'Referral Campaign',
            '🎁 Invite friends to LocalConnect and earn rewards!\nShare your unique referral code and get benefits when they register.',
            Icons.card_giftcard,
          ),
          SizedBox(height: 2.h),
          _sectionHeader('🏪 Provider Onboarding Banner', Icons.store),
          _promoMessageCard(
            'Provider Onboarding',
            '💼 Grow Your Business with LocalConnect!\nRegister as a service provider and reach thousands of customers in your area. Free registration. Start earning today!',
            Icons.business_center,
          ),
          SizedBox(height: 2.h),
          _sectionHeader('👥 Customer Invitation Banner', Icons.person_add),
          _promoMessageCard(
            'Customer Invitation',
            '🏠 Need a trusted electrician, plumber, or any home service?\nDownload LocalConnect — All Local Services in One App!\nAvailable on Google Play: local-connect.co.in',
            Icons.download,
          ),
        ],
      ),
    );
  }

  // ── TAB 5: Social Media Assets ────────────────────────────────────────────
  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('📸 Instagram Post (1080×1080)', Icons.photo_camera),
          _assetPreviewCard(
            'assets/images/social_media_instagram_post.png',
            'Instagram Square Post',
            '1080 × 1080 px — Ready to post',
          ),
          SizedBox(height: 2.h),
          _sectionHeader('📘 Facebook Post Caption', Icons.facebook),
          _copyCard(_facebookCaption, 'Facebook Caption'),
          SizedBox(height: 2.h),
          _sectionHeader('💬 WhatsApp Business Message', Icons.chat),
          _copyCard(_whatsappMessage, 'WhatsApp Message'),
          SizedBox(height: 2.h),
          _sectionHeader('💼 LinkedIn Post', Icons.work),
          _copyCard(_linkedinPost, 'LinkedIn Post', maxLines: 6),
          SizedBox(height: 2.h),
          _sectionHeader('🎬 YouTube Description', Icons.play_circle),
          _copyCard(_youtubeDescription, 'YouTube Description', maxLines: 6),
          SizedBox(height: 2.h),
          _sectionHeader('📱 App Icon (512×512)', Icons.apps),
          _assetPreviewCard(
            'assets/images/localconnect_app_icon_512.png',
            'App Icon',
            '512 × 512 px — Upload to Play Console',
          ),
        ],
      ),
    );
  }

  // ── TAB 6: QR Poster ──────────────────────────────────────────────────────
  Widget _buildQrPosterTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🖨️ A4 Printable Poster', Icons.print),
          _assetPreviewCard(
            'assets/images/qr_poster_a4_printable.png',
            'QR Code Download Poster',
            'A4 (794 × 1123 px) — Print-ready',
          ),
          SizedBox(height: 2.h),
          _infoCard(
            '📌 How to Use This Poster',
            '1. Generate your actual Play Store QR code from play.google.com after publishing\n'
                '2. Replace the QR placeholder with the real QR code\n'
                '3. Print on A4 paper (glossy recommended)\n'
                '4. Display at your business location, events, or distribute digitally\n'
                '5. Website: local-connect.co.in',
          ),
          SizedBox(height: 2.h),
          _sectionHeader('📋 Production Readiness Checklist', Icons.checklist),
          _checklistWidget(),
        ],
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, color: _primaryBlue, size: 18.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyCard(String content, String label, {int maxLines = 4}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey[800],
                height: 1.5,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          TextButton.icon(
            onPressed: () => _copyToClipboard(content, label),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(
              'Copy $label',
              style: GoogleFonts.inter(fontSize: 11.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _accentBlue,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetPreviewCard(String assetPath, String title, String subtitle) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12.0),
            ),
            child: Image.asset(
              assetPath,
              width: double.infinity,
              height: 20.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 20.h,
                color: _lightBlue,
                child: Center(
                  child: Icon(Icons.image, color: _primaryBlue, size: 30.sp),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryBlue,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenshotCard(Map<String, String> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12.0),
            ),
            child: Image.asset(
              data['asset']!,
              width: 25.w,
              height: 14.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 25.w,
                height: 14.h,
                color: _lightBlue,
                child: Icon(Icons.phone_android, color: _primaryBlue),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']!,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    data['caption']!,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      '✓ Ready',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightsList() {
    final highlights = [
      '🔍 Find 15+ local service categories in one app',
      '✅ Verified & rated service providers',
      '📍 Location-based provider discovery',
      '💬 Real-time chat with providers',
      '📅 Easy booking with date & time selection',
      '💳 Secure Razorpay payment integration',
      '🔔 Real-time booking status notifications',
      '⭐ Review and rate service providers',
      '🏪 Virtual shop for grocery & hardware orders',
      '🚗 Transport & logistics booking',
      '🎉 Event management services',
      '🏠 Rent & PG listing discovery',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Column(
        children: highlights
            .map(
              (h) => ListTile(
                dense: true,
                title: Text(
                  h,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _faqList() {
    final faqs = [
      {
        'q': 'How do I book a service?',
        'a':
            'Search for the service you need, select a provider, choose date & time, and confirm your booking. Payment can be made online or in cash.',
      },
      {
        'q': 'How do I register as a service provider?',
        'a':
            'Tap "Register as Provider" on the login screen, fill in your business details, upload KYC documents, and wait for admin approval (usually within 24 hours).',
      },
      {
        'q': 'Is the app free to use?',
        'a':
            'Yes! The app is free to download and use. Providers can subscribe to premium plans for additional features and visibility.',
      },
      {
        'q': 'How do I cancel a booking?',
        'a':
            'Go to My Bookings, select the booking you want to cancel, and tap "Cancel Booking". Cancellation policies may apply.',
      },
      {
        'q': 'Is my payment secure?',
        'a':
            'Yes. All payments are processed through Razorpay, a PCI-DSS compliant payment gateway with bank-level security.',
      },
      {
        'q': 'How do I contact support?',
        'a':
            'Go to Profile > Support, or email us at support@local-connect.co.in. We respond within 24 hours.',
      },
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final faq = entry.value;
          return ExpansionTile(
            title: Text(
              faq['q']!,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                child: Text(
                  faq['a']!,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _contactInfo() {
    final contacts = [
      {
        'icon': Icons.email,
        'label': 'Email',
        'value': 'support@local-connect.co.in',
      },
      {
        'icon': Icons.language,
        'label': 'Website',
        'value': 'www.local-connect.co.in',
      },
      {
        'icon': Icons.location_on,
        'label': 'Address',
        'value': 'Maharashtra, India',
      },
      {
        'icon': Icons.access_time,
        'label': 'Support Hours',
        'value': 'Mon–Sat, 9 AM – 6 PM IST',
      },
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Column(
        children: contacts
            .map(
              (c) => ListTile(
                leading: Icon(c['icon'] as IconData, color: _accentBlue),
                title: Text(
                  c['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                subtitle: Text(
                  c['value'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: _accentBlue,
                  onPressed: () => _copyToClipboard(
                    c['value'] as String,
                    c['label'] as String,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _promoMessageCard(String title, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentBlue, size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          SizedBox(height: 1.h),
          TextButton.icon(
            onPressed: () => _copyToClipboard(message, title),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(
              'Copy Message',
              style: GoogleFonts.inter(fontSize: 10.sp),
            ),
            style: TextButton.styleFrom(foregroundColor: _accentBlue),
          ),
        ],
      ),
    );
  }

  Widget _checklistWidget() {
    final items = [
      {'done': true, 'text': 'App Icon 512×512 PNG generated'},
      {'done': true, 'text': 'Feature Graphic 1024×500 generated'},
      {'done': true, 'text': '9 Play Store screenshots created'},
      {'done': true, 'text': 'App title (≤50 chars) prepared'},
      {'done': true, 'text': 'Short description (≤80 chars) prepared'},
      {'done': true, 'text': 'Full description (≤4000 chars) prepared'},
      {'done': true, 'text': 'Privacy Policy content ready'},
      {'done': true, 'text': 'Terms & Conditions content ready'},
      {'done': true, 'text': 'FAQ & Support content ready'},
      {'done': true, 'text': 'Promotional banners created'},
      {'done': true, 'text': 'Social media assets generated'},
      {'done': true, 'text': 'A4 QR poster designed'},
      {'done': false, 'text': 'Replace QR placeholder with real Play Store QR'},
      {'done': false, 'text': 'Upload app to Google Play Console'},
      {'done': false, 'text': 'Set content rating in Play Console'},
      {'done': false, 'text': 'Add Play Store URL to share messages'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _lightBlue, width: 1.5),
      ),
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                dense: true,
                leading: Icon(
                  item['done'] as bool
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item['done'] as bool ? Colors.green : Colors.orange,
                  size: 18.sp,
                ),
                title: Text(
                  item['text'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: item['done'] as bool
                        ? Colors.grey[700]
                        : Colors.orange[800],
                    decoration: item['done'] as bool
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Content Strings ───────────────────────────────────────────────────────

  static const String _fullDescription =
      '''LocalConnect is your one-stop platform for discovering and booking trusted local service providers in your area.

🔧 HOME SERVICES
Find verified electricians, plumbers, carpenters, painters, masons, cleaners, and daily wage workers near you. Book with confidence knowing every provider is reviewed and rated by real customers.

🚗 TRANSPORT & LOGISTICS
Book ride services, goods transport, and logistics solutions for your personal and business needs. Get real-time tracking and transparent pricing.

🎉 EVENT MANAGEMENT
Plan your perfect event with our network of photographers, decorators, caterers, sound & DJ services, makeup artists, and mehndi artists.

🛒 VIRTUAL SHOP
Order groceries, vegetables, meat, electrical hardware, and plumbing supplies from local shops with doorstep delivery.

🏠 RENT & PG
Find rooms, PG accommodations, hostels, villas, and rental tools in your locality.

💡 WHY LOCALCONNECT?
✅ Verified & KYC-approved providers
✅ Real-time booking status updates
✅ Secure Razorpay payment gateway
✅ In-app chat with providers
✅ Review & rating system
✅ Referral rewards program
✅ Available in English & Marathi

📍 Supporting local businesses and connecting communities across Maharashtra.

Download LocalConnect today and experience the convenience of having all local services at your fingertips!''';

  static const String _whatsNewTemplate = '''Version X.X.X — What's New

🆕 New Features:
• [Feature 1 description]
• [Feature 2 description]

🐛 Bug Fixes:
• Improved booking confirmation flow
• Fixed notification delivery issues

⚡ Performance:
• Faster app startup
• Smoother animations

Thank you for using LocalConnect! Rate us if you enjoy the app. ⭐''';

  static const String _privacyPolicy = '''PRIVACY POLICY — LocalConnect

Last Updated: July 2025

1. INFORMATION WE COLLECT
We collect information you provide directly: name, phone number, email, address, and profile photo. We also collect location data (with permission) to show nearby providers, and usage data to improve the app.

2. HOW WE USE YOUR INFORMATION
• To provide and improve our services
• To connect customers with service providers
• To process payments securely via Razorpay
• To send booking confirmations and notifications
• To verify provider identity through KYC

3. DATA SHARING
We do not sell your personal data. We share data only with:
• Service providers you book
• Razorpay for payment processing
• Twilio for OTP verification

4. DATA SECURITY
All data is encrypted in transit (HTTPS/TLS). Passwords are hashed. Payment data is handled by PCI-DSS compliant Razorpay.

5. YOUR RIGHTS
You may request data deletion by contacting support@local-connect.co.in. Account deletion removes all personal data within 30 days.

6. CONTACT
Email: support@local-connect.co.in
Website: www.local-connect.co.in''';

  static const String _termsConditions = '''TERMS & CONDITIONS — LocalConnect

Last Updated: July 2025

1. ACCEPTANCE
By using LocalConnect, you agree to these Terms. If you disagree, please do not use the app.

2. USER ACCOUNTS
You must provide accurate information when registering. You are responsible for maintaining account security. One account per person.

3. SERVICE PROVIDERS
Providers must complete KYC verification. LocalConnect is a platform connecting customers and providers — we are not responsible for service quality disputes.

4. PAYMENTS
Payments are processed securely via Razorpay. Refund policies are subject to provider terms and LocalConnect's dispute resolution process.

5. PROHIBITED CONDUCT
• Providing false information
• Harassment or abuse of other users
• Fraudulent bookings or payments
• Misuse of the referral system

6. LIMITATION OF LIABILITY
LocalConnect is not liable for damages arising from service provider actions. Our liability is limited to the amount paid for the specific service.

7. TERMINATION
We reserve the right to suspend accounts that violate these terms.

8. CONTACT
Email: legal@local-connect.co.in''';

  static const String _aboutUs = '''About LocalConnect

LocalConnect is a Made-in-India platform dedicated to empowering local service providers and making quality services accessible to every household.

Our Mission: To digitize and connect local service ecosystems, enabling skilled workers to grow their businesses while giving customers a trusted, convenient way to find help.

Founded in Maharashtra, we serve communities across the state with 15+ service categories, verified providers, and a seamless booking experience.

We believe in:
• Supporting local businesses
• Creating employment opportunities
• Building trust through transparency
• Making technology accessible to all

Website: www.local-connect.co.in
Email: hello@local-connect.co.in''';

  static const String _facebookCaption =
      '''🏠 Tired of searching for reliable local services?

LocalConnect brings all local services to your phone!
⚡ Electricians | 🔧 Plumbers | 🚗 Transport | 🎉 Events | 🛒 Grocery & more

✅ Verified providers
✅ Real-time booking
✅ Secure payments

Download FREE on Google Play 👇
🌐 local-connect.co.in

#LocalConnect #LocalServices #Maharashtra #HomeServices #BookNow''';

  static const String _whatsappMessage = '''🙏 नमस्कार!

LocalConnect वापरून बघा — एका अॅपमध्ये सर्व स्थानिक सेवा!

⚡ इलेक्ट्रिशियन
🔧 प्लंबर
🚗 वाहतूक
🎉 इव्हेंट सेवा
🛒 किराणा डिलिव्हरी

आत्ताच डाउनलोड करा: local-connect.co.in

Looking for trusted local services? I use LocalConnect to find electricians, plumbers, transport, event services and many more. Download the app: local-connect.co.in''';

  static const String _linkedinPost =
      '''Excited to share LocalConnect — a platform transforming how local service businesses operate in Maharashtra! 🚀

LocalConnect connects skilled service providers (electricians, plumbers, carpenters, transport operators, event managers) with customers through a seamless mobile app.

Key features:
→ KYC-verified provider profiles
→ Real-time booking & tracking
→ Secure Razorpay payments
→ In-app messaging
→ Review & rating system
→ Referral rewards program

Supporting local businesses and creating digital opportunities for skilled workers.

🌐 local-connect.co.in

#LocalConnect #MadeInIndia #LocalBusiness #Maharashtra #ServicePlatform #StartupIndia''';

  static const String _youtubeDescription =
      '''LocalConnect — All Local Services in One App!

Find and book trusted local service providers near you. Electricians, plumbers, carpenters, transport, event management, grocery delivery, and much more!

📱 Download Free: local-connect.co.in

FEATURES:
✅ 15+ service categories
✅ Verified & rated providers
✅ Real-time booking
✅ Secure payments
✅ In-app chat
✅ Location-based discovery

TIMESTAMPS:
0:00 Introduction
0:30 How to search services
1:00 Booking a provider
1:30 Provider dashboard
2:00 Payment & confirmation

Subscribe for more updates!

#LocalConnect #LocalServices #HomeServices #Maharashtra''';
}
