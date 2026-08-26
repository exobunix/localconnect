import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './supabase_service.dart';

/// Represents a resolved location with all address components
class LocationData {
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String village;
  final String city;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final String method; // 'gps', 'map', 'manual'

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    this.village = '',
    this.city = '',
    this.taluka = '',
    this.district = '',
    this.state = 'Maharashtra',
    this.pincode = '',
    this.method = 'gps',
  });

  String get displayCity {
    if (city.isNotEmpty) return city;
    if (district.isNotEmpty) return district;
    if (village.isNotEmpty) return village;
    if (taluka.isNotEmpty) return taluka;
    return '';
  }

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'full_address': fullAddress,
    'village': village,
    'city': city,
    'taluka': taluka,
    'district': district,
    'state': state,
    'pincode': pincode,
    'location_method': method,
    'location_updated_at': DateTime.now().toIso8601String(),
  };

  factory LocationData.fromMap(Map<String, dynamic> m) => LocationData(
    latitude: (m['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (m['longitude'] as num?)?.toDouble() ?? 0,
    fullAddress: m['full_address'] as String? ?? '',
    village: m['village'] as String? ?? '',
    city: m['city'] as String? ?? '',
    taluka: m['taluka'] as String? ?? '',
    district: m['district'] as String? ?? '',
    state: m['state'] as String? ?? 'Maharashtra',
    pincode: m['pincode'] as String? ?? '',
    method: m['location_method'] as String? ?? 'manual',
  );
}

/// Result of a smart nearby providers search with expansion info
class NearbyProvidersResult {
  final List<Map<String, dynamic>> providers;
  final double searchedRadiusKm;
  final bool wasExpanded;
  final double? originalRadiusKm;

  const NearbyProvidersResult({
    required this.providers,
    required this.searchedRadiusKm,
    this.wasExpanded = false,
    this.originalRadiusKm,
  });

  String? get expansionMessage {
    if (!wasExpanded || originalRadiusKm == null) return null;
    if (providers.isEmpty) {
      return 'No providers found within ${searchedRadiusKm.toInt()} km.';
    }
    return 'No providers found within ${originalRadiusKm!.toInt()} km. Showing providers within ${searchedRadiusKm.toInt()} km.';
  }
}

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._() {
    loadSearchRadius();
  }

  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  double _searchRadius = 50.0;
  double get searchRadius => _searchRadius;

  Future<void> saveSearchRadius(double radius) async {
    _searchRadius = radius;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('search_radius_km', radius);
    } catch (_) {}
  }

  Future<double> loadSearchRadius() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchRadius = prefs.getDouble('search_radius_km') ?? 50.0;
    } catch (_) {}
    return _searchRadius;
  }

  // Smart expansion radii (can be overridden by admin settings)
  static const List<double> _smartRadii = [5, 10, 20, 50];
  static const int _minProvidersThreshold = 3;

  LocationData? _lastKnownLocation;
  LocationData? get lastKnownLocation => _lastKnownLocation;

  static const String _prefCachedLat = 'cached_user_lat';
  static const String _prefCachedLng = 'cached_user_lng';
  static const String _prefCachedCity = 'cached_user_city';
  static const String _prefCachedDistrict = 'cached_user_district';
  static const String _prefCachedAddress = 'cached_user_address';

  Future<void> cacheLocationLocally(LocationData location) async {
    _lastKnownLocation = location;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefCachedLat, location.latitude);
      await prefs.setDouble(_prefCachedLng, location.longitude);
      await prefs.setString(_prefCachedCity, location.city);
      await prefs.setString(_prefCachedDistrict, location.district);
      await prefs.setString(_prefCachedAddress, location.fullAddress);
    } catch (_) {}
  }

  Future<LocationData?> getCachedLocalLocation() async {
    if (_lastKnownLocation != null) return _lastKnownLocation;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefCachedLat);
      final lng = prefs.getDouble(_prefCachedLng);
      final city = prefs.getString(_prefCachedCity) ?? '';
      final district = prefs.getString(_prefCachedDistrict) ?? '';
      final addr = prefs.getString(_prefCachedAddress) ?? '';
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        _lastKnownLocation = LocationData(
          latitude: lat,
          longitude: lng,
          fullAddress: addr,
          city: city,
          district: district,
          method: 'cached',
        );
        return _lastKnownLocation;
      }
    } catch (_) {}
    return null;
  }

  // ─── Permission & GPS ────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return kIsWeb; // On web, browser will prompt on getCurrentPosition
    }
  }

  Future<Position?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  // ─── Reverse Geocoding (Nominatim - free, no key required) ───────────────

  Future<LocationData?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'LocalConnect/1.0'}),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final displayName = data['display_name'] as String? ?? '';

        // Extract address components
        final village =
            addr['village'] as String? ??
            addr['hamlet'] as String? ??
            addr['neighbourhood'] as String? ??
            addr['suburb'] as String? ??
            '';
        final city =
            addr['city'] as String? ??
            addr['town'] as String? ??
            addr['municipality'] as String? ??
            addr['city_district'] as String? ??
            addr['suburb'] as String? ??
            '';
        final taluka =
            addr['county'] as String? ??
            addr['state_district'] as String? ??
            '';
        final district =
            addr['state_district'] as String? ??
            addr['district'] as String? ??
            addr['county'] as String? ??
            '';
        final state = addr['state'] as String? ?? 'Maharashtra';
        final pincode = addr['postcode'] as String? ?? '';

        return LocationData(
          latitude: lat,
          longitude: lng,
          fullAddress: displayName,
          village: village,
          city: city,
          taluka: taluka,
          district: district,
          state: state,
          pincode: pincode,
          method: 'gps',
        );
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return null;
  }

  // ─── GPS Location ─────────────────────────────────────────────────────────

  Future<LocationData?> getGpsLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final pos = await getCurrentPosition(timeout: timeout);
    if (pos == null) {
      return await getCachedLocalLocation();
    }
    final data = await reverseGeocode(pos.latitude, pos.longitude);
    final resolved = data ??
        LocationData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          fullAddress:
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
          method: 'gps',
        );
    await cacheLocationLocally(resolved);
    return resolved;
  }

  // ─── Save Location as Saved Address ──────────────────────────────────────

  /// Converts a LocationData into a saved address entry in the DB.
  Future<void> saveLocationAsAddress({
    required LocationData location,
    required String label,
  }) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    final addressLine1 = location.village.isNotEmpty
        ? location.village
        : location.city.isNotEmpty
        ? location.city
        : location.fullAddress.split(',').first.trim();
    await SupabaseService.instance.addAddress(
      label: label,
      addressLine1: addressLine1,
      city: location.city.isNotEmpty ? location.city : location.district,
      state: location.state,
      pincode: location.pincode,
      village: location.village,
      taluka: location.taluka,
      district: location.district,
      fullAddress: location.fullAddress,
      latitude: location.latitude != 0 ? location.latitude : null,
      longitude: location.longitude != 0 ? location.longitude : null,
      locationMethod: location.method,
    );
  }

  // ─── Save Customer Location ───────────────────────────────────────────────

  Future<void> saveCustomerLocation(LocationData location) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    await SupabaseService.instance.client
        .from('user_profiles')
        .update(location.toMap())
        .eq('id', userId);
  }

  Future<LocationData?> getCustomerLocation() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return null;
    try {
      final data = await SupabaseService.instance.client
          .from('user_profiles')
          .select(
            'latitude, longitude, full_address, village, city, taluka, district, state, pincode, location_method',
          )
          .eq('id', userId)
          .maybeSingle();
      if (data == null || data['latitude'] == null) return null;
      return LocationData.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ─── Save Provider Location ───────────────────────────────────────────────

  Future<void> saveProviderLocation({
    required String providerId,
    required LocationData location,
  }) async {
    await SupabaseService.instance.client
        .from('service_providers')
        .update({
          'business_latitude': location.latitude,
          'business_longitude': location.longitude,
          'business_address': location.fullAddress,
          'village': location.village,
          'city': location.city,
          'taluka': location.taluka,
          'district': location.district,
          'state': location.state,
          'pincode': location.pincode,
          'location_updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', providerId);
  }

  // ─── Save Provider Service Area ───────────────────────────────────────────

  Future<void> saveProviderServiceArea({
    required String providerId,
    required double radiusKm,
    required String serviceMode,
    required List<String> villages,
    required List<String> talukas,
    required List<String> districts,
  }) async {
    await SupabaseService.instance.client
        .from('service_providers')
        .update({
          'service_radius_km': radiusKm,
          'service_mode': serviceMode,
          'service_villages': villages,
          'service_talukas': talukas,
          'service_districts': districts,
        })
        .eq('id', providerId);
  }

  // ─── Nearby Providers (GPS-based with Haversine via RPC) ─────────────────

  Future<List<Map<String, dynamic>>> getNearbyProviders({
    required double lat,
    required double lng,
    double radiusKm = 50,
    String? village,
    String? taluka,
    String? district,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await SupabaseService.instance.client.rpc(
        'get_nearby_providers',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': radiusKm,
          if (village != null && village.isNotEmpty) 'p_village': village,
          if (taluka != null && taluka.isNotEmpty) 'p_taluka': taluka,
          if (district != null && district.isNotEmpty) 'p_district': district,
          if (category != null && category.isNotEmpty) 'p_category': category,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      debugPrint('getNearbyProviders error: $e');
      return [];
    }
  }

  /// Smart nearby providers search with automatic radius expansion.
  /// Tries progressively larger radii until enough providers are found.
  Future<NearbyProvidersResult> getNearbyProvidersSmart({
    required double lat,
    required double lng,
    double? initialRadiusKm,
    String? category,
    int limit = 50,
    int minProviders = _minProvidersThreshold,
  }) async {
    // Load admin settings for smart expansion radii
    final baseRadii = await _getSmartRadii(category);
    final radii = List<double>.from(baseRadii);
    if (!radii.contains(_searchRadius)) {
      radii.add(_searchRadius);
      radii.sort();
    }
    // Filter out step elements that exceed the custom searchRadius limits
    radii.removeWhere((r) => r > _searchRadius);
    if (radii.isEmpty || (radii.isNotEmpty && radii.last != _searchRadius)) {
      radii.add(_searchRadius);
    }
    
    final startRadius = initialRadiusKm ?? radii.first;

    // Try each radius step
    for (int i = 0; i < radii.length; i++) {
      final radius = radii[i];
      if (radius < startRadius && initialRadiusKm != null) continue;

      try {
        final result = await SupabaseService.instance.client.rpc(
          'get_nearby_providers_smart',
          params: {
            'p_lat': lat,
            'p_lng': lng,
            'p_radius_km': radius,
            if (category != null && category.isNotEmpty) 'p_category': category,
            'p_limit': limit,
            'p_offset': 0,
          },
        );
        final providers = List<Map<String, dynamic>>.from(result as List);

        if (providers.length >= minProviders || i == radii.length - 1) {
          return NearbyProvidersResult(
            providers: providers,
            searchedRadiusKm: radius,
            wasExpanded: radius > startRadius,
            originalRadiusKm: radius > startRadius ? startRadius : null,
          );
        }
      } catch (e) {
        debugPrint('getNearbyProvidersSmart error at radius $radius: $e');
        // Fall back to basic getNearbyProviders
        final fallback = await getNearbyProviders(
          lat: lat,
          lng: lng,
          radiusKm: radius,
          category: category,
          limit: limit,
        );
        return NearbyProvidersResult(
          providers: fallback,
          searchedRadiusKm: radius,
          wasExpanded: radius > startRadius,
          originalRadiusKm: radius > startRadius ? startRadius : null,
        );
      }
    }

    return const NearbyProvidersResult(providers: [], searchedRadiusKm: 50);
  }

  /// Load smart expansion radii from admin settings (with fallback defaults)
  Future<List<double>> _getSmartRadii(String? category) async {
    try {
      final rows = await SupabaseService.instance.client
          .from('admin_location_settings')
          .select('setting_key, setting_value')
          .inFilter('setting_key', [
            'smart_expand_step1_km',
            'smart_expand_step2_km',
            'smart_expand_step3_km',
            'smart_expand_step4_km',
          ]);

      if (rows.isNotEmpty) {
        final map = <String, double>{};
        for (final row in rows) {
          final key = row['setting_key'] as String;
          final val =
              double.tryParse(row['setting_value'] as String? ?? '') ?? 0;
          map[key] = val;
        }
        final radii = [
          map['smart_expand_step1_km'] ?? 5,
          map['smart_expand_step2_km'] ?? 10,
          map['smart_expand_step3_km'] ?? 20,
          map['smart_expand_step4_km'] ?? 50,
        ].where((r) => r > 0).toList();
        if (radii.isNotEmpty) return radii;
      }
    } catch (_) {}
    return _smartRadii;
  }

  // ─── Booking Validation ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> validateServiceArea({
    required String providerId,
    required double customerLat,
    required double customerLng,
    String? customerVillage,
    String? customerTaluka,
    String? customerDistrict,
  }) async {
    try {
      final result = await SupabaseService.instance.client.rpc(
        'validate_provider_service_area',
        params: {
          'p_provider_id': providerId,
          'p_customer_lat': customerLat,
          'p_customer_lng': customerLng,
          if (customerVillage != null && customerVillage.isNotEmpty)
            'p_customer_village': customerVillage,
          if (customerTaluka != null && customerTaluka.isNotEmpty)
            'p_customer_taluka': customerTaluka,
          if (customerDistrict != null && customerDistrict.isNotEmpty)
            'p_customer_district': customerDistrict,
        },
      );
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      return {'eligible': true, 'reason': 'Validation unavailable'};
    }
  }

  // ─── Distance Calculation (client-side Haversine) ────────────────────────

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  /// Estimate travel time based on distance (rough approximation)
  String estimateTravelTime(double km) {
    if (km < 1) {
      final mins = (km * 1000 / 80).round(); // walking ~80m/min
      return '${mins < 1 ? 1 : mins} min walk';
    } else if (km < 5) {
      final mins = (km / 0.5).round(); // ~30 km/h in local traffic
      return '$mins min';
    } else {
      final mins = (km / 0.67).round(); // ~40 km/h
      return '$mins min';
    }
  }

  // ─── Admin Location Settings ──────────────────────────────────────────────

  Future<Map<String, String>> getAdminLocationSettings() async {
    try {
      final rows = await SupabaseService.instance.client
          .from('admin_location_settings')
          .select('setting_key, setting_value');
      return {
        for (final row in rows)
          row['setting_key'] as String: row['setting_value'] as String,
      };
        } catch (e) {
      debugPrint('getAdminLocationSettings error: $e');
    }
    return {};
  }

  Future<void> updateAdminLocationSetting(String key, String value) async {
    await SupabaseService.instance.client
        .from('admin_location_settings')
        .upsert({
          'setting_key': key,
          'setting_value': value,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': SupabaseService.instance.currentUser?.id,
        }, onConflict: 'setting_key');
  }
}
