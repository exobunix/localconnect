import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../data/app_categories.dart';
import '../../services/connectivity_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/offline_banner_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online && _categoryId != null) _loadProviders(_categoryId!);
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
      _loadProviders(newCategoryId);
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
    if (_categoryId != null) _loadProviders(_categoryId!);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final categoryId = args is String ? args : 'shop';
    final category =
        AppCategories.findById(categoryId) ?? AppCategories.all.first;

    final filteredProviders = _providers.where((p) {
      final matchesSub =
          _selectedSubcategoryId == null ||
          (p['subcategory'] as String?) == _selectedSubcategoryId;
      final matchesSearch =
          _searchQuery.isEmpty ||
          ((p['business_name'] as String?) ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesSub && matchesSearch;
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width > 800;
    Widget bodyContent = CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: category.color,
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
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: () => _showFilterSheet(context, category),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    category.color,
                    category.color.withValues(alpha: 0.7),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find the best ${category.name.toLowerCase()} services',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white70,
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
                    hintText: 'Search in ${category.name}...',
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
        SliverToBoxAdapter(
          child: _SubcategoryChips(
            subcategories: category.subcategories,
            selectedId: _selectedSubcategoryId,
            categoryColor: category.color,
            onSelected: (id) => setState(() {
              _selectedSubcategoryId = _selectedSubcategoryId == id
                  ? null
                  : id;
            }),
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
                  'No cached providers for ${category.name}. Connect to the internet to load providers.',
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
                              'Be the first to offer ${category.name} services!',
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
                : isDesktop
                    ? SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProviderListCard(
                            provider: filteredProviders[index],
                            categoryColor: category.color,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.providerProfileScreen,
                              arguments: {
                                'providerId': filteredProviders[index]['id'],
                                'providerUserId': filteredProviders[index]['user_id'],
                                'name': filteredProviders[index]['business_name'],
                                'imageUrl': filteredProviders[index]['image_url'] ?? '',
                              },
                            ),
                          ),
                          childCount: filteredProviders.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.6,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProviderListCard(
                              provider: filteredProviders[index],
                              categoryColor: category.color,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.providerProfileScreen,
                                arguments: {
                                  'providerId': filteredProviders[index]['id'],
                                  'providerUserId': filteredProviders[index]['user_id'],
                                  'name': filteredProviders[index]['business_name'],
                                  'imageUrl': filteredProviders[index]['image_url'] ?? '',
                                },
                              ),
                            ),
                          ),
                          childCount: filteredProviders.length,
                        ),
                      ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );

    if (isDesktop) {
      bodyContent = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: bodyContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: bodyContent,
    );
  }

  void _showFilterSheet(BuildContext context, AppCategory category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Sort By', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Nearest', 'Highest Rated', 'Most Reviews', 'Open Now']
                  .map(
                    (s) => FilterChip(
                      label: Text(s),
                      selected: false,
                      onSelected: (_) => Navigator.pop(context),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  final List<SubCategory> subcategories;
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
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF44474E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sub.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF44474E),
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
  final VoidCallback onTap;

  const _ProviderListCard({
    required this.provider,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final todayOffer = provider['today_offer'] as String?;
    final hasOffer = todayOffer != null && todayOffer.isNotEmpty;
    final availabilityStatus = resolveProviderStatus(provider);
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = provider['review_count'] as int? ?? 0;
    final imageUrl = provider['image_url'] as String? ?? '';
    final businessName = provider['business_name'] as String? ?? 'Provider';
    final address = provider['address'] as String? ?? '';
    final priceRange = provider['price_range'] as String? ?? '';
    final serviceDuration = provider['service_duration'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasOffer)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            semanticLabel: '$businessName service provider',
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: categoryColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.store_rounded,
                                color: categoryColor,
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: categoryColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.store_rounded,
                              color: categoryColor,
                              size: 32,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                businessName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1C1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            StatusBadgeWidget(
                              status: availabilityStatus,
                              fontSize: 9,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            Text(
                              ' ($reviewCount)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Pricing + duration inline row
                        Row(
                          children: [
                            if (priceRange.isNotEmpty) ...[
                              const Icon(
                                Icons.currency_rupee_rounded,
                                size: 13,
                                color: Color(0xFF2E7D32),
                              ),
                              Text(
                                priceRange,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                            if (priceRange.isNotEmpty &&
                                serviceDuration.isNotEmpty)
                              Text(
                                '  •  ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                            if (serviceDuration.isNotEmpty) ...[
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: Color(0xFF74777F),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                serviceDuration,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                size: 12,
                                color: Color(0xFF90A4AE),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  address,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF90A4AE),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
