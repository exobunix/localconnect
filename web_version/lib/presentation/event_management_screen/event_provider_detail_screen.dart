import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class EventProviderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> subcategory;

  const EventProviderDetailScreen({
    super.key,
    required this.provider,
    required this.subcategory,
  });

  @override
  State<EventProviderDetailScreen> createState() =>
      _EventProviderDetailScreenState();
}

class _EventProviderDetailScreenState extends State<EventProviderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPortfolioIndex = 0;
  bool _isFavourite = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _bookedDates = [
    '2026-07-05',
    '2026-07-12',
    '2026-07-18',
    '2026-07-25',
    '2026-08-02',
    '2026-08-10',
  ];

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _color => widget.subcategory['color'] as Color;

  void _showInquirySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InquirySheet(provider: widget.provider, color: _color),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(color: _color),
    );
  }

  Future<void> _launchCall() async {
    final phone = widget.provider['phone'] as String? ?? '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No phone number available.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch phone dialer.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = widget.provider['phone'] as String? ?? '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No phone number available.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
      return;
    }
    final number = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi, I found your profile on LocalConnect and would like to inquire about your event services.',
    );
    final whatsappUri = Uri.parse('https://wa.me/$number?text=$message');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open WhatsApp.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    }
  }

  void _launchChat() {
    Navigator.pushNamed(
      context,
      AppRoutes.chatDetailScreen,
      arguments: {
        'providerId': widget.provider['id'],
        'providerName': widget.provider['name'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = widget.provider;
    final portfolio = (provider['portfolio'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _color,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavourite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavourite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  setState(() => _isFavourite = !_isFavourite);
                  HapticFeedback.lightImpact();
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => HapticFeedback.lightImpact(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) {
                  if (v == 'report') _showReportSheet();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report Provider'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (portfolio.isNotEmpty)
                    PageView.builder(
                      itemCount: portfolio.length,
                      onPageChanged: (i) =>
                          setState(() => _selectedPortfolioIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        portfolio[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: _color.withAlpha(40)),
                        semanticLabel:
                            '${provider['name']} portfolio image ${i + 1}',
                      ),
                    )
                  else
                    Image.network(
                      provider['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: _color.withAlpha(40)),
                      semanticLabel:
                          '${provider['name']} event service provider profile image',
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  if (portfolio.length > 1)
                    Positioned(
                      bottom: 56,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          portfolio.length,
                          (i) => Container(
                            width: i == _selectedPortfolioIndex ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i == _selectedPortfolioIndex
                                  ? Colors.white
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (provider['verified'] == true)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((provider['badge'] as String? ?? '').isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _color,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  provider['badge'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${provider['rating']} (${provider['reviews']} reviews)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white70,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${provider['distance']} km away',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Provider Info Header
            Container(
              color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider['speciality'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 13,
                                  color: _color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${provider['experience']} experience',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Starting from',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatPrice(provider['startingPrice'] as num),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Chat',
                          color: _color,
                          onTap: _launchChat,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          color: _color,
                          onTap: _launchCall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: _launchWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _showInquirySheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Send Inquiry',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: _color,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _color,
                    indicatorWeight: 2.5,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Availability'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    provider: provider,
                    subcategory: widget.subcategory,
                    isDark: isDark,
                    color: _color,
                  ),
                  _PortfolioTab(
                    provider: provider,
                    color: _color,
                    isDark: isDark,
                  ),
                  _AvailabilityTab(
                    bookedDates: _bookedDates,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,
                    color: _color,
                    isDark: isDark,
                    onMonthChanged: (m, y) => setState(() {
                      _selectedMonth = m;
                      _selectedYear = y;
                    }),
                  ),
                  _ReviewsTab(
                    provider: provider,
                    color: _color,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '₹${(price / 1000).toStringAsFixed(0)}K';
    return '₹$price';
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> subcategory;
  final bool isDark;
  final Color color;

  const _OverviewTab({
    required this.provider,
    required this.subcategory,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final details =
        provider['subcategoryDetails'] as Map<String, dynamic>? ?? {};
    final subId = subcategory['id'] as String;
    final tags = (provider['tags'] as List?)?.cast<String>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // About
        _SectionCard(
          title: 'About',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Professional ${subcategory['label']} service provider with ${provider['experience']} of experience. Specializing in ${provider['speciality']}.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Subcategory-specific details
        _SectionCard(
          title: 'Service Details',
          isDark: isDark,
          child: _buildSubcategoryDetails(subId, details, isDark),
        ),
        const SizedBox(height: 12),
        // Quick Info Grid
        _SectionCard(
          title: 'Quick Info',
          isDark: isDark,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _InfoTile(
                icon: Icons.star_rounded,
                label: 'Rating',
                value: '${provider['rating']} ★',
                color: const Color(0xFFFFB300),
              ),
              _InfoTile(
                icon: Icons.reviews_rounded,
                label: 'Reviews',
                value: '${provider['reviews']}',
                color: color,
              ),
              _InfoTile(
                icon: Icons.location_on_rounded,
                label: 'Distance',
                value: '${provider['distance']} km',
                color: color,
              ),
              _InfoTile(
                icon: Icons.work_outline_rounded,
                label: 'Experience',
                value: provider['experience'] as String,
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Location
        _SectionCard(
          title: 'Service Location',
          isDark: isDark,
          child: Column(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, color: color, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        'View on Google Maps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Serves within ${provider['distance']} km radius',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Similar Providers
        _SectionCard(
          title: 'Similar Providers',
          isDark: isDark,
          child: Text(
            'Explore more ${subcategory['label']} providers in your area',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubcategoryDetails(
    String subId,
    Map<String, dynamic> details,
    bool isDark,
  ) {
    switch (subId) {
      case 'photography':
      case 'videography':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['specializations'] != null) ...[
              Text(
                'Specializations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['specializations'] as List)
                    .map<Widget>(
                      (s) => _DetailChip(label: s.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            if (details['equipment'] != null)
              _DetailRow(
                icon: Icons.camera_alt_rounded,
                label: 'Equipment',
                value: details['equipment'].toString(),
                color: color,
              ),
            if (details['albumPackages'] == true)
              _DetailRow(
                icon: Icons.photo_album_rounded,
                label: 'Album Packages',
                value: 'Available',
                color: color,
              ),
            if (details['cinematicVideo'] == true)
              _DetailRow(
                icon: Icons.movie_rounded,
                label: 'Cinematic Video',
                value: 'Available',
                color: color,
              ),
          ],
        );
      case 'sound':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['djPackages'] != null) ...[
              Text(
                'DJ Packages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              ...(details['djPackages'] as List).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(
                        p.toString(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (details['capacity'] != null)
              _DetailRow(
                icon: Icons.people_rounded,
                label: 'Capacity',
                value: details['capacity'].toString(),
                color: color,
              ),
            if (details['indoorOutdoor'] != null)
              _DetailRow(
                icon: Icons.home_rounded,
                label: 'Setup',
                value: details['indoorOutdoor'].toString(),
                color: color,
              ),
            if (details['genres'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Music Genres',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['genres'] as List)
                    .map<Widget>(
                      (g) => _DetailChip(label: g.toString(), color: color),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      case 'catering':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['vegNonVeg'] != null)
              _DetailRow(
                icon: Icons.restaurant_rounded,
                label: 'Menu Type',
                value: details['vegNonVeg'].toString(),
                color: color,
              ),
            if (details['minGuests'] != null)
              _DetailRow(
                icon: Icons.group_rounded,
                label: 'Min Guests',
                value: '${details['minGuests']}',
                color: color,
              ),
            if (details['maxCapacity'] != null)
              _DetailRow(
                icon: Icons.groups_rounded,
                label: 'Max Capacity',
                value: '${details['maxCapacity']} guests',
                color: color,
              ),
            if (details['pricePerPlate'] != null)
              _DetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Price/Plate',
                value: details['pricePerPlate'].toString(),
                color: color,
              ),
            if (details['hygieneCertified'] == true)
              _DetailRow(
                icon: Icons.verified_rounded,
                label: 'Hygiene Certified',
                value: 'Yes',
                color: color,
              ),
            if (details['cuisines'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cuisines',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['cuisines'] as List)
                    .map<Widget>(
                      (c) => _DetailChip(label: c.toString(), color: color),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      case 'makeup':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['makeupTypes'] != null) ...[
              Text(
                'Makeup Types',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['makeupTypes'] as List)
                    .map<Widget>(
                      (m) => _DetailChip(label: m.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (details['brands'] != null)
              _DetailRow(
                icon: Icons.star_rounded,
                label: 'Brands Used',
                value: details['brands'].toString(),
                color: color,
              ),
          ],
        );
      case 'mehendi':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['mehendiStyles'] != null) ...[
              Text(
                'Mehendi Styles',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['mehendiStyles'] as List)
                    .map<Widget>(
                      (s) => _DetailChip(label: s.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (details['pricePerHand'] != null)
              _DetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Price/Hand',
                value: details['pricePerHand'].toString(),
                color: color,
              ),
            if (details['organicHenna'] == true)
              _DetailRow(
                icon: Icons.eco_rounded,
                label: 'Organic Henna',
                value: 'Yes',
                color: color,
              ),
          ],
        );
      case 'band':
      case 'orchestra':
      case 'dance':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['performanceType'] != null)
              _DetailRow(
                icon: Icons.music_note_rounded,
                label: 'Performance Type',
                value: details['performanceType'].toString(),
                color: color,
              ),
            if (details['teamSize'] != null)
              _DetailRow(
                icon: Icons.people_rounded,
                label: 'Team Size',
                value: '${details['teamSize']} members',
                color: color,
              ),
            if (details['duration'] != null)
              _DetailRow(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: details['duration'].toString(),
                color: color,
              ),
            if (details['genres'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Genres',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['genres'] as List)
                    .map<Widget>(
                      (g) => _DetailChip(label: g.toString(), color: color),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      case 'generator':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['capacity'] != null)
              _DetailRow(
                icon: Icons.power_rounded,
                label: 'Capacity',
                value: details['capacity'].toString(),
                color: color,
              ),
            if (details['fuelType'] != null)
              _DetailRow(
                icon: Icons.local_gas_station_rounded,
                label: 'Fuel Type',
                value: details['fuelType'].toString(),
                color: color,
              ),
            if (details['rentalDuration'] != null)
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Rental Duration',
                value: details['rentalDuration'].toString(),
                color: color,
              ),
            if (details['deliveryAvailable'] == true)
              _DetailRow(
                icon: Icons.local_shipping_rounded,
                label: 'Delivery',
                value: 'Available',
                color: color,
              ),
          ],
        );
      case 'chair_table':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['chairTypes'] != null) ...[
              Text(
                'Chair Types',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['chairTypes'] as List)
                    .map<Widget>(
                      (c) => _DetailChip(label: c.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (details['tableTypes'] != null) ...[
              Text(
                'Table Types',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['tableTypes'] as List)
                    .map<Widget>(
                      (t) => _DetailChip(label: t.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (details['quantityAvailable'] != null)
              _DetailRow(
                icon: Icons.inventory_rounded,
                label: 'Quantity',
                value: details['quantityAvailable'].toString(),
                color: color,
              ),
            if (details['deliveryCharges'] != null)
              _DetailRow(
                icon: Icons.local_shipping_rounded,
                label: 'Delivery',
                value: details['deliveryCharges'].toString(),
                color: color,
              ),
          ],
        );
      case 'tent':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details['tentTypes'] != null) ...[
              Text(
                'Tent Types',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: (details['tentTypes'] as List)
                    .map<Widget>(
                      (t) => _DetailChip(label: t.toString(), color: color),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (details['stageSetup'] == true)
              _DetailRow(
                icon: Icons.theater_comedy_rounded,
                label: 'Stage Setup',
                value: 'Available',
                color: color,
              ),
            if (details['decoration'] == true)
              _DetailRow(
                icon: Icons.celebration_rounded,
                label: 'Decoration',
                value: 'Available',
                color: color,
              ),
            if (details['seatingArrangements'] == true)
              _DetailRow(
                icon: Icons.chair_rounded,
                label: 'Seating',
                value: 'Available',
                color: color,
              ),
            if (details['lightingPackages'] == true)
              _DetailRow(
                icon: Icons.lightbulb_rounded,
                label: 'Lighting',
                value: 'Available',
                color: color,
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.entries
              .map(
                (e) => _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: e.key,
                  value: e.value.toString(),
                  color: color,
                ),
              )
              .toList(),
        );
    }
  }
}

// ── Portfolio Tab ─────────────────────────────────────────────────────────────
class _PortfolioTab extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color color;
  final bool isDark;

  const _PortfolioTab({
    required this.provider,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final portfolio = (provider['portfolio'] as List?)?.cast<String>() ?? [];
    final allImages = [provider['image'] as String, ...portfolio];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: allImages.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              allImages[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: color.withAlpha(30)),
              semanticLabel:
                  '${provider['name']} portfolio image showing event service work',
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Availability Tab ──────────────────────────────────────────────────────────
class _AvailabilityTab extends StatelessWidget {
  final List<String> bookedDates;
  final int selectedMonth;
  final int selectedYear;
  final Color color;
  final bool isDark;
  final Function(int, int) onMonthChanged;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const _AvailabilityTab({
    required this.bookedDates,
    required this.selectedMonth,
    required this.selectedYear,
    required this.color,
    required this.isDark,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1).weekday;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2023) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      if (selectedMonth == 1) {
                        onMonthChanged(12, selectedYear - 1);
                      } else {
                        onMonthChanged(selectedMonth - 1, selectedYear);
                      }
                    },
                  ),
                  Text(
                    '${_monthNames[selectedMonth - 1]} $selectedYear',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      if (selectedMonth == 12) {
                        onMonthChanged(1, selectedYear + 1);
                      } else {
                        onMonthChanged(selectedMonth + 1, selectedYear);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _dayNames
                    .map(
                      (d) => SizedBox(
                        width: 36,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: daysInMonth + firstDayOfMonth - 1,
                itemBuilder: (_, i) {
                  if (i < firstDayOfMonth - 1) return const SizedBox();
                  final day = i - firstDayOfMonth + 2;
                  final dateStr =
                      '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                  final isBooked = bookedDates.contains(dateStr);
                  final isToday =
                      DateTime.now().day == day &&
                      DateTime.now().month == selectedMonth &&
                      DateTime.now().year == selectedYear;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? AppTheme.error.withAlpha(30)
                          : isToday
                          ? color.withAlpha(30)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: color, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isBooked
                              ? AppTheme.error
                              : isToday
                              ? color
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                    color: color.withAlpha(30),
                    borderColor: color,
                    label: 'Today',
                  ),
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: AppTheme.error.withAlpha(30),
                    borderColor: Colors.transparent,
                    label: 'Booked',
                  ),
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: Colors.grey.withAlpha(20),
                    borderColor: Colors.transparent,
                    label: 'Available',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2023) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Hours',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...['Monday - Friday', 'Saturday', 'Sunday'].map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          day,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        day == 'Sunday'
                            ? 'By Appointment'
                            : '9:00 AM - 8:00 PM',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;
  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ── Reviews Tab ───────────────────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color color;
  final bool isDark;

  const _ReviewsTab({
    required this.provider,
    required this.color,
    required this.isDark,
  });

  static final _mockReviews = [
    {
      'name': 'Priya Sharma',
      'rating': 5,
      'date': '15 Jun 2026',
      'text':
          'Absolutely amazing service! The quality exceeded our expectations. Highly recommended for any event.',
      'avatar': 'P',
    },
    {
      'name': 'Rahul Mehta',
      'rating': 5,
      'date': '2 Jun 2026',
      'text':
          'Professional, punctual, and delivered exactly what was promised. Will definitely book again.',
      'avatar': 'R',
    },
    {
      'name': 'Anita Patel',
      'rating': 4,
      'date': '20 May 2026',
      'text':
          'Very good service overall. Minor delay but the final result was worth it.',
      'avatar': 'A',
    },
    {
      'name': 'Vikram Singh',
      'rating': 5,
      'date': '10 May 2026',
      'text':
          'Outstanding work! Our guests were thoroughly impressed. Best decision we made for our event.',
      'avatar': 'V',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final rating = provider['rating'] as double;
    final reviews = provider['reviews'] as int;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2023) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    '$rating',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: i < rating.round()
                            ? const Color(0xFFFFB300)
                            : Colors.grey.withAlpha(60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reviews reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final pct = star == 5
                        ? 0.7
                        : star == 4
                        ? 0.2
                        : star == 3
                        ? 0.07
                        : 0.02;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.withAlpha(30),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(pct * 100).toInt()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._mockReviews.map(
          (review) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2023) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withAlpha(30),
                      child: Text(
                        review['avatar'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            review['date'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        review['rating'] as int,
                        (_) => const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review['text'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Inquiry Sheet ─────────────────────────────────────────────────────────────
class _InquirySheet extends StatefulWidget {
  final Map<String, dynamic> provider;
  final Color color;
  const _InquirySheet({required this.provider, required this.color});

  @override
  State<_InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends State<_InquirySheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _contactMethod = 'chat';
  DateTime? _eventDate;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2023) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Inquiry Sent!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.provider['name']} will respond shortly.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(color: widget.color),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Send Inquiry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'to ${widget.provider['name']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField('Your Name', _nameCtrl, Icons.person_rounded),
                  const SizedBox(height: 10),
                  _buildField(
                    'Phone Number',
                    _phoneCtrl,
                    Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  // Event Date
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _eventDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withAlpha(60)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: widget.color,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _eventDate == null
                                ? 'Select Event Date'
                                : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: _eventDate == null ? Colors.grey : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildField(
                    'Message / Requirements',
                    _msgCtrl,
                    Icons.message_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preferred Contact',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        [
                              {
                                'id': 'chat',
                                'label': 'Chat',
                                'icon': Icons.chat_bubble_rounded,
                              },
                              {
                                'id': 'call',
                                'label': 'Call',
                                'icon': Icons.phone_rounded,
                              },
                              {
                                'id': 'whatsapp',
                                'label': 'WhatsApp',
                                'icon': Icons.chat_rounded,
                              },
                            ]
                            .map(
                              (m) => Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _contactMethod = m['id'] as String,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _contactMethod == m['id']
                                          ? widget.color
                                          : widget.color.withAlpha(15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          m['icon'] as IconData,
                                          size: 16,
                                          color: _contactMethod == m['id']
                                              ? Colors.white
                                              : widget.color,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          m['label'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _contactMethod == m['id']
                                                ? Colors.white
                                                : widget.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = _nameCtrl.text.trim();
                        final phone = _phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in your name and phone number')),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final dateStr = _eventDate != null
                              ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                              : DateTime.now().toString().split(' ').first;
                          
                          final startingPrice = widget.provider['starting_price']?.toString() ?? '15000';

                          final res = await SupabaseService.instance.createOrder(
                            providerName: widget.provider['name'] as String? ?? 'Event Partner',
                            providerId: widget.provider['id'] as String?,
                            service: widget.provider['speciality'] as String? ?? 'Event Management',
                            category: 'event_management',
                            scheduledDate: dateStr,
                            scheduledTime: 'On Demand',
                            amount: startingPrice.startsWith('₹') ? startingPrice : '₹$startingPrice',
                            paymentMethod: 'cash',
                            notes: _msgCtrl.text.trim().isNotEmpty 
                                ? 'Contact info: $name ($phone), Method: $_contactMethod | ${_msgCtrl.text.trim()}'
                                : 'Contact info: $name ($phone), Method: $_contactMethod',
                          );

                          if (context.mounted) Navigator.pop(context); // Pop loading dialog

                          if (res != null) {
                            setState(() => _submitted = true);
                          } else {
                            if (mounted) {
                              final errorMsg = SupabaseService.instance.lastOrderError != null
                                  ? 'Failed to send inquiry: ${SupabaseService.instance.lastOrderError}'
                                  : 'Failed to send inquiry. Please try again.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg)),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send Inquiry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: widget.color),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

// ── Report Sheet ──────────────────────────────────────────────────────────────
class _ReportSheet extends StatefulWidget {
  final Color color;
  const _ReportSheet({required this.color});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  bool _submitted = false;

  static const _reasons = [
    'Fake/Misleading information',
    'Inappropriate content',
    'Fraud or scam',
    'Poor service quality',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2023) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Report Submitted',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We will review this report within 24 hours.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(color: widget.color),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Provider',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._reasons.map(
                  (r) => RadioListTile<String>(
                    value: r,
                    groupValue: _selectedReason,
                    onChanged: (v) => setState(() => _selectedReason = v),
                    title: Text(
                      r,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                    activeColor: widget.color,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedReason == null
                        ? null
                        : () => setState(() => _submitted = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Report',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2023) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(60)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
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
