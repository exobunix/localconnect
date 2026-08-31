import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/connectivity_service.dart';
import '../../services/supabase_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner_widget.dart';
import '../../widgets/universal_enquiry_dialog.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String? _selectedSubcategoryId;
  String _searchQuery = '';
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _categoryId;
  bool _isOnline = true;
  String? _cacheAge;

  DynamicCategory? _dynamicCategory;
  List<DynamicSubCategory> _subcategories = [];
  bool _dynamicCategoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online && _categoryId != null) {
          _loadCategoryDetails(_categoryId!);
          _loadProviders(_categoryId!);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final newCategoryId = args is String ? args : 'shop';

    // Redirect shop category to dedicated shop home screen
    if (newCategoryId == 'shop') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.shopHomeScreen);
        }
      });
      return;
    }

    // Redirect transport category to transport customer screen
    if (newCategoryId == 'transport') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.transportCustomerScreen,
            arguments: {'vehicleType': 'rickshaw'},
          );
        }
      });
      return;
    }

    // Redirect rent category to rent customer screen
    if (newCategoryId == 'rent') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.rentCustomerScreen);
        }
      });
      return;
    }

    // Redirect home_maintenance category to home maintenance customer screen
    if (newCategoryId == 'home_maintenance') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.homeMaintenanceCustomerScreen,
          );
        }
      });
      return;
    }

    // Redirect events category to event management customer screen
    if (newCategoryId == 'events') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.eventManagementCustomerScreen,
          );
        }
      });
      return;
    }

    // Redirect delivery category to delivery customer screen
    if (newCategoryId == 'delivery') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.deliveryCustomerScreen,
          );
        }
      });
      return;
    }

    if (_categoryId != newCategoryId) {
      _categoryId = newCategoryId;
      _loadCategoryDetails(newCategoryId);
      _loadProviders(newCategoryId);
    }
  }

  Future<void> _loadCategoryDetails(String categoryId) async {
    try {
      final activeCategories = await CategoryService.instance.getActiveCategories();
      final matched = activeCategories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => DynamicCategory(
          id: categoryId,
          name: categoryId,
          nameMarathi: categoryId,
          icon: Icons.category_rounded,
          imageUrl: '',
          color: AppTheme.primary,
          isActive: true,
          sortOrder: 99,
          subcategories: [],
        ),
      );
      if (mounted) {
        setState(() {
          _dynamicCategory = matched;
          _subcategories = matched.subcategories;
          _dynamicCategoryLoaded = true;
          if (_selectedSubcategoryId == null && _subcategories.isNotEmpty) {
            _selectedSubcategoryId = _subcategories.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('[CategoryDetailScreen] Error loading category details: $e');
    }
  }

  Future<void> _loadProviders(String categoryId) async {
    final cacheKey = 'category_providers_$categoryId';

    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(cacheKey);
      if (cached != null && mounted) {
        final list = cached['data'];
        final ts = ConnectivityService.instance.getCachedTimestamp(cached);
        setState(() {
          _providers = list is List
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _cacheAge = ConnectivityService.instance.formatCacheAge(ts);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getProvidersByCategory(
        categoryId,
      );
      if (mounted) {
        setState(() {
          _providers = data;
          _isLoading = false;
          _cacheAge = null;
        });
        await ConnectivityService.instance.cacheData(cacheKey, data);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleRetry() {
    if (_categoryId != null) {
      _loadCategoryDetails(_categoryId!);
      _loadProviders(_categoryId!);
    }
  }

  void _handleCall(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: p);
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
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleWhatsApp(String phone) async {
    final p = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final number = p.startsWith('+') ? p.replaceFirst('+', '') : '91$p';
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available for WhatsApp.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open WhatsApp.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final categoryId = args is String ? args : 'shop';

    final categoryName = _dynamicCategory?.name ?? categoryId;
    final categoryNameMarathi = _dynamicCategory?.nameMarathi ?? '';
    final categoryColor = _dynamicCategory?.color ?? AppTheme.primary;
    final categoryIcon = _dynamicCategory?.icon ?? Icons.category_rounded;
    final categoryImageUrl = _dynamicCategory?.imageUrl ?? '';

    final selectedSub = _selectedSubcategoryId != null
        ? _subcategories.firstWhere(
            (s) => s.id == _selectedSubcategoryId,
            orElse: () => DynamicSubCategory(
              id: '',
              name: '',
              nameMarathi: '',
              icon: Icons.category,
              imageUrl: '',
              description: '',
              isActive: true,
              sortOrder: 99,
            ),
          )
        : null;

    final filteredProviders = _providers.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          ((p['business_name'] as String?) ?? '').toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

      if (_selectedSubcategoryId == null) return matchesSearch;

      final providerSub = (p['subcategory'] as String? ?? '').trim().toLowerCase();
      final targetSubId = _selectedSubcategoryId!.toLowerCase();
      final targetSubName = selectedSub?.name.toLowerCase() ?? '';

      final matchesSub = providerSub == targetSubId || providerSub == targetSubName;
      return matchesSub && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: categoryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!_isOnline)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: categoryImageUrl.isNotEmpty
                                ? Image.network(
                                    categoryImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      categoryIcon,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                : Icon(
                                    categoryIcon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                categoryName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              if (categoryNameMarathi.isNotEmpty)
                                Text(
                                  categoryNameMarathi,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: OfflineBannerWidget(onRetry: _handleRetry)),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search in $categoryName...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_cacheAge != null) ...[
                    const SizedBox(height: 8),
                    OfflineChipWidget(cacheAge: _cacheAge),
                  ],
                ],
              ),
            ),
          ),
          if (_subcategories.isNotEmpty)
            SliverToBoxAdapter(
              child: _SubcategoryChips(
                subcategories: _subcategories,
                selectedId: _selectedSubcategoryId,
                categoryColor: categoryColor,
                onSelected: (id) => setState(() {
                  _selectedSubcategoryId = _selectedSubcategoryId == id ? null : id;
                }),
              ),
            ),
          // Subcategory Info Header Card
          if (selectedSub != null && selectedSub.id.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedSub.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.network(
                          selectedSub.imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSub.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D1B20),
                            ),
                          ),
                          if (selectedSub.nameMarathi.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              selectedSub.nameMarathi,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF49454F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (selectedSub.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              selectedSub.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF49454F),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LoadingSkeletonWidget(
                        width: double.infinity,
                        height: 100,
                        borderRadius: 14,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (!_isOnline && _providers.isEmpty)
            SliverToBoxAdapter(
              child: OfflineFallbackWidget(
                onRetry: _handleRetry,
                message:
                    'No cached providers for $categoryName. Connect to the internet to load providers.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: filteredProviders.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppTheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No providers found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to offer $categoryName services!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF74777F),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProviderListCard(
                            provider: filteredProviders[index],
                            categoryColor: categoryColor,
                            categoryName: categoryName,
                            subcategoryName: selectedSub?.name ?? 'General',
                            onTap: () => _showProviderDetail(
                              filteredProviders[index],
                              categoryColor,
                              categoryName,
                              selectedSub?.name ?? 'General',
                            ),
                            onEnquiry: () => _showEnquiryDialog(
                              filteredProviders[index],
                              categoryColor,
                              categoryName,
                              selectedSub?.name ?? 'General',
                            ),
                            onBook: () => _showBookingSheet(
                              filteredProviders[index],
                              categoryColor,
                              categoryName,
                            ),
                          ),
                        ),
                        childCount: filteredProviders.length,
                      ),
                    ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showProviderDetail(
    Map<String, dynamic> provider,
    Color categoryColor,
    String categoryName,
    String subcategoryName,
  ) {
    final businessName = (provider['business_name'] ?? provider['owner_name'] ?? provider['full_name'] ?? 'Provider').toString();
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
    final reviewCount = (provider['review_count'] as num?)?.toInt() ?? 100;
    final imageUrl = provider['image_url'] as String? ?? '';
    final phone = provider['phone'] as String? ?? '';

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: categoryColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person_rounded,
                                color: categoryColor,
                                size: 36,
                              ),
                            ),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            color: categoryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_rounded,
                              color: categoryColor,
                              size: 36,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                businessName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider['is_verified'] == true || provider['registration_status'] == 'approved')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider['description'] ?? '$subcategoryName Service Provider',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            Text(
                              ' $rating',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                            ),
                            Text(
                              ' ($reviewCount reviews)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (phone.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: categoryColor),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statChip(
                    Icons.work_history_rounded,
                    '${(provider['completed_orders'] as num?)?.toInt() ?? 250} Jobs',
                    categoryColor,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    Icons.location_on_rounded,
                    '1.8 km',
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    Icons.timer_rounded,
                    '${(provider['years_experience'] as num?)?.toInt() ?? 6} yrs',
                    Colors.orange[700]!,
                  ),
                ],
              ),
              if (provider['gallery_photos'] != null && (provider['gallery_photos'] as List).isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Work Gallery',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (provider['gallery_photos'] as List).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        (provider['gallery_photos'] as List)[i] as String,
                        width: 120,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Call, Message, WhatsApp row
              Row(
                children: [
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      color: Colors.green[700]!,
                      onTap: () => Navigator.pop(context, 'call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: categoryColor,
                      onTap: () => Navigator.pop(context, 'message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.help_outline,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => Navigator.pop(context, 'whatsapp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chat and Book Now row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Make Enquiry',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: categoryColor,
                        side: BorderSide(color: categoryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, 'enquiry'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Book Now',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, 'book'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((result) {
      if (result == 'call') {
        _handleCall(phone);
      } else if (result == 'message') {
        Navigator.pushNamed(
          context,
          AppRoutes.chatDetailScreen,
          arguments: {
            'providerId': provider['id'],
            'providerName': businessName,
          },
        );
      } else if (result == 'whatsapp') {
        _handleWhatsApp(phone);
      } else if (result == 'enquiry') {
        _showEnquiryDialog(provider, categoryColor, categoryName, subcategoryName);
      } else if (result == 'book') {
        _showBookingSheet(provider, categoryColor, categoryName);
      }
    });
  }

  void _showEnquiryDialog(
    Map<String, dynamic> provider,
    Color categoryColor,
    String categoryName,
    String subcategoryName,
  ) {
    final businessName = (provider['business_name'] ?? provider['owner_name'] ?? provider['full_name'] ?? 'Provider').toString();
    final imageUrl = provider['image_url'] as String? ?? '';
    final phone = provider['phone'] as String? ?? '';
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
    final priceVal = (provider['charge'] as num?)?.toInt() ?? 300;
    final priceUnit = provider['chargeUnit'] as String? ?? '/visit';

    UniversalEnquiryDialog.show(
      context,
      providerId: provider['id'] as String? ?? '',
      providerName: businessName,
      providerImage: imageUrl.isNotEmpty ? imageUrl : null,
      providerPhone: phone.isNotEmpty ? phone : null,
      providerRating: rating,
      category: categoryName,
      subcategory: subcategoryName,
      serviceTitle: provider['description'] ?? '$subcategoryName Service',
      basePrice: '₹$priceVal$priceUnit',
      themeColor: categoryColor,
    );
  }

  void _showBookingSheet(
    Map<String, dynamic> provider,
    Color categoryColor,
    String categoryName,
  ) {
    final businessName = (provider['business_name'] ?? provider['owner_name'] ?? provider['full_name'] ?? 'Provider').toString();
    final imageUrl = provider['image_url'] as String? ?? '';
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
    final priceVal = (provider['charge'] as num?)?.toInt() ?? 300;

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Book Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (d != null) setModal(() => selectedDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate != null
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Select Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: selectedDate != null
                                      ? Colors.black87
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null) setModal(() => selectedTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(ctx)
                                    : 'Select Time',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: selectedTime != null
                                      ? Colors.black87
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 16,
                        color: categoryColor,
                      ),
                      Text(
                        'Service Charge: ₹$priceVal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      final dateStr = selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Now';
                      final timeStr = selectedTime != null
                          ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, "0")}'
                          : 'On Demand';

                      Navigator.pop(context); // Pop booking sheet
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookingCheckoutScreen,
                        arguments: {
                          'providerId': provider['id'] as String?,
                          'providerName': businessName,
                          'providerImage': imageUrl,
                          'providerRating': rating,
                          'service': provider['description'] ?? '$categoryName Service',
                          'category': categoryName,
                          'scheduledDate': dateStr,
                          'scheduledTime': timeStr,
                          'amount': '₹$priceVal',
                        },
                      );
                    },
                    child: Text(
                      'Confirm Booking',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  final List<DynamicSubCategory> subcategories;
  final String? selectedId;
  final Color categoryColor;
  final ValueChanged<String> onSelected;

  const _SubcategoryChips({
    required this.subcategories,
    required this.selectedId,
    required this.categoryColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final sub = subcategories[index];
          final isSelected = selectedId == sub.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(sub.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? categoryColor : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? categoryColor : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sub.icon,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF44474E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sub.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF44474E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderListCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color categoryColor;
  final String categoryName;
  final String subcategoryName;
  final VoidCallback onTap;
  final VoidCallback onEnquiry;
  final VoidCallback onBook;

  const _ProviderListCard({
    required this.provider,
    required this.categoryColor,
    required this.categoryName,
    required this.subcategoryName,
    required this.onTap,
    required this.onEnquiry,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final todayOffer = provider['today_offer'] as String?;
    final hasOffer = todayOffer != null && todayOffer.isNotEmpty;
    final rating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
    final reviewCount = (provider['review_count'] as num?)?.toInt() ?? 100;
    final imageUrl = provider['image_url'] as String? ?? '';
    final businessName = (provider['business_name'] ?? provider['owner_name'] ?? provider['full_name'] ?? 'Provider').toString();
    final address = provider['address'] as String? ?? '';
    final priceVal = (provider['charge'] as num?)?.toInt() ?? 300;
    final priceUnit = provider['chargeUnit'] as String? ?? '/visit';

    final completedJobs = (provider['completed_orders'] as num?)?.toInt() ?? 250;
    final experience = (provider['years_experience'] as num?)?.toInt() ?? 6;
    const distance = 1.8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasOffer)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.warningContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_rounded,
                      size: 14,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        todayOffer,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(hasOffer ? 0.0 : 16.0),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: categoryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.home_repair_service_rounded,
                              size: 48,
                              color: categoryColor.withValues(alpha: 0.4),
                            ),
                          ),
                        )
                      : Container(
                          height: 140,
                          color: categoryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.home_repair_service_rounded,
                            size: 48,
                            color: categoryColor.withValues(alpha: 0.4),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (provider['is_verified'] == true || provider['registration_status'] == 'approved')
                        _badge(
                          'Verified',
                          Colors.green[700]!,
                          Icons.verified_rounded,
                        ),
                      if (provider['is_open'] != false) ...[
                        const SizedBox(width: 6),
                        _badge(
                          'Open Now',
                          Colors.blue[700]!,
                          Icons.schedule_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          businessName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D1B20),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          Text(
                            ' $rating',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' ($reviewCount)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider['description'] ?? '$subcategoryName Service Provider',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      Text(
                        ' $distance km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 13,
                        color: categoryColor,
                      ),
                      Text(
                        '$priceVal${priceUnit.startsWith('/') ? priceUnit : "/$priceUnit"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: onEnquiry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: categoryColor,
                          side: BorderSide(color: categoryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Make Enquiry',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
