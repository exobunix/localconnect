import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class VillaProviderDashboard extends StatefulWidget {
  const VillaProviderDashboard({super.key});

  @override
  State<VillaProviderDashboard> createState() => _VillaProviderDashboardState();
}

class _VillaProviderDashboardState extends State<VillaProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _villaColor = Color(0xFFE65100);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dailyRentController = TextEditingController();
  final _weeklyRentController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _depositController = TextEditingController();
  final _addressController = TextEditingController();
  final _videoLinkController = TextEditingController();

  int _maxGuests = 8;
  int _bedrooms = 3;
  int _bathrooms = 2;
  bool _hasPool = false, _hasGarden = false, _hasBBQ = false;
  bool _hasPetFriendly = false, _hasParking = true, _hasAC = true;
  bool _hasKitchen = true, _hasWifi = true;
  String _pricingType = 'Daily';
  final List<String> _videoLinks = [];

  final List<Map<String, dynamic>> _bookings = [
    {
      'name': 'Sharma Family',
      'checkIn': '2026-07-10',
      'checkOut': '2026-07-13',
      'guests': 6,
      'status': 'Confirmed',
      'amount': 24000,
    },
    {
      'name': 'Mehta Group',
      'checkIn': '2026-07-20',
      'checkOut': '2026-07-22',
      'guests': 4,
      'status': 'Pending',
      'amount': 16000,
    },
    {
      'name': 'Patel Family',
      'checkIn': '2026-06-25',
      'checkOut': '2026-06-28',
      'guests': 8,
      'status': 'Completed',
      'amount': 24000,
    },
  ];

  // Availability calendar - blocked dates
  final Set<DateTime> _blockedDates = {};

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
    _dailyRentController.dispose();
    _weeklyRentController.dispose();
    _monthlyRentController.dispose();
    _depositController.dispose();
    _addressController.dispose();
    _videoLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _villaColor,
        title: Text(
          'Villa / Holiday Home',
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
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildListingTab(),
          _buildBookingsTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_villaColor, _villaColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month Revenue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        '₹64,000',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniChip('3 Bookings'),
                          const SizedBox(width: 8),
                          _miniChip('18 Nights'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.villa_rounded, color: Colors.white, size: 48),
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
                'Total Bookings',
                '12',
                Icons.calendar_today_rounded,
                _villaColor,
              ),
              _statCard(
                'Avg Rating',
                '4.8',
                Icons.star_rounded,
                AppTheme.warning,
              ),
              _statCard(
                'Views',
                '342',
                Icons.visibility_rounded,
                AppTheme.primary,
              ),
              _statCard(
                'Enquiries',
                '28',
                Icons.message_rounded,
                AppTheme.success,
              ),
            ],
          ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Chat',
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
            'Villa / Holiday Home Name',
            Icons.villa_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _descController,
            'Description',
            Icons.description_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _sectionHeader('Capacity'),
          const SizedBox(height: 12),
          _buildCounterRow(
            'Max Guests',
            _maxGuests,
            (v) => setState(() => _maxGuests = v),
            1,
            30,
          ),
          const SizedBox(height: 10),
          _buildCounterRow(
            'Bedrooms',
            _bedrooms,
            (v) => setState(() => _bedrooms = v),
            1,
            10,
          ),
          const SizedBox(height: 10),
          _buildCounterRow(
            'Bathrooms',
            _bathrooms,
            (v) => setState(() => _bathrooms = v),
            1,
            10,
          ),
          const SizedBox(height: 16),
          _sectionHeader('Pricing'),
          const SizedBox(height: 10),
          Row(
            children: ['Daily', 'Weekly', 'Monthly'].map((t) {
              final sel = _pricingType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _pricingType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _villaColor : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? _villaColor : AppTheme.outlineVariant,
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
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _dailyRentController,
                  'Daily Rate (₹)',
                  Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _depositController,
                  'Deposit (₹)',
                  Icons.lock_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionHeader('Amenities'),
          const SizedBox(height: 12),
          _buildAmenitiesGrid(),
          const SizedBox(height: 16),
          _sectionHeader('Video / Virtual Tour'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _videoLinkController,
                  'YouTube / Virtual Tour URL',
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
                  backgroundColor: _villaColor,
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
                  color: _villaColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: _villaColor,
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Listing saved!',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: _villaColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _villaColor,
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
        'label': 'Swimming Pool',
        'icon': Icons.pool_rounded,
        'val': _hasPool,
        'set': (v) => setState(() => _hasPool = v),
      },
      {
        'label': 'Garden',
        'icon': Icons.grass_rounded,
        'val': _hasGarden,
        'set': (v) => setState(() => _hasGarden = v),
      },
      {
        'label': 'BBQ Area',
        'icon': Icons.outdoor_grill_rounded,
        'val': _hasBBQ,
        'set': (v) => setState(() => _hasBBQ = v),
      },
      {
        'label': 'Pet Friendly',
        'icon': Icons.pets_rounded,
        'val': _hasPetFriendly,
        'set': (v) => setState(() => _hasPetFriendly = v),
      },
      {
        'label': 'Parking',
        'icon': Icons.local_parking_rounded,
        'val': _hasParking,
        'set': (v) => setState(() => _hasParking = v),
      },
      {
        'label': 'AC',
        'icon': Icons.ac_unit_rounded,
        'val': _hasAC,
        'set': (v) => setState(() => _hasAC = v),
      },
      {
        'label': 'Kitchen',
        'icon': Icons.kitchen_rounded,
        'val': _hasKitchen,
        'set': (v) => setState(() => _hasKitchen = v),
      },
      {
        'label': 'Wi-Fi',
        'icon': Icons.wifi_rounded,
        'val': _hasWifi,
        'set': (v) => setState(() => _hasWifi = v),
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
                  ? _villaColor.withValues(alpha: 0.12)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? _villaColor : AppTheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  a['icon'] as IconData,
                  size: 14,
                  color: isOn ? _villaColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 5),
                Text(
                  a['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOn ? _villaColor : Colors.grey.shade700,
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
        Text(
          'Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
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
                      '${booking['guests']} guests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                '${booking['checkIn']} → ${booking['checkOut']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                '₹${booking['amount']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _villaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDay = DateTime(now.year, now.month, 1);
    final startWeekday = firstDay.weekday % 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability Calendar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap dates to mark as blocked/available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_monthName(now.month)} ${now.year}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map(
                        (d) => SizedBox(
                          width: 36,
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: startWeekday + daysInMonth,
                  itemBuilder: (_, i) {
                    if (i < startWeekday) return const SizedBox();
                    final day = i - startWeekday + 1;
                    final date = DateTime(now.year, now.month, day);
                    final isBlocked = _blockedDates.contains(date);
                    final isToday = day == now.day;
                    return GestureDetector(
                      onTap: () => setState(
                        () => isBlocked
                            ? _blockedDates.remove(date)
                            : _blockedDates.add(date),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? _villaColor
                              : isToday
                              ? _villaColor.withValues(alpha: 0.15)
                              : null,
                          shape: BoxShape.circle,
                          border: isToday && !isBlocked
                              ? Border.all(color: _villaColor)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isBlocked
                                  ? Colors.white
                                  : isToday
                                  ? _villaColor
                                  : const Color(0xFF1A1C1E),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendItem(_villaColor, 'Blocked'),
              const SizedBox(width: 16),
              _legendItem(Colors.white, 'Available', border: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }

  Widget _buildCounterRow(
    String label,
    int value,
    ValueChanged<int> onChanged,
    int min,
    int max,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
            color: value > min ? _villaColor : Colors.grey.shade400,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            color: value < max ? _villaColor : Colors.grey.shade400,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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
          color: _villaColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _villaColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _villaColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _villaColor,
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
            color: _villaColor,
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
        prefixIcon: Icon(icon, size: 18, color: _villaColor),
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
          borderSide: BorderSide(color: _villaColor, width: 2),
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
}
