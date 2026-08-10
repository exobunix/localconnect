import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class DailyWageProviderDashboard extends StatefulWidget {
  const DailyWageProviderDashboard({super.key});

  @override
  State<DailyWageProviderDashboard> createState() =>
      _DailyWageProviderDashboardState();
}

class _DailyWageProviderDashboardState
    extends State<DailyWageProviderDashboard> {
  int _bottomNavIndex = 0;
  static const _primaryColor = Color(0xFF00695C);

  final Map<String, dynamic> _rates = {
    'hourly': 80,
    'halfDay': 300,
    'fullDay': 550,
  };

  final List<String> _skills = [
    'Loading',
    'Moving',
    'Garden Work',
    'Construction Helper',
    'Cleaning',
    'Painting Helper',
  ];
  final Set<String> _selectedSkills = {'Loading', 'Moving', 'Garden Work'};

  final List<Map<String, dynamic>> _bookings = [
    {
      'customer': 'Rajesh Gupta',
      'work': 'Moving & Loading',
      'workers': 2,
      'duration': 'Full Day',
      'date': 'Today',
      'status': 'Active',
      'amount': 1100,
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)),
    },
    {
      'customer': 'Sunita Sharma',
      'work': 'Garden Work',
      'workers': 1,
      'duration': 'Half Day',
      'date': 'Tomorrow',
      'status': 'Pending',
      'amount': 300,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 25)),
    },
    {
      'customer': 'Mohan Das',
      'work': 'Construction Helper',
      'workers': 3,
      'duration': 'Full Day',
      'date': 'Jun 28',
      'status': 'Completed',
      'amount': 1650,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'customer': 'Priya Verma',
      'work': 'Cleaning',
      'workers': 1,
      'duration': 'Half Day',
      'date': 'Today',
      'status': 'Pending',
      'amount': 300,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 7)),
    },
  ];

  bool _isAvailable = true;
  final String _workingHours = '7:00 AM – 7:00 PM';

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
      'Not enough workers',
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
    setState(() => booking['status'] = 'Active');
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
      case 'Active':
        return Colors.blue[700]!;
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
          _buildRates(),
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
              Icons.currency_rupee_rounded,
              color: _bottomNavIndex == 2 ? _primaryColor : Colors.grey,
            ),
            label: 'Rates',
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
                              Icons.engineering_rounded,
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
                                  'Helper Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Daily Wage Worker',
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
                                _isAvailable ? '● Available' : '○ Busy',
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
                      '₹8,250',
                      Icons.currency_rupee_rounded,
                      Colors.green[700]!,
                    ),
                    _kpiCard(
                      'Rating',
                      '4.3 ★',
                      Icons.star_rounded,
                      Colors.amber[700]!,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Rate cards
                Row(
                  children: [
                    _rateCard(
                      'Hourly',
                      '₹${_rates['hourly']}',
                      Icons.timer_rounded,
                    ),
                    const SizedBox(width: 10),
                    _rateCard(
                      'Half Day',
                      '₹${_rates['halfDay']}',
                      Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(width: 10),
                    _rateCard(
                      'Full Day',
                      '₹${_rates['fullDay']}',
                      Icons.calendar_today_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Skills
                Text(
                  'My Skills',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: _primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                Text(
                  'Active Bookings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ..._bookings
                    .where((b) => b['status'] == 'Active')
                    .map((b) => _bookingCard(b)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _quickAction(
                      Icons.workspace_premium_rounded,
                      'Subscription',
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.providerSubscriptionScreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _quickAction(Icons.star_border_rounded, 'Reviews', () {}),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.chat_rounded,
                      'Chat',
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.chatListScreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.help_outline_rounded,
                      'Support',
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.customerSupportScreen,
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

  Widget _rateCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Icon(icon, size: 18, color: _primaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _primaryColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
                      '${b['work']} · ${b['workers']} worker(s) · ${b['duration']}',
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
                Icons.calendar_today_rounded,
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
              const Spacer(),
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

  Widget _buildRates() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Rates & Skills',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Rates',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _rateEditTile('Hourly Rate', '₹${_rates['hourly']}/hr'),
            _rateEditTile('Half Day Rate', '₹${_rates['halfDay']}/half-day'),
            _rateEditTile('Full Day Rate', '₹${_rates['fullDay']}/day'),
            const SizedBox(height: 20),
            Text(
              'My Skills',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((s) {
                final selected = _selectedSkills.contains(s);
                return GestureDetector(
                  onTap: () => setState(
                    () => selected
                        ? _selectedSkills.remove(s)
                        : _selectedSkills.add(s),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: selected ? _primaryColor : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: selected ? Colors.white : Colors.grey[700],
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Working Hours',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                  Icon(
                    Icons.access_time_rounded,
                    color: _primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _workingHours,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateEditTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.currency_rupee_rounded, color: _primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit_rounded, size: 16, color: Colors.grey[400]),
        ],
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
                    '₹24,600',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _earningChip('This Month', '₹8,250'),
                      const SizedBox(width: 12),
                      _earningChip('This Week', '₹1,650'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Completed Jobs',
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
                                b['work'] as String,
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
                      Icons.engineering_rounded,
                      size: 36,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Raju Helper Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Daily Wage Worker · 2 years experience',
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
                        ' 4.3 · 45 reviews',
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
              Icons.access_time_rounded,
              'Working Hours',
              _workingHours,
              () {},
            ),
            _profileTile(
              Icons.location_on_rounded,
              'Service Area',
              'Pune – 10 km radius',
              () {},
            ),
            _profileTile(
              Icons.workspace_premium_rounded,
              'Subscription',
              'Basic Plan – Active',
              () => Navigator.pushNamed(
                context,
                AppRoutes.providerSubscriptionScreen,
              ),
            ),
            _profileTile(
              Icons.star_border_rounded,
              'Ratings & Reviews',
              '4.3 ★ (45 reviews)',
              () {},
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
