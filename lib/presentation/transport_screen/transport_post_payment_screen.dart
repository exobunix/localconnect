import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_export.dart';
import '../../services/gps_tracking_service.dart';

class TransportPostPaymentScreen extends StatefulWidget {
  const TransportPostPaymentScreen({super.key});

  @override
  State<TransportPostPaymentScreen> createState() =>
      _TransportPostPaymentScreenState();
}

class _TransportPostPaymentScreenState extends State<TransportPostPaymentScreen>
    with TickerProviderStateMixin {
  // Args
  late Map<String, dynamic> _args;

  // Payment details
  String _paymentRef = '';
  double _amount = 0;
  DateTime _paymentTime = DateTime.now();

  // Provider details
  String _providerName = '';
  double _providerRating = 4.8;
  int _reviewCount = 120;
  String _vehicleNo = '';
  String _vehicleLabel = 'Auto Rickshaw';
  Color _vehicleColor = const Color(0xFF1E88E5);
  IconData _vehicleIcon = Icons.electric_rickshaw_rounded;

  // Trip details
  String _pickup = '';
  String _drop = '';
  int _etaMinutes = 15;

  // Map
  final MapController _mapController = MapController();
  final GpsTrackingService _gpsService = GpsTrackingService.instance;
  LatLng? _currentLocation;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  bool _mapReady = false;

  static const LatLng _defaultCenter = LatLng(19.9975, 73.7898);

  // ETA countdown
  late int _remainingMinutes;
  Timer? _etaTimer;

  // Animations
  late AnimationController _successController;
  late AnimationController _pulseController;
  late Animation<double> _successScale;
  late Animation<double> _pulseAnim;

  StreamSubscription? _locationSub;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _successController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final raw = ModalRoute.of(context)?.settings.arguments;
    _args = raw is Map ? Map<String, dynamic>.from(raw) : {};

    _paymentRef =
        _args['paymentRef'] as String? ??
        _args['paymentId'] as String? ??
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _amount =
        (_args['fare'] as num?)?.toDouble() ??
        (_args['amount'] as num?)?.toDouble() ??
        0;
    _paymentTime = DateTime.now();

    _providerName =
        _args['providerName'] as String? ??
        _args['provider_name'] as String? ??
        'Provider';
    _providerRating = (_args['rating'] as num?)?.toDouble() ?? 4.8;
    _reviewCount = _args['review_count'] as int? ?? 120;
    _vehicleNo =
        _args['vehicleNo'] as String? ??
        _args['vehicle_no'] as String? ??
        'MH 15 XX 1234';
    _pickup =
        _args['pickup'] as String? ??
        _args['pickupAddress'] as String? ??
        'Pickup Location';
    _drop =
        _args['drop'] as String? ??
        _args['dropAddress'] as String? ??
        'Drop Location';
    _etaMinutes =
        _args['etaMinutes'] as int? ?? _args['eta_minutes'] as int? ?? 15;
    _remainingMinutes = _etaMinutes;

    final vt = _args['vehicleType'] as String? ?? 'rickshaw';
    _setVehicleStyle(vt);
    _initMap();
    _startEtaCountdown();
  }

  void _setVehicleStyle(String vt) {
    switch (vt) {
      case 'car':
        _vehicleLabel = 'Car (Taxi)';
        _vehicleColor = const Color(0xFF00838F);
        _vehicleIcon = Icons.directions_car_rounded;
        break;
      case 'tempo':
        _vehicleLabel = 'Tempo';
        _vehicleColor = const Color(0xFF7B1FA2);
        _vehicleIcon = Icons.local_shipping_rounded;
        break;
      case 'pickup_van':
        _vehicleLabel = 'Pickup Van';
        _vehicleColor = const Color(0xFFE65100);
        _vehicleIcon = Icons.airport_shuttle_rounded;
        break;
      case 'truck':
        _vehicleLabel = 'Truck';
        _vehicleColor = const Color(0xFF2E7D32);
        _vehicleIcon = Icons.fire_truck_rounded;
        break;
      default:
        _vehicleLabel = 'Auto Rickshaw';
        _vehicleColor = const Color(0xFF1E88E5);
        _vehicleIcon = Icons.electric_rickshaw_rounded;
    }
  }

  Future<void> _initMap() async {
    final position = await _gpsService.getCurrentPosition();
    if (!mounted) return;
    final base = position != null
        ? LatLng(position.latitude, position.longitude)
        : _defaultCenter;
    final rng = math.Random(42);
    setState(() {
      _currentLocation = base;
      _pickupLatLng = LatLng(
        base.latitude + (rng.nextDouble() - 0.5) * 0.015,
        base.longitude + (rng.nextDouble() - 0.5) * 0.015,
      );
      _dropLatLng = LatLng(
        base.latitude + (rng.nextDouble() - 0.5) * 0.04,
        base.longitude + (rng.nextDouble() - 0.5) * 0.04,
      );
      _mapReady = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _mapController.move(base, 14.0);
    }
  }

  void _startEtaCountdown() {
    _etaTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_remainingMinutes > 0) {
        setState(() => _remainingMinutes--);
      } else {
        _etaTimer?.cancel();
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final months = [
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
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $ampm';
  }

  @override
  void dispose() {
    _successController.dispose();
    _pulseController.dispose();
    _etaTimer?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSuccessHeader(),
                const SizedBox(height: 16),
                _buildEtaCard(),
                const SizedBox(height: 16),
                _buildMapCard(),
                const SizedBox(height: 16),
                _buildTripDetailsCard(),
                const SizedBox(height: 16),
                _buildProviderCard(),
                const SizedBox(height: 16),
                _buildReceiptCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _vehicleColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (r) => false,
        ),
      ),
      title: Text(
        'Booking Confirmed',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.homeScreen,
            (r) => false,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_vehicleColor, _vehicleColor.withValues(alpha: 0.75)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Payment Successful!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transport has been booked',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_vehicleIcon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  _vehicleLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) =>
                  Transform.scale(scale: _pulseAnim.value, child: child),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _vehicleColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_vehicleIcon, color: _vehicleColor, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Arrival',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _remainingMinutes > 0
                        ? '$_remainingMinutes min away'
                        : 'Arriving now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _vehicleColor,
                    ),
                  ),
                  Text(
                    'Vehicle: $_vehicleNo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF44474E),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: AppTheme.success,
                    size: 10,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    final center = _currentLocation ?? _defaultCenter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                if (_mapReady)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.localconnect',
                      ),
                      if (_pickupLatLng != null && _dropLatLng != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                _currentLocation ?? center,
                                _pickupLatLng!,
                                _dropLatLng!,
                              ],
                              color: _vehicleColor,
                              strokeWidth: 3.5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          // Current vehicle position
                          Marker(
                            point: _currentLocation ?? center,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _vehicleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _vehicleColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _vehicleIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          // Pickup marker
                          if (_pickupLatLng != null)
                            Marker(
                              point: _pickupLatLng!,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          // Drop marker
                          if (_dropLatLng != null)
                            Marker(
                              point: _dropLatLng!,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else
                  Container(
                    color: const Color(0xFFE8EFF5),
                    child: Center(
                      child: CircularProgressIndicator(color: _vehicleColor),
                    ),
                  ),
                // Map overlay label
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
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
                        const Icon(
                          Icons.radio_button_checked,
                          color: AppTheme.success,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Tracking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Full map button
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.transportLiveMapScreen,
                      arguments: {
                        'vehicleType': _args['vehicleType'] ?? 'rickshaw',
                        'isCustomerView': true,
                        'providerName': _providerName,
                        'vehicleNo': _vehicleNo,
                        'pickupAddress': _pickup,
                        'dropAddress': _drop,
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _vehicleColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_full_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Full Map',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
      ),
    );
  }

  Widget _buildTripDetailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, color: _vehicleColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Trip Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TripRow(
              icon: Icons.my_location_rounded,
              color: AppTheme.success,
              label: 'Pickup',
              value: _pickup,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 2,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDD3DA),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
            _TripRow(
              icon: Icons.location_on_rounded,
              color: AppTheme.error,
              label: 'Drop',
              value: _drop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_rounded, color: _vehicleColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Provider Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _vehicleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _providerName.isNotEmpty
                          ? _providerName[0].toUpperCase()
                          : 'P',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _vehicleColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFA726),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _providerRating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($_reviewCount reviews)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F2F5)),
            const SizedBox(height: 14),
            Row(
              children: [
                _ProviderInfoChip(
                  icon: _vehicleIcon,
                  label: _vehicleLabel,
                  color: _vehicleColor,
                ),
                const SizedBox(width: 10),
                _ProviderInfoChip(
                  icon: Icons.confirmation_number_rounded,
                  label: _vehicleNo,
                  color: const Color(0xFF44474E),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: _vehicleColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Receipt',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _paymentRef));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _vehicleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: _vehicleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _vehicleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amount highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount Paid',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_amount.toStringAsFixed(_amount == _amount.truncateToDouble() ? 0 : 2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ReceiptRow(label: 'Reference No.', value: _paymentRef),
            const _ReceiptDivider(),
            _ReceiptRow(label: 'Service', value: _vehicleLabel),
            const _ReceiptDivider(),
            _ReceiptRow(
              label: 'Date & Time',
              value: _formatDateTime(_paymentTime),
            ),
            const _ReceiptDivider(),
            _ReceiptRow(label: 'Payment Method', value: 'Razorpay'),
            const _ReceiptDivider(),
            _ReceiptRow(label: 'Status', value: 'Paid', isSuccess: true),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: Color(0xFF74777F),
                ),
                const SizedBox(width: 4),
                Text(
                  'Secured by Razorpay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.transportLiveMapScreen,
                arguments: {
                  'vehicleType': _args['vehicleType'] ?? 'rickshaw',
                  'isCustomerView': true,
                  'providerName': _providerName,
                  'vehicleNo': _vehicleNo,
                  'pickupAddress': _pickup,
                  'dropAddress': _drop,
                },
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                'Track Vehicle Live',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vehicleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeScreen,
                (r) => false,
              ),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: Text(
                'Go to Home',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _vehicleColor.withValues(alpha: 0.4)),
                foregroundColor: _vehicleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _TripRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _TripRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF74777F),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProviderInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSuccess;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
            ),
          ),
          const Spacer(),
          if (isSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
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

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF0F2F5));
  }
}
