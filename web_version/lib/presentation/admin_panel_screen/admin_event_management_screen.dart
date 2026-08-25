import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() =>
      _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState extends State<AdminEventManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  static const _subcategories = [
    {'id': 'photography', 'label': 'Photography', 'color': Color(0xFFAD1457)},
    {'id': 'videography', 'label': 'Videography', 'color': Color(0xFF6A1B9A)},
    {'id': 'sound', 'label': 'Sound & DJ', 'color': Color(0xFF0277BD)},
    {'id': 'mandap', 'label': 'Mandap Decor', 'color': Color(0xFFE65100)},
    {'id': 'birthday', 'label': 'Birthday Decor', 'color': Color(0xFFC62828)},
    {'id': 'catering', 'label': 'Catering', 'color': Color(0xFF00695C)},
    {'id': 'makeup', 'label': 'Makeup Artist', 'color': Color(0xFF880E4F)},
    {'id': 'mehendi', 'label': 'Mehendi Artist', 'color': Color(0xFF4E342E)},
    {'id': 'lighting', 'label': 'Lighting Decor', 'color': Color(0xFFF9A825)},
    {'id': 'planner', 'label': 'Event Planner', 'color': Color(0xFF1A237E)},
    {'id': 'anchor', 'label': 'Anchor / Host', 'color': Color(0xFF37474F)},
    {'id': 'band', 'label': 'Live Band', 'color': Color(0xFF4A148C)},
    {'id': 'orchestra', 'label': 'Orchestra', 'color': Color(0xFF1B5E20)},
    {'id': 'dance', 'label': 'Dance Group', 'color': Color(0xFFBF360C)},
    {
      'id': 'generator',
      'label': 'Generator Rental',
      'color': Color(0xFF263238),
    },
    {'id': 'chair_table', 'label': 'Chair & Table', 'color': Color(0xFF4E342E)},
    {'id': 'tent', 'label': 'Tent House', 'color': Color(0xFF37474F)},
  ];

  final List<Map<String, dynamic>> _kpis = [
    {
      'label': 'Total Providers',
      'value': '2,847',
      'change': '+15%',
      'positive': true,
      'icon': Icons.people_rounded,
      'color': Color(0xFFAD1457),
    },
    {
      'label': 'Active Bookings',
      'value': '634',
      'change': '+22%',
      'positive': true,
      'icon': Icons.event_available_rounded,
      'color': Color(0xFF6A1B9A),
    },
    {
      'label': 'Total Revenue',
      'value': '₹8.6L',
      'change': '+31%',
      'positive': true,
      'icon': Icons.currency_rupee_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'label': 'Pending Approvals',
      'value': '89',
      'change': '-12%',
      'positive': false,
      'icon': Icons.pending_actions_rounded,
      'color': Color(0xFFE65100),
    },
    {
      'label': 'Avg. Rating',
      'value': '4.7',
      'change': '+0.3',
      'positive': true,
      'icon': Icons.star_rounded,
      'color': Color(0xFFF9A825),
    },
    {
      'label': 'New Providers',
      'value': '143',
      'change': '+28%',
      'positive': true,
      'icon': Icons.person_add_rounded,
      'color': Color(0xFF1565C0),
    },
  ];

  final List<Map<String, dynamic>> _subcategoryStats = [
    {
      'name': 'Photography',
      'color': Color(0xFFAD1457),
      'providers': 312,
      'bookings': 89,
      'revenue': '₹1.2L',
      'rating': 4.8,
      'activeSubscriptions': 198,
    },
    {
      'name': 'Videography',
      'color': Color(0xFF6A1B9A),
      'providers': 198,
      'bookings': 67,
      'revenue': '₹0.9L',
      'rating': 4.7,
      'activeSubscriptions': 134,
    },
    {
      'name': 'Catering',
      'color': Color(0xFF00695C),
      'providers': 421,
      'bookings': 134,
      'revenue': '₹1.8L',
      'rating': 4.8,
      'activeSubscriptions': 287,
    },
    {
      'name': 'Mandap Decor',
      'color': Color(0xFFE65100),
      'providers': 156,
      'bookings': 45,
      'revenue': '₹0.7L',
      'rating': 4.9,
      'activeSubscriptions': 98,
    },
    {
      'name': 'Event Planner',
      'color': Color(0xFF1A237E),
      'providers': 98,
      'bookings': 28,
      'revenue': '₹0.6L',
      'rating': 4.9,
      'activeSubscriptions': 67,
    },
    {
      'name': 'Makeup Artist',
      'color': Color(0xFF880E4F),
      'providers': 287,
      'bookings': 98,
      'revenue': '₹0.5L',
      'rating': 4.9,
      'activeSubscriptions': 201,
    },
    {
      'name': 'Sound & DJ',
      'color': Color(0xFF0277BD),
      'providers': 189,
      'bookings': 56,
      'revenue': '₹0.4L',
      'rating': 4.6,
      'activeSubscriptions': 134,
    },
    {
      'name': 'Mehendi Artist',
      'color': Color(0xFF4E342E),
      'providers': 234,
      'bookings': 78,
      'revenue': '₹0.3L',
      'rating': 4.7,
      'activeSubscriptions': 167,
    },
    {
      'name': 'Lighting Decor',
      'color': Color(0xFFF9A825),
      'providers': 145,
      'bookings': 42,
      'revenue': '₹0.4L',
      'rating': 4.6,
      'activeSubscriptions': 89,
    },
    {
      'name': 'Birthday Decor',
      'color': Color(0xFFC62828),
      'providers': 178,
      'bookings': 67,
      'revenue': '₹0.3L',
      'rating': 4.7,
      'activeSubscriptions': 112,
    },
    {
      'name': 'Anchor / Host',
      'color': Color(0xFF37474F),
      'providers': 89,
      'bookings': 34,
      'revenue': '₹0.2L',
      'rating': 4.8,
      'activeSubscriptions': 56,
    },
    {
      'name': 'Live Band',
      'color': Color(0xFF4A148C),
      'providers': 67,
      'bookings': 23,
      'revenue': '₹0.2L',
      'rating': 4.7,
      'activeSubscriptions': 45,
    },
    {
      'name': 'Orchestra',
      'color': Color(0xFF1B5E20),
      'providers': 34,
      'bookings': 12,
      'revenue': '₹0.2L',
      'rating': 4.9,
      'activeSubscriptions': 23,
    },
    {
      'name': 'Dance Group',
      'color': Color(0xFFBF360C),
      'providers': 56,
      'bookings': 19,
      'revenue': '₹0.2L',
      'rating': 4.8,
      'activeSubscriptions': 34,
    },
    {
      'name': 'Generator Rental',
      'color': Color(0xFF263238),
      'providers': 78,
      'bookings': 28,
      'revenue': '₹0.2L',
      'rating': 4.5,
      'activeSubscriptions': 45,
    },
    {
      'name': 'Chair & Table',
      'color': Color(0xFF4E342E),
      'providers': 123,
      'bookings': 45,
      'revenue': '₹0.2L',
      'rating': 4.5,
      'activeSubscriptions': 78,
    },
    {
      'name': 'Tent House',
      'color': Color(0xFF37474F),
      'providers': 89,
      'bookings': 34,
      'revenue': '₹0.3L',
      'rating': 4.6,
      'activeSubscriptions': 56,
    },
  ];

  // Monetization config (admin editable)
  final Map<String, Map<String, dynamic>> _monetizationConfig = {
    'photography': {
      'freeListings': true,
      'freeCount': 1,
      'model': 'subscription',
      'basicPrice': 299,
      'standardPrice': 599,
      'premiumPrice': 999,
      'featured7': 199,
      'featured15': 349,
      'featured30': 599,
      'sponsoredPrice': 499,
      'badgePrice': 999,
      'payPerLead': false,
      'payPerLeadPrice': 49,
      'badgeEnabled': true,
    },
    'videography': {
      'freeListings': true,
      'freeCount': 1,
      'model': 'subscription',
      'basicPrice': 299,
      'standardPrice': 599,
      'premiumPrice': 999,
      'featured7': 199,
      'featured15': 349,
      'featured30': 599,
      'sponsoredPrice': 499,
      'badgePrice': 999,
      'payPerLead': false,
      'payPerLeadPrice': 49,
      'badgeEnabled': true,
    },
    'catering': {
      'freeListings': false,
      'freeCount': 0,
      'model': 'subscription',
      'basicPrice': 499,
      'standardPrice': 899,
      'premiumPrice': 1499,
      'featured7': 299,
      'featured15': 499,
      'featured30': 799,
      'sponsoredPrice': 699,
      'badgePrice': 1499,
      'payPerLead': false,
      'payPerLeadPrice': 99,
      'badgeEnabled': true,
    },
    'makeup': {
      'freeListings': true,
      'freeCount': 2,
      'model': 'hybrid',
      'basicPrice': 199,
      'standardPrice': 399,
      'premiumPrice': 699,
      'featured7': 149,
      'featured15': 249,
      'featured30': 399,
      'sponsoredPrice': 299,
      'badgePrice': 699,
      'payPerLead': true,
      'payPerLeadPrice': 49,
      'badgeEnabled': false,
    },
    'planner': {
      'freeListings': false,
      'freeCount': 0,
      'model': 'subscription',
      'basicPrice': 499,
      'standardPrice': 999,
      'premiumPrice': 1999,
      'featured7': 399,
      'featured15': 699,
      'featured30': 999,
      'sponsoredPrice': 799,
      'badgePrice': 1999,
      'payPerLead': false,
      'payPerLeadPrice': 149,
      'badgeEnabled': true,
    },
    'mandap': {
      'freeListings': false,
      'freeCount': 0,
      'model': 'subscription',
      'basicPrice': 499,
      'standardPrice': 899,
      'premiumPrice': 1499,
      'featured7': 299,
      'featured15': 499,
      'featured30': 799,
      'sponsoredPrice': 599,
      'badgePrice': 1299,
      'payPerLead': false,
      'payPerLeadPrice': 99,
      'badgeEnabled': true,
    },
    'mehendi': {
      'freeListings': true,
      'freeCount': 2,
      'model': 'hybrid',
      'basicPrice': 149,
      'standardPrice': 299,
      'premiumPrice': 499,
      'featured7': 99,
      'featured15': 179,
      'featured30': 299,
      'sponsoredPrice': 249,
      'badgePrice': 499,
      'payPerLead': true,
      'payPerLeadPrice': 29,
      'badgeEnabled': false,
    },
    'tent': {
      'freeListings': false,
      'freeCount': 0,
      'model': 'subscription',
      'basicPrice': 399,
      'standardPrice': 799,
      'premiumPrice': 1299,
      'featured7': 249,
      'featured15': 449,
      'featured30': 699,
      'sponsoredPrice': 549,
      'badgePrice': 1199,
      'payPerLead': false,
      'payPerLeadPrice': 79,
      'badgeEnabled': true,
    },
  };

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Event Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: const Color(0xFFAD1457),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onSelected: (v) => setState(() => _selectedPeriod = v),
            itemBuilder: (_) => _periods
                .map((p) => PopupMenuItem(value: p, child: Text(p)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subcategories'),
            Tab(text: 'Monetization'),
            Tab(text: 'Inquiries'),
            Tab(text: 'Revenue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            kpis: _kpis,
            subcategoryStats: _subcategoryStats,
            isDark: isDark,
          ),
          _SubcategoriesTab(
            subcategoryStats: _subcategoryStats,
            isDark: isDark,
          ),
          _MonetizationTab(
            subcategories: _subcategories,
            config: _monetizationConfig,
            isDark: isDark,
            onConfigUpdate: (sub, key, val) =>
                setState(() => _monetizationConfig[sub]?[key] = val),
          ),
          _InquiriesTab(isDark: isDark),
          _RevenueTab(isDark: isDark, subcategoryStats: _subcategoryStats),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> kpis;
  final List<Map<String, dynamic>> subcategoryStats;
  final bool isDark;

  const _OverviewTab({
    required this.kpis,
    required this.subcategoryStats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) {
            final kpi = kpis[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252729) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (kpi['color'] as Color).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          kpi['icon'] as IconData,
                          color: kpi['color'] as Color,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (kpi['positive'] as bool)
                              ? AppTheme.success.withAlpha(30)
                              : AppTheme.error.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kpi['change'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: (kpi['positive'] as bool)
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    kpi['value'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    kpi['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Top Performing Subcategories',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...subcategoryStats
            .take(6)
            .map(
              (sub) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252729) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (sub['color'] as Color).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          sub['name'].toString().substring(0, 1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sub['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${sub['providers']} providers • ${sub['bookings']} bookings',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          sub['revenue'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sub['color'] as Color,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Color(0xFFFFB300),
                            ),
                            Text(
                              ' ${sub['rating']}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11),
                            ),
                          ],
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
}

// ── Subcategories Tab ─────────────────────────────────────────────────────────
class _SubcategoriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> subcategoryStats;
  final bool isDark;

  const _SubcategoriesTab({
    required this.subcategoryStats,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: subcategoryStats
          .map(
            (sub) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252729) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
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
                          color: (sub['color'] as Color).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sub['name'].toString().substring(0, 1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: sub['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sub['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SubStat(
                        label: 'Providers',
                        value: '${sub['providers']}',
                        color: sub['color'] as Color,
                      ),
                      _SubStat(
                        label: 'Bookings',
                        value: '${sub['bookings']}',
                        color: sub['color'] as Color,
                      ),
                      _SubStat(
                        label: 'Revenue',
                        value: sub['revenue'] as String,
                        color: sub['color'] as Color,
                      ),
                      _SubStat(
                        label: 'Subscriptions',
                        value: '${sub['activeSubscriptions']}',
                        color: sub['color'] as Color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFFFB300),
                          ),
                          Text(
                            ' ${sub['rating']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'Manage',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: sub['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
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
}

class _SubStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SubStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Monetization Tab ──────────────────────────────────────────────────────────
class _MonetizationTab extends StatefulWidget {
  final List<Map<String, dynamic>> subcategories;
  final Map<String, Map<String, dynamic>> config;
  final bool isDark;
  final Function(String, String, dynamic) onConfigUpdate;

  const _MonetizationTab({
    required this.subcategories,
    required this.config,
    required this.isDark,
    required this.onConfigUpdate,
  });

  @override
  State<_MonetizationTab> createState() => _MonetizationTabState();
}

class _MonetizationTabState extends State<_MonetizationTab> {
  String _selectedSub = 'photography';

  Map<String, dynamic> get _currentConfig {
    return widget.config[_selectedSub] ??
        {
          'freeListings': true,
          'freeCount': 1,
          'model': 'subscription',
          'basicPrice': 299,
          'standardPrice': 599,
          'premiumPrice': 999,
          'featured7': 199,
          'featured15': 349,
          'featured30': 599,
          'sponsoredPrice': 499,
          'badgePrice': 999,
          'payPerLead': false,
          'payPerLeadPrice': 49,
          'badgeEnabled': true,
        };
  }

  Color get _activeColor {
    final sub = widget.subcategories.firstWhere(
      (s) => s['id'] == _selectedSub,
      orElse: () => widget.subcategories.first,
    );
    return sub['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _currentConfig;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Subcategory Selector
        Text(
          'Select Subcategory',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.subcategories.length,
            itemBuilder: (_, i) {
              final sub = widget.subcategories[i];
              final isSelected = sub['id'] == _selectedSub;
              return GestureDetector(
                onTap: () => setState(() => _selectedSub = sub['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (sub['color'] as Color)
                        : (sub['color'] as Color).withAlpha(15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    sub['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : sub['color'] as Color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Monetization Model
        _ConfigSection(
          title: 'Monetization Model',
          isDark: widget.isDark,
          child: Column(
            children: [
              ...[
                'subscription',
                'pay_per_listing',
                'pay_per_lead',
                'hybrid',
              ].map(
                (model) => RadioListTile<String>(
                  value: model,
                  groupValue: cfg['model'] as String,
                  onChanged: (v) {
                    widget.onConfigUpdate(_selectedSub, 'model', v);
                    setState(() {});
                  },
                  title: Text(
                    _modelLabel(model),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  activeColor: _activeColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Free Listings
        _ConfigSection(
          title: 'Free Listings',
          isDark: widget.isDark,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enable Free Listings',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ),
                  Switch(
                    value: cfg['freeListings'] as bool,
                    onChanged: (v) {
                      widget.onConfigUpdate(_selectedSub, 'freeListings', v);
                      setState(() {});
                    },
                    activeColor: _activeColor,
                  ),
                ],
              ),
              if (cfg['freeListings'] == true) ...[
                const SizedBox(height: 8),
                _PriceField(
                  label: 'Free Listing Count',
                  value: cfg['freeCount'] as int,
                  color: _activeColor,
                  isDark: widget.isDark,
                  onChanged: (v) {
                    widget.onConfigUpdate(_selectedSub, 'freeCount', v);
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Subscription Prices
        _ConfigSection(
          title: 'Subscription Prices (₹/month)',
          isDark: widget.isDark,
          child: Column(
            children: [
              _PriceField(
                label: 'Basic Plan',
                value: cfg['basicPrice'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'basicPrice', v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _PriceField(
                label: 'Standard Plan',
                value: cfg['standardPrice'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'standardPrice', v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _PriceField(
                label: 'Premium Plan',
                value: cfg['premiumPrice'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'premiumPrice', v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Featured Listing Prices
        _ConfigSection(
          title: 'Featured Listing Prices (₹)',
          isDark: widget.isDark,
          child: Column(
            children: [
              _PriceField(
                label: '7 Days',
                value: cfg['featured7'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'featured7', v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _PriceField(
                label: '15 Days',
                value: cfg['featured15'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'featured15', v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _PriceField(
                label: '30 Days',
                value: cfg['featured30'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'featured30', v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Other Pricing
        _ConfigSection(
          title: 'Other Pricing (₹)',
          isDark: widget.isDark,
          child: Column(
            children: [
              _PriceField(
                label: 'Sponsored Listing',
                value: cfg['sponsoredPrice'] as int,
                color: _activeColor,
                isDark: widget.isDark,
                onChanged: (v) {
                  widget.onConfigUpdate(_selectedSub, 'sponsoredPrice', v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PriceField(
                      label: 'Verified Badge',
                      value: cfg['badgePrice'] as int,
                      color: _activeColor,
                      isDark: widget.isDark,
                      onChanged: (v) {
                        widget.onConfigUpdate(_selectedSub, 'badgePrice', v);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        'Enable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Switch(
                        value: cfg['badgeEnabled'] as bool,
                        onChanged: (v) {
                          widget.onConfigUpdate(
                            _selectedSub,
                            'badgeEnabled',
                            v,
                          );
                          setState(() {});
                        },
                        activeColor: _activeColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pay Per Lead
        _ConfigSection(
          title: 'Pay Per Lead',
          isDark: widget.isDark,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enable Pay Per Lead',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ),
                  Switch(
                    value: cfg['payPerLead'] as bool,
                    onChanged: (v) {
                      widget.onConfigUpdate(_selectedSub, 'payPerLead', v);
                      setState(() {});
                    },
                    activeColor: _activeColor,
                  ),
                ],
              ),
              if (cfg['payPerLead'] == true) ...[
                const SizedBox(height: 8),
                _PriceField(
                  label: 'Price Per Lead (₹)',
                  value: cfg['payPerLeadPrice'] as int,
                  color: _activeColor,
                  isDark: widget.isDark,
                  onChanged: (v) {
                    widget.onConfigUpdate(_selectedSub, 'payPerLeadPrice', v);
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Configuration saved successfully',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 24),
      ],
    );
  }

  String _modelLabel(String model) {
    switch (model) {
      case 'subscription':
        return 'Subscription';
      case 'pay_per_listing':
        return 'Pay Per Listing';
      case 'pay_per_lead':
        return 'Pay Per Lead';
      case 'hybrid':
        return 'Hybrid (Subscription + Pay Per Lead)';
      default:
        return model;
    }
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _ConfigSection({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252729) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PriceField extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _PriceField({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_PriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.color,
            ),
            decoration: InputDecoration(
              prefixText: '₹',
              prefixStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: widget.color,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.color.withAlpha(60)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.color.withAlpha(40)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.color, width: 1.5),
              ),
              filled: true,
              fillColor: widget.color.withAlpha(10),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) widget.onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }
}

// ── Inquiries Tab ─────────────────────────────────────────────────────────────
class _InquiriesTab extends StatelessWidget {
  final bool isDark;

  const _InquiriesTab({required this.isDark});

  static final _mockInquiries = [
    {
      'customer': 'Priya Sharma',
      'provider': 'Kapil Photography',
      'subcategory': 'Photography',
      'date': '2 Jul 2026',
      'status': 'pending',
      'color': Color(0xFFAD1457),
    },
    {
      'customer': 'Rahul Mehta',
      'provider': 'Shree Caterers',
      'subcategory': 'Catering',
      'date': '1 Jul 2026',
      'status': 'accepted',
      'color': Color(0xFF00695C),
    },
    {
      'customer': 'Anita Patel',
      'provider': 'Glamour by Sneha',
      'subcategory': 'Makeup Artist',
      'date': '30 Jun 2026',
      'status': 'completed',
      'color': Color(0xFF880E4F),
    },
    {
      'customer': 'Vikram Singh',
      'provider': 'Dream Events Co.',
      'subcategory': 'Event Planner',
      'date': '29 Jun 2026',
      'status': 'rejected',
      'color': Color(0xFF1A237E),
    },
    {
      'customer': 'Meera Joshi',
      'provider': 'Royal Mandap Decorators',
      'subcategory': 'Mandap Decor',
      'date': '28 Jun 2026',
      'status': 'negotiating',
      'color': Color(0xFFE65100),
    },
    {
      'customer': 'Suresh Kumar',
      'provider': 'Raj Sound Systems',
      'subcategory': 'Sound & DJ',
      'date': '27 Jun 2026',
      'status': 'accepted',
      'color': Color(0xFF0277BD),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Row
        Row(
          children: [
            _InquiryStat(label: 'Total', value: '634', color: AppTheme.primary),
            _InquiryStat(
              label: 'Pending',
              value: '89',
              color: AppTheme.warning,
            ),
            _InquiryStat(
              label: 'Accepted',
              value: '312',
              color: AppTheme.success,
            ),
            _InquiryStat(
              label: 'Completed',
              value: '198',
              color: const Color(0xFF6A1B9A),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Recent Inquiries',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ..._mockInquiries.map((inq) {
          final status = inq['status'] as String;
          final statusColor = status == 'pending'
              ? AppTheme.warning
              : status == 'accepted'
              ? AppTheme.success
              : status == 'completed'
              ? const Color(0xFF6A1B9A)
              : status == 'negotiating'
              ? AppTheme.info
              : AppTheme.error;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252729) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (inq['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      (inq['customer'] as String).substring(0, 1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: inq['color'] as Color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inq['customer'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${inq['provider']} • ${inq['subcategory']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        inq['date'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _InquiryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InquiryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
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
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Revenue Tab ───────────────────────────────────────────────────────────────
class _RevenueTab extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> subcategoryStats;

  const _RevenueTab({required this.isDark, required this.subcategoryStats});

  @override
  Widget build(BuildContext context) {
    final revenueBreakdown = [
      {
        'label': 'Subscriptions',
        'value': '₹5.2L',
        'pct': 0.60,
        'color': const Color(0xFFAD1457),
      },
      {
        'label': 'Featured Listings',
        'value': '₹1.8L',
        'pct': 0.21,
        'color': const Color(0xFFFFB300),
      },
      {
        'label': 'Sponsored Listings',
        'value': '₹0.9L',
        'pct': 0.10,
        'color': const Color(0xFF6A1B9A),
      },
      {
        'label': 'Verified Badges',
        'value': '₹0.4L',
        'pct': 0.05,
        'color': AppTheme.success,
      },
      {
        'label': 'Pay Per Lead',
        'value': '₹0.3L',
        'pct': 0.04,
        'color': AppTheme.info,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Revenue Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFAD1457), Color(0xFF880E4F)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Revenue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹8.6L',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+31% vs last month',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Revenue Breakdown',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252729) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6),
            ],
          ),
          child: Column(
            children: revenueBreakdown
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: item['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              item['value'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: item['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item['pct'] as double,
                            backgroundColor: Colors.grey.withAlpha(20),
                            valueColor: AlwaysStoppedAnimation(
                              item['color'] as Color,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Revenue by Subcategory',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...subcategoryStats.map(
          (sub) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252729) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sub['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sub['name'] as String,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ),
                Text(
                  sub['revenue'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sub['color'] as Color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${sub['activeSubscriptions']} subs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
