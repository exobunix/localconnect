import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/delivery_realtime_service.dart';
import '../../services/gps_tracking_service.dart';

class RiderAppScreen extends StatefulWidget {
  const RiderAppScreen({super.key});

  @override
  State<RiderAppScreen> createState() => _RiderAppScreenState();
}

class _RiderAppScreenState extends State<RiderAppScreen>
    with TickerProviderStateMixin {
  bool _isOnline = false;
  int _bottomNavIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Color _riderColor = const Color(0xFF00897B);
  final Color _riderAccent = const Color(0xFF4DB6AC);

  // ─── Realtime ─────────────────────────────────────────────────────────────
  final DeliveryRealtimeService _realtimeService =
      DeliveryRealtimeService.instance;
  final GpsTrackingService _gpsService = GpsTrackingService.instance;
  StreamSubscription<Position>? _gpsSubscription;
  bool _isUpdatingStatus = false;

  final List<Map<String, dynamic>> _pendingOrders = [
    {
      'id': 'DEL001',
      'type': 'Food Delivery',
      'from': 'Sharma Restaurant, MG Road',
      'to': 'Sector 5, Pune',
      'distance': '3.2 km',
      'amount': 65,
      'riderEarning': 45,
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFFF6B35),
      'customer': 'Amit Sharma',
      'phone': '9876543210',
      'timeLeft': 45,
    },
    {
      'id': 'DEL002',
      'type': 'Medicine',
      'from': 'City Pharmacy, Camp',
      'to': 'Koregaon Park',
      'distance': '4.1 km',
      'amount': 45,
      'riderEarning': 32,
      'icon': Icons.medication_rounded,
      'color': const Color(0xFF3498DB),
      'customer': 'Priya Patel',
      'phone': '9876543211',
      'timeLeft': 30,
    },
  ];

  Map<String, dynamic>? _activeDelivery;
  String _deliveryStep = 'none'; // none, accepted, picked_up, delivered

  final List<Map<String, dynamic>> _completedToday = [
    {
      'id': 'DEL-A01',
      'type': 'Grocery',
      'earning': 38,
      'time': '9:30 AM',
      'rating': 5,
    },
    {
      'id': 'DEL-A02',
      'type': 'Food Delivery',
      'earning': 45,
      'time': '11:15 AM',
      'rating': 4,
    },
    {
      'id': 'DEL-A03',
      'type': 'Parcel',
      'earning': 55,
      'time': '1:00 PM',
      'rating': 5,
    },
    {
      'id': 'DEL-A04',
      'type': 'Medicine',
      'earning': 32,
      'time': '3:45 PM',
      'rating': 4,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gpsSubscription?.cancel();
    if (_isOnline) {
      _gpsService.stopTracking();
      _realtimeService.updateRiderLocation(lat: 0, lng: 0, isOnline: false);
    }
    super.dispose();
  }

  // ─── Online/Offline toggle with GPS ───────────────────────────────────────

  Future<void> _toggleOnlineStatus() async {
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);

    if (newStatus) {
      // Start GPS tracking
      final started = await _gpsService.startTracking(
        bookingId: _activeDelivery?['id'] as String?,
      );
      if (started) {
        _gpsSubscription = _gpsService.locationStream.listen((position) {
          _realtimeService.updateRiderLocation(
            lat: position.latitude,
            lng: position.longitude,
            isOnline: true,
            activeDeliveryId: _activeDelivery?['id'] as String?,
          );
        });
      }
    } else {
      // Stop GPS tracking
      await _gpsSubscription?.cancel();
      _gpsSubscription = null;
      await _gpsService.stopTracking();
      await _realtimeService.updateRiderLocation(
        lat: 0,
        lng: 0,
        isOnline: false,
      );
    }
  }

  // ─── Accept delivery order ─────────────────────────────────────────────────

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    setState(() => _isUpdatingStatus = true);

    // Create tracking record in Supabase
    await _realtimeService.createDeliveryTracking(
      deliveryId: order['id'] as String,
      deliveryType: order['type'] as String,
      pickupAddress: order['from'] as String,
      dropoffAddress: order['to'] as String,
      amount: (order['amount'] as int).toDouble(),
      riderEarning: (order['riderEarning'] as int).toDouble(),
    );

    // Update status to accepted
    await _realtimeService.updateDeliveryStatus(
      deliveryId: order['id'] as String,
      status: 'accepted',
    );

    setState(() {
      _activeDelivery = order;
      _deliveryStep = 'accepted';
      _pendingOrders.removeWhere((o) => o['id'] == order['id']);
      _isUpdatingStatus = false;
    });

    // Start GPS if not already online
    if (!_isOnline) {
      await _toggleOnlineStatus();
    }
  }

  // ─── Update delivery step ──────────────────────────────────────────────────

  Future<void> _updateDeliveryStep(String newStep) async {
    if (_activeDelivery == null) return;
    setState(() => _isUpdatingStatus = true);

    final deliveryId = _activeDelivery!['id'] as String;

    // Map UI step to DB status
    final statusMap = {'picked_up': 'picked_up', 'delivered': 'delivered'};

    final dbStatus = statusMap[newStep];
    if (dbStatus != null) {
      await _realtimeService.updateDeliveryStatus(
        deliveryId: deliveryId,
        status: dbStatus,
      );
    }

    if (newStep == 'delivered') {
      // Stop GPS, clear active delivery
      await _gpsSubscription?.cancel();
      _gpsSubscription = null;
      await _gpsService.stopTracking();
      await _realtimeService.updateRiderLocation(
        lat: 0,
        lng: 0,
        isOnline: _isOnline,
        activeDeliveryId: null,
      );

      setState(() {
        _completedToday.insert(0, {
          'id': _activeDelivery!['id'],
          'type': _activeDelivery!['type'],
          'earning': _activeDelivery!['riderEarning'],
          'time': TimeOfDay.now().format(context),
          'rating': 0,
        });
        _activeDelivery = null;
        _deliveryStep = 'none';
        _isUpdatingStatus = false;
      });
    } else {
      setState(() {
        _deliveryStep = newStep;
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildHomeTab(),
          _buildEarningsTab(),
          _buildHistoryTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (i) => setState(() => _bottomNavIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _riderColor,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: _riderColor,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notificationScreen),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_riderColor, _riderAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ravi Kumar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '4.8 Rating',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildOnlineToggle(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Realtime status indicator
                _buildRealtimeStatusBanner(),
                const SizedBox(height: 12),
                _buildTodayStats(),
                const SizedBox(height: 20),
                if (_activeDelivery != null) ...[
                  _buildActiveDeliveryCard(),
                  const SizedBox(height: 20),
                ],
                if (_isOnline && _activeDelivery == null) ...[
                  _buildPendingOrdersSection(),
                ],
                if (!_isOnline) _buildOfflineMessage(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline
            ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isOnline
              ? const Color(0xFF2ECC71).withValues(alpha: 0.4)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isOnline ? const Color(0xFF2ECC71) : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isOnline
                  ? 'Realtime GPS active — location syncing to vendor & customers'
                  : 'Go online to start broadcasting your location',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _isOnline ? const Color(0xFF1B7A3E) : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isUpdatingStatus)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isOnline ? Colors.transparent : Colors.white54,
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _isOnline ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF2ECC71) : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _isOnline ? _riderColor : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    final totalEarned = _completedToday.fold<int>(
      0,
      (sum, d) => sum + (d['earning'] as int),
    );
    return Row(
      children: [
        _buildStatCard(
          'Today\'s Earnings',
          '₹$totalEarned',
          Icons.currency_rupee_rounded,
          _riderColor,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Deliveries',
          '${_completedToday.length}',
          Icons.check_circle_rounded,
          const Color(0xFF2ECC71),
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          'Distance',
          '18.4 km',
          Icons.route_rounded,
          const Color(0xFF3498DB),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'You are Offline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Go online to start receiving delivery requests',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleOnlineStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _riderColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Go Online',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'New Delivery Requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _riderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _riderColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._pendingOrders.map((order) => _buildOrderRequestCard(order)),
      ],
    );
  }

  Widget _buildOrderRequestCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (order['color'] as Color).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (order['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order['icon'] as IconData,
                  color: order['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['type'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      order['from'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '→ ${order['to']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${order['riderEarning']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _riderColor,
                    ),
                  ),
                  Text(
                    'Your earning',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 11,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        order['distance'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(
                      () => _pendingOrders.removeWhere(
                        (o) => o['id'] == order['id'],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isUpdatingStatus
                      ? null
                      : () => _acceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _riderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _isUpdatingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Accept & Start',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard() {
    if (_activeDelivery == null) return const SizedBox.shrink();

    final steps = [
      {
        'key': 'accepted',
        'label': 'Accepted',
        'icon': Icons.check_circle_rounded,
      },
      {
        'key': 'picked_up',
        'label': 'Picked Up',
        'icon': Icons.inventory_rounded,
      },
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.home_rounded},
    ];

    final currentStepIndex = steps.indexWhere((s) => s['key'] == _deliveryStep);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_riderColor, _riderAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _riderColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _activeDelivery!['icon'] as IconData? ??
                      Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Delivery',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _activeDelivery!['type'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Realtime sync indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Syncing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Step tracker
          Row(
            children: List.generate(steps.length, (i) {
              final isDone = i <= currentStepIndex;
              final isCurrent = i == currentStepIndex;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              steps[i]['icon'] as IconData,
                              size: 16,
                              color: isDone ? _riderColor : Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            steps[i]['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: isDone
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentStepIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _activeDelivery!['from'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'To',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _activeDelivery!['to'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons based on current step
          if (_deliveryStep == 'accepted')
            _buildStepActionButton(
              label: 'Confirm Pickup (OTP)',
              onTap: () => _showOtpSheet(
                title: 'Pickup OTP Verification',
                subtitle: 'Enter the 4-digit OTP from the pickup location',
                onVerified: () => _updateDeliveryStep('picked_up'),
              ),
            ),
          if (_deliveryStep == 'picked_up')
            _buildStepActionButton(
              label: 'Confirm Delivery (OTP)',
              onTap: () => _showOtpSheet(
                title: 'Delivery OTP Verification',
                subtitle: 'Enter the 4-digit OTP from the customer',
                onVerified: () => _updateDeliveryStep('delivered'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUpdatingStatus ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _riderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isUpdatingStatus
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _riderColor,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  void _showOtpSheet({
    required String title,
    required String subtitle,
    required VoidCallback onVerified,
  }) {
    final otpController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.lock_rounded, color: _riderColor, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '----',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    color: Colors.grey[300],
                    letterSpacing: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _riderColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onVerified();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _riderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Verify & Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsTab() {
    final totalEarned = _completedToday.fold<int>(
      0,
      (sum, d) => sum + (d['earning'] as int),
    );
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _riderColor,
          automaticallyImplyLeading: false,
          title: Text(
            'Earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_riderColor, _riderAccent],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Today\'s Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹$totalEarned',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_completedToday.length} deliveries completed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildEarningCard(
                      'This Week',
                      '₹3,240',
                      Icons.calendar_view_week_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildEarningCard(
                      'This Month',
                      '₹12,800',
                      Icons.calendar_month_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: _riderColor, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _riderColor,
          automaticallyImplyLeading: false,
          title: Text(
            'Delivery History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((_, i) {
            final d = _completedToday[i];
            return Container(
              margin: EdgeInsets.fromLTRB(4.w, i == 0 ? 2.h : 0, 4.w, 1.h),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _riderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: _riderColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['type'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          d['time'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${d['earning']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _riderColor,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          d['rating'] as int,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }, childCount: _completedToday.length),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _riderColor,
          automaticallyImplyLeading: false,
          title: Text(
            'My Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _riderColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person_rounded,
                          color: _riderColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ravi Kumar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Rider ID: RDR-2024-001',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '4.8 • 247 deliveries',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                const SizedBox(height: 16),
                // Realtime status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.gps_fixed_rounded,
                        color: _riderColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPS & Realtime Sync',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _isOnline
                                  ? 'Active — location visible to vendor & customers'
                                  : 'Inactive — go online to enable',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: _isOnline
                                    ? const Color(0xFF1B7A3E)
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? const Color(0xFF2ECC71)
                              : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
