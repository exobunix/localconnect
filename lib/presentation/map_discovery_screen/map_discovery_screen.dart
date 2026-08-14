import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../data/app_categories.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  bool _isLoading = true;

  String? _selectedCategory;
  double _radiusKm = 10.0;
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _selectedProviderOffers = [];

  late AnimationController _sheetAnimController;
  late Animation<double> _sheetAnim;

  // Customer location
  LocationData? _customerLocation;
  bool _usingGpsLocation = false;

  // Smart expansion message
  String? _expansionMessage;
  double _actualSearchedRadius = 10.0;

  // Sort mode
  String _sortMode = 'distance'; // distance, rating, response_time

  // Default center: Pune, Maharashtra
  static const LatLng _defaultCenter = LatLng(18.5204, 73.8567);

  // City coordinates map
  static const Map<String, LatLng> _cityCoords = {
    'Pune': LatLng(18.5204, 73.8567),
    'Mumbai': LatLng(19.0760, 72.8777),
    'Nashik': LatLng(19.9975, 73.7898),
    'Aurangabad': LatLng(19.8762, 75.3433),
    'Nagpur': LatLng(21.1458, 79.0882),
    'Kolhapur': LatLng(16.7050, 74.2433),
    'Alibag': LatLng(18.6414, 72.8722),
    'Roha': LatLng(18.4400, 73.1200),
    'Nagothane': LatLng(18.5500, 73.1500),
    'Pen': LatLng(18.7400, 73.0900),
    'Mangaon': LatLng(18.2300, 73.2800),
    'Mahad': LatLng(18.0800, 73.4200),
    'Poladpur': LatLng(17.9800, 73.5200),
    'Shrivardhan': LatLng(18.0400, 73.0200),
    'Murud': LatLng(18.3200, 72.9600),
    'Panvel': LatLng(18.9894, 73.1175),
    'Khopoli': LatLng(18.7900, 73.3400),
    'Karjat': LatLng(18.9100, 73.3200),
  };

  final List<double> _radiusOptions = [2, 5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sheetAnim = CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutCubic,
    );
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndLoad() async {
    // Try to load saved customer location first
    final saved = await LocationService.instance.getCustomerLocation();
    if (saved != null && saved.latitude != 0) {
      setState(() {
        _customerLocation = saved;
        _usingGpsLocation = true;
      });
      _mapController.move(LatLng(saved.latitude, saved.longitude), 13);
    }
    await _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _expansionMessage = null;
    });
    try {
      final data = await SupabaseService.instance.getProviders(limit: 100);
      if (mounted) {
        setState(() {
          _providers = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_providers);

    if (_selectedCategory != null) {
      result = result
          .where(
            (p) =>
                (p['category'] as String?)?.toLowerCase() ==
                _selectedCategory!.toLowerCase(),
          )
          .toList();
    }

    // Assign lat/lng — use real business_latitude/business_longitude if available
    final rng = math.Random(42);
    result = result.map((p) {
      final lat = (p['business_latitude'] ?? p['latitude']) as num?;
      final lng = (p['business_longitude'] ?? p['longitude']) as num?;
      if (lat == null || lng == null || lat == 0 || lng == 0) {
        final city = p['city'] as String? ?? 'Pune';
        final base = _cityCoords[city] ?? _defaultCenter;
        final offsetLat = (rng.nextDouble() - 0.5) * (_radiusKm / 55.0);
        final offsetLng = (rng.nextDouble() - 0.5) * (_radiusKm / 50.0);
        return {
          ...p,
          'latitude': base.latitude + offsetLat,
          'longitude': base.longitude + offsetLng,
        };
      }
      // Compute distance if customer location is known
      double distKm = (p['distance_km'] as num?)?.toDouble() ?? 9999;
      if (distKm == 9999 && _customerLocation != null) {
        distKm = LocationService.instance.calculateDistance(
          _customerLocation!.latitude,
          _customerLocation!.longitude,
          lat.toDouble(),
          lng.toDouble(),
        );
      }
      return {
        ...p,
        'latitude': lat.toDouble(),
        'longitude': lng.toDouble(),
        'distance_km': distKm,
      };
    }).toList();

    // Sort
    switch (_sortMode) {
      case 'rating':
        result.sort((a, b) {
          final ra = (a['rating'] as num?)?.toDouble() ?? 0;
          final rb = (b['rating'] as num?)?.toDouble() ?? 0;
          return rb.compareTo(ra);
        });
        break;
      case 'distance':
      default:
        result.sort((a, b) {
          final da = (a['distance_km'] as num?)?.toDouble() ?? 9999;
          final db = (b['distance_km'] as num?)?.toDouble() ?? 9999;
          return da.compareTo(db);
        });
    }

    _filteredProviders = result;
  }

  void _onMarkerTap(Map<String, dynamic> provider) {
    setState(() {
      _selectedProvider = provider;
      _selectedProviderOffers = [];
    });
    _sheetAnimController.forward(from: 0);
    // Load active offers for this provider
    final providerId = provider['id'] as String?;
    if (providerId != null) {
      SupabaseService.instance.getActiveProviderOffers(providerId).then((
        offers,
      ) {
        if (mounted && _selectedProvider?['id'] == providerId) {
          setState(() => _selectedProviderOffers = offers);
        }
      });
    }
  }

  void _closeSheet() {
    _sheetAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedProvider = null;
          _selectedProviderOffers = [];
        });
      }
    });
  }

  void _openProviderProfile() {
    if (_selectedProvider == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.providerProfileScreen,
      arguments: {'providerId': _selectedProvider!['id']},
    );
  }

  Future<void> _navigateToProvider(Map<String, dynamic> provider) async {
    final lat = (provider['business_latitude'] ?? provider['latitude']) as num?;
    final lng =
        (provider['business_longitude'] ?? provider['longitude']) as num?;
    if (lat == null || lng == null) return;
    final name = Uri.encodeComponent(
      provider['business_name'] as String? ?? 'Provider',
    );
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _categoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'shop':
        return AppTheme.catGrocery;
      case 'transport':
        return AppTheme.catTransport;
      case 'home_maintenance':
        return AppTheme.catPlumbing;
      case 'delivery':
        return AppTheme.catDelivery;
      case 'rent':
        return AppTheme.catRent;
      case 'events':
        return AppTheme.catEvents;
      case 'food':
        return AppTheme.catFood;
      case 'beauty':
        return AppTheme.catBeauty;
      case 'doctor':
        return AppTheme.catDoctor;
      default:
        return AppTheme.primary;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'shop':
        return Icons.storefront_rounded;
      case 'transport':
        return Icons.local_taxi_rounded;
      case 'home_maintenance':
        return Icons.home_repair_service_rounded;
      case 'delivery':
        return Icons.delivery_dining_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'events':
        return Icons.celebration_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'beauty':
        return Icons.spa_rounded;
      case 'doctor':
        return Icons.local_hospital_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          _buildMap(),

          // ── Top Bar ──────────────────────────────────────────────────────
          _buildTopBar(),

          // ── Category Filter Chips ─────────────────────────────────────
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: _buildCategoryFilter(),
          ),

          // ── Smart Expansion Banner ────────────────────────────────────
          if (_expansionMessage != null)
            Positioned(
              top: 155,
              left: 16,
              right: 16,
              child: _buildExpansionBanner(),
            ),

          // ── Sort & Radius Controls ────────────────────────────────────
          Positioned(
            bottom: _selectedProvider != null ? 330 : 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSortButton(),
                const SizedBox(height: 8),
                _buildRadiusButton(),
              ],
            ),
          ),

          // ── Provider Count Badge ──────────────────────────────────────
          Positioned(
            bottom: _selectedProvider != null ? 330 : 24,
            left: 16,
            child: _buildCountBadge(),
          ),

          // ── Provider Bottom Sheet ─────────────────────────────────────
          if (_selectedProvider != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildProviderSheet(),
            ),

          // ── Loading Overlay ───────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpansionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
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
          GestureDetector(
            onTap: () => setState(() => _expansionMessage = null),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final customerLatLng =
        _customerLocation != null && _customerLocation!.latitude != 0
        ? LatLng(_customerLocation!.latitude, _customerLocation!.longitude)
        : null;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: customerLatLng ?? _defaultCenter,
        initialZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (_, __) => _closeSheet(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.flutter_template.app',
        ),
        // Service radius circle for selected provider
        if (_selectedProvider != null) ...[
          CircleLayer(circles: _buildServiceRadiusCircles()),
        ],
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  List<CircleMarker> _buildServiceRadiusCircles() {
    final circles = <CircleMarker>[];
    // Customer location circle
    if (_customerLocation != null && _customerLocation!.latitude != 0) {
      circles.add(
        CircleMarker(
          point: LatLng(
            _customerLocation!.latitude,
            _customerLocation!.longitude,
          ),
          radius: _actualSearchedRadius * 1000,
          useRadiusInMeter: true,
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderColor: AppTheme.primary.withValues(alpha: 0.3),
          borderStrokeWidth: 1.5,
        ),
      );
    }
    // Selected provider service radius
    if (_selectedProvider != null) {
      final lat =
          (_selectedProvider!['business_latitude'] ??
                  _selectedProvider!['latitude'])
              as num?;
      final lng =
          (_selectedProvider!['business_longitude'] ??
                  _selectedProvider!['longitude'])
              as num?;
      final radius =
          (_selectedProvider!['service_radius_km'] as num?)?.toDouble() ?? 10;
      if (lat != null && lng != null && lat != 0) {
        circles.add(
          CircleMarker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            radius: radius * 1000,
            useRadiusInMeter: true,
            color: _categoryColor(
              _selectedProvider!['category'] as String?,
            ).withValues(alpha: 0.08),
            borderColor: _categoryColor(
              _selectedProvider!['category'] as String?,
            ).withValues(alpha: 0.4),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }
    return circles;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Customer location marker
    if (_customerLocation != null && _customerLocation!.latitude != 0) {
      markers.add(
        Marker(
          point: LatLng(
            _customerLocation!.latitude,
            _customerLocation!.longitude,
          ),
          width: 48,
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
        ),
      );
    }

    // Group providers by proximity for cluster simulation
    final Map<String, List<Map<String, dynamic>>> clusters = {};

    for (final p in _filteredProviders) {
      final lat = (p['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (p['longitude'] as num?)?.toDouble() ?? 0;
      // Round to 2 decimal places for clustering
      final key = '${(lat * 50).round() / 50}_${(lng * 50).round() / 50}';
      clusters.putIfAbsent(key, () => []).add(p);
    }

    for (final entry in clusters.entries) {
      final group = entry.value;
      final lat = (group.first['latitude'] as num).toDouble();
      final lng = (group.first['longitude'] as num).toDouble();

      if (group.length > 1) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () => _onMarkerTap(group.first),
              child: _ClusterMarker(count: group.length),
            ),
          ),
        );
      } else {
        final p = group.first;
        final color = _categoryColor(p['category'] as String?);
        final icon = _categoryIcon(p['category'] as String?);
        final isSelected = _selectedProvider?['id'] == p['id'];

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: isSelected ? 56 : 44,
            height: isSelected ? 64 : 52,
            child: GestureDetector(
              onTap: () => _onMarkerTap(p),
              child: _ProviderMarker(
                color: color,
                icon: icon,
                isSelected: isSelected,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.98),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _usingGpsLocation
                                ? Icons.gps_fixed
                                : Icons.location_on_outlined,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _customerLocation != null
                                  ? (_customerLocation!.district.isNotEmpty
                                        ? '${_customerLocation!.district}, ${_customerLocation!.state}'
                                        : _customerLocation!
                                              .fullAddress
                                              .isNotEmpty
                                        ? _customerLocation!.fullAddress
                                        : 'Nearby Providers')
                                  : 'Set your location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.grey,
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
      ),
    );
  }

  void _showLocationPicker() {
    Navigator.pushNamed(context, '/customer-location-setup-screen').then((
      result,
    ) {
      if (result == true) {
        _initLocationAndLoad();
      }
    });
  }

  Widget _buildCategoryFilter() {
    final categories = [null, ...AppCategories.all.map((c) => c.id)];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final catId = categories[i];
          final isSelected = _selectedCategory == catId;
          final cat = catId != null
              ? AppCategories.all.firstWhere(
                  (c) => c.id == catId,
                  orElse: () => AppCategories.all.first,
                )
              : null;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = catId;
                _applyFilters();
              });
              _loadProviders();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat != null) ...[
                    Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat?.name ?? 'All',
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
          );
        },
      ),
    );
  }

  Widget _buildSortButton() {
    final sortLabels = {'distance': 'Distance', 'rating': 'Rating'};
    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              sortLabels[_sortMode] ?? 'Sort',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusButton() {
    return GestureDetector(
      onTap: _showRadiusSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              '${_radiusKm.toInt()} km',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            '${_filteredProviders.length} providers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF44474E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSheet() {
    final p = _selectedProvider!;
    final rating = (p['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = p['review_count'] as int? ?? 0;
    final name = p['business_name'] as String? ?? 'Provider';
    final category = p['category'] as String? ?? '';
    final city = p['city'] as String? ?? '';
    final address =
        p['business_address'] as String? ?? p['address'] as String? ?? '';
    final imageUrl = p['image_url'] as String?;
    final color = _categoryColor(category);
    final icon = _categoryIcon(category);
    final isVerified = p['is_verified'] as bool? ?? false;
    final isOpen = p['is_open'] as bool? ?? true;
    final distanceKm = (p['distance_km'] as num?)?.toDouble();
    final serviceRadiusKm = (p['service_radius_km'] as num?)?.toDouble() ?? 10;

    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _sheetAnim.value) * 300),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Provider image / icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(icon, color: color, size: 28),
                                ),
                              )
                            : Icon(icon, color: color, size: 28),
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
                                    name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1C1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 10,
                                          color: AppTheme.success,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    category.replaceAll('_', ' ').toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: AppTheme.secondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    address.isNotEmpty ? address : city,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF74777F),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Distance, travel time, status, service radius row
                  Row(
                    children: [
                      if (distanceKm != null && distanceKm < 9999) ...[
                        _InfoChip(
                          icon: Icons.near_me_rounded,
                          label: LocationService.instance.formatDistance(
                            distanceKm,
                          ),
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: LocationService.instance.estimateTravelTime(
                            distanceKm,
                          ),
                          color: const Color(0xFF5C6BC0),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _InfoChip(
                        icon: isOpen
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        label: isOpen ? 'Open' : 'Closed',
                        color: isOpen ? AppTheme.success : AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.radar_rounded,
                        label: '${serviceRadiusKm.toInt()} km radius',
                        color: const Color(0xFF795548),
                      ),
                    ],
                  ),
                  // Active offers strip
                  if (_selectedProviderOffers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedProviderOffers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final o = _selectedProviderOffers[i];
                          final type =
                              o['discount_type'] as String? ?? 'percentage';
                          final val =
                              (o['discount_value'] as num?)?.toDouble() ?? 0;
                          final label = type == 'flat'
                              ? '₹${val.toStringAsFixed(0)} OFF'
                              : '${val.toStringAsFixed(0)}% OFF';
                          final code = o['promo_code'] as String?;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  code != null && code.isNotEmpty
                                      ? '$label • $code'
                                      : label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Navigate button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _navigateToProvider(_selectedProvider!),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(
                            'Navigate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _openProviderProfile,
                          icon: const Icon(Icons.person_rounded, size: 16),
                          label: Text(
                            'View Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    ),
    );
  }

  void _showSortSheet() {
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
              'Sort Providers By',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('distance', Icons.near_me_rounded, 'Distance (Nearest First)'),
              ('rating', Icons.star_rounded, 'Rating (Highest First)'),
            ].map((item) {
              final isSelected = _sortMode == item.$1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _sortMode = item.$1;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$2,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFF44474E),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.$3,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF44474E),
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showRadiusSheet() {
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
              'Search Radius',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Providers are shown only if you are within their service area.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _radiusOptions.map((r) {
                final isSelected = _radiusKm == r;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _radiusKm = r;
                    });
                    Navigator.pop(context);
                    _loadProviders();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${r.toInt()} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF44474E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip Widget ──────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Marker Widgets ─────────────────────────────────────────────────────

class _ProviderMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;

  const _ProviderMarker({
    required this.color,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 48 : 38,
          height: isSelected ? 48 : 38,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isSelected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.45 : 0.25),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: isSelected ? 22 : 18,
            color: isSelected ? Colors.white : color,
          ),
        ),
        // Pin tail
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTailPainter(color: color),
        ),
      ],
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  final int count;

  const _ClusterMarker({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              count > 99 ? '99+' : '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: count > 9 ? 11 : 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTailPainter(color: AppTheme.primary),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
