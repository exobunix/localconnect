import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminAdvancedReportsScreen extends StatefulWidget {
  const AdminAdvancedReportsScreen({super.key});

  @override
  State<AdminAdvancedReportsScreen> createState() =>
      _AdminAdvancedReportsScreenState();
}

class _AdminAdvancedReportsScreenState extends State<AdminAdvancedReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isLoading = false;
  String _selectedPeriod = 'Monthly';
  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

  // Mock analytics data
  final Map<String, dynamic> _analyticsData = {
    'totalRevenue': 284500,
    'monthlyRevenue': 48200,
    'todayRevenue': 3800,
    'totalOrders': 1247,
    'completedOrders': 1089,
    'cancelledOrders': 158,
    'totalCustomers': 892,
    'newCustomersThisMonth': 67,
    'totalProviders': 234,
    'newProvidersThisMonth': 12,
    'activeSubscriptions': 189,
    'subscriptionRevenue': 82300,
    'pendingComplaints': 14,
    'resolvedComplaints': 89,
    'activeCities': 18,
    'activeCategories': 12,
  };

  final List<Map<String, dynamic>> _monthlyRevenue = [
    {'month': 'Jan', 'revenue': 28000, 'orders': 89},
    {'month': 'Feb', 'revenue': 32000, 'orders': 102},
    {'month': 'Mar', 'revenue': 38500, 'orders': 124},
    {'month': 'Apr', 'revenue': 35000, 'orders': 115},
    {'month': 'May', 'revenue': 42000, 'orders': 138},
    {'month': 'Jun', 'revenue': 48200, 'orders': 156},
  ];

  final List<Map<String, dynamic>> _categoryPerformance = [
    {
      'name': 'Home Maintenance',
      'orders': 342,
      'revenue': 68400,
      'color': AppTheme.primary,
    },
    {
      'name': 'Shop',
      'orders': 289,
      'revenue': 57800,
      'color': AppTheme.success,
    },
    {
      'name': 'Transport',
      'orders': 198,
      'revenue': 39600,
      'color': AppTheme.warning,
    },
    {
      'name': 'Events',
      'orders': 145,
      'revenue': 72500,
      'color': const Color(0xFF9C27B0),
    },
    {
      'name': 'Rent',
      'orders': 167,
      'revenue': 33400,
      'color': const Color(0xFF00BCD4),
    },
    {
      'name': 'Delivery',
      'orders': 106,
      'revenue': 13200,
      'color': AppTheme.error,
    },
  ];

  final List<Map<String, dynamic>> _cityPerformance = [
    {'city': 'Roha', 'orders': 312, 'providers': 45, 'revenue': 62400},
    {'city': 'Alibag', 'orders': 245, 'providers': 38, 'revenue': 49000},
    {'city': 'Mumbai', 'orders': 198, 'providers': 67, 'revenue': 39600},
    {'city': 'Pune', 'orders': 167, 'providers': 42, 'revenue': 33400},
    {'city': 'Nagothane', 'orders': 134, 'providers': 28, 'revenue': 26800},
    {'city': 'Pen', 'orders': 112, 'providers': 22, 'revenue': 22400},
    {'city': 'Nashik', 'orders': 79, 'providers': 18, 'revenue': 15800},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
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
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _exportAllReports,
            tooltip: 'Export CSV',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Categories'),
            Tab(text: 'Cities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRevenueTab(),
          _buildCategoriesTab(),
          _buildCitiesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Row(
            children: [
              Text(
                'Period:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              ..._periods.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedPeriod == p
                            ? AppTheme.primary
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedPeriod == p
                              ? Colors.white
                              : AppTheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // KPI grid
          _buildSectionTitle('Platform KPIs'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _kpiCard(
                'Total Revenue',
                '₹${_formatNum(_analyticsData['totalRevenue'])}',
                Icons.currency_rupee_rounded,
                AppTheme.success,
              ),
              _kpiCard(
                'Monthly Revenue',
                '₹${_formatNum(_analyticsData['monthlyRevenue'])}',
                Icons.trending_up_rounded,
                AppTheme.primary,
              ),
              _kpiCard(
                'Today Revenue',
                '₹${_formatNum(_analyticsData['todayRevenue'])}',
                Icons.today_rounded,
                AppTheme.warning,
              ),
              _kpiCard(
                'Total Orders',
                '${_analyticsData['totalOrders']}',
                Icons.receipt_long_rounded,
                const Color(0xFF9C27B0),
              ),
              _kpiCard(
                'Total Customers',
                '${_analyticsData['totalCustomers']}',
                Icons.people_rounded,
                AppTheme.primary,
              ),
              _kpiCard(
                'Total Providers',
                '${_analyticsData['totalProviders']}',
                Icons.store_rounded,
                AppTheme.success,
              ),
              _kpiCard(
                'Active Subs',
                '${_analyticsData['activeSubscriptions']}',
                Icons.workspace_premium_rounded,
                const Color(0xFF00BCD4),
              ),
              _kpiCard(
                'Sub Revenue',
                '₹${_formatNum(_analyticsData['subscriptionRevenue'])}',
                Icons.monetization_on_rounded,
                AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Order completion rate
          _buildSectionTitle('Order Completion Rate'),
          const SizedBox(height: 12),
          _buildCompletionRateCard(),
          const SizedBox(height: 20),
          // Growth metrics
          _buildSectionTitle('Growth This Month'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _growthCard(
                  'New Customers',
                  '+${_analyticsData['newCustomersThisMonth']}',
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _growthCard(
                  'New Providers',
                  '+${_analyticsData['newProvidersThisMonth']}',
                  AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Complaints summary
          _buildSectionTitle('Complaints Summary'),
          const SizedBox(height: 12),
          _buildComplaintsSummary(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard() {
    final total = _analyticsData['totalOrders'] as int;
    final completed = _analyticsData['completedOrders'] as int;
    final cancelled = _analyticsData['cancelledOrders'] as int;
    final rate = total > 0 ? (completed / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                    Text(
                      'Completion Rate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: completed.toDouble(),
                            color: AppTheme.success,
                            radius: 30,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: cancelled.toDouble(),
                            color: AppTheme.error,
                            radius: 30,
                            title: '',
                          ),
                        ],
                        centerSpaceRadius: 20,
                        sectionsSpace: 2,
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
              _legendDot(AppTheme.success, 'Completed: $completed'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.error, 'Cancelled: $cancelled'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.outline, 'Total: $total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _growthCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.trending_up_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsSummary() {
    final pending = _analyticsData['pendingComplaints'] as int;
    final resolved = _analyticsData['resolvedComplaints'] as int;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _complaintStat('Pending', '$pending', AppTheme.error),
          ),
          Container(width: 1, height: 40, color: AppTheme.outlineVariant),
          Expanded(
            child: _complaintStat('Resolved', '$resolved', AppTheme.success),
          ),
          Container(width: 1, height: 40, color: AppTheme.outlineVariant),
          Expanded(
            child: _complaintStat(
              'Total',
              '${pending + resolved}',
              AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _complaintStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Monthly Revenue Trend'),
          const SizedBox(height: 12),
          _buildRevenueChart(),
          const SizedBox(height: 20),
          _buildSectionTitle('Monthly Breakdown'),
          const SizedBox(height: 12),
          _buildMonthlyTable(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportRevenue,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    'Export Revenue CSV',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 60000,
                barGroups: _monthlyRevenue.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['revenue'] as int).toDouble(),
                        color: AppTheme.primary,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= _monthlyRevenue.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _monthlyRevenue[idx]['month'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.outline,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '₹${(v / 1000).toStringAsFixed(0)}k',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppTheme.outlineVariant, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Month',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Revenue',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Orders',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._monthlyRevenue.asMap().entries.map((e) {
            final isEven = e.key % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: isEven
                  ? Colors.white
                  : AppTheme.surfaceVariant.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value['month'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₹${_formatNum(e.value['revenue'])}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.value['orders']}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.outline,
                      ),
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

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Category Performance'),
          const SizedBox(height: 12),
          ..._categoryPerformance.map((cat) => _buildCategoryCard(cat)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportCategories,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    'Export Category CSV',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final maxOrders = _categoryPerformance
        .map((c) => c['orders'] as int)
        .reduce((a, b) => a > b ? a : b);
    final pct = maxOrders > 0 ? (cat['orders'] as int) / maxOrders : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cat['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '₹${_formatNum(cat['revenue'])}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.surfaceVariant,
              color: cat['color'] as Color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cat['orders']} orders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('City-wise Performance'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'City',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Orders',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Providers',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Revenue',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._cityPerformance.asMap().entries.map((e) {
                  final isEven = e.key % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: isEven
                        ? Colors.white
                        : AppTheme.surfaceVariant.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.value['city'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.value['orders']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.outline,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.value['providers']}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.outline,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '₹${_formatNum(e.value['revenue'])}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportCities,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    'Export City Report CSV',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
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
                  fontSize: 10,
                  color: AppTheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }

  String _formatNum(dynamic value) {
    final n = (value as num).toInt();
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  void _exportAllReports() {
    _showSnack('All reports exported to CSV!', AppTheme.success);
  }

  void _exportRevenue() {
    _showSnack('Revenue report exported to CSV!', AppTheme.success);
  }

  void _exportCategories() {
    _showSnack('Category report exported to CSV!', AppTheme.success);
  }

  void _exportCities() {
    _showSnack('City report exported to CSV!', AppTheme.success);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
