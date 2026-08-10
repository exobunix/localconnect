import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class PainterProviderDashboard extends StatefulWidget {
  const PainterProviderDashboard({super.key});

  @override
  State<PainterProviderDashboard> createState() =>
      _PainterProviderDashboardState();
}

class _PainterProviderDashboardState extends State<PainterProviderDashboard> {
  int _bottomNavIndex = 0;
  static const _primaryColor = Color(0xFF6A1B9A);

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Interior Painting',
      'price': 12,
      'unit': '/sq.ft',
      'enabled': true,
    },
    {
      'name': 'Exterior Painting',
      'price': 10,
      'unit': '/sq.ft',
      'enabled': true,
    },
    {
      'name': 'Texture Painting',
      'price': 18,
      'unit': '/sq.ft',
      'enabled': true,
    },
    {
      'name': 'Waterproof Coating',
      'price': 15,
      'unit': '/sq.ft',
      'enabled': true,
    },
    {'name': 'Wall Putty', 'price': 8, 'unit': '/sq.ft', 'enabled': false},
    {
      'name': 'Decorative Finishes',
      'price': 22,
      'unit': '/sq.ft',
      'enabled': true,
    },
  ];

  final List<Map<String, dynamic>> _quotations = [
    {
      'customer': 'Anita Mehta',
      'area': '800 sq.ft',
      'type': 'Interior',
      'status': 'Pending',
      'estimate': 9600,
      'date': 'Today',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 8)),
    },
    {
      'customer': 'Rohit Sharma',
      'area': '1200 sq.ft',
      'type': 'Exterior',
      'status': 'Accepted',
      'estimate': 12000,
      'date': 'Jun 30',
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'customer': 'Priya Singh',
      'area': '500 sq.ft',
      'type': 'Texture',
      'status': 'Completed',
      'estimate': 9000,
      'date': 'Jun 25',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'customer': 'Suresh Nair',
      'area': '600 sq.ft',
      'type': 'Interior',
      'status': 'Pending',
      'estimate': 7200,
      'date': 'Today',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 1)),
    },
  ];

  final List<String> _gallery = [
    'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=300',
    'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg?w=300',
    'https://images.unsplash.com/photo-1562259929-b4e1fd3aef09?w=300',
    'https://images.pexels.com/photos/2724749/pexels-photo-2724749.jpeg?w=300',
  ];

  bool _isAvailable = true;

  List<Map<String, dynamic>> get _sortedPendingQuotations {
    final pending = _quotations.where((q) => q['status'] == 'Pending').toList();
    pending.sort((a, b) {
      final aTime = a['createdAt'] as DateTime? ?? DateTime(2000);
      final bTime = b['createdAt'] as DateTime? ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return pending;
  }

  Future<void> _showRejectDialog(Map<String, dynamic> q) async {
    final reasons = [
      'Not available',
      'Outside service area',
      'Already booked',
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
            'Decline Request',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason for ${q['customer']}:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
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
                'Decline',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => q['status'] = 'Declined');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request declined.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _acceptQuotation(Map<String, dynamic> q) {
    setState(() => q['status'] = 'Accepted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Accepted! Opening chat...',
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

  void _signOut() => Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.loginScreen,
    (_) => false,
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':
        return Colors.orange[700]!;
      case 'Accepted':
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
          _buildQuotations(),
          _buildServices(),
          _buildGallery(),
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
              Icons.request_quote_rounded,
              color: _bottomNavIndex == 1 ? _primaryColor : Colors.grey,
            ),
            label: 'Quotations',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.format_paint_rounded,
              color: _bottomNavIndex == 2 ? _primaryColor : Colors.grey,
            ),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.photo_library_rounded,
              color: _bottomNavIndex == 3 ? _primaryColor : Colors.grey,
            ),
            label: 'Gallery',
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
                              Icons.format_paint_rounded,
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
                                  'Painter Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'ColorCraft Painters',
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
                      'Active Projects',
                      '2',
                      Icons.work_rounded,
                      Colors.blue[700]!,
                    ),
                    _kpiCard(
                      'Pending Quotes',
                      '1',
                      Icons.request_quote_rounded,
                      Colors.orange[700]!,
                    ),
                    _kpiCard(
                      'This Month',
                      '₹21,000',
                      Icons.currency_rupee_rounded,
                      Colors.green[700]!,
                    ),
                    _kpiCard(
                      'Rating',
                      '4.7 ★',
                      Icons.star_rounded,
                      Colors.amber[700]!,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Brands used
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        color: _primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brands Used',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              'Asian Paints · Berger · Nerolac · Dulux',
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
                    if (_sortedPendingQuotations.isNotEmpty)
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
                          '${_sortedPendingQuotations.length} new',
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
                ..._sortedPendingQuotations.asMap().entries.map(
                  (e) => _quotationCard(
                    e.value,
                    showActions: true,
                    isNewest: e.key == 0,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _quickAction(
                      Icons.add_photo_alternate_rounded,
                      'Add to\nGallery',
                      () => setState(() => _bottomNavIndex = 3),
                    ),
                    const SizedBox(width: 10),
                    _quickAction(
                      Icons.request_quote_rounded,
                      'New\nQuote',
                      () => setState(() => _bottomNavIndex = 1),
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

  Widget _buildQuotations() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Quotations',
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quotations.length,
        itemBuilder: (_, i) => _quotationCard(
          _quotations[i],
          showActions: _quotations[i]['status'] == 'Pending',
        ),
      ),
    );
  }

  Widget _quotationCard(
    Map<String, dynamic> q, {
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
                    Row(
                      children: [
                        Text(
                          q['customer'] as String,
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
                      '${q['type']} · ${q['area']}',
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
                    q['status'] as String,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  q['status'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _statusColor(q['status'] as String),
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
                q['date'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                'Est: ₹${q['estimate']}',
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
                    onPressed: () => _showRejectDialog(q),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[200]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Decline',
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
                    onPressed: () => _acceptQuotation(q),
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

  Widget _buildServices() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Services & Pricing',
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
                    Icons.format_paint_rounded,
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
                        s['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${s['price']}${s['unit']}',
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

  Widget _buildGallery() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Work Gallery',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate_rounded,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _gallery.length,
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(
            _gallery[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_rounded, color: Colors.grey),
            ),
          ),
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
                      Icons.format_paint_rounded,
                      size: 36,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ColorCraft Painters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Painter · 10 years experience',
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
                        ' 4.7 · 98 reviews',
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
              Icons.palette_rounded,
              'Brands Used',
              'Asian Paints, Berger, Nerolac',
              () {},
            ),
            _profileTile(
              Icons.access_time_rounded,
              'Working Hours',
              '9:00 AM – 7:00 PM',
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
              '4.7 ★ (98 reviews)',
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
