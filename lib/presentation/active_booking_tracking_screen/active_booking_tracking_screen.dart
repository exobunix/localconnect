import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:localconnect/core/supabase_mock.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/gps_tracking_service.dart';
import '../../theme/app_theme.dart';

/// Active Booking Live Tracking Screen
/// Shows provider location on map (when en-route), ETA, service progress
/// timeline, and completion confirmation — visible from active booking detail.
class ActiveBookingTrackingScreen extends StatefulWidget {
  const ActiveBookingTrackingScreen({super.key});

  @override
  State<ActiveBookingTrackingScreen> createState() =>
      _ActiveBookingTrackingScreenState();
}

class _ActiveBookingTrackingScreenState
    extends State<ActiveBookingTrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GpsTrackingService _gpsService = GpsTrackingService.instance;

  // Booking data from arguments
  String _bookingId = '';
  String _providerName = '';
  String _serviceName = '';
  String _status = 'accepted';
  String _scheduledDate = '';
  String _address = '';
  double _totalAmount = 0;
  String _providerId = '';
  String? _providerPhone;

  // Map state
  LatLng? _providerLocation;
  LatLng? _customerLocation;
  bool _isLoadingLocation = true;
  bool _mapReady = false;

  // ETA
  String _etaText = 'Calculating...';

  // Realtime subscription
  RealtimeChannel? _trackingChannel;
  RealtimeChannel? _bookingChannel;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  // Default center: Nashik, Maharashtra
  static const LatLng _defaultCenter = LatLng(19.9975, 73.7898);

  // Simulated provider movement for demo
  Timer? _simulationTimer;
  double _simLat = 19.9975;
  double _simLng = 73.7898;

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingId = args['booking_id'] as String? ?? '';
      _providerName = args['provider_name'] as String? ?? 'Provider';
      _serviceName = args['service_name'] as String? ?? 'Service';
      _status = args['status'] as String? ?? 'accepted';
      _scheduledDate = args['scheduled_date'] as String? ?? '';
      _address = args['address'] as String? ?? '';
      _totalAmount = (args['total_amount'] as num?)?.toDouble() ?? 0;
      _providerId = args['provider_id'] as String? ?? '';
      _providerPhone = args['provider_phone'] as String?;
    }
    _initializeTracking();
    _slideController.forward();
  }

  Future<void> _initializeTracking() async {
    final pos = await _gpsService.getCurrentPosition();
    if (mounted && pos != null) {
      setState(() {
        _customerLocation = LatLng(pos.latitude, pos.longitude);
      });
    }

    await _fetchProviderLocation();

    if (_providerId.isNotEmpty) {
      _subscribeToProviderLocation();
    }

    if (_bookingId.isNotEmpty) {
      _subscribeToBookingStatus();
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }

    if (_status == 'en_route' && _providerLocation == null) {
      _startSimulation();
    }
  }

  Future<void> _fetchProviderLocation() async {
    if (_providerId.isEmpty) return;
    try {
      final result = await Supabase.instance.client
          .from('service_providers')
          .select('latitude, longitude')
          .eq('user_id', _providerId)
          .maybeSingle();
      if (result != null && mounted) {
        final lat = (result['latitude'] as num?)?.toDouble();
        final lng = (result['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _providerLocation = LatLng(lat, lng);
          });
          _calculateEta();
        }
      }
    } catch (_) {}
  }

  void _subscribeToProviderLocation() {
    _trackingChannel = _gpsService.subscribeToProviderLocation(
      providerId: _providerId,
      onLocationUpdate: (lat, lng) {
        if (mounted) {
          setState(() {
            _providerLocation = LatLng(lat, lng);
          });
          _calculateEta();
          if (_mapReady && _providerLocation != null) {
            try {
              _mapController.move(_providerLocation!, 15);
            } catch (_) {}
          }
        }
      },
    );
  }

  void _subscribeToBookingStatus() {
    _bookingChannel = Supabase.instance.client
        .channel('booking_status_$_bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _bookingId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus != null && mounted) {
              setState(() => _status = newStatus);
              if (newStatus == 'en_route' && _providerLocation == null) {
                _startSimulation();
              }
              if (newStatus == 'completed') {
                _simulationTimer?.cancel();
                _showCompletionDialog();
              }
            }
          },
        )
        .subscribe();
  }

  void _startSimulation() {
    final rng = math.Random();
    _simLat = _defaultCenter.latitude + (rng.nextDouble() - 0.5) * 0.02;
    _simLng = _defaultCenter.longitude + (rng.nextDouble() - 0.5) * 0.02;

    if (mounted) {
      setState(() {
        _providerLocation = LatLng(_simLat, _simLng);
      });
      _calculateEta();
    }

    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _simLat += (rng.nextDouble() - 0.3) * 0.001;
      _simLng += (rng.nextDouble() - 0.3) * 0.001;
      setState(() {
        _providerLocation = LatLng(_simLat, _simLng);
      });
      _calculateEta();
    });
  }

  void _calculateEta() {
    if (_providerLocation == null) {
      setState(() => _etaText = 'Calculating...');
      return;
    }
    final dest = _customerLocation ?? _defaultCenter;
    const Distance distance = Distance();
    final meters = distance.as(LengthUnit.Meter, _providerLocation!, dest);
    final minutes = (meters / 500).ceil();
    setState(() {
      final clamped = minutes.clamp(1, 120);
      if (clamped <= 1) {
        _etaText = 'Arriving now';
      } else if (clamped < 60) {
        _etaText = '$clamped min away';
      } else {
        final h = clamped ~/ 60;
        final m = clamped % 60;
        _etaText = m > 0 ? '${h}h ${m}m away' : '${h}h away';
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Service Completed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_providerName has completed the service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, 'rate');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Rate Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _simulationTimer?.cancel();
    _trackingChannel?.unsubscribe();
    _bookingChannel?.unsubscribe();
    super.dispose();
  }

  String _fmtAmount(double amount) {
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '—';
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
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildBottomPanel(),
            ),
          ),
          if (_isLoadingLocation)
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

  Widget _buildMap() {
    final center = _providerLocation ?? _customerLocation ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        onMapReady: () => setState(() => _mapReady = true),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.localconnect.app',
        ),
        if (_providerLocation != null && _customerLocation != null)
          PolylineLayer(
            polylines: [
              Polyline<Object>(
                points: [_providerLocation!, _customerLocation!],
                color: AppTheme.primary.withValues(alpha: 0.7),
                strokeWidth: 4,
                pattern: _status == 'accepted'
                    ? const StrokePattern.dotted()
                    : const StrokePattern.solid(),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_providerLocation != null)
              Marker(
                point: _providerLocation!,
                width: 56,
                height: 56,
                child: _buildProviderMarker(),
              ),
            Marker(
              point: _customerLocation ?? _defaultCenter,
              width: 48,
              height: 48,
              child: _buildCustomerMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderMarker() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _status == 'en_route' ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_walk_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCustomerMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
    );
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
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Tracking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _serviceName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_status == 'en_route')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _etaText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
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
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProviderInfoRow(),
            ),
            const SizedBox(height: 16),
            if (_status == 'en_route') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildEtaBanner(),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgressTimeline(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildBookingDetails(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfoRow() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
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
              Text(
                _serviceName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildStatusBadge(_status),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;
    String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = const Color(0xFF1565C0);
        bg = const Color(0xFFE3F2FD);
        label = 'Accepted';
        break;
      case 'en_route':
        color = AppTheme.warning;
        bg = AppTheme.warningContainer;
        label = 'En Route';
        break;
      case 'in_progress':
        color = const Color(0xFF6A1B9A);
        bg = const Color(0xFFF3E5F5);
        label = 'In Progress';
        break;
      case 'completed':
        color = AppTheme.success;
        bg = AppTheme.successContainer;
        label = 'Completed';
        break;
      default:
        color = AppTheme.outline;
        bg = AppTheme.surfaceVariant;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEtaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: AppTheme.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider is on the way',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  _etaText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline() {
    final steps = [
      _TimelineStep(
        label: 'Booking Accepted',
        sublabel: 'Provider confirmed your booking',
        icon: Icons.handshake_rounded,
        activeStatuses: ['accepted', 'en_route', 'in_progress', 'completed'],
        currentStatuses: ['accepted'],
      ),
      _TimelineStep(
        label: 'En Route',
        sublabel: 'Provider is heading to your location',
        icon: Icons.directions_walk_rounded,
        activeStatuses: ['en_route', 'in_progress', 'completed'],
        currentStatuses: ['en_route'],
      ),
      _TimelineStep(
        label: 'Service In Progress',
        sublabel: 'Work is underway',
        icon: Icons.build_rounded,
        activeStatuses: ['in_progress', 'completed'],
        currentStatuses: ['in_progress'],
      ),
      _TimelineStep(
        label: 'Completed',
        sublabel: 'Service successfully delivered',
        icon: Icons.check_circle_rounded,
        activeStatuses: ['completed'],
        currentStatuses: ['completed'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Progress',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isActive = step.activeStatuses.contains(_status.toLowerCase());
          final isCurrent = step.currentStatuses.contains(
            _status.toLowerCase(),
          );
          final isLast = i == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isCurrent
                                    ? AppTheme.primary
                                    : AppTheme.success)
                              : const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isActive && !isCurrent
                              ? Icons.check_rounded
                              : step.icon,
                          size: 16,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isActive
                                ? const Color(0xFF1A1C1E)
                                : const Color(0xFFBDBDBD),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.sublabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isActive
                                ? const Color(0xFF74777F)
                                : const Color(0xFFD0D0D0),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current Status',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Scheduled',
            value: _fmtDate(_scheduledDate),
          ),
          if (_address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: _address,
            ),
          ],
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.payments_rounded,
            label: 'Amount',
            value: _fmtAmount(_totalAmount),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isEnRoute = _status == 'en_route';
    final canRate = _status == 'in_progress' || _status == 'completed';

    return Row(
      children: [
        if (_providerPhone != null) ...[
          Expanded(
            child: _TrackingActionButton(
              icon: Icons.call_rounded,
              label: 'Call',
              color: AppTheme.success,
              bgColor: AppTheme.successContainer,
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: _providerPhone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _TrackingActionButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            color: AppTheme.primary,
            bgColor: AppTheme.primaryContainer,
            onTap: () => Navigator.pop(context, 'chat'),
          ),
        ),
        if (canRate) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _TrackingActionButton(
              icon: Icons.star_rounded,
              label: 'Rate',
              color: AppTheme.warning,
              bgColor: AppTheme.warningContainer,
              onTap: () => Navigator.pop(context, 'rate'),
            ),
          ),
        ],
        if (isEnRoute && !canRate) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _TrackingActionButton(
              icon: Icons.my_location_rounded,
              label: 'Center',
              color: const Color(0xFF6A1B9A),
              bgColor: const Color(0xFFF3E5F5),
              onTap: () {
                if (_providerLocation != null && _mapReady) {
                  try {
                    _mapController.move(_providerLocation!, 15);
                  } catch (_) {}
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Helper Models ─────────────────────────────────────────────────────────────

class _TimelineStep {
  final String label;
  final String sublabel;
  final IconData icon;
  final List<String> activeStatuses;
  final List<String> currentStatuses;

  const _TimelineStep({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.activeStatuses,
    required this.currentStatuses,
  });
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF74777F),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TrackingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _TrackingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
