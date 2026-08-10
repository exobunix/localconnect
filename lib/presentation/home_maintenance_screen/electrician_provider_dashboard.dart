import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class ElectricianProviderDashboard extends StatefulWidget {
  const ElectricianProviderDashboard({super.key});

  @override
  State<ElectricianProviderDashboard> createState() =>
      _ElectricianProviderDashboardState();
}

class _ElectricianProviderDashboardState
    extends State<ElectricianProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  static const _primaryColor = Color(0xFFF57F17);

  final List<Map<String, dynamic>> _services = [
    {'name': 'New Wiring', 'price': 1500, 'enabled': true, 'emergency': false},
    {'name': 'Fault Repair', 'price': 400, 'enabled': true, 'emergency': true},
    {
      'name': 'Fan Installation',
      'price': 250,
      'enabled': true,
      'emergency': false,
    },
    {
      'name': 'Light Installation',
      'price': 200,
      'enabled': true,
      'emergency': false,
    },
    {
      'name': 'Switchboard Repair',
      'price': 300,
      'enabled': true,
      'emergency': false,
    },
    {
      'name': 'Inverter Installation',
      'price': 1200,
      'enabled': true,
      'emergency': false,
    },
    {
      'name': 'UPS Installation',
      'price': 1000,
      'enabled': false,
      'emergency': false,
    },
    {
      'name': 'MCB Replacement',
      'price': 350,
      'enabled': true,
      'emergency': true,
    },
    {
      'name': 'Earthing Work',
      'price': 800,
      'enabled': true,
      'emergency': false,
    },
    {
      'name': 'Emergency Electrical',
      'price': 700,
      'enabled': true,
      'emergency': true,
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'EL001',
      'customer': 'Kavita Joshi',
      'service': 'Fan Installation',
      'date': 'Today, 3:00 PM',
      'status': 'Pending',
      'amount': 250,
      'address': '34 Baner Road, Pune',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
    },
    {
      'id': 'EL002',
      'customer': 'Deepak Nair',
      'service': 'Fault Repair',
      'date': 'Tomorrow, 9:00 AM',
      'status': 'Confirmed',
      'amount': 400,
      'address': '12 Kothrud',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'EL003',
      'customer': 'Meena Gupta',
      'service': 'New Wiring',
      'date': 'Jun 28, 11:00 AM',
      'status': 'Completed',
      'amount': 1500,
      'address': '56 Hadapsar',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': 'EL004',
      'customer': 'Ravi Tiwari',
      'service': 'MCB Replacement',
      'date': 'Jul 3, 2:00 PM',
      'status': 'Confirmed',
      'amount': 350,
      'address': '8 Wakad',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 'EL005',
      'customer': 'Sunita Rao',
      'service': 'Switchboard Repair',
      'date': 'Today, 5:00 PM',
      'status': 'Pending',
      'amount': 300,
      'address': '22 Viman Nagar, Pune',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
    },
  ];

  bool _isAvailable = true;
  bool _acceptsEmergency = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange[700]!;
      case 'Confirmed':
        return Colors.blue[700]!;
      case 'Completed':
        return Colors.green[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  List<Map<String, dynamic>> get _sortedPendingBookings {
    final pending = _bookings.where((b) => b['status'] == 'Pending').toList();
    pending.sort((a, b) {
      final aTime = a['createdAt'] as DateTime? ?? DateTime(2000);
      final bTime = b['createdAt'] as DateTime? ?? DateTime(2000);
      return bTime.compareTo(aTime); // newest first
    });
    return pending;
  }

  Future<void> _showRejectDialog(Map<String, dynamic> booking) async {
    final reasonController = TextEditingController();
    final reasons = [
      'Not available at this time',
      'Outside service area',
      'Already booked',
      'Emergency only slot',
      'Other',
    ];
    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reject Request',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a reason for ${booking['customer']}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selectedReason,
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                  title: Text(
                    r,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Colors.red[700],
                ),
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reject',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => booking['status'] = 'Rejected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request from ${booking['customer']} rejected.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _acceptBooking(Map<String, dynamic> booking) {
    setState(() => booking['status'] = 'Confirmed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Accepted! Opening chat with ${booking['customer']}...',
          style: GoogleFonts.plusJakartaSans(),
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.chatListScreen);
      }
    });
  }

  void _signOut() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loginScreen,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildDashboardTab(),
          _buildBookingsTab(),
          _buildServicesTab(),
          _buildEarningsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: _primaryColor.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_rounded,
              color: _bottomNavIndex == 0 ? _primaryColor : Colors.grey,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: _bottomNavIndex == 1 ? _primaryColor : Colors.grey,
            ),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.electrical_services_rounded,
              color: _bottomNavIndex == 2 ? _primaryColor : Colors.grey,
            ),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: _bottomNavIndex == 3 ? _primaryColor : Colors.grey,
            ),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_rounded,
              color: _bottomNavIndex == 4 ? _primaryColor : Colors.grey,
            ),
            label: 'Profile',
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
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notificationScreen),
            ),
            IconButton(
              icon: const Icon(Icons.chat_rounded, color: Colors.white),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.chatListScreen),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor,
                    _primaryColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              Icons.electrical_services_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Electrician Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Vijay Electrical Services',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isAvailable = !_isAvailable),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _isAvailable
                                    ? Colors.green[400]
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                _isAvailable ? '● Online' : '○ Offline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white,
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
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _kpiCard(
                      'Today\'s Jobs',
                      '4',
                      Icons.work_rounded,
                      Colors.blue[700]!,
                    ),
                    _kpiCard(
                      'Pending',
                      '${_sortedPendingBookings.length}',
                      Icons.pending_actions_rounded,
                      Colors.orange[700]!,
                    ),
                    _kpiCard(
                      'This Month',
                      '₹18,600',
                      Icons.currency_rupee_rounded,
                      Colors.green[700]!,
                    ),
                    _kpiCard(
                      'Rating',
                      '4.9 ★',
                      Icons.star_rounded,
                      Colors.amber[700]!,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Certifications banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: _primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certified Electrician',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              'ITI Certified · 12 years experience',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Pending Requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_sortedPendingBookings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_sortedPendingBookings.length} new',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Newest first',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._sortedPendingBookings.map(
                  (b) => _bookingCard(
                    b,
                    showActions: true,
                    isNewest: _sortedPendingBookings.indexOf(b) == 0,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _quickAction(
                      Icons.add_photo_alternate_rounded,
                      'Work\nGallery',
                      () {},
                    ),
                    const SizedBox(width: 10),
                    _quickAction(Icons.receipt_long_rounded, 'Invoice', () {}),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.calendar_today_rounded,
                      'Calendar',
                      () {},
                    ),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.workspace_premium_rounded,
                      'Subscription',
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.providerSubscriptionScreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Bookings',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _bookingList('Pending'),
          _bookingList('Confirmed'),
          _bookingList('Completed'),
          _bookingList(null),
        ],
      ),
    );
  }

  Widget _bookingList(String? filter) {
    List<Map<String, dynamic>> list;
    if (filter == null) {
      list = List.from(_bookings);
    } else if (filter == 'Pending') {
      list = _sortedPendingBookings;
    } else {
      list = _bookings.where((b) => b['status'] == filter).toList();
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No bookings',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _bookingCard(
        list[i],
        showActions: list[i]['status'] == 'Pending',
        isNewest: filter == 'Pending' && i == 0,
      ),
    );
  }

  Widget _bookingCard(
    Map<String, dynamic> b, {
    bool showActions = false,
    bool isNewest = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: isNewest
            ? Border.all(color: Colors.orange[300]!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          b['customer'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isNewest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NEW',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      b['service'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(
                    b['status'] as String,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  b['status'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _statusColor(b['status'] as String),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                b['date'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.location_on_rounded,
                size: 13,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  b['address'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '₹${b['amount']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(b),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[200]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptBooking(b),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Accept & Chat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Service Catalogue',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (_, i) {
          final s = _services[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.electrical_services_rounded,
                    size: 18,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (s['emergency'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'Emergency',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '₹${s['price']} per visit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: s['enabled'] as bool,
                  onChanged: (v) => setState(() => s['enabled'] = v),
                  activeColor: _primaryColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Earnings',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.providerSubscriptionScreen,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor,
                    _primaryColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹72,500',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _earningChip('This Month', '₹18,600'),
                      const SizedBox(width: 12),
                      _earningChip('This Week', '₹4,800'),
                      const SizedBox(width: 12),
                      _earningChip('Today', '₹1,250'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recent Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ..._bookings
                .where((b) => b['status'] == 'Completed')
                .map(
                  (b) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b['customer'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                b['service'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+₹${b['amount']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w700,
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

  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.loginScreen,
              (_) => false,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vijay Electrical Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Electrician · 12 years experience',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'ITI Certified',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      Text(
                        ' 4.9 · 201 reviews',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _profileTile(
              Icons.verified_rounded,
              'Certifications',
              'ITI Certified · Upload Certificate',
              () {},
            ),
            _profileTile(
              Icons.access_time_rounded,
              'Working Hours',
              '8:00 AM – 9:00 PM',
              () {},
            ),
            _profileTile(
              Icons.location_on_rounded,
              'Service Area',
              'Pune – 15 km radius',
              () {},
            ),
            _profileTile(
              Icons.flash_on_rounded,
              'Emergency Service',
              _acceptsEmergency ? 'Enabled' : 'Disabled',
              () => setState(() => _acceptsEmergency = !_acceptsEmergency),
            ),
            _profileTile(
              Icons.workspace_premium_rounded,
              'Subscription Plan',
              'Pro Plan – Active',
              () => Navigator.pushNamed(
                context,
                AppRoutes.providerSubscriptionScreen,
              ),
            ),
            _profileTile(
              Icons.star_border_rounded,
              'Ratings & Reviews',
              '4.9 ★ (201 reviews)',
              () {},
            ),
            _profileTile(
              Icons.help_outline_rounded,
              'Support',
              'Get help',
              () =>
                  Navigator.pushNamed(context, AppRoutes.customerSupportScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
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
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _primaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earningChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _profileTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 18, color: _primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
