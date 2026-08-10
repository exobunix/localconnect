import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/provider_action_bar_widget.dart';
import './widgets/provider_hero_widget.dart';
import './widgets/provider_info_card_widget.dart';
import './widgets/provider_tabs_widget.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  Map<String, dynamic>? _routeArgs;
  Map<String, dynamic>? _providerData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 200;
      if (collapsed != _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = collapsed);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_routeArgs == null && args != null) {
      _routeArgs = args;
      _loadProvider(args);
    }
  }

  Future<void> _loadProvider(Map<String, dynamic> args) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providerId = args['providerId'] as String?;
      Map<String, dynamic>? provider;

      if (providerId != null) {
        provider = await SupabaseService.instance.getProviderById(providerId);
      }

      if (provider == null) {
        // Try to build from passed args directly (from category list)
        if (args.containsKey('name') || args.containsKey('business_name')) {
          provider = args;
        }
      }

      if (mounted) {
        setState(() {
          _providerData = provider;
          _isLoading = false;
          if (provider == null) _error = 'Provider not found.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load provider details.';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _providerName =>
      (_providerData?['business_name'] as String?) ??
      (_providerData?['name'] as String?) ??
      'Provider';

  String get _category => (_providerData?['category'] as String?) ?? 'Service';

  double get _rating => ((_providerData?['rating'] as num?)?.toDouble()) ?? 0.0;

  int get _reviewCount => (_providerData?['review_count'] as int?) ?? 0;

  bool get _isOpen => (_providerData?['is_open'] as bool?) ?? true;

  String get _address => (_providerData?['address'] as String?) ?? '';

  String get _phone => (_providerData?['phone'] as String?) ?? '';

  String get _upiId => (_providerData?['upi_id'] as String?) ?? '';

  String get _ownerName => (_providerData?['owner_name'] as String?) ?? '';

  String get _priceRange =>
      (_providerData?['price_range'] as String?) ?? '₹200+';

  String get _memberSince => (_providerData?['member_since'] as String?) ?? '';

  int get _completedOrders => (_providerData?['completed_orders'] as int?) ?? 0;

  String get _imageUrl => (_providerData?['image_url'] as String?) ?? '';

  List<Map<String, dynamic>> get _heroImages {
    if (_imageUrl.isNotEmpty) {
      return [
        {
          'url': _imageUrl,
          'semanticLabel': '$_providerName - $_category service provider',
        },
      ];
    }
    return [
      {
        'url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_13ed4c5d0-1783271524441.png',
        'semanticLabel': 'Service provider at work',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null || _providerData == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Provider not found',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_routeArgs != null) _loadProvider(_routeArgs!);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, _providerName),
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: ProviderActionBarWidget(
        onCall: () => _handleCall(),
        onWhatsApp: () => _handleWhatsApp(),
        onBook: () => _showBookingSheet(context),
        onUpiQr: () => Navigator.pushNamed(
          context,
          AppRoutes.upiPaymentScreen,
          arguments: {'providerName': _providerName, 'upiId': _upiId},
        ),
        onMessage: () => _handleMessage(context),
        showBookNow: !_isCurrentUserProvider(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String providerName) {
    return AppBar(
      backgroundColor: _isAppBarCollapsed
          ? AppTheme.primary
          : Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _isAppBarCollapsed
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _isAppBarCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          providerName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isAppBarCollapsed
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isAppBarCollapsed
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildPhoneLayout() {
    final todayOffer = _providerData?['today_offer'] as String?;
    final lat = (_providerData?['latitude'] as num?)?.toDouble() ?? 18.5204;
    final lng = (_providerData?['longitude'] as num?)?.toDouble() ?? 73.8567;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ProviderHeroWidget(
            images: _heroImages,
            providerName: _providerName,
            category: _category,
            rating: _rating,
            reviewCount: _reviewCount,
            distance: (_providerData?['distance'] as String?) ?? '',
            isOpen: _isOpen,
          ),
        ),
        if (todayOffer != null && todayOffer.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Offer 🎉",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          todayOffer,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Location on Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening in Google Maps...',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_rounded,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Directions',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 160,
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE8F0FE),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFFE8F0FE)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_rounded,
                            size: 40,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _address.isNotEmpty
                                ? _address
                                : 'Location not available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ProviderInfoCardWidget(
            ownerName: _ownerName,
            address: _address,
            openHours:
                (_providerData?['open_hours'] as String?) ??
                '9:00 AM – 8:00 PM',
            responseTime:
                (_providerData?['response_time'] as String?) ?? '~30 min',
            completedOrders: _completedOrders,
            memberSince: _memberSince,
            priceRange: _priceRange,
            phone: _phone,
          ),
        ),
        SliverToBoxAdapter(
          child: ProviderTabsWidget(
            tabController: _tabController,
            providerId:
                _routeArgs?['providerId'] as String? ??
                _providerData?['id'] as String?,
            isOwner: _isCurrentUserProvider(),
            category: _category,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.42,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ProviderHeroWidget(
                    images: _heroImages,
                    providerName: _providerName,
                    category: _category,
                    rating: _rating,
                    reviewCount: _reviewCount,
                    distance: (_providerData?['distance'] as String?) ?? '',
                    isOpen: _isOpen,
                  ),
                  ProviderInfoCardWidget(
                    ownerName: _ownerName,
                    address: _address,
                    openHours:
                        (_providerData?['open_hours'] as String?) ??
                        '9:00 AM – 8:00 PM',
                    responseTime:
                        (_providerData?['response_time'] as String?) ??
                        '~30 min',
                    completedOrders: _completedOrders,
                    memberSince: _memberSince,
                    priceRange: _priceRange,
                    phone: _phone,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ProviderTabsWidget(
              tabController: _tabController,
              providerId:
                  _routeArgs?['providerId'] as String? ??
                  _providerData?['id'] as String?,
              isOwner: _isCurrentUserProvider(),
              category: _category,
            ),
          ),
        ],
      ),
    );
  }

  void _handleCall() async {
    final phone = _phone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available for this provider.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch dialer. Number: $phone',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _handleWhatsApp() async {
    final phone = _phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final number = phone.startsWith('+')
        ? phone.replaceFirst('+', '')
        : '91$phone';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available for WhatsApp.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    final message = Uri.encodeComponent(
      'Hi, I found your profile on LocalConnect and would like to inquire about your services.',
    );
    final whatsappUri = Uri.parse('https://wa.me/$number?text=$message');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open WhatsApp. Number: $_phone',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showBookingSheet(BuildContext context) {
    final serviceController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ListView(
            controller: ctrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Book Service',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '$_providerName • $_category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 20),
              _buildBookingTextField(
                controller: serviceController,
                label: 'Service Type',
                hint: 'e.g. Fan repair, wiring',
              ),
              const SizedBox(height: 14),
              _buildBookingTextField(
                controller: dateController,
                label: 'Preferred Date',
                hint: 'DD/MM/YYYY',
                isDate: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    dateController.text =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildBookingTextField(
                controller: timeController,
                label: 'Preferred Time',
                hint: 'e.g. 10:00 AM',
              ),
              const SizedBox(height: 14),
              _buildBookingTextField(
                controller: addressController,
                label: 'Address',
                hint: 'Your full address',
                isMultiline: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.checkoutScreen,
                        arguments: {
                          'providerId': _providerData?['id'],
                          'providerUserId': _providerData?['user_id'],
                          'providerName': _providerName,
                          'service': serviceController.text.isNotEmpty
                              ? serviceController.text
                              : _category,
                          'category': _category,
                          'amount': _priceRange,
                          'imageUrl': _imageUrl,
                          'scheduledDate': dateController.text.isNotEmpty
                              ? dateController.text
                              : '${DateTime.now().add(const Duration(days: 1)).day.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 1)).month.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 1)).year}',
                          'scheduledTime': timeController.text.isNotEmpty
                              ? timeController.text
                              : 'Flexible',
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Proceed to Checkout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDate = false,
    bool isMultiline = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: isMultiline ? 3 : 1,
          readOnly: isDate,
          onTap: onTap,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF90A4AE),
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: isDate
                ? const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _handleMessage(BuildContext context) async {
    final providerUserId = _providerData?['user_id'] as String?;
    final providerServiceId = _providerData?['id'] as String?;
    final providerImage = _imageUrl;

    if (providerUserId == null) {
      Navigator.pushNamed(context, AppRoutes.chatListScreen);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    final conv = await SupabaseService.instance.getOrCreateConversation(
      providerUserId: providerUserId,
      providerServiceId: providerServiceId,
    );

    if (context.mounted) Navigator.pop(context);

    if (conv != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetailScreen,
        arguments: {
          'conversationId': conv['id'] as String,
          'otherUserId': providerUserId,
          'otherUserName': _providerName,
          'otherUserAvatar': providerImage,
        },
      );
    }
  }

  bool _isCurrentUserProvider() {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId == null) return false;
    final providerUserId = _providerData?['user_id'] as String?;
    return providerUserId != null && providerUserId == currentUserId;
  }
}
