import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../quotation_screen/customer_enquiry_screen.dart';

/// Customer-facing Provider Public Profile Screen
/// Shows full provider profile with call/WhatsApp/message/book/share/favourite
class ProviderPublicProfileScreen extends StatefulWidget {
  const ProviderPublicProfileScreen({super.key});

  @override
  State<ProviderPublicProfileScreen> createState() =>
      _ProviderPublicProfileScreenState();
}

class _ProviderPublicProfileScreenState
    extends State<ProviderPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollCtrl = ScrollController();
  bool _isAppBarCollapsed = false;

  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _serviceCharges = [];
  Map<String, dynamic>? _fareConfig;
  Map<String, dynamic>? _portfolio;
  List<Map<String, dynamic>> _packages = [];
  List<String> _galleryPhotos = [];

  bool _isLoading = true;
  bool _isFavorite = false;
  String? _providerId;
  String? _category;

  List<Map<String, dynamic>> _reviews = [];
  bool _reviewsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.offset > 220;
      if (collapsed != _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = collapsed);
      }
    });
    _tabController.addListener(() {
      if (_tabController.index == 3 && _reviews.isEmpty && !_reviewsLoading) {
        _loadReviews();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _providerId == null) {
      _providerId = args['providerId'] as String?;
      _category = args['category'] as String?;
      _loadAll();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadProvider(),
        _loadServiceCharges(),
        _loadFareConfig(),
        _loadPortfolio(),
        _loadPackages(),
        _loadGallery(),
        _checkFavorite(),
        _loadReviews(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadReviews() async {
    if (_providerId == null) return;
    setState(() => _reviewsLoading = true);
    try {
      final data = await SupabaseService.instance.getProviderReviews(
        _providerId!,
      );
      if (mounted) setState(() => _reviews = data);
    } catch (_) {}
    if (mounted) setState(() => _reviewsLoading = false);
  }

  Future<void> _loadProvider() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('service_providers')
          .select()
          .eq('id', _providerId!)
          .maybeSingle();
      if (mounted) setState(() => _provider = data);
    } catch (_) {}
  }

  Future<void> _loadServiceCharges() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_service_charges')
          .select()
          .eq('provider_id', _providerId!)
          .eq('is_enabled', true)
          .order('sort_order');
      if (mounted) {
        setState(() {
          _serviceCharges = List<Map<String, dynamic>>.from(data)
              .where((s) => !(s['service_name'] as String).startsWith('__'))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFareConfig() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('transport_fare_config')
          .select()
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (mounted) setState(() => _fareConfig = data);
    } catch (_) {}
  }

  Future<void> _loadPortfolio() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_portfolio')
          .select()
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (mounted) setState(() => _portfolio = data);
    } catch (_) {}
  }

  Future<void> _loadPackages() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_packages')
          .select()
          .eq('provider_id', _providerId!)
          .eq('is_enabled', true)
          .order('sort_order');
      if (mounted) {
        setState(() => _packages = List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  Future<void> _loadGallery() async {
    if (_providerId == null) return;
    try {
      final photos = await SupabaseService.instance.getProviderPhotos(
        _providerId!,
      );
      if (mounted) {
        setState(() {
          _galleryPhotos = photos
              .map((p) => p['photo_url'] as String? ?? '')
              .where((u) => u.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _checkFavorite() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || _providerId == null) return;
      final data = await Supabase.instance.client
          .from('customer_favorites')
          .select('id')
          .eq('customer_id', userId)
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (mounted) setState(() => _isFavorite = data != null);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || _providerId == null) return;
      if (_isFavorite) {
        await Supabase.instance.client
            .from('customer_favorites')
            .delete()
            .eq('customer_id', userId)
            .eq('provider_id', _providerId!);
        setState(() => _isFavorite = false);
        _showSnack('Removed from favorites');
      } else {
        await Supabase.instance.client.from('customer_favorites').insert({
          'customer_id': userId,
          'provider_id': _providerId,
        });
        setState(() => _isFavorite = true);
        _showSnack('Added to favorites!', isSuccess: true);
      }
    } catch (_) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openChat() async {
    final providerUserId = _provider?['user_id'] as String?;
    if (providerUserId == null || providerUserId.isEmpty) {
      _showSnack('Chat unavailable for this provider');
      return;
    }
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showSnack('Please log in to chat');
      return;
    }
    try {
      final conversation = await SupabaseService.instance
          .getOrCreateConversation(
            providerUserId: providerUserId,
            providerServiceId: _providerId,
          );
      if (conversation == null) {
        _showSnack('Could not open chat. Please try again.');
        return;
      }
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetailScreen,
        arguments: {
          'conversationId': conversation['id'] as String,
          'otherUserId': providerUserId,
          'otherUserName': _providerName,
          'otherUserAvatar': _profilePhoto,
        },
      );
    } catch (_) {
      _showSnack('Could not open chat. Please try again.');
    }
  }

  void _bookNow() {
    Navigator.pushNamed(
      context,
      AppRoutes.serviceOrderConfirmationScreen,
      arguments: {
        'providerId': _providerId,
        'providerName': _providerName,
        'category': _category,
        'service': _serviceCharges.isNotEmpty
            ? (_serviceCharges.first['service_name'] as String? ?? 'Service')
            : 'Service',
        'amount': _serviceCharges.isNotEmpty
            ? '₹${_serviceCharges.first['price']?.toString() ?? '0'}'
            : '₹0',
      },
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? Colors.green[700] : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _providerName =>
      (_provider?['business_name'] as String?) ??
      (_provider?['owner_name'] as String?) ??
      'Provider';

  String get _phone => _provider?['phone'] as String? ?? '';
  String get _whatsapp => _provider?['whatsapp_number'] as String? ?? _phone;
  double get _rating => (_provider?['rating'] as num?)?.toDouble() ?? 0.0;
  int get _reviewCount => _provider?['review_count'] as int? ?? 0;
  int get _completedJobs => _provider?['completed_jobs'] as int? ?? 0;
  int get _yearsExp => _provider?['years_experience'] as int? ?? 0;
  String get _responseTime =>
      _provider?['response_time'] as String? ?? 'Within 1 hour';
  String get _description =>
      _provider?['business_description'] as String? ?? '';
  String get _address => _provider?['address'] as String? ?? '';
  String get _workingHours =>
      _provider?['working_hours'] as String? ?? '9 AM - 6 PM';
  String get _serviceArea => _provider?['service_area'] as String? ?? '';
  String get _profilePhoto => _provider?['image_url'] as String? ?? '';
  String get _coverPhoto => _provider?['cover_image_url'] as String? ?? '';

  Color get _categoryColor {
    switch (_category) {
      case 'transport':
        return const Color(0xFF1E88E5);
      case 'home_maintenance':
        return const Color(0xFF0277BD);
      case 'event_management':
        return const Color(0xFFAD1457);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: _categoryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (ctx, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: _categoryColor,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: _isAppBarCollapsed
                  ? Text(
                      _providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.red[300] : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _showSnack('Share link copied!'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(background: _buildHeroSection()),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                isScrollable: true,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Services'),
                  Tab(text: 'Gallery'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildServicesTab(),
            _buildGalleryTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image
        _coverPhoto.isNotEmpty
            ? Image.network(
                _coverPhoto,
                fit: BoxFit.cover,
                semanticLabel: '$_providerName cover photo',
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _categoryColor,
                      _categoryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
        ),
        // Profile info
        Positioned(
          bottom: 60,
          left: 16,
          right: 16,
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                backgroundImage: _profilePhoto.isNotEmpty
                    ? NetworkImage(_profilePhoto)
                    : null,
                child: _profilePhoto.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: _categoryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_description.isNotEmpty)
                      Text(
                        _description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber[400],
                          size: 14,
                        ),
                        Text(
                          ' ${_rating.toStringAsFixed(1)}  •  $_reviewCount reviews',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
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
      ],
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        _buildStatsRow(),
        const SizedBox(height: 16),
        // About
        if (_description.isNotEmpty) ...[
          _buildCard(
            'About',
            Icons.info_outline_rounded,
            child: Text(
              _description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Details
        _buildCard(
          'Business Details',
          Icons.business_rounded,
          child: Column(
            children: [
              if (_workingHours.isNotEmpty)
                _detailRow(
                  Icons.access_time_rounded,
                  'Working Hours',
                  _workingHours,
                ),
              if (_serviceArea.isNotEmpty)
                _detailRow(
                  Icons.location_on_rounded,
                  'Service Area',
                  _serviceArea,
                ),
              if (_address.isNotEmpty)
                _detailRow(Icons.home_rounded, 'Address', _address),
              if (_yearsExp > 0)
                _detailRow(
                  Icons.workspace_premium_rounded,
                  'Experience',
                  '$_yearsExp years',
                ),
              _detailRow(Icons.timer_rounded, 'Response Time', _responseTime),
              if (_completedJobs > 0)
                _detailRow(
                  Icons.check_circle_rounded,
                  'Completed Jobs',
                  '$_completedJobs jobs',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Languages
        if (_provider?['languages_spoken'] is List) ...[
          _buildCard(
            'Languages',
            Icons.language_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (_provider!['languages_spoken'] as List)
                  .map(
                    (lang) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _categoryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        lang as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Map link
        if ((_provider?['google_map_url'] as String?)?.isNotEmpty == true) ...[
          OutlinedButton.icon(
            onPressed: () => _launchUrl(_provider!['google_map_url'] as String),
            icon: const Icon(Icons.map_rounded),
            label: Text(
              'View on Google Maps',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _categoryColor,
              side: BorderSide(color: _categoryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // ── Recent Reviews section ──────────────────────────────────────────
        _buildRecentReviewsSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRecentReviewsSection() {
    // Compute aggregated values from loaded reviews
    final totalReviews = _reviews.length;
    final double avgRating = totalReviews > 0
        ? _reviews.fold<double>(
                0,
                (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0),
              ) /
              totalReviews
        : _rating;
    final displayRating = totalReviews > 0 ? avgRating : _rating;
    final displayCount = totalReviews > 0 ? totalReviews : _reviewCount;

    return _buildCard(
      'Customer Reviews',
      Icons.star_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aggregated rating header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayRating.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < displayRating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$displayCount ${displayCount == 1 ? 'review' : 'reviews'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (displayCount > 0)
                GestureDetector(
                  onTap: () => _tabController.animateTo(3),
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _categoryColor,
                    ),
                  ),
                ),
            ],
          ),
          if (_reviewsLoading) ...[
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ] else if (_reviews.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No reviews yet. Be the first!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ..._reviews
                .take(3)
                .map((review) => _buildCompactReviewCard(review)),
            if (_reviews.length > 3) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _tabController.animateTo(3),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _categoryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'View all ${_reviews.length} reviews',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCompactReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = (review['review_text'] as String?) ?? '';
    final createdAt = review['created_at'] as String?;
    final userProfile = review['user_profiles'];
    final customerName = userProfile is Map
        ? (userProfile['full_name'] as String?) ?? 'Customer'
        : 'Customer';
    final avatarUrl = userProfile is Map
        ? userProfile['avatar_url'] as String?
        : null;

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        const months = [
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
        formattedDate = '${dt.day} ${months[dt.month - 1]}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _categoryColor.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 12,
                  ),
                ),
              ),
              if (formattedDate.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Transport fare chart
        if (_fareConfig != null) ...[
          _buildFareChart(),
          const SizedBox(height: 12),
        ],
        // Service charges
        if (_serviceCharges.isNotEmpty) ...[
          _buildServiceChargeChart(),
          const SizedBox(height: 12),
        ],
        // Packages
        if (_packages.isNotEmpty) ...[
          _buildPackagesList(),
          const SizedBox(height: 12),
        ],
        if (_fareConfig == null && _serviceCharges.isEmpty && _packages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No service charges listed yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFareChart() {
    final fc = _fareConfig!;
    return _buildCard(
      'Fare Chart',
      Icons.receipt_long_rounded,
      child: Column(
        children: [
          _fareRow('Base Fare', '₹${fc['base_fare'] ?? 0}'),
          _fareRow('Per Kilometer', '₹${fc['per_km_charge'] ?? 0}/km'),
          _fareRow('Minimum Fare', '₹${fc['minimum_fare'] ?? 0}'),
          _fareRow(
            'Waiting Charge',
            '₹${fc['waiting_charge_per_min'] ?? 0}/min',
          ),
          if ((fc['night_charge'] as num?)?.toDouble() != 0)
            _fareRow('Night Charge', '₹${fc['night_charge'] ?? 0} extra'),
          if ((fc['hourly_package'] as num?)?.toDouble() != 0)
            _fareRow('Hourly Package', '₹${fc['hourly_package'] ?? 0}/hr'),
          if ((fc['daily_package'] as num?)?.toDouble() != 0)
            _fareRow('Daily Package', '₹${fc['daily_package'] ?? 0}/day'),
          if ((fc['outstation_fare'] as num?)?.toDouble() != 0)
            _fareRow('Outstation', '₹${fc['outstation_fare'] ?? 0}/km'),
          if ((fc['toll_charges'] as String?)?.isNotEmpty == true)
            _fareRow('Toll Charges', fc['toll_charges'] as String),
          if ((fc['parking_charges'] as String?)?.isNotEmpty == true)
            _fareRow('Parking', fc['parking_charges'] as String),
          if (fc['ac_available'] as bool? ?? false)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '❄️ AC Available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Negotiate fare via call or message. Updated fares reflect instantly.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.orange[800],
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

  Widget _buildServiceChargeChart() {
    return _buildCard(
      'Service Charges',
      Icons.price_check_rounded,
      child: Column(
        children: [
          ..._serviceCharges.map((s) {
            final isEmergency = s['is_emergency'] as bool? ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isEmergency ? Colors.red[50] : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isEmergency ? Colors.red[200]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  if (isEmergency)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.emergency_rounded,
                        size: 14,
                        color: Colors.red[600],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      s['service_name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                  Text(
                    '₹${(s['base_price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _categoryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s['unit'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Negotiate charges via call or message. Updated charges reflect instantly.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.orange[800],
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

  Widget _buildPackagesList() {
    return _buildCard(
      'Service Packages',
      Icons.inventory_2_rounded,
      child: Column(
        children: _packages.map((pkg) {
          final isPopular = pkg['is_popular'] as bool? ?? false;
          final features = pkg['features'];
          final featureList = features is List
              ? List<String>.from(features)
              : <String>[];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPopular
                  ? _categoryColor.withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPopular
                    ? _categoryColor.withValues(alpha: 0.3)
                    : Colors.grey[200]!,
                width: isPopular ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pkg['package_name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Popular',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _categoryColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${(pkg['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _categoryColor,
                      ),
                    ),
                  ],
                ),
                if ((pkg['duration'] as String?)?.isNotEmpty == true)
                  Text(
                    pkg['duration'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if ((pkg['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    pkg['description'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
                if (featureList.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...featureList
                      .take(4)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGalleryTab() {
    // Combine gallery photos + portfolio photos
    final portfolioPhotos = _portfolio?['photo_urls'];
    final allPhotos = <String>[
      ..._galleryPhotos,
      if (portfolioPhotos is List) ...List<String>.from(portfolioPhotos),
    ];

    // Social links
    final reels = _portfolio?['instagram_reel_links'];
    final posts = _portfolio?['instagram_post_links'];
    final yt = _portfolio?['youtube_links'];
    final reelList = reels is List ? List<String>.from(reels) : <String>[];
    final postList = posts is List ? List<String>.from(posts) : <String>[];
    final ytList = yt is List ? List<String>.from(yt) : <String>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (allPhotos.isNotEmpty) ...[
          _buildCard(
            'Photo Gallery',
            Icons.photo_library_rounded,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: allPhotos.length,
              itemBuilder: (ctx, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    allPhotos[i],
                    fit: BoxFit.cover,
                    semanticLabel: 'Gallery photo ${i + 1}',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (reelList.isNotEmpty) ...[
          _buildCard(
            'Instagram Reels',
            Icons.video_collection_rounded,
            child: Column(
              children: reelList
                  .map(
                    (link) => _linkRow(
                      Icons.play_circle_outline_rounded,
                      'View Reel',
                      link,
                      Colors.pink,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (postList.isNotEmpty) ...[
          _buildCard(
            'Instagram Posts',
            Icons.photo_camera_rounded,
            child: Column(
              children: postList
                  .map(
                    (link) => _linkRow(
                      Icons.photo_rounded,
                      'View Post',
                      link,
                      Colors.purple,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ytList.isNotEmpty) ...[
          _buildCard(
            'YouTube Videos',
            Icons.play_circle_outline_rounded,
            child: Column(
              children: ytList
                  .map(
                    (link) => _linkRow(
                      Icons.smart_display_rounded,
                      'Watch Video',
                      link,
                      Colors.red,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (allPhotos.isEmpty &&
            reelList.isEmpty &&
            postList.isEmpty &&
            ytList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No gallery content yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildReviewsTab() {
    if (_reviewsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    // Compute rating distribution
    final Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final star = (r['rating'] as num?)?.toInt() ?? 0;
      if (star >= 1 && star <= 5) {
        starCounts[star] = (starCounts[star] ?? 0) + 1;
      }
    }
    final totalReviews = _reviews.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          'Rating Summary',
          Icons.star_rounded,
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < _rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = starCounts[star] ?? 0;
                    final fraction = totalReviews > 0
                        ? count / totalReviews
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: fraction,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _categoryColor,
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
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
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reviews yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to review this provider!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._reviews.map((review) => _buildReviewCard(review)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = (review['review_text'] as String?) ?? '';
    final service = (review['service'] as String?) ?? '';
    final photoUrl = review['photo_url'] as String?;
    final createdAt = review['created_at'] as String?;
    final userProfile = review['user_profiles'];
    final customerName = userProfile is Map
        ? (userProfile['full_name'] as String?) ?? 'Customer'
        : 'Customer';
    final avatarUrl = userProfile is Map
        ? userProfile['avatar_url'] as String?
        : null;

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        const months = [
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
        formattedDate = '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _categoryColor.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (service.isNotEmpty)
                      Text(
                        service,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ),
                  ),
                  if (formattedDate.isNotEmpty)
                    Text(
                      formattedDate,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ],
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                photoUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Review photo by $customerName',
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Call
            _actionButton(
              Icons.call_rounded,
              'Call',
              Colors.green[700]!,
              () async {
                if (_phone.isNotEmpty) {
                  await _launchPhone(_phone);
                } else {
                  _showSnack('No phone number available');
                }
              },
            ),
            const SizedBox(width: 8),
            // WhatsApp
            _actionButton(
              Icons.chat_rounded,
              'WhatsApp',
              const Color(0xFF25D366),
              () async {
                if (_whatsapp.isNotEmpty) {
                  await _launchWhatsApp(_whatsapp);
                } else {
                  _showSnack('No WhatsApp number available');
                }
              },
            ),
            const SizedBox(width: 8),
            // Chat
            _actionButton(
              Icons.message_rounded,
              'Chat',
              Colors.blue[700]!,
              _openChat,
            ),
            const SizedBox(width: 8),
            // Send Enquiry
            _actionButton(
              Icons.request_quote_rounded,
              'Enquiry',
              const Color(0xFF7B1FA2),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerEnquiryScreen(provider: _provider),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Book Now
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _bookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Book Now',
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

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('${_rating.toStringAsFixed(1)}★', 'Rating', Colors.amber),
        const SizedBox(width: 8),
        _statCard('$_reviewCount', 'Reviews', Colors.blue),
        const SizedBox(width: 8),
        _statCard('$_yearsExp yr', 'Exp', Colors.green),
        const SizedBox(width: 8),
        _statCard('$_completedJobs', 'Jobs', _categoryColor),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _categoryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _categoryColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(IconData icon, String label, String url, Color color) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
