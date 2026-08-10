import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class PgProviderDashboard extends StatefulWidget {
  const PgProviderDashboard({super.key});

  @override
  State<PgProviderDashboard> createState() => _PgProviderDashboardState();
}

class _PgProviderDashboardState extends State<PgProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _pgColor = Color(0xFF7B1FA2);

  String _pgType = 'Boys PG';
  final String _sharingType = 'Single Sharing';
  bool _foodIncluded = false, _laundry = false, _housekeeping = false;
  bool _hasWifi = true, _hasAC = false, _hasCCTV = true, _hasSecurity = false;
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  String _curfewTime = 'No Curfew';
  String _visitorPolicy = 'Allowed';

  final List<Map<String, dynamic>> _rooms = [
    {'type': 'Single Sharing', 'beds': 5, 'occupied': 3, 'rent': 7000},
    {'type': 'Double Sharing', 'beds': 8, 'occupied': 6, 'rent': 5500},
    {'type': 'Triple Sharing', 'beds': 6, 'occupied': 4, 'rent': 4500},
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'name': 'Priya Sharma',
      'room': 'Single Sharing',
      'date': '2026-07-01',
      'status': 'Active',
      'rent': 7000,
    },
    {
      'name': 'Neha Gupta',
      'room': 'Double Sharing',
      'date': '2026-07-10',
      'status': 'Pending',
      'rent': 5500,
    },
    {
      'name': 'Kavya Reddy',
      'room': 'Single Sharing',
      'date': '2026-06-15',
      'status': 'Completed',
      'rent': 7000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _pgColor,
        title: Text(
          'PG Provider Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.loginScreen,
              (_) => false,
            ),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Rooms'),
            Tab(text: 'Bookings'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRoomsTab(),
          _buildBookingsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalBeds = _rooms.fold(0, (s, r) => s + (r['beds'] as int));
    final occupiedBeds = _rooms.fold(0, (s, r) => s + (r['occupied'] as int));
    final occupancyRate = totalBeds > 0
        ? (occupiedBeds / totalBeds * 100).toInt()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_pgColor, _pgColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Occupancy Rate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$occupancyRate%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancyRate / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$occupiedBeds / $totalBeds beds occupied',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard(
                'Total Beds',
                '$totalBeds',
                Icons.bed_rounded,
                _pgColor,
              ),
              _statCard(
                'Available',
                '${totalBeds - occupiedBeds}',
                Icons.check_circle_rounded,
                AppTheme.success,
              ),
              _statCard(
                'Monthly Revenue',
                '₹${_rooms.fold(0, (s, r) => s + (r['occupied'] as int) * (r['rent'] as int))}',
                Icons.currency_rupee_rounded,
                AppTheme.warning,
              ),
              _statCard(
                'Enquiries',
                '12',
                Icons.message_rounded,
                AppTheme.primary,
              ),
            ],
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
              Expanded(
                child: _actionButton(
                  'Customer Chat',
                  Icons.chat_rounded,
                  () => Navigator.pushNamed(context, AppRoutes.chatListScreen),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  'Subscription',
                  Icons.workspace_premium_rounded,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.providerSubscriptionScreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Room Categories',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddRoomSheet(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: _pgColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._rooms.map((r) => _buildRoomCard(r)),
      ],
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final available = (room['beds'] as int) - (room['occupied'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _pgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bedroom_child_rounded,
                  color: _pgColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['type'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '₹${room['rent']}/month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _pgColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: available > 0
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$available available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: available > 0 ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _bedProgress(
                  'Total',
                  room['beds'] as int,
                  room['beds'] as int,
                  Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _bedProgress(
                  'Occupied',
                  room['occupied'] as int,
                  room['beds'] as int,
                  _pgColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bedProgress(String label, int value, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._bookings.map((b) {
          final statusColors = {
            'Active': AppTheme.success,
            'Pending': AppTheme.warning,
            'Completed': AppTheme.primary,
          };
          final color = statusColors[b['status']] ?? Colors.grey;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${b['room']} • ${b['date']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        b['status'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${b['rent']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _pgColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PG Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Boys PG',
                  'Girls PG',
                  'Family PG',
                  'Working Professional',
                  'Student PG',
                ].map((t) {
                  final sel = _pgType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _pgType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _pgColor : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? _pgColor : AppTheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Facilities'),
          const SizedBox(height: 10),
          _facilityToggle(
            'Food Included',
            Icons.restaurant_rounded,
            _foodIncluded,
            (v) => setState(() => _foodIncluded = v),
          ),
          _facilityToggle(
            'Laundry',
            Icons.local_laundry_service_rounded,
            _laundry,
            (v) => setState(() => _laundry = v),
          ),
          _facilityToggle(
            'Housekeeping',
            Icons.cleaning_services_rounded,
            _housekeeping,
            (v) => setState(() => _housekeeping = v),
          ),
          _facilityToggle(
            'Wi-Fi',
            Icons.wifi_rounded,
            _hasWifi,
            (v) => setState(() => _hasWifi = v),
          ),
          _facilityToggle(
            'AC',
            Icons.ac_unit_rounded,
            _hasAC,
            (v) => setState(() => _hasAC = v),
          ),
          _facilityToggle(
            'CCTV',
            Icons.videocam_rounded,
            _hasCCTV,
            (v) => setState(() => _hasCCTV = v),
          ),
          _facilityToggle(
            'Security Guard',
            Icons.security_rounded,
            _hasSecurity,
            (v) => setState(() => _hasSecurity = v),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Rules'),
          const SizedBox(height: 10),
          _buildDropdownRow('Curfew', _curfewTime, [
            'No Curfew',
            '9:00 PM',
            '10:00 PM',
            '11:00 PM',
          ], (v) => setState(() => _curfewTime = v!)),
          const SizedBox(height: 10),
          _buildDropdownRow('Visitors', _visitorPolicy, [
            'Allowed',
            'Not Allowed',
            'With Permission',
          ], (v) => setState(() => _visitorPolicy = v!)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Settings saved!',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: _pgColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pgColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityToggle(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? _pgColor : Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, activeColor: _pgColor, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _pgColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pgColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _pgColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _pgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _pgColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Room Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pgColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
