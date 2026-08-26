import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/loading_skeleton_widget.dart';
import '../../../widgets/offline_banner_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../services/supabase_service.dart';
import '../../../services/location_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../routes/app_routes.dart';

class HomeNearbyProvidersWidget extends StatefulWidget {
  final ValueChanged<String> onProviderTap;
  final bool isOnline;
  final String? city;

  const HomeNearbyProvidersWidget({
    super.key,
    required this.onProviderTap,
    this.isOnline = true,
    this.city,
  });

  @override
  State<HomeNearbyProvidersWidget> createState() =>
      _HomeNearbyProvidersWidgetState();
}

class _HomeNearbyProvidersWidgetState extends State<HomeNearbyProvidersWidget> {
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _cacheAge;
  String? _expansionMessage;

  static const _cacheKey = 'home_nearby_providers_gps';

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void didUpdateWidget(HomeNearbyProvidersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline && widget.isOnline) {
      _loadProviders();
    }
  }

  Future<void> _loadProviders() async {
    if (!widget.isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(
        _cacheKey,
      );
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
      List<Map<String, dynamic>> data = [];
      String? expansionMsg;

      // 1. Try GPS location first
      try {
        final location = await LocationService.instance.getCurrentPosition();
        if (location != null) {
          final result = await LocationService.instance.getNearbyProvidersSmart(
            lat: location.latitude,
            lng: location.longitude,
            limit: 12,
          );
          data = result.providers;
          expansionMsg = result.expansionMessage;
        }
      } catch (e) {
        debugPrint('[HomeNearbyProviders] GPS load error: $e');
      }

      // 2. Fallback to Selected City
      if (data.isEmpty && widget.city != null && widget.city!.isNotEmpty) {
        data = await SupabaseService.instance.getNearbyProviders(
          city: widget.city,
          limit: 12,
        );
      }

      // 3. Fallback to ALL active providers in DB
      if (data.isEmpty) {
        data = await SupabaseService.instance.getNearbyProviders(
          limit: 12,
        );
      }

      if (mounted) {
        setState(() {
          _providers = data;
          _isLoading = false;
          _cacheAge = null;
          _expansionMessage = expansionMsg;
        });
        await ConnectivityService.instance.cacheData(_cacheKey, data);
      }
    } catch (e) {
      debugPrint('[HomeNearbyProviders] Error loading providers: $e');
      if (mounted) {
        setState(() {
          _providers = [];
          _isLoading = false;
        });
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'home_maintenance':
        return AppTheme.catElectrician;
      case 'shop':
        return AppTheme.catGrocery;
      case 'beauty':
        return AppTheme.catBeauty;
      case 'transport':
        return AppTheme.catTransport;
      case 'delivery':
        return AppTheme.catDelivery;
      case 'events':
        return AppTheme.catEvents;
      case 'rent':
        return AppTheme.catRent;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'जवळचे सेवा प्रदाते',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Nearest Providers by GPS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
                if (_cacheAge != null)
                  OfflineChipWidget(cacheAge: _cacheAge)
                else ...[
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'सर्व पहा',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.mapDiscoveryScreen,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Map',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Smart expansion message
          if (_expansionMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _expansionMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: _isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                      child: LoadingSkeletonWidget(
                        width: 150,
                        height: 220,
                        borderRadius: 16,
                      ),
                    ),
                  )
                : _providers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isOnline
                              ? Icons.search_off_rounded
                              : Icons.wifi_off_rounded,
                          size: 36,
                          color: AppTheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isOnline
                              ? 'No providers found nearby'
                              : 'No cached providers',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF74777F),
                          ),
                        ),
                        if (widget.isOnline) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Set your location to find providers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _providers.length,
                    itemBuilder: (context, index) {
                      final p = _providers[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _providers.length - 1 ? 12 : 0,
                        ),
                        child: _ProviderCard(
                          provider: p,
                          categoryColor: _getCategoryColor(p['category'] ?? ''),
                          onTap: () => widget.onProviderTap(p['id'] as String),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final availabilityStatus = resolveProviderStatus(provider);
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = provider['review_count'] as int? ?? 0;
    final imageUrl = provider['image_url'] as String? ?? '';
    final priceRange = provider['price_range'] as String? ?? '';
    final distanceKm = (provider['distance_km'] as num?)?.toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border(left: BorderSide(color: categoryColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: 168,
                          height: 100,
                          fit: BoxFit.cover,
                          semanticLabel:
                              provider['business_name'] as String? ??
                              'Provider',
                        )
                      : Container(
                          width: 168,
                          height: 100,
                          color: categoryColor.withAlpha(38),
                          child: Icon(
                            Icons.store_rounded,
                            color: categoryColor,
                            size: 40,
                          ),
                        ),
                ),
                // Status badge overlay on image
                Positioned(
                  top: 7,
                  right: 7,
                  child: StatusBadgeWidget(
                    status: availabilityStatus,
                    fontSize: 9,
                  ),
                ),
                // Distance badge
                if (distanceKm != null && distanceKm < 9999)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            LocationService.instance.formatDistance(distanceKm),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider['business_name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ),
                    // Travel time row
                    if (distanceKm != null && distanceKm < 9999)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Color(0xFF5C6BC0),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            LocationService.instance.estimateTravelTime(
                              distanceKm,
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5C6BC0),
                            ),
                          ),
                        ],
                      )
                    else if (priceRange.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.currency_rupee_rounded,
                            size: 11,
                            color: Color(0xFF2E7D32),
                          ),
                          Expanded(
                            child: Text(
                              priceRange,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
