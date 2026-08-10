import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class CleaningProviderDashboard extends StatefulWidget {
  const CleaningProviderDashboard({super.key});

  @override
  State<CleaningProviderDashboard> createState() =>
      _CleaningProviderDashboardState();
}

class _CleaningProviderDashboardState extends State<CleaningProviderDashboard> {
  int _bottomNavIndex = 0;
  static const _primaryColor = Color(0xFF1565C0);

  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Basic Home Cleaning',
      'price': 499,
      'duration': '2-3 hrs',
      'enabled': true,
      'includes': 'Sweeping, mopping, dusting',
    },
    {
      'name': 'Deep Cleaning',
      'price': 1299,
      'duration': '5-6 hrs',
      'enabled': true,
      'includes': 'Full deep clean including kitchen & bathrooms',
    },
    {
      'name': 'Bathroom Cleaning',
      'price': 299,
      'duration': '1 hr',
      'enabled': true,
      'includes': 'Tiles, toilet, sink, mirror',
    },
    {
      'name': 'Kitchen Cleaning',
      'price': 399,
      'duration': '1-2 hrs',
      'enabled': true,
      'includes': 'Chimney, stove, counters, sink',
    },
    {
      'name': 'Sofa Cleaning',
      'price': 599,
      'duration': '2 hrs',
      'enabled': true,
      'includes': 'Steam cleaning, stain removal',
    },
    {
      'name': 'Carpet Cleaning',
      'price': 799,
      'duration': '2-3 hrs',
      'enabled': false,
      'includes': 'Shampoo wash, steam dry',
    },
    {
      'name': 'Office Cleaning',
      'price': 1499,
      'duration': '4-5 hrs',
      'enabled': true,
      'includes': 'Workstations, floors, washrooms',
    },
    {
      'name': 'Water Tank Cleaning',
      'price': 899,
      'duration': '3-4 hrs',
      'enabled': true,
      'includes': 'Drain, scrub, disinfect, refill',
    },
    {
      'name': 'Post-Construction Cleaning',
      'price': 2499,
      'duration': '8+ hrs',
      'enabled': true,
      'includes': 'Dust, debris, paint marks removal',
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'customer': 'Pooja Sharma',
      'package': 'Deep Cleaning',
      'date': 'Today, 10:00 AM',
      'status': 'Active',
      'amount': 1299,
      'address': '45 Baner Road',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      'customer': 'Vikram Nair',
      'package': 'Bathroom Cleaning',
      'date': 'Tomorrow, 9:00 AM',
      'status': 'Pending',
      'amount': 299,
      'address': '12 Kothrud',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 22)),
    },
    {
      'customer': 'Ananya Patel',
      'package': 'Sofa Cleaning',
      'date': 'Jun 30, 2:00 PM',
      'status': 'Confirmed',
      'amount': 599,
      'address': '8 Aundh',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'customer': 'Ravi Kumar',
      'package': 'Basic Home Cleaning',
      'date': 'Jun 28, 11:00 AM',
      'status': 'Completed',
      'amount': 499,
      'address': '23 Wakad',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'customer': 'Meena Joshi',
      'package': 'Kitchen Cleaning',
      'date': 'Today, 4:00 PM',
      'status': 'Pending',
      'amount': 399,
      'address': '17 Viman Nagar',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 6)),
    },
  ];

  final List<String> _equipment = [
    'Vacuum Cleaner',
    'Steam Mop',
    'Pressure Washer',
    'Eco-friendly Products',
    'Microfiber Cloths',
  ];

  bool _isAvailable = true;

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
      'Equipment not available',
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
      if (mounted) Navigator.pushNamed(context, AppRoutes.chatListScreen);
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':
        return Colors.orange[700]!;
      case 'Confirmed':
        return Colors.blue[700]!;
      case 'Active':
        return Colors.purple[700]!;
      case 'Completed':
        return Colors.green[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _buildDashboard(),
          _buildBookings(),
          _buildPackages(),
          _buildEarnings(),
          _buildProfile(),
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
              Icons.cleaning_services_rounded,
              color: _bottomNavIndex == 2 ? _primaryColor : Colors.grey,
            ),
            label: 'Packages',
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

  Widget _buildDashboard() {
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
              tooltip: 'Sign Out',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginScreen,
                (_) => false,
              ),
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
                              Icons.cleaning_services_rounded,
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
                                  'Cleaning Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'SparkleClean Services',
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
                      '1',
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
                      '₹24,800',
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
                // Equipment
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build_rounded,
                            color: _primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Equipment Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _equipment
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  e,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
                if (_sortedPendingBookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No pending requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                else
                  ..._sortedPendingBookings.map(
                    (b) => _bookingCard(b, showActions: true),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _quickAction(
                      Icons.add_photo_alternate_rounded,
                      'Add\nPhoto',
                      () {},
                    ),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.repeat_rounded,
                      'Recurring\nClients',
                      () {},
                    ),
                    const SizedBox(width: 10),
                    _quickAction(Icons.star_border_rounded, 'Reviews', () {}),
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

  Widget _buildBookings() {
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (_, i) => _bookingCard(
          _bookings[i],
          showActions: _bookings[i]['status'] == 'Pending',
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b, {bool showActions = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['customer'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      b['package'] as String,
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
              const SizedBox(width: 8),
              Icon(
                Icons.location_on_rounded,
                size: 13,
                color: Colors.grey[500],
              ),
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
                    child: Text(
                      'Accept',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildPackages() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Service Packages',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _packages.length,
        itemBuilder: (_, i) {
          final p = _packages[i];
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
                    Icons.cleaning_services_rounded,
                    size: 18,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${p['price']} · ${p['duration']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        p['includes'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: p['enabled'] as bool,
                  onChanged: (v) => setState(() => p['enabled'] = v),
                  activeColor: _primaryColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarnings() {
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
                    '₹86,400',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _earningChip('This Month', '₹24,800'),
                      const SizedBox(width: 12),
                      _earningChip('This Week', '₹6,200'),
                      const SizedBox(width: 12),
                      _earningChip('Today', '₹1,299'),
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
                                b['package'] as String,
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

  Widget _buildProfile() {
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
                      Icons.cleaning_services_rounded,
                      size: 36,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SparkleClean Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Cleaning Service · 6 years experience',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
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
                        ' 4.9 · 187 reviews',
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
              Icons.build_rounded,
              'Equipment',
              '${_equipment.length} items available',
              () {},
            ),
            _profileTile(
              Icons.access_time_rounded,
              'Working Hours',
              '8:00 AM – 8:00 PM',
              () {},
            ),
            _profileTile(
              Icons.location_on_rounded,
              'Service Area',
              'Pune – 20 km radius',
              () {},
            ),
            _profileTile(
              Icons.workspace_premium_rounded,
              'Subscription',
              'Pro Plan – Active',
              () => Navigator.pushNamed(
                context,
                AppRoutes.providerSubscriptionScreen,
              ),
            ),
            _profileTile(
              Icons.star_border_rounded,
              'Ratings & Reviews',
              '4.9 ★ (187 reviews)',
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
