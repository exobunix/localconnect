import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/delivery_realtime_service.dart';

class DeliveryVendorDashboard extends StatefulWidget {
  const DeliveryVendorDashboard({super.key});

  @override
  State<DeliveryVendorDashboard> createState() =>
      _DeliveryVendorDashboardState();
}

class _DeliveryVendorDashboardState extends State<DeliveryVendorDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _accentColor = const Color(0xFF42A5F5);

  // ─── Realtime ─────────────────────────────────────────────────────────────
  final DeliveryRealtimeService _realtimeService =
      DeliveryRealtimeService.instance;
  bool _realtimeConnected = false;

  // Realtime-synced data (overlays mock data with live updates)
  final Map<String, Map<String, dynamic>> _liveDeliveryStatuses = {};
  final Map<String, Map<String, dynamic>> _liveRiderLocations = {};

  final List<Map<String, dynamic>> _newRequests = [
    {
      'id': 'REQ001',
      'type': 'Food Delivery',
      'from': 'Sharma Restaurant, MG Road',
      'to': 'Sector 5, Pune',
      'distance': '3.2 km',
      'amount': 65,
      'time': '2 min ago',
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFFF6B35),
      'customer': 'Amit Sharma',
    },
    {
      'id': 'REQ002',
      'type': 'Medicine',
      'from': 'City Pharmacy, Camp',
      'to': 'Koregaon Park',
      'distance': '4.1 km',
      'amount': 45,
      'time': '5 min ago',
      'icon': Icons.medication_rounded,
      'color': const Color(0xFF3498DB),
      'customer': 'Priya Patel',
    },
    {
      'id': 'REQ003',
      'type': 'Parcel',
      'from': 'Sender, Kothrud',
      'to': 'Baner',
      'distance': '6.5 km',
      'amount': 95,
      'time': '8 min ago',
      'icon': Icons.inventory_2_rounded,
      'color': const Color(0xFF9B59B6),
      'customer': 'Rahul Desai',
    },
  ];

  final List<Map<String, dynamic>> _riders = [
    {
      'name': 'Ravi Kumar',
      'phone': '9876543210',
      'status': 'online',
      'currentJob': 'Food Delivery',
      'completedToday': 8,
      'earnings': 640,
      'rating': 4.8,
      'location': 'MG Road',
    },
    {
      'name': 'Suresh Patil',
      'phone': '9876543211',
      'status': 'on_delivery',
      'currentJob': 'Medicine',
      'completedToday': 5,
      'earnings': 425,
      'rating': 4.6,
      'location': 'Camp Area',
    },
    {
      'name': 'Mahesh Jadhav',
      'phone': '9876543212',
      'status': 'online',
      'currentJob': null,
      'completedToday': 12,
      'earnings': 960,
      'rating': 4.9,
      'location': 'Kothrud',
    },
    {
      'name': 'Vijay Shinde',
      'phone': '9876543213',
      'status': 'offline',
      'currentJob': null,
      'completedToday': 3,
      'earnings': 240,
      'rating': 4.3,
      'location': 'Hadapsar',
    },
    {
      'name': 'Anil Bhosale',
      'phone': '9876543214',
      'status': 'on_delivery',
      'currentJob': 'Grocery',
      'completedToday': 7,
      'earnings': 560,
      'rating': 4.7,
      'location': 'Baner',
    },
  ];

  final List<Map<String, dynamic>> _activeDeliveries = [
    {
      'id': 'DEL001',
      'rider': 'Ravi Kumar',
      'type': 'Food Delivery',
      'from': 'Sharma Restaurant',
      'to': 'Sector 5',
      'status': 'picked_up',
      'eta': '12 min',
      'amount': 65,
    },
    {
      'id': 'DEL002',
      'rider': 'Suresh Patil',
      'type': 'Medicine',
      'from': 'City Pharmacy',
      'to': 'Koregaon Park',
      'status': 'on_way',
      'eta': '8 min',
      'amount': 45,
    },
    {
      'id': 'DEL003',
      'rider': 'Anil Bhosale',
      'type': 'Grocery',
      'from': 'Fresh Mart',
      'to': 'Baner',
      'status': 'assigned',
      'eta': '25 min',
      'amount': 55,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    // Subscribe to all delivery status changes
    _realtimeService.subscribeToAllDeliveries(
      onUpdate: (eventType, record) {
        if (!mounted) return;
        setState(() {
          _realtimeConnected = true;
          final deliveryId = record['delivery_id'] as String?;
          if (deliveryId != null) {
            _liveDeliveryStatuses[deliveryId] = record;
            // Update matching active delivery status
            for (int i = 0; i < _activeDeliveries.length; i++) {
              if (_activeDeliveries[i]['id'] == deliveryId) {
                _activeDeliveries[i] = {
                  ..._activeDeliveries[i],
                  'status':
                      record['delivery_status'] ??
                      _activeDeliveries[i]['status'],
                };
              }
            }
          }
        });
      },
    );

    // Subscribe to all rider location updates
    _realtimeService.subscribeToAllRiderLocations(
      onUpdate: (record) {
        if (!mounted) return;
        setState(() {
          _realtimeConnected = true;
          final riderId = record['rider_id'] as String?;
          if (riderId != null) {
            _liveRiderLocations[riderId] = record;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeService.unsubscribeAll();
    super.dispose();
  }

  String _getLiveDeliveryStatus(String deliveryId, String fallback) {
    return _liveDeliveryStatuses[deliveryId]?['delivery_status'] as String? ??
        fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildDashboardTab(),
          _buildRidersTab(),
          _buildDeliveriesTab(),
          _buildAnalyticsTab(),
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
        selectedItemColor: _primaryColor,
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
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bike_rounded),
            label: 'Riders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: _primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notificationScreen),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Delivery Vendor Dashboard',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Pune City • ${_riders.where((r) => r['status'] != 'offline').length} riders active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
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
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRealtimeBanner(),
                const SizedBox(height: 12),
                _buildKPIGrid(),
                const SizedBox(height: 20),
                _buildNewRequestsSection(),
                const SizedBox(height: 20),
                _buildLiveMapSection(),
                const SizedBox(height: 20),
                _buildQuickActionsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealtimeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _realtimeConnected
            ? const Color(0xFF2ECC71).withValues(alpha: 0.08)
            : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _realtimeConnected
              ? const Color(0xFF2ECC71).withValues(alpha: 0.4)
              : const Color(0xFFFFD700).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _realtimeConnected
                  ? const Color(0xFF2ECC71)
                  : const Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _realtimeConnected
                  ? 'Realtime active — ${_liveRiderLocations.length} rider(s) broadcasting GPS • ${_liveDeliveryStatuses.length} live status update(s)'
                  : 'Connecting to realtime — waiting for rider activity...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _realtimeConnected
                    ? const Color(0xFF1B7A3E)
                    : const Color(0xFF856404),
              ),
            ),
          ),
          Icon(
            Icons.sync_rounded,
            size: 16,
            color: _realtimeConnected
                ? const Color(0xFF2ECC71)
                : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    final kpis = [
      {
        'label': 'New Requests',
        'value': '${_newRequests.length}',
        'icon': Icons.inbox_rounded,
        'color': const Color(0xFFFF6B35),
        'sub': 'Pending',
      },
      {
        'label': 'Active',
        'value': '${_activeDeliveries.length}',
        'icon': Icons.directions_bike_rounded,
        'color': const Color(0xFF2ECC71),
        'sub': 'In progress',
      },
      {
        'label': "Today's Revenue",
        'value': '₹2,825',
        'icon': Icons.currency_rupee_rounded,
        'color': _primaryColor,
        'sub': '+12% vs yesterday',
      },
      {
        'label': 'Completed',
        'value': '35',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF27AE60),
        'sub': 'Today',
      },
      {
        'label': 'Online Riders',
        'value': '${_riders.where((r) => r['status'] != 'offline').length}',
        'icon': Icons.person_rounded,
        'color': _accentColor,
        'sub': 'of ${_riders.length} total',
      },
      {
        'label': 'Cancelled',
        'value': '2',
        'icon': Icons.cancel_rounded,
        'color': Colors.red[400]!,
        'sub': 'Today',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) {
        final kpi = kpis[i];
        return Container(
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  kpi['icon'] as IconData,
                  color: kpi['color'] as Color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Text(
                kpi['value'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                kpi['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                kpi['sub'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'New Requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_newRequests.length} pending',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._newRequests.map((req) => _buildRequestCard(req)),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (req['color'] as Color).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: (req['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  req['icon'] as IconData,
                  color: req['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          req['type'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '₹${req['amount']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${req['from']} → ${req['to']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          req['customer'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.route_rounded,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          req['distance'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          req['time'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAssignRiderSheet(req),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Assign Rider',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAssignRiderSheet(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Accept & Assign',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildLiveMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Rider Locations',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFE8F4FD),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 60,
                          color: _primaryColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Google Maps — Live Rider Tracking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                        Text(
                          '${_riders.where((r) => r['status'] != 'offline').length} riders online',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'label': 'Add Rider',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF2ECC71),
      },
      {
        'label': 'Complaints',
        'icon': Icons.report_problem_rounded,
        'color': Colors.orange[700]!,
      },
      {
        'label': 'Earnings',
        'icon': Icons.currency_rupee_rounded,
        'color': _primaryColor,
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_rounded,
        'color': Colors.grey[700]!,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            a['icon'] as IconData,
                            color: a['color'] as Color,
                            size: 22,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRidersTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _primaryColor,
          title: Text(
            'Rider Management',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => setState(() => _bottomNavIndex = 0),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                _buildRiderStatusSummary(),
                const SizedBox(height: 16),
                ..._riders.map((r) => _buildRiderCard(r)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderStatusSummary() {
    final online = _riders.where((r) => r['status'] == 'online').length;
    final onDelivery = _riders
        .where((r) => r['status'] == 'on_delivery')
        .length;
    final offline = _riders.where((r) => r['status'] == 'offline').length;

    return Row(
      children: [
        _buildStatusChip('Online', online, const Color(0xFF2ECC71)),
        const SizedBox(width: 8),
        _buildStatusChip('On Delivery', onDelivery, const Color(0xFFFF6B35)),
        const SizedBox(width: 8),
        _buildStatusChip('Offline', offline, Colors.grey),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
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

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final statusColors = {
      'online': const Color(0xFF2ECC71),
      'on_delivery': const Color(0xFFFF6B35),
      'offline': Colors.grey,
    };
    final statusLabels = {
      'online': 'Available',
      'on_delivery': 'On Delivery',
      'offline': 'Offline',
    };
    final color = statusColors[rider['status']] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                child: Text(
                  (rider['name'] as String).substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rider['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabels[rider['status']] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rider['location'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '${rider['rating']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${rider['completedToday']} today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.currency_rupee_rounded,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    Text(
                      '${rider['earnings']}',
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
          Column(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.call_rounded,
                    color: _primaryColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey[700],
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    return DefaultTabController(
      length: 4,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _primaryColor,
            title: Text(
              'Deliveries',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => setState(() => _bottomNavIndex = 0),
            ),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              children: [
                _buildDeliveryList(_activeDeliveries, 'active'),
                _buildDeliveryList([], 'pending'),
                _buildDeliveryList([], 'completed'),
                _buildDeliveryList([], 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryList(
    List<Map<String, dynamic>> deliveries,
    String type,
  ) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No $type deliveries',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: deliveries.length,
      itemBuilder: (_, i) => _buildActiveDeliveryCard(deliveries[i]),
    );
  }

  Widget _buildActiveDeliveryCard(Map<String, dynamic> del) {
    // Use live realtime status if available, fallback to local data
    final liveStatus = _getLiveDeliveryStatus(
      del['id'] as String,
      del['status'] as String,
    );
    final statusColors = {
      'assigned': const Color(0xFF3498DB),
      'accepted': const Color(0xFF3498DB),
      'picked_up': const Color(0xFFFF6B35),
      'on_way': const Color(0xFF2ECC71),
      'delivered': const Color(0xFF27AE60),
      'cancelled': Colors.red,
    };
    final color = statusColors[liveStatus] ?? Colors.grey;
    final isLive = _liveDeliveryStatuses.containsKey(del['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                del['id'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      liveStatus.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.directions_bike_rounded,
                size: 13,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                del['rider'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '₹${del['amount']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${del['from']} → ${del['to']}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                  label: Text(
                    'Reassign',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.call_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Call Customer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _primaryColor,
          title: Text(
            'Analytics & Earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => setState(() => _bottomNavIndex = 0),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEarningsSummary(),
                const SizedBox(height: 20),
                _buildWeeklyChart(),
                const SizedBox(height: 20),
                _buildTopRiders(),
                const SizedBox(height: 20),
                _buildRevenueBreakdown(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹48,250',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'This month • +18% vs last month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEarningChip('Today', '₹2,825'),
              const SizedBox(width: 10),
              _buildEarningChip('This Week', '₹18,450'),
              const SizedBox(width: 10),
              _buildEarningChip('Commission', '₹4,825'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [42, 38, 55, 48, 62, 75, 35];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Deliveries',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final height = (values[i] / maxVal) * 100;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[i]}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryColor, _accentColor],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRiders() {
    final topRiders = _riders.where((r) => r['status'] != 'offline').toList()
      ..sort(
        (a, b) =>
            (b['completedToday'] as int).compareTo(a['completedToday'] as int),
      );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Riders Today',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...topRiders.take(3).toList().asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(medals[i], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${r['completedToday']} deliveries',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${r['earnings']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final breakdown = [
      {'label': 'Food Delivery', 'amount': 12500, 'pct': 0.35},
      {'label': 'Grocery', 'amount': 8200, 'pct': 0.23},
      {'label': 'Medicine', 'amount': 5800, 'pct': 0.16},
      {'label': 'Parcel & Docs', 'amount': 7400, 'pct': 0.20},
      {'label': 'Others', 'amount': 2150, 'pct': 0.06},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.map((b) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${b['amount']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: b['pct'] as double,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAssignRiderSheet(Map<String, dynamic> req) {
    final availableRiders = _riders
        .where((r) => r['status'] == 'online')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 60.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.person_search_rounded, color: _primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'Assign Rider — ${req['id']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: availableRiders.length,
                itemBuilder: (_, i) {
                  final rider = availableRiders[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${rider['name']} assigned to ${req['id']}',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: _primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (rider['name'] as String).substring(0, 1),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rider['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${rider['location']} • ⭐ ${rider['rating']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Assign',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
