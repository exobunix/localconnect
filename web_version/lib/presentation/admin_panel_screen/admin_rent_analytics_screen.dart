import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_export.dart';

class AdminRentAnalyticsScreen extends StatefulWidget {
  const AdminRentAnalyticsScreen({super.key});

  @override
  State<AdminRentAnalyticsScreen> createState() =>
      _AdminRentAnalyticsScreenState();
}

class _AdminRentAnalyticsScreenState extends State<AdminRentAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  int _selectedSubcategoryFilter = 0;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  final List<String> _subcategoryFilters = [
    'All',
    'Room',
    'PG',
    'Hostel',
    'Villa',
    'Tools',
  ];

  // ── KPI Data ──────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _kpis = [
    {
      'label': 'Total Listings',
      'value': '1,248',
      'change': '+12%',
      'positive': true,
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF26A69A),
    },
    {
      'label': 'Active Bookings',
      'value': '342',
      'change': '+8%',
      'positive': true,
      'icon': Icons.event_available_rounded,
      'color': Color(0xFF7B1FA2),
    },
    {
      'label': 'Total Revenue',
      'value': '₹4.2L',
      'change': '+18%',
      'positive': true,
      'icon': Icons.currency_rupee_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'label': 'Pending Approvals',
      'value': '47',
      'change': '-5%',
      'positive': false,
      'icon': Icons.pending_actions_rounded,
      'color': Color(0xFFE65100),
    },
    {
      'label': 'Avg. Rating',
      'value': '4.6',
      'change': '+0.2',
      'positive': true,
      'icon': Icons.star_rounded,
      'color': Color(0xFFF9A825),
    },
    {
      'label': 'New Providers',
      'value': '86',
      'change': '+23%',
      'positive': true,
      'icon': Icons.person_add_rounded,
      'color': Color(0xFF1565C0),
    },
  ];

  // ── Subcategory Breakdown ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _subcategoryStats = [
    {
      'name': 'Room',
      'icon': Icons.bedroom_parent_rounded,
      'color': Color(0xFF26A69A),
      'listings': 412,
      'bookings': 128,
      'revenue': '₹1.4L',
      'rating': 4.7,
      'pending': 14,
    },
    {
      'name': 'PG',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF7B1FA2),
      'listings': 287,
      'bookings': 94,
      'revenue': '₹98K',
      'rating': 4.5,
      'pending': 11,
    },
    {
      'name': 'Hostel',
      'icon': Icons.hotel_rounded,
      'color': Color(0xFF1565C0),
      'listings': 156,
      'bookings': 62,
      'revenue': '₹72K',
      'rating': 4.4,
      'pending': 8,
    },
    {
      'name': 'Villa',
      'icon': Icons.villa_rounded,
      'color': Color(0xFFE65100),
      'listings': 98,
      'bookings': 34,
      'revenue': '₹1.1L',
      'rating': 4.8,
      'pending': 7,
    },
    {
      'name': 'Tools',
      'icon': Icons.build_rounded,
      'color': Color(0xFF2E7D32),
      'listings': 295,
      'bookings': 24,
      'revenue': '₹56K',
      'rating': 4.6,
      'pending': 7,
    },
  ];

  // ── Pending Listings ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _pendingListings = [
    {
      'title': '2BHK Furnished Room – Andheri West',
      'provider': 'Ramesh Gupta',
      'subcategory': 'Room',
      'subcategoryColor': Color(0xFF26A69A),
      'price': '₹18,000/mo',
      'submitted': '2 hours ago',
      'status': 'pending',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f7f8b52f-1773147663130.png',
    },
    {
      'title': 'Girls PG – Koramangala, Bangalore',
      'provider': 'Sunita Sharma',
      'subcategory': 'PG',
      'subcategoryColor': Color(0xFF7B1FA2),
      'price': '₹8,500/mo',
      'submitted': '5 hours ago',
      'status': 'pending',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17b1802a5-1772164143831.png',
    },
    {
      'title': 'Premium Villa – Lonavala',
      'provider': 'Vikram Mehta',
      'subcategory': 'Villa',
      'subcategoryColor': Color(0xFFE65100),
      'price': '₹12,000/day',
      'submitted': '1 day ago',
      'status': 'pending',
      'avatar':
          'https://images.pixabay.com/photo/2016/11/18/17/20/living-room-1835923_1280.jpg?w=100',
    },
    {
      'title': 'JCB Excavator – Daily Rental',
      'provider': 'Mohan Tools Co.',
      'subcategory': 'Tools',
      'subcategoryColor': Color(0xFF2E7D32),
      'price': '₹4,500/day',
      'submitted': '3 hours ago',
      'status': 'pending',
      'avatar': 'https://images.unsplash.com/photo-1676287241277-c14188fde5c8',
    },
    {
      'title': 'Boys Hostel – 4-Bed Dorm, Pune',
      'provider': 'Priya Hostel Mgmt',
      'subcategory': 'Hostel',
      'subcategoryColor': Color(0xFF1565C0),
      'price': '₹5,200/mo',
      'submitted': '6 hours ago',
      'status': 'pending',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_119e1051b-1782697644172.png',
    },
  ];

  // ── Top Providers ─────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _topProviders = [
    {
      'name': 'Ramesh Properties',
      'subcategory': 'Room',
      'listings': 12,
      'bookings': 48,
      'revenue': '₹86,400',
      'rating': 4.9,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80',
      'badge': 'Top Earner',
      'badgeColor': Color(0xFFF9A825),
    },
    {
      'name': 'Sunita PG Services',
      'subcategory': 'PG',
      'listings': 8,
      'bookings': 36,
      'revenue': '₹72,000',
      'rating': 4.8,
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80',
      'badge': 'Most Booked',
      'badgeColor': Color(0xFF7B1FA2),
    },
    {
      'name': 'Vikram Villa Rentals',
      'subcategory': 'Villa',
      'listings': 5,
      'bookings': 22,
      'revenue': '₹2,64,000',
      'rating': 4.9,
      'avatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80',
      'badge': 'Premium',
      'badgeColor': Color(0xFFE65100),
    },
    {
      'name': 'Mohan Equipment Hub',
      'subcategory': 'Tools',
      'listings': 24,
      'bookings': 18,
      'revenue': '₹54,000',
      'rating': 4.7,
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80',
      'badge': 'Most Listings',
      'badgeColor': Color(0xFF2E7D32),
    },
  ];

  // ── Recent Bookings ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _recentBookings = [
    {
      'customer': 'Anita Mehta',
      'listing': '2BHK Room – Andheri',
      'subcategory': 'Room',
      'amount': '₹18,000',
      'status': 'confirmed',
      'date': 'Today, 10:30 AM',
    },
    {
      'customer': 'Ravi Joshi',
      'listing': 'Boys PG – Koramangala',
      'subcategory': 'PG',
      'amount': '₹8,500',
      'status': 'pending',
      'date': 'Today, 9:15 AM',
    },
    {
      'customer': 'Deepak Nair',
      'listing': 'Lonavala Villa – 3 nights',
      'subcategory': 'Villa',
      'amount': '₹36,000',
      'status': 'confirmed',
      'date': 'Yesterday, 6:45 PM',
    },
    {
      'customer': 'Kavita Patel',
      'listing': 'Drill Machine – 2 days',
      'subcategory': 'Tools',
      'amount': '₹600',
      'status': 'completed',
      'date': 'Yesterday, 3:20 PM',
    },
    {
      'customer': 'Suresh Rao',
      'listing': 'Hostel Bed – Pune',
      'subcategory': 'Hostel',
      'amount': '₹5,200',
      'status': 'cancelled',
      'date': '2 days ago',
    },
  ];

  // ── Monetization Config ───────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _monetizationConfig = {
    'room': {
      'freeListings': 2,
      'payPerListing': 99,
      'featured7': 299,
      'featured15': 499,
      'featured30': 799,
      'verifiedBadge': 199,
      'freeEnabled': true,
    },
    'pg': {
      'freeListings': 0,
      'payPerListing': 99,
      'featured7': 299,
      'featured15': 499,
      'featured30': 799,
      'verifiedBadge': 199,
      'freeEnabled': false,
    },
    'hostel': {
      'freeListings': 0,
      'payPerListing': 149,
      'featured7': 349,
      'featured15': 599,
      'featured30': 899,
      'verifiedBadge': 249,
      'freeEnabled': false,
    },
    'hotel': {
      'freeListings': 0,
      'payPerListing': 199,
      'featured7': 499,
      'featured15': 799,
      'featured30': 1299,
      'verifiedBadge': 299,
      'freeEnabled': false,
    },
    'villa': {
      'freeListings': 1,
      'payPerListing': 149,
      'featured7': 399,
      'featured15': 699,
      'featured30': 999,
      'verifiedBadge': 299,
      'freeEnabled': true,
    },
    'tools': {
      'freeListings': 2,
      'payPerListing': 99,
      'featured7': 299,
      'featured15': 499,
      'featured30': 799,
      'verifiedBadge': 199,
      'freeEnabled': true,
    },
  };

  String _selectedMonetizationSub = 'room';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Rent Admin Dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage listings, bookings, revenue & monetization',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Listings'),
                Tab(text: 'Bookings'),
                Tab(text: 'Providers'),
                Tab(text: 'Monetization'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildListingsTab(),
            _buildBookingsTab(),
            _buildProvidersTab(),
            _buildMonetizationTab(),
          ],
        ),
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          // KPI Grid
          _buildSectionTitle('Key Metrics', Icons.insights_rounded),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _kpis.length,
            itemBuilder: (context, i) => _buildKpiCard(_kpis[i]),
          ),
          const SizedBox(height: 24),
          // Subcategory breakdown
          _buildSectionTitle('Subcategory Breakdown', Icons.pie_chart_rounded),
          const SizedBox(height: 12),
          ..._subcategoryStats.map((s) => _buildSubcategoryRow(s)),
          const SizedBox(height: 24),
          // Revenue bar chart
          _buildSectionTitle('Monthly Revenue', Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          _buildRevenueChart(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Listings Tab ──────────────────────────────────────────────────────────
  Widget _buildListingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subcategoryFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = _selectedSubcategoryFilter == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubcategoryFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A237E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1A237E)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      _subcategoryFilters[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF44474E),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(
            'Pending Approvals (${_pendingListings.length})',
            Icons.pending_actions_rounded,
          ),
          const SizedBox(height: 12),
          ..._pendingListings.map((l) => _buildListingApprovalCard(l)),
          const SizedBox(height: 24),
          // Stats summary
          _buildListingStatsSummary(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Bookings Tab ──────────────────────────────────────────────────────────
  Widget _buildBookingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking status summary
          Row(
            children: [
              _buildStatusSummaryCard(
                'Confirmed',
                '128',
                const Color(0xFF2E7D32),
                Icons.check_circle_rounded,
              ),
              const SizedBox(width: 12),
              _buildStatusSummaryCard(
                'Pending',
                '47',
                const Color(0xFFF9A825),
                Icons.schedule_rounded,
              ),
              const SizedBox(width: 12),
              _buildStatusSummaryCard(
                'Cancelled',
                '23',
                const Color(0xFFD32F2F),
                Icons.cancel_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Recent Bookings', Icons.receipt_long_rounded),
          const SizedBox(height: 12),
          ..._recentBookings.map((b) => _buildBookingRow(b)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Providers Tab ─────────────────────────────────────────────────────────
  Widget _buildProvidersTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Top Performers', Icons.emoji_events_rounded),
          const SizedBox(height: 12),
          ..._topProviders.map((p) => _buildTopProviderCard(p)),
          const SizedBox(height: 24),
          _buildSectionTitle('Provider Actions', Icons.manage_accounts_rounded),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.verified_user_rounded,
            title: 'Verify Providers',
            subtitle: '12 providers awaiting verification',
            color: const Color(0xFF1565C0),
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.block_rounded,
            title: 'Suspended Listings',
            subtitle: '3 listings currently suspended',
            color: const Color(0xFFD32F2F),
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.star_rounded,
            title: 'Featured Listings',
            subtitle: 'Manage 8 featured rent listings',
            color: const Color(0xFFF9A825),
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.workspace_premium_rounded,
            title: 'Subscription Overview',
            subtitle: '64 active rent provider subscriptions',
            color: const Color(0xFF7B1FA2),
            onTap: () {},
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _periods.map((p) {
          final selected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1A237E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF78909C),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi) {
    final color = kpi['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi['icon'] as IconData, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (kpi['positive'] as bool)
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kpi['change'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: (kpi['positive'] as bool)
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kpi['value'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                kpi['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF78909C),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryRow(Map<String, dynamic> s) {
    final color = s['color'] as Color;
    final total = _subcategoryStats.fold<int>(
      0,
      (sum, item) => sum + (item['listings'] as int),
    );
    final pct = ((s['listings'] as int) / total * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      '${s['listings']} listings · ${s['bookings']} bookings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    s['revenue'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFF9A825),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${s['rating']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final values = [1.8, 2.1, 2.6, 3.0, 3.7, 4.2];
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue (₹ Lakhs)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF78909C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+18% vs last period',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (i) {
                final barHeight = (values[i] / maxVal) * 100;
                final isLast = i == months.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isLast)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₹${values[i]}L',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 80),
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLast
                                  ? [
                                      const Color(0xFF1A237E),
                                      const Color(0xFF3949AB),
                                    ]
                                  : [
                                      const Color(0xFF90CAF9),
                                      const Color(0xFF42A5F5),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          months[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF78909C),
                            fontWeight: FontWeight.w500,
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

  Widget _buildListingApprovalCard(Map<String, dynamic> l) {
    final color = l['subcategoryColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  l['avatar'] as String,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: color.withValues(alpha: 0.15),
                    child: Icon(Icons.home_rounded, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l['subcategory'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l['price'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By ${l['provider']} · ${l['submitted']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showActionSnackbar('Listing rejected'),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: Text(
                    'Reject',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFD32F2F)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showActionSnackbar('Listing approved ✓'),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: Text(
                    'Approve',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildListingStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem('Total', '1,248', Colors.white),
              _buildSummaryItem('Active', '1,156', const Color(0xFF81C784)),
              _buildSummaryItem('Pending', '47', const Color(0xFFFFD54F)),
              _buildSummaryItem('Suspended', '45', const Color(0xFFEF9A9A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
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
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF78909C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingRow(Map<String, dynamic> b) {
    final statusColors = {
      'confirmed': const Color(0xFF2E7D32),
      'pending': const Color(0xFFF9A825),
      'completed': const Color(0xFF1565C0),
      'cancelled': const Color(0xFFD32F2F),
    };
    final statusBg = {
      'confirmed': const Color(0xFFE8F5E9),
      'pending': const Color(0xFFFFF8E1),
      'completed': const Color(0xFFE3F2FD),
      'cancelled': const Color(0xFFFFEBEE),
    };
    final status = b['status'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b['listing'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${b['customer']} · ${b['date']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                b['amount'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg[status],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColors[status],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProviderCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p['avatar'] as String,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: const Color(0xFFE3F2FD),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (p['badgeColor'] as Color).withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p['badge'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: p['badgeColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${p['subcategory']} · ${p['listings']} listings · ${p['bookings']} bookings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p['revenue'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: Color(0xFFF9A825),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${p['rating']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF44474E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF78909C),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF78909C),
        ),
      ),
    );
  }

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A237E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Monetization Tab ──────────────────────────────────────────────────────
  Widget _buildMonetizationTab() {
    final subcategories = [
      {'id': 'room', 'label': 'Room', 'color': const Color(0xFF26A69A)},
      {'id': 'pg', 'label': 'PG', 'color': const Color(0xFF7B1FA2)},
      {'id': 'hostel', 'label': 'Hostel', 'color': const Color(0xFF1565C0)},
      {'id': 'hotel', 'label': 'Hotel', 'color': const Color(0xFFD84315)},
      {'id': 'villa', 'label': 'Villa', 'color': const Color(0xFFE65100)},
      {'id': 'tools', 'label': 'Tools', 'color': const Color(0xFF2E7D32)},
    ];

    final config = _monetizationConfig[_selectedMonetizationSub]!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monetization Revenue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRevenueStat(
                      'Subscriptions',
                      '₹2.8L',
                      const Color(0xFF81C784),
                    ),
                    _buildRevenueStat(
                      'Featured',
                      '₹64K',
                      const Color(0xFFFFD54F),
                    ),
                    _buildRevenueStat(
                      'Pay/Listing',
                      '₹18K',
                      const Color(0xFF80DEEA),
                    ),
                    _buildRevenueStat(
                      'Badges',
                      '₹12K',
                      const Color(0xFFCE93D8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subcategory selector
          _buildSectionTitle(
            'Configure by Subcategory',
            Icons.settings_rounded,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subcategories.map((s) {
                final sel = _selectedMonetizationSub == s['id'];
                final color = s['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedMonetizationSub = s['id'] as String,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? color : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      s['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF44474E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Config card
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_selectedMonetizationSub[0].toUpperCase()}${_selectedMonetizationSub.substring(1)} Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: config['freeEnabled'] as bool,
                      onChanged: (v) => setState(
                        () =>
                            _monetizationConfig[_selectedMonetizationSub]!['freeEnabled'] =
                                v,
                      ),
                      activeThumbColor: const Color(0xFF26A69A),
                    ),
                    Text(
                      'Free Listings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildConfigRow(
                  'Free Listings Allowed',
                  '${config['freeListings']}',
                  Icons.card_giftcard_rounded,
                  const Color(0xFF26A69A),
                ),
                _buildConfigRow(
                  'Pay Per Listing',
                  '₹${config['payPerListing']}',
                  Icons.receipt_rounded,
                  const Color(0xFF1565C0),
                ),
                _buildConfigRow(
                  'Featured – 7 Days',
                  '₹${config['featured7']}',
                  Icons.star_rounded,
                  const Color(0xFFF9A825),
                ),
                _buildConfigRow(
                  'Featured – 15 Days',
                  '₹${config['featured15']}',
                  Icons.star_rounded,
                  const Color(0xFFF9A825),
                ),
                _buildConfigRow(
                  'Featured – 30 Days',
                  '₹${config['featured30']}',
                  Icons.star_rounded,
                  const Color(0xFFF9A825),
                ),
                _buildConfigRow(
                  'Verified Badge',
                  '₹${config['verifiedBadge']}',
                  Icons.verified_rounded,
                  Colors.blue.shade600,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showActionSnackbar(
                      'Settings saved for ${_selectedMonetizationSub[0].toUpperCase()}${_selectedMonetizationSub.substring(1)} ✓',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Configuration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subscription plans overview
          _buildSectionTitle(
            'Active Subscriptions',
            Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: 12),
          _buildSubscriptionOverview(),
          const SizedBox(height: 20),

          // Featured listings management
          _buildSectionTitle('Featured Listings', Icons.star_rounded),
          const SizedBox(height: 12),
          _buildFeaturedListingsManagement(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRevenueStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF44474E),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showActionSnackbar('Edit $label'),
            child: const Icon(
              Icons.edit_rounded,
              size: 16,
              color: Color(0xFF78909C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOverview() {
    final plans = [
      {
        'plan': 'Free',
        'count': 312,
        'revenue': '₹0',
        'color': Colors.grey.shade600,
      },
      {
        'plan': 'Basic',
        'count': 186,
        'revenue': '₹74K',
        'color': const Color(0xFF26A69A),
      },
      {
        'plan': 'Standard',
        'count': 94,
        'revenue': '₹56K',
        'color': const Color(0xFF1565C0),
      },
      {
        'plan': 'Premium',
        'count': 42,
        'revenue': '₹42K',
        'color': const Color(0xFFF9A825),
      },
    ];
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: plans.map((p) {
          final color = p['color'] as Color;
          final count = p['count'] as int;
          final total = plans.fold<int>(0, (s, x) => s + (x['count'] as int));
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: Text(
                    p['plan'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 40,
                  child: Text(
                    p['revenue'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedListingsManagement() {
    final featured = [
      {
        'title': 'Luxury Villa – Lonavala',
        'sub': 'Villa',
        'expires': '5 days left',
        'color': const Color(0xFFE65100),
      },
      {
        'title': 'Girls PG – Koramangala',
        'sub': 'PG',
        'expires': '12 days left',
        'color': const Color(0xFF7B1FA2),
      },
      {
        'title': 'JCB Excavator – Pune',
        'sub': 'Tools',
        'expires': '3 days left',
        'color': const Color(0xFF2E7D32),
      },
      {
        'title': 'Hotel Sunrise Premium',
        'sub': 'Hotel',
        'expires': '22 days left',
        'color': const Color(0xFFD84315),
      },
    ];
    return Column(
      children: featured.map((f) {
        final color = f['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f['sub'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f['expires'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF78909C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        _showActionSnackbar('Extended featured listing'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Extend',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        _showActionSnackbar('Featured listing removed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
