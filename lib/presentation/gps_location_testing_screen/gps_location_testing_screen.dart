import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/location_service.dart';
import '../../services/supabase_service.dart';

enum _TestStatus { idle, running, passed, failed, warning }

class _TestResult {
  final String name;
  final _TestStatus status;
  final String message;
  final Map<String, dynamic>? data;
  final Duration? duration;

  const _TestResult({
    required this.name,
    required this.status,
    required this.message,
    this.data,
    this.duration,
  });
}

class GpsLocationTestingScreen extends StatefulWidget {
  const GpsLocationTestingScreen({super.key});

  @override
  State<GpsLocationTestingScreen> createState() =>
      _GpsLocationTestingScreenState();
}

class _GpsLocationTestingScreenState extends State<GpsLocationTestingScreen> {
  final List<_TestResult> _results = [];
  bool _isRunning = false;
  bool _allDone = false;
  LocationData? _detectedLocation;
  int _passCount = 0;
  int _failCount = 0;
  int _warnCount = 0;

  // Manual override for testing
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '10');
  final _providerIdController = TextEditingController();
  bool _useManualCoords = false;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _providerIdController.dispose();
    super.dispose();
  }

  void _addResult(_TestResult result) {
    if (mounted) {
      setState(() {
        _results.add(result);
        if (result.status == _TestStatus.passed) _passCount++;
        if (result.status == _TestStatus.failed) _failCount++;
        if (result.status == _TestStatus.warning) _warnCount++;
      });
    }
  }

  Future<void> _runAllTests() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _allDone = false;
      _results.clear();
      _passCount = 0;
      _failCount = 0;
      _warnCount = 0;
      _detectedLocation = null;
    });

    await _testGpsPermission();
    await _testGpsDetection();
    await _testDistanceCalculation();
    await _testReverseGeocoding();
    await _testNearbyProvidersBasic();
    await _testSmartRadiusExpansion();
    await _testServiceRadiusValidation();
    await _testBookingEligibility();
    await _testAdminLocationSettings();
    await _testSupabaseRpcFunctions();

    if (mounted) {
      setState(() {
        _isRunning = false;
        _allDone = true;
      });
    }
  }

  // ── Test 1: GPS Permission ─────────────────────────────────────────────────
  Future<void> _testGpsPermission() async {
    final sw = Stopwatch()..start();
    try {
      final granted = await LocationService.instance.requestPermission();
      sw.stop();
      _addResult(
        _TestResult(
          name: 'GPS Permission',
          status: granted ? _TestStatus.passed : _TestStatus.warning,
          message: granted
              ? 'Location permission granted'
              : 'Permission denied — manual coords will be used for remaining tests',
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'GPS Permission',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 2: GPS Detection ──────────────────────────────────────────────────
  Future<void> _testGpsDetection() async {
    final sw = Stopwatch()..start();
    try {
      if (_useManualCoords) {
        final lat = double.tryParse(_latController.text);
        final lng = double.tryParse(_lngController.text);
        if (lat == null || lng == null) {
          _addResult(
            _TestResult(
              name: 'GPS Detection',
              status: _TestStatus.warning,
              message: 'Manual mode: invalid coordinates entered',
              duration: sw.elapsed,
            ),
          );
          return;
        }
        _detectedLocation = LocationData(
          latitude: lat,
          longitude: lng,
          fullAddress: 'Manual: $lat, $lng',
          method: 'manual',
        );
        sw.stop();
        _addResult(
          _TestResult(
            name: 'GPS Detection',
            status: _TestStatus.passed,
            message: 'Manual coordinates accepted',
            data: {'lat': lat, 'lng': lng},
            duration: sw.elapsed,
          ),
        );
        return;
      }

      final pos = await LocationService.instance.getCurrentPosition();
      sw.stop();
      if (pos == null) {
        _addResult(
          _TestResult(
            name: 'GPS Detection',
            status: _TestStatus.failed,
            message:
                'Could not get GPS position — check permissions or enable location services',
            duration: sw.elapsed,
          ),
        );
        return;
      }
      _detectedLocation = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        fullAddress:
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
        method: 'gps',
      );
      _addResult(
        _TestResult(
          name: 'GPS Detection',
          status: _TestStatus.passed,
          message: 'GPS fix acquired',
          data: {
            'lat': pos.latitude.toStringAsFixed(6),
            'lng': pos.longitude.toStringAsFixed(6),
            'accuracy': '${pos.accuracy.toStringAsFixed(1)} m',
            'altitude': '${pos.altitude.toStringAsFixed(1)} m',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'GPS Detection',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 3: Distance Calculation ───────────────────────────────────────────
  Future<void> _testDistanceCalculation() async {
    final sw = Stopwatch()..start();
    try {
      // Known reference: Mumbai to Pune ≈ 148 km
      const lat1 = 19.0760, lng1 = 72.8777; // Mumbai
      const lat2 = 18.5204, lng2 = 73.8567; // Pune

      final dist = LocationService.instance.calculateDistance(
        lat1,
        lng1,
        lat2,
        lng2,
      );
      final formatted = LocationService.instance.formatDistance(dist);
      final travel = LocationService.instance.estimateTravelTime(dist);

      // Haversine Mumbai-Pune should be ~148 km (allow ±10 km tolerance)
      final isAccurate = dist >= 138 && dist <= 158;
      sw.stop();

      // Also test short distance (< 1 km)
      final shortDist = LocationService.instance.calculateDistance(
        19.0760,
        72.8777,
        19.0770,
        72.8787,
      );
      final shortFormatted = LocationService.instance.formatDistance(shortDist);

      _addResult(
        _TestResult(
          name: 'Distance Calculation (Haversine)',
          status: isAccurate ? _TestStatus.passed : _TestStatus.warning,
          message: isAccurate
              ? 'Haversine formula accurate within tolerance'
              : 'Distance ${dist.toStringAsFixed(1)} km — expected ~148 km for Mumbai→Pune',
          data: {
            'Mumbai→Pune': '${dist.toStringAsFixed(2)} km',
            'formatted': formatted,
            'travel_time': travel,
            'short_distance': shortFormatted,
            'accuracy': isAccurate
                ? '✅ Within ±10 km tolerance'
                : '⚠️ Outside tolerance',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Distance Calculation (Haversine)',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 4: Reverse Geocoding ──────────────────────────────────────────────
  Future<void> _testReverseGeocoding() async {
    if (_detectedLocation == null) {
      _addResult(
        const _TestResult(
          name: 'Reverse Geocoding',
          status: _TestStatus.warning,
          message: 'Skipped — no GPS position available',
        ),
      );
      return;
    }
    final sw = Stopwatch()..start();
    try {
      final loc = await LocationService.instance.reverseGeocode(
        _detectedLocation!.latitude,
        _detectedLocation!.longitude,
      );
      sw.stop();
      if (loc == null) {
        _addResult(
          _TestResult(
            name: 'Reverse Geocoding',
            status: _TestStatus.warning,
            message: 'Nominatim returned null — network issue or rate limit',
            duration: sw.elapsed,
          ),
        );
        return;
      }
      _detectedLocation = loc;
      _addResult(
        _TestResult(
          name: 'Reverse Geocoding',
          status: _TestStatus.passed,
          message: 'Address resolved via Nominatim',
          data: {
            'address': loc.fullAddress.length > 60
                ? '${loc.fullAddress.substring(0, 60)}…'
                : loc.fullAddress,
            'village': loc.village.isEmpty ? '(none)' : loc.village,
            'city': loc.city.isEmpty ? '(none)' : loc.city,
            'district': loc.district.isEmpty ? '(none)' : loc.district,
            'state': loc.state,
            'pincode': loc.pincode.isEmpty ? '(none)' : loc.pincode,
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Reverse Geocoding',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 5: Nearby Providers (Basic) ──────────────────────────────────────
  Future<void> _testNearbyProvidersBasic() async {
    final lat = _detectedLocation?.latitude ?? 19.0760;
    final lng = _detectedLocation?.longitude ?? 72.8777;
    final radius = double.tryParse(_radiusController.text) ?? 10.0;

    final sw = Stopwatch()..start();
    try {
      final providers = await LocationService.instance.getNearbyProviders(
        lat: lat,
        lng: lng,
        radiusKm: radius,
        limit: 20,
      );
      sw.stop();

      final hasDistance =
          providers.isNotEmpty && providers.first.containsKey('distance_km');

      _addResult(
        _TestResult(
          name: 'Nearby Providers (Basic RPC)',
          status: providers.isNotEmpty
              ? _TestStatus.passed
              : _TestStatus.warning,
          message: providers.isNotEmpty
              ? 'Found ${providers.length} provider(s) within ${radius.toInt()} km'
              : 'No providers found within ${radius.toInt()} km — try increasing radius',
          data: {
            'search_lat': lat.toStringAsFixed(5),
            'search_lng': lng.toStringAsFixed(5),
            'radius_km': '${radius.toInt()} km',
            'providers_found': providers.length.toString(),
            'distance_field_present': hasDistance ? '✅ Yes' : '⚠️ No',
            if (providers.isNotEmpty)
              'nearest':
                  providers.first['business_name'] as String? ??
                  providers.first['name'] as String? ??
                  'Unknown',
            if (providers.isNotEmpty && hasDistance)
              'nearest_distance':
                  '${(providers.first['distance_km'] as num?)?.toStringAsFixed(2) ?? '?'} km',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Nearby Providers (Basic RPC)',
          status: _TestStatus.failed,
          message: 'RPC error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 6: Smart Radius Expansion ────────────────────────────────────────
  Future<void> _testSmartRadiusExpansion() async {
    final lat = _detectedLocation?.latitude ?? 19.0760;
    final lng = _detectedLocation?.longitude ?? 72.8777;

    final sw = Stopwatch()..start();
    try {
      final result = await LocationService.instance.getNearbyProvidersSmart(
        lat: lat,
        lng: lng,
        initialRadiusKm: 5,
        minProviders: 3,
      );
      sw.stop();

      _addResult(
        _TestResult(
          name: 'Smart Radius Expansion',
          status: _TestStatus.passed,
          message: result.wasExpanded
              ? 'Radius auto-expanded: ${result.originalRadiusKm?.toInt()} km → ${result.searchedRadiusKm.toInt()} km'
              : 'Found ${result.providers.length} provider(s) within initial 5 km radius',
          data: {
            'initial_radius': '5 km',
            'final_radius': '${result.searchedRadiusKm.toInt()} km',
            'was_expanded': result.wasExpanded ? '✅ Yes' : 'No',
            'providers_found': result.providers.length.toString(),
            'expansion_message':
                result.expansionMessage ?? 'No expansion needed',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Smart Radius Expansion',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 7: Service Radius Validation ─────────────────────────────────────
  Future<void> _testServiceRadiusValidation() async {
    final sw = Stopwatch()..start();
    try {
      // Fetch a real provider from DB to test against
      final providers = await SupabaseService.instance.client
          .from('service_providers')
          .select(
            'id, business_name, service_radius_km, business_latitude, business_longitude',
          )
          .not('business_latitude', 'is', null)
          .not('service_radius_km', 'is', null)
          .limit(5);

      if (providers.isEmpty) {
        sw.stop();
        _addResult(
          _TestResult(
            name: 'Service Radius Validation',
            status: _TestStatus.warning,
            message: 'No providers with GPS + service radius found in DB',
            duration: sw.elapsed,
          ),
        );
        return;
      }

      final provider = providers.first;
      final provLat = (provider['business_latitude'] as num?)?.toDouble();
      final provLng = (provider['business_longitude'] as num?)?.toDouble();
      final serviceRadius =
          (provider['service_radius_km'] as num?)?.toDouble() ?? 10;

      if (provLat == null || provLng == null) {
        sw.stop();
        _addResult(
          _TestResult(
            name: 'Service Radius Validation',
            status: _TestStatus.warning,
            message: 'Provider has null coordinates',
            duration: sw.elapsed,
          ),
        );
        return;
      }

      final custLat = _detectedLocation?.latitude ?? 19.0760;
      final custLng = _detectedLocation?.longitude ?? 72.8777;

      final distKm = LocationService.instance.calculateDistance(
        custLat,
        custLng,
        provLat,
        provLng,
      );
      final withinRadius = distKm <= serviceRadius;

      sw.stop();
      _addResult(
        _TestResult(
          name: 'Service Radius Validation',
          status: _TestStatus.passed,
          message: withinRadius
              ? 'Customer is within provider service radius'
              : 'Customer is outside provider service radius (expected for distant providers)',
          data: {
            'provider': provider['business_name'] as String? ?? 'Unknown',
            'provider_lat': provLat.toStringAsFixed(5),
            'provider_lng': provLng.toStringAsFixed(5),
            'service_radius': '${serviceRadius.toInt()} km',
            'customer_distance': '${distKm.toStringAsFixed(2)} km',
            'within_radius': withinRadius ? '✅ Yes' : '❌ No',
            'providers_tested': providers.length.toString(),
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Service Radius Validation',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 8: Booking Eligibility ────────────────────────────────────────────
  Future<void> _testBookingEligibility() async {
    final sw = Stopwatch()..start();
    try {
      // Get a provider with GPS coords
      final providers = await SupabaseService.instance.client
          .from('service_providers')
          .select('id, business_name, is_active, is_approved')
          .eq('is_active', true)
          .eq('is_approved', true)
          .not('business_latitude', 'is', null)
          .limit(3);

      if (providers.isEmpty) {
        sw.stop();
        _addResult(
          _TestResult(
            name: 'Booking Eligibility',
            status: _TestStatus.warning,
            message: 'No active+approved providers with GPS found in DB',
            duration: sw.elapsed,
          ),
        );
        return;
      }

      final provider = providers.first;
      final providerId = provider['id'] as String;
      final custLat = _detectedLocation?.latitude ?? 19.0760;
      final custLng = _detectedLocation?.longitude ?? 72.8777;

      final validation = await LocationService.instance.validateServiceArea(
        providerId: providerId,
        customerLat: custLat,
        customerLng: custLng,
        customerVillage: _detectedLocation?.village,
        customerTaluka: _detectedLocation?.taluka,
        customerDistrict: _detectedLocation?.district,
      );

      sw.stop();
      final eligible = validation['eligible'] as bool? ?? true;

      _addResult(
        _TestResult(
          name: 'Booking Eligibility',
          status: eligible ? _TestStatus.passed : _TestStatus.warning,
          message: eligible
              ? 'Provider accepts bookings from customer location'
              : 'Provider does not serve customer location',
          data: {
            'provider': provider['business_name'] as String? ?? 'Unknown',
            'provider_id': providerId.substring(0, 8),
            'eligible': eligible ? '✅ Yes' : '❌ No',
            'reason': validation['reason'] as String? ?? 'N/A',
            'distance_km': validation['distance_km']?.toString() ?? 'N/A',
            'service_radius_km':
                validation['service_radius_km']?.toString() ?? 'N/A',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Booking Eligibility',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 9: Admin Location Settings ───────────────────────────────────────
  Future<void> _testAdminLocationSettings() async {
    final sw = Stopwatch()..start();
    try {
      final settings = await LocationService.instance
          .getAdminLocationSettings();
      sw.stop();

      final hasSettings = settings.isNotEmpty;
      final requiredKeys = [
        'default_search_radius_km',
        'smart_expand_step1_km',
        'smart_expand_step2_km',
        'smart_expand_step3_km',
        'smart_expand_step4_km',
      ];
      final missingKeys = requiredKeys
          .where((k) => !settings.containsKey(k))
          .toList();

      _addResult(
        _TestResult(
          name: 'Admin Location Settings',
          status: hasSettings && missingKeys.isEmpty
              ? _TestStatus.passed
              : hasSettings
              ? _TestStatus.warning
              : _TestStatus.warning,
          message: !hasSettings
              ? 'No admin settings found — defaults will be used (5/10/20/50 km)'
              : missingKeys.isNotEmpty
              ? 'Missing keys: ${missingKeys.join(', ')}'
              : 'All ${settings.length} settings loaded from DB',
          data: {
            'total_settings': settings.length.toString(),
            'default_radius':
                settings['default_search_radius_km'] ?? '(default: 10)',
            'expand_step1': settings['smart_expand_step1_km'] ?? '(default: 5)',
            'expand_step2':
                settings['smart_expand_step2_km'] ?? '(default: 10)',
            'expand_step3':
                settings['smart_expand_step3_km'] ?? '(default: 20)',
            'expand_step4':
                settings['smart_expand_step4_km'] ?? '(default: 50)',
          },
          duration: sw.elapsed,
        ),
      );
    } catch (e) {
      sw.stop();
      _addResult(
        _TestResult(
          name: 'Admin Location Settings',
          status: _TestStatus.failed,
          message: 'Error: $e',
          duration: sw.elapsed,
        ),
      );
    }
  }

  // ── Test 10: Supabase RPC Functions ───────────────────────────────────────
  Future<void> _testSupabaseRpcFunctions() async {
    final lat = _detectedLocation?.latitude ?? 19.0760;
    final lng = _detectedLocation?.longitude ?? 72.8777;

    final sw = Stopwatch()..start();
    final rpcResults = <String, String>{};

    // Test get_nearby_providers RPC
    try {
      await SupabaseService.instance.client.rpc(
        'get_nearby_providers',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': 50.0,
          'p_limit': 1,
          'p_offset': 0,
        },
      );
      rpcResults['get_nearby_providers'] = '✅ OK';
    } catch (e) {
      rpcResults['get_nearby_providers'] = '❌ ${e.toString().substring(0, 50)}';
    }

    // Test get_nearby_providers_smart RPC
    try {
      await SupabaseService.instance.client.rpc(
        'get_nearby_providers_smart',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': 50.0,
          'p_limit': 1,
          'p_offset': 0,
        },
      );
      rpcResults['get_nearby_providers_smart'] = '✅ OK';
    } catch (e) {
      rpcResults['get_nearby_providers_smart'] =
          '❌ ${e.toString().substring(0, 50)}';
    }

    // Test validate_provider_service_area RPC (needs a real provider ID)
    try {
      final providers = await SupabaseService.instance.client
          .from('service_providers')
          .select('id')
          .limit(1);
      if (providers.isNotEmpty) {
        await SupabaseService.instance.client.rpc(
          'validate_provider_service_area',
          params: {
            'p_provider_id': providers.first['id'],
            'p_customer_lat': lat,
            'p_customer_lng': lng,
          },
        );
        rpcResults['validate_provider_service_area'] = '✅ OK';
      } else {
        rpcResults['validate_provider_service_area'] =
            '⚠️ No providers to test';
      }
    } catch (e) {
      rpcResults['validate_provider_service_area'] =
          '❌ ${e.toString().substring(0, 50)}';
    }

    sw.stop();

    final allOk = rpcResults.values.every((v) => v.startsWith('✅'));
    final anyFailed = rpcResults.values.any((v) => v.startsWith('❌'));

    _addResult(
      _TestResult(
        name: 'Supabase RPC Functions',
        status: allOk
            ? _TestStatus.passed
            : anyFailed
            ? _TestStatus.failed
            : _TestStatus.warning,
        message: allOk
            ? 'All ${rpcResults.length} RPC functions responding correctly'
            : 'Some RPC functions have issues — check migration status',
        data: rpcResults,
        duration: sw.elapsed,
      ),
    );
  }

  // ── Run Single Custom Test ─────────────────────────────────────────────────
  Future<void> _runCustomProviderTest() async {
    final providerId = _providerIdController.text.trim();
    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a provider ID first')),
      );
      return;
    }
    final custLat =
        _detectedLocation?.latitude ??
        double.tryParse(_latController.text) ??
        19.0760;
    final custLng =
        _detectedLocation?.longitude ??
        double.tryParse(_lngController.text) ??
        72.8777;

    setState(() => _isRunning = true);
    final sw = Stopwatch()..start();
    try {
      final validation = await LocationService.instance.validateServiceArea(
        providerId: providerId,
        customerLat: custLat,
        customerLng: custLng,
      );
      sw.stop();
      final eligible = validation['eligible'] as bool? ?? true;
      if (mounted) {
        setState(() {
          _isRunning = false;
          _results.add(
            _TestResult(
              name: 'Custom Provider Test',
              status: eligible ? _TestStatus.passed : _TestStatus.warning,
              message: 'Provider ID: ${providerId.substring(0, 8)}…',
              data: {
                'eligible': eligible ? '✅ Yes' : '❌ No',
                'reason': validation['reason'] as String? ?? 'N/A',
                'distance_km': validation['distance_km']?.toString() ?? 'N/A',
                'service_radius_km':
                    validation['service_radius_km']?.toString() ?? 'N/A',
              },
              duration: sw.elapsed,
            ),
          );
          if (eligible) {
            _passCount++;
          } else {
            _warnCount++;
          }
        });
      }
    } catch (e) {
      sw.stop();
      if (mounted) {
        setState(() {
          _isRunning = false;
          _results.add(
            _TestResult(
              name: 'Custom Provider Test',
              status: _TestStatus.failed,
              message: 'Error: $e',
              duration: sw.elapsed,
            ),
          );
          _failCount++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.gps_fixed_rounded,
                color: Color(0xFF00C853),
                size: 18,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              'GPS Location Testing',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF21262D),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
            child: Text(
              '🔬 Production Testing • Live Supabase Data',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: const Color(0xFF8B949E),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Summary Bar ──────────────────────────────────────────────────
          if (_allDone) _buildSummaryBar(),
          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              children: [
                _buildConfigCard(),
                SizedBox(height: 2.h),
                _buildRunButton(),
                SizedBox(height: 2.h),
                if (_results.isNotEmpty) ...[
                  _buildResultsHeader(),
                  SizedBox(height: 1.h),
                  ..._results.map(_buildResultCard),
                ],
                if (_results.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  _buildCustomTestCard(),
                ],
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final total = _passCount + _failCount + _warnCount;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      color: _failCount > 0
          ? const Color(0xFF3D1A1A)
          : _warnCount > 0
          ? const Color(0xFF2D2200)
          : const Color(0xFF0D2818),
      child: Row(
        children: [
          _buildSummaryChip('✅ $_passCount Passed', const Color(0xFF00C853)),
          SizedBox(width: 2.w),
          _buildSummaryChip('⚠️ $_warnCount Warn', const Color(0xFFFFB300)),
          SizedBox(width: 2.w),
          _buildSummaryChip('❌ $_failCount Failed', const Color(0xFFFF5252)),
          const Spacer(),
          Text(
            '$total tests',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF8B949E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: Color(0xFF58A6FF),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Test Configuration',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Switch(
                value: _useManualCoords,
                onChanged: (v) => setState(() => _useManualCoords = v),
                activeThumbColor: const Color(0xFF58A6FF),
              ),
              SizedBox(width: 2.w),
              Text(
                'Use manual coordinates',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF8B949E),
                ),
              ),
            ],
          ),
          if (_useManualCoords) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_latController, 'Latitude', '19.0760'),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildTextField(
                    _lngController,
                    'Longitude',
                    '72.8777',
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 1.h),
          _buildTextField(_radiusController, 'Search Radius (km)', '10'),
          if (_detectedLocation != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF00C853),
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      '${_detectedLocation!.latitude.toStringAsFixed(5)}, ${_detectedLocation!.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 9.sp,
                        color: const Color(0xFF00C853),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: GoogleFonts.robotoMono(fontSize: 10.sp, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 9.sp,
          color: const Color(0xFF8B949E),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 9.sp,
          color: const Color(0xFF484F58),
        ),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF58A6FF)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        isDense: true,
      ),
    );
  }

  Widget _buildRunButton() {
    return GestureDetector(
      onTap: _isRunning ? null : _runAllTests,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        decoration: BoxDecoration(
          gradient: _isRunning
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF238636), Color(0xFF2EA043)],
                ),
          color: _isRunning ? const Color(0xFF21262D) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isRunning
                ? const Color(0xFF30363D)
                : const Color(0xFF2EA043),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF58A6FF),
                ),
              )
            else
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            SizedBox(width: 2.w),
            Text(
              _isRunning ? 'Running Tests…' : 'Run All Tests',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: _isRunning ? const Color(0xFF8B949E) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        const Icon(Icons.terminal_rounded, color: Color(0xFF8B949E), size: 16),
        SizedBox(width: 2.w),
        Text(
          'Test Results',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B949E),
          ),
        ),
        const Spacer(),
        if (_isRunning)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: const Color(0xFF58A6FF),
            ),
          ),
      ],
    );
  }

  Widget _buildResultCard(_TestResult result) {
    final color = _statusColor(result.status);
    final icon = _statusIcon(result.status);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          childrenPadding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.5.h),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          title: Text(
            result.name,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  result.message,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: const Color(0xFF8B949E),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (result.duration != null)
                Text(
                  '${result.duration!.inMilliseconds}ms',
                  style: GoogleFonts.robotoMono(
                    fontSize: 8.sp,
                    color: const Color(0xFF484F58),
                  ),
                ),
            ],
          ),
          iconColor: const Color(0xFF8B949E),
          collapsedIconColor: const Color(0xFF8B949E),
          children: [
            if (result.data != null)
              ...result.data!.entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 0.4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 35.w,
                        child: Text(
                          e.key,
                          style: GoogleFonts.robotoMono(
                            fontSize: 8.5.sp,
                            color: const Color(0xFF58A6FF),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(
                              ClipboardData(text: e.value.toString()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(
                            e.value.toString(),
                            style: GoogleFonts.robotoMono(
                              fontSize: 8.5.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ),
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

  Widget _buildCustomTestCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                color: Color(0xFFFFB300),
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Custom Provider Test',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildTextField(
            _providerIdController,
            'Provider UUID',
            'paste-provider-id-here',
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onTap: _isRunning ? null : _runCustomProviderTest,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1.4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  'Test This Provider',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFB300),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(_TestStatus status) {
    switch (status) {
      case _TestStatus.passed:
        return const Color(0xFF00C853);
      case _TestStatus.failed:
        return const Color(0xFFFF5252);
      case _TestStatus.warning:
        return const Color(0xFFFFB300);
      case _TestStatus.running:
        return const Color(0xFF58A6FF);
      case _TestStatus.idle:
        return const Color(0xFF8B949E);
    }
  }

  IconData _statusIcon(_TestStatus status) {
    switch (status) {
      case _TestStatus.passed:
        return Icons.check_circle_rounded;
      case _TestStatus.failed:
        return Icons.cancel_rounded;
      case _TestStatus.warning:
        return Icons.warning_rounded;
      case _TestStatus.running:
        return Icons.hourglass_top_rounded;
      case _TestStatus.idle:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}