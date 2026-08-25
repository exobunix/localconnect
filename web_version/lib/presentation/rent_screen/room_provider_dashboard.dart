import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class RoomProviderDashboard extends StatefulWidget {
  const RoomProviderDashboard({super.key});

  @override
  State<RoomProviderDashboard> createState() => _RoomProviderDashboardState();
}

class _RoomProviderDashboardState extends State<RoomProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  // Listing form state
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  final _addressController = TextEditingController();
  String _furnished = 'Furnished';
  String _occupancy = 'Single';
  String _bathroom = 'Attached';
  bool _hasParking = false, _hasWifi = false, _hasAC = false;
  bool _hasKitchen = false, _hasBalcony = false, _hasPowerBackup = false;
  bool _hasWaterSupply = true;
  DateTime? _availableFrom;

  final List<String> _videoLinks = [];
  final _videoLinkController = TextEditingController();

  // Mock bookings
  final List<Map<String, dynamic>> _bookings = [
    {
      'name': 'Rahul Verma',
      'date': '2026-07-05',
      'status': 'Confirmed',
      'type': 'Visit',
      'amount': 0,
    },
    {
      'name': 'Sneha Kulkarni',
      'date': '2026-07-08',
      'status': 'Pending',
      'type': 'Booking',
      'amount': 8500,
    },
    {
      'name': 'Amit Singh',
      'date': '2026-06-28',
      'status': 'Completed',
      'type': 'Visit',
      'amount': 0,
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
    _titleController.dispose();
    _descController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _maintenanceController.dispose();
    _addressController.dispose();
    _videoLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.catRent,
        title: Text(
          'Room Provider Dashboard',
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
            Tab(text: 'Dashboard'),
            Tab(text: 'Listing'),
            Tab(text: 'Bookings'),
            Tab(text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildListingTab(),
          _buildBookingsTab(),
          _buildEarningsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatGrid(),
          const SizedBox(height: 20),
          Text(
            'Recent Bookings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._bookings.take(2).map((b) => _buildBookingCard(b)),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = [
      {
        'label': 'Total Views',
        'value': '248',
        'icon': Icons.visibility_rounded,
        'color': AppTheme.catRent,
      },
      {
        'label': 'Enquiries',
        'value': '18',
        'icon': Icons.message_rounded,
        'color': AppTheme.primary,
      },
      {
        'label': 'Visits Booked',
        'value': '7',
        'icon': Icons.calendar_today_rounded,
        'color': AppTheme.warning,
      },
      {
        'label': 'Occupancy',
        'value': '85%',
        'icon': Icons.people_rounded,
        'color': AppTheme.success,
      },
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats
          .map(
            (s) => Container(
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
                      color: (s['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s['value'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: s['color'] as Color,
                        ),
                      ),
                      Text(
                        s['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Update Availability',
        'icon': Icons.calendar_month_rounded,
        'color': AppTheme.catRent,
      },
      {
        'label': 'View on Map',
        'icon': Icons.map_rounded,
        'color': AppTheme.primary,
      },
      {
        'label': 'Customer Chat',
        'icon': Icons.chat_rounded,
        'color': AppTheme.warning,
      },
      {
        'label': 'Subscription',
        'icon': Icons.workspace_premium_rounded,
        'color': AppTheme.success,
      },
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: actions
          .map(
            (a) => GestureDetector(
              onTap: () {
                if (a['label'] == 'Customer Chat') {
                  Navigator.pushNamed(context, AppRoutes.chatListScreen);
                }
                if (a['label'] == 'Subscription') {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.providerSubscriptionScreen,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (a['color'] as Color).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (a['color'] as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      a['icon'] as IconData,
                      color: a['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: a['color'] as Color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Property Details'),
          const SizedBox(height: 12),
          _buildTextField(
            _titleController,
            'Property Title',
            Icons.title_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _descController,
            'Full Description',
            Icons.description_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _sectionHeader('Pricing'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _rentController,
                  'Monthly Rent (₹)',
                  Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  _depositController,
                  'Security Deposit (₹)',
                  Icons.lock_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _maintenanceController,
            'Maintenance Charges (₹)',
            Icons.build_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _sectionHeader('Property Details'),
          const SizedBox(height: 12),
          _buildDropdownRow('Furnished Status', _furnished, [
            'Furnished',
            'Semi-Furnished',
            'Unfurnished',
          ], (v) => setState(() => _furnished = v!)),
          const SizedBox(height: 12),
          _buildDropdownRow('Occupancy', _occupancy, [
            'Single',
            'Double',
            'Triple',
          ], (v) => setState(() => _occupancy = v!)),
          const SizedBox(height: 12),
          _buildDropdownRow('Bathroom', _bathroom, [
            'Attached',
            'Common',
          ], (v) => setState(() => _bathroom = v!)),
          const SizedBox(height: 16),
          _sectionHeader('Amenities'),
          const SizedBox(height: 12),
          _buildAmenitiesGrid(),
          const SizedBox(height: 16),
          _sectionHeader('Availability'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _availableFrom = d);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _availableFrom != null
                      ? AppTheme.catRent
                      : AppTheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.catRent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _availableFrom != null
                        ? 'Available From: ${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}'
                        : 'Select Available From Date',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: _availableFrom != null
                          ? const Color(0xFF1A1C1E)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Video Links'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _videoLinkController,
                  'YouTube / Instagram URL',
                  Icons.video_library_rounded,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_videoLinkController.text.isNotEmpty) {
                    setState(() {
                      _videoLinks.add(_videoLinkController.text);
                      _videoLinkController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.catRent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_videoLinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._videoLinks.map(
              (link) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.catRent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: AppTheme.catRent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _videoLinks.remove(link)),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _sectionHeader('Location'),
          const SizedBox(height: 12),
          _buildTextField(
            _addressController,
            'Full Address',
            Icons.location_on_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showSuccessSnackbar('Listing saved successfully!'),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.catRent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAmenitiesGrid() {
    final amenities = [
      {
        'label': 'Wi-Fi',
        'icon': Icons.wifi_rounded,
        'val': _hasWifi,
        'set': (v) => setState(() => _hasWifi = v),
      },
      {
        'label': 'AC',
        'icon': Icons.ac_unit_rounded,
        'val': _hasAC,
        'set': (v) => setState(() => _hasAC = v),
      },
      {
        'label': 'Parking',
        'icon': Icons.local_parking_rounded,
        'val': _hasParking,
        'set': (v) => setState(() => _hasParking = v),
      },
      {
        'label': 'Kitchen',
        'icon': Icons.kitchen_rounded,
        'val': _hasKitchen,
        'set': (v) => setState(() => _hasKitchen = v),
      },
      {
        'label': 'Balcony',
        'icon': Icons.balcony_rounded,
        'val': _hasBalcony,
        'set': (v) => setState(() => _hasBalcony = v),
      },
      {
        'label': 'Power Backup',
        'icon': Icons.bolt_rounded,
        'val': _hasPowerBackup,
        'set': (v) => setState(() => _hasPowerBackup = v),
      },
      {
        'label': 'Water Supply',
        'icon': Icons.water_drop_rounded,
        'val': _hasWaterSupply,
        'set': (v) => setState(() => _hasWaterSupply = v),
      },
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) {
        final isOn = a['val'] as bool;
        return GestureDetector(
          onTap: () => (a['set'] as Function)(!isOn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOn
                  ? AppTheme.catRent.withValues(alpha: 0.12)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? AppTheme.catRent : AppTheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  a['icon'] as IconData,
                  size: 14,
                  color: isOn ? AppTheme.catRent : Colors.grey.shade600,
                ),
                const SizedBox(width: 5),
                Text(
                  a['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOn ? AppTheme.catRent : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'All Bookings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_bookings.length} total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.catRent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._bookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final statusColors = {
      'Confirmed': AppTheme.success,
      'Pending': AppTheme.warning,
      'Completed': AppTheme.primary,
    };
    final color = statusColors[booking['status']] ?? Colors.grey;
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
            offset: const Offset(0, 2),
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
                  booking['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${booking['type']} • ${booking['date']}',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking['status'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if ((booking['amount'] as int) > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '₹${booking['amount']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.catRent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.catRent,
                  AppTheme.catRent.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 4),
                Text(
                  '₹42,500',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _earningChip('This Month', '₹8,500'),
                    const SizedBox(width: 10),
                    _earningChip('Pending', '₹8,500'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Transaction History',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            {'month': 'June 2026', 'amount': '₹8,500', 'bookings': 1},
            {'month': 'May 2026', 'amount': '₹17,000', 'bookings': 2},
            {'month': 'April 2026', 'amount': '₹8,500', 'bookings': 1},
          ].map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.catRent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppTheme.catRent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['month'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${t['bookings']} booking(s)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    t['amount'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.catRent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.home_work_rounded, 'label': 'Listing'},
      {'icon': Icons.chat_rounded, 'label': 'Chat'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _bottomNavIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _bottomNavIndex = i);
                  if (i == 2) {
                    Navigator.pushNamed(context, AppRoutes.chatListScreen);
                  }
                  if (i == 3) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.providerProfileScreen,
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: isActive ? AppTheme.catRent : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? AppTheme.catRent
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
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
            color: AppTheme.catRent,
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

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.catRent),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.catRent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey.shade500,
        ),
      ),
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

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.catRent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
