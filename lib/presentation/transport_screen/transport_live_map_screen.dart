import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/gps_tracking_service.dart';
import '../../theme/app_theme.dart';

/// Live Map Screen for Transport Providers
/// Shows provider's real-time GPS location, active booking route,
/// and nearby transport activity on an interactive map.
class TransportLiveMapScreen extends StatefulWidget {
  const TransportLiveMapScreen({super.key});

  @override
  State<TransportLiveMapScreen> createState() => _TransportLiveMapScreenState();
}

class _TransportLiveMapScreenState extends State<TransportLiveMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GpsTrackingService _gpsService = GpsTrackingService.instance;

  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  bool _isTracking = false;
  bool _isLoadingLocation = true;
  String _vehicleType = 'rickshaw';
  String _vehicleLabel = 'Auto Rickshaw';
  Color _vehicleColor = const Color(0xFF1E88E5);
  String _bookingId = '';
  String _customerName = '';
  String _pickupAddress = '';
  String _dropAddress = '';
  bool _isCustomerView = false;
  String _providerName = '';
  String _vehicleNo = '';

  // Simulated nearby vehicles for demo
  final List<Map<String, dynamic>> _nearbyVehicles = [];

  // Default center: Nashik, Maharashtra
  static const LatLng _defaultCenter = LatLng(19.9975, 73.7898);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _vehicleType = args?['vehicleType'] as String? ?? 'rickshaw';
    _bookingId = args?['bookingId'] as String? ?? '';
    _customerName = args?['customerName'] as String? ?? '';
    _pickupAddress = args?['pickupAddress'] as String? ?? '';
    _dropAddress = args?['dropAddress'] as String? ?? '';
    _isCustomerView = args?['isCustomerView'] as bool? ?? false;
    _providerName = args?['providerName'] as String? ?? '';
    _vehicleNo = args?['vehicleNo'] as String? ?? '';

    _setVehicleStyle(_vehicleType);
    _initializeMap();
    _generateNearbyVehicles();
  }

  void _setVehicleStyle(String vt) {
    switch (vt) {
      case 'car':
        _vehicleLabel = 'Car (Taxi)';
        _vehicleColor = const Color(0xFF00838F);
        break;
      case 'tempo':
        _vehicleLabel = 'Tempo';
        _vehicleColor = const Color(0xFF7B1FA2);
        break;
      case 'pickup_van':
        _vehicleLabel = 'Pickup Van';
        _vehicleColor = const Color(0xFFE65100);
        break;
      case 'truck':
        _vehicleLabel = 'Truck';
        _vehicleColor = const Color(0xFF2E7D32);
        break;
      default:
        _vehicleLabel = 'Auto Rickshaw';
        _vehicleColor = const Color(0xFF1E88E5);
    }
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoadingLocation = true);
    final position = await _gpsService.getCurrentPosition();
    if (mounted) {
      if (position != null) {
        final loc = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = loc;
          _isLoadingLocation = false;
        });
        _mapController.move(loc, 15.0);
      } else {
        // Use default location for demo
        setState(() {
          _currentLocation = _defaultCenter;
          _isLoadingLocation = false;
        });
        _mapController.move(_defaultCenter, 14.0);
      }
      // Set simulated pickup/drop if booking exists
      if (_bookingId.isNotEmpty) {
        _setSimulatedRoute();
      }
    }
  }

  void _setSimulatedRoute() {
    final base = _currentLocation ?? _defaultCenter;
    final rng = math.Random(42);
    setState(() {
      _pickupLocation = LatLng(
        base.latitude + (rng.nextDouble() - 0.5) * 0.02,
        base.longitude + (rng.nextDouble() - 0.5) * 0.02,
      );
      _dropLocation = LatLng(
        base.latitude + (rng.nextDouble() - 0.5) * 0.05,
        base.longitude + (rng.nextDouble() - 0.5) * 0.05,
      );
    });
  }

  void _generateNearbyVehicles() {
    final base = _currentLocation ?? _defaultCenter;
    final rng = math.Random(99);
    _nearbyVehicles.clear();
    for (int i = 0; i < 5; i++) {
      _nearbyVehicles.add({
        'lat': base.latitude + (rng.nextDouble() - 0.5) * 0.03,
        'lng': base.longitude + (rng.nextDouble() - 0.5) * 0.03,
        'name': 'Provider ${i + 1}',
        'rating': (4.0 + rng.nextDouble()).toStringAsFixed(1),
      });
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _gpsService.stopTracking();
      _locationSubscription?.cancel();
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS tracking stopped'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final started = await _gpsService.startTracking(
        bookingId: _bookingId.isNotEmpty ? _bookingId : null,
      );
      if (started) {
        setState(() => _isTracking = true);
        _locationSubscription = _gpsService.locationStream.listen((position) {
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('GPS tracking started — sharing live location'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission required. Please enable in settings.',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _centerOnMyLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _gpsService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          if (_bookingId.isNotEmpty) _buildBookingCard(),
          _buildBottomControls(),
          if (_isLoadingLocation) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final center = _currentLocation ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        minZoom: 8.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.localconnect.app',
        ),
        // Route polyline if booking active
        if (_pickupLocation != null &&
            _dropLocation != null &&
            _currentLocation != null)
          PolylineLayer(
            polylines: <Polyline<Object>>[
              Polyline<Object>(
                points: [_currentLocation!, _pickupLocation!, _dropLocation!],
                color: _vehicleColor.withValues(alpha: 0.7),
                strokeWidth: 4.0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Current provider location
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isTracking)
                          Container(
                            width: 50 * _pulseAnim.value,
                            height: 50 * _pulseAnim.value,
                            decoration: BoxDecoration(
                              color: _vehicleColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _vehicleColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _vehicleColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getVehicleIcon(),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Pickup marker
            if (_pickupLocation != null)
              Marker(
                point: _pickupLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.trip_origin_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            // Drop marker
            if (_dropLocation != null)
              Marker(
                point: _dropLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            // Nearby vehicles
            ..._nearbyVehicles.map(
              (v) => Marker(
                point: LatLng(v['lat'] as double, v['lng'] as double),
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _vehicleColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getVehicleIcon(),
                    color: _vehicleColor.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getVehicleIcon() {
    switch (_vehicleType) {
      case 'car':
        return Icons.directions_car_rounded;
      case 'tempo':
        return Icons.airport_shuttle_rounded;
      case 'pickup_van':
        return Icons.local_shipping_rounded;
      case 'truck':
        return Icons.fire_truck_rounded;
      default:
        return Icons.electric_rickshaw_rounded;
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_vehicleColor, _vehicleColor.withValues(alpha: 0.85)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCustomerView
                        ? 'Track — $_vehicleLabel'
                        : 'Live Map — $_vehicleLabel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isCustomerView
                              ? Colors.greenAccent
                              : (_isTracking
                                    ? Colors.greenAccent
                                    : Colors.white.withValues(alpha: 0.5)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _isCustomerView
                              ? (_providerName.isNotEmpty
                                    ? 'Tracking: $_providerName${_vehicleNo.isNotEmpty ? " · $_vehicleNo" : ""}'
                                    : 'Tracking provider location')
                              : (_isTracking
                                    ? 'Broadcasting live location'
                                    : 'Location tracking off'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _centerOnMyLocation,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: _vehicleColor),
                const SizedBox(width: 6),
                Text(
                  _customerName.isNotEmpty ? _customerName : 'Active Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'In Transit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            if (_pickupAddress.isNotEmpty || _dropAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRouteRow(
                Icons.trip_origin_rounded,
                AppTheme.success,
                _pickupAddress,
              ),
              const SizedBox(height: 4),
              _buildRouteRow(
                Icons.location_on_rounded,
                AppTheme.error,
                _dropAddress,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address.isNotEmpty ? address : 'Location set',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF44474E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  Icons.trip_origin_rounded,
                  AppTheme.success,
                  'Pickup',
                ),
                _buildLegendItem(
                  Icons.location_on_rounded,
                  AppTheme.error,
                  'Drop',
                ),
                _buildLegendItem(
                  _getVehicleIcon(),
                  _vehicleColor,
                  _isCustomerView ? 'Vehicle' : 'You',
                ),
                _buildLegendItem(
                  _getVehicleIcon(),
                  _vehicleColor.withValues(alpha: 0.5),
                  'Nearby',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isCustomerView)
            // Customer view: show provider info card + refresh button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _vehicleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getVehicleIcon(),
                      color: _vehicleColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _providerName.isNotEmpty
                              ? _providerName
                              : _vehicleLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_vehicleNo.isNotEmpty)
                          Text(
                            _vehicleNo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _initializeMap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _vehicleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: _vehicleColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Provider view: GPS toggle button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleTracking,
                icon: Icon(
                  _isTracking ? Icons.gps_off_rounded : Icons.gps_fixed_rounded,
                  size: 20,
                ),
                label: Text(
                  _isTracking ? 'Stop GPS Tracking' : 'Start GPS Tracking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? AppTheme.error : _vehicleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF44474E),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _vehicleColor),
              const SizedBox(height: 12),
              Text(
                'Getting your location...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
