import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// Platform commission rate (10%)
const double _kCommissionRate = 0.10;

class ProviderEarningsDashboardScreen extends StatefulWidget {
  const ProviderEarningsDashboardScreen({super.key});

  @override
  State<ProviderEarningsDashboardScreen> createState() =>
      _ProviderEarningsDashboardScreenState();
}

class _ProviderEarningsDashboardScreenState
    extends State<ProviderEarningsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _providerProfile;

  // All completed orders (regular + quotation)
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _quotationOrders = [];

  // Gross earnings
  double _totalGross = 0;
  double _todayGross = 0;
  double _weekGross = 0;
  double _monthGross = 0;

  // Net earnings (after commission)
  double _totalNet = 0;
  double _todayNet = 0;
  double _weekNet = 0;
  double _monthNet = 0;

  // Commission totals
  double _totalCommission = 0;
  double _monthCommission = 0;

  int _completedCount = 0;
  double _avgOrderValue = 0;

  // Weekly chart data (last 7 days) — net earnings
  List<double> _weeklyData = List.filled(7, 0);
  List<String> _weeklyLabels = [];

  // Monthly chart data (last 6 months) — net earnings
  List<double> _monthlyData = List.filled(6, 0);
  List<String> _monthlyLabels = [];

  // Location demand data
  List<Map<String, dynamic>> _locationDemand = [];
  bool _locationDemandLoading = false;
  String _locationDemandFilter = 'all'; // all, village, taluka

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadEarnings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = await SupabaseService.instance.getMyProviderProfile();
      if (provider == null) {
        setState(() {
          _error = 'Provider profile not found.';
          _isLoading = false;
        });
        return;
      }
      _providerProfile = provider;

      final orders = await SupabaseService.instance.getProviderOrders(
        provider['id'] as String,
      );

      final completed = orders
          .where((o) => (o['status'] as String?) == 'completed')
          .toList();

      // Separate quotation orders (ORD-Q- prefix)
      final quotationCompleted = completed
          .where(
            (o) => ((o['order_number'] as String?) ?? '').startsWith('ORD-Q-'),
          )
          .toList();

      double totalGross = 0, todayGross = 0, weekGross = 0, monthGross = 0;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Weekly chart buckets (net)
      final Map<int, double> dayNet = {};
      for (int i = 0; i < 7; i++) {
        dayNet[i] = 0;
      }

      // Monthly chart buckets (net) — last 6 months
      final Map<int, double> monthNet = {};
      for (int i = 0; i < 6; i++) {
        monthNet[i] = 0;
      }

      for (final order in completed) {
        final amountStr = order['amount'] as String? ?? '0';
        final gross =
            double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        final net = gross * (1 - _kCommissionRate);
        final createdAt = order['created_at'] != null
            ? DateTime.tryParse(order['created_at'] as String)
            : null;

        totalGross += gross;

        if (createdAt != null) {
          if (createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day) {
            todayGross += gross;
          }
          if (createdAt.isAfter(weekAgo)) {
            weekGross += gross;
            final daysAgo = now.difference(createdAt).inDays;
            if (daysAgo < 7) {
              dayNet[6 - daysAgo] = (dayNet[6 - daysAgo] ?? 0) + net;
            }
          }
          if (createdAt.isAfter(monthAgo)) {
            monthGross += gross;
          }
          // Monthly chart: last 6 months
          final monthsAgo =
              (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
          if (monthsAgo >= 0 && monthsAgo < 6) {
            monthNet[5 - monthsAgo] = (monthNet[5 - monthsAgo] ?? 0) + net;
          }
        }
      }

      // Build weekly labels
      final wLabels = <String>[];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        wLabels.add(days[day.weekday - 1]);
      }

      // Build monthly labels (last 6 months)
      const monthNames = [
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
      final mLabels = <String>[];
      for (int i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        mLabels.add(monthNames[m.month - 1]);
      }

      final totalCommission = totalGross * _kCommissionRate;
      final monthCommission = monthGross * _kCommissionRate;

      if (mounted) {
        setState(() {
          _completedOrders = completed;
          _quotationOrders = quotationCompleted;
          _totalGross = totalGross;
          _todayGross = todayGross;
          _weekGross = weekGross;
          _monthGross = monthGross;
          _totalNet = totalGross * (1 - _kCommissionRate);
          _todayNet = todayGross * (1 - _kCommissionRate);
          _weekNet = weekGross * (1 - _kCommissionRate);
          _monthNet = monthGross * (1 - _kCommissionRate);
          _totalCommission = totalCommission;
          _monthCommission = monthCommission;
          _completedCount = completed.length;
          _avgOrderValue = completed.isNotEmpty
              ? _totalNet / completed.length
              : 0;
          _weeklyData = List.generate(7, (i) => dayNet[i] ?? 0);
          _weeklyLabels = wLabels;
          _monthlyData = List.generate(6, (i) => monthNet[i] ?? 0);
          _monthlyLabels = mLabels;
          _isLoading = false;
        });
      }

      // Load location demand after main data
      _loadLocationDemand(provider['id'] as String);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load earnings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocationDemand(String providerId) async {
    if (!mounted) return;
    setState(() => _locationDemandLoading = true);
    try {
      final result = await SupabaseService.instance.client.rpc(
        'get_provider_location_demand',
        params: {'p_provider_id': providerId},
      );
      if (mounted) {
        setState(() {
          _locationDemand = List<Map<String, dynamic>>.from(result as List);
          _locationDemandLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationDemandLoading = false);
    }
  }

  String _fmt(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF44474E),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadEarnings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
          title: Text(
            'Earnings Dashboard',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
              Tab(text: 'Quotations'),
              Tab(text: 'Analytics'),
              Tab(text: 'Location Demand'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHistoryTab(allOrders: true),
          _buildHistoryTab(allOrders: false),
          _buildAnalyticsTab(),
          _buildLocationDemandTab(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(_totalNet),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'of ${_fmt(_totalGross)} gross',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeaderBadge(
                label: '$_completedCount orders',
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _HeaderBadge(
                label:
                    '${(_kCommissionRate * 100).toStringAsFixed(0)}% platform fee',
                icon: Icons.percent_rounded,
                color: Colors.orange.shade200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Net earnings stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              label: 'Today (Net)',
              value: _fmt(_todayNet),
              icon: Icons.today_rounded,
              color: AppTheme.success,
            ),
            _StatCard(
              label: 'This Week (Net)',
              value: _fmt(_weekNet),
              icon: Icons.date_range_rounded,
              color: AppTheme.primary,
            ),
            _StatCard(
              label: 'This Month (Net)',
              value: _fmt(_monthNet),
              icon: Icons.calendar_month_rounded,
              color: AppTheme.secondary,
            ),
            _StatCard(
              label: 'Avg. Order (Net)',
              value: _fmt(_avgOrderValue),
              icon: Icons.trending_up_rounded,
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Commission summary card
        _buildCommissionCard(),
        const SizedBox(height: 16),
        // Weekly chart
        _buildBarChart(
          title: 'Weekly Net Earnings',
          subtitle: 'Last 7 days',
          data: _weeklyData,
          labels: _weeklyLabels,
        ),
        const SizedBox(height: 16),
        // Monthly chart
        _buildBarChart(
          title: 'Monthly Net Earnings',
          subtitle: 'Last 6 months',
          data: _monthlyData,
          labels: _monthlyLabels,
          barColor: AppTheme.secondary,
        ),
        const SizedBox(height: 16),
        // Recent orders
        _buildRecentOrders(),
      ],
    );
  }

  Widget _buildCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF3E0), const Color(0xFFFFF8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFFE65100),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Commission & Deductions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CommissionRow(
            label: 'Gross Earnings (All Time)',
            value: _fmt(_totalGross),
            valueColor: const Color(0xFF1A1C1E),
          ),
          const Divider(height: 16, color: Color(0xFFFFCC80)),
          _CommissionRow(
            label:
                'Platform Fee (${(_kCommissionRate * 100).toStringAsFixed(0)}%) — All Time',
            value: '- ${_fmt(_totalCommission)}',
            valueColor: const Color(0xFFE65100),
          ),
          _CommissionRow(
            label: 'Platform Fee — This Month',
            value: '- ${_fmt(_monthCommission)}',
            valueColor: const Color(0xFFE65100),
          ),
          const Divider(height: 16, color: Color(0xFFFFCC80)),
          _CommissionRow(
            label: 'Net Earnings (All Time)',
            value: _fmt(_totalNet),
            valueColor: AppTheme.success,
            bold: true,
          ),
          _CommissionRow(
            label: 'Net Earnings — This Month',
            value: _fmt(_monthNet),
            valueColor: AppTheme.success,
            bold: true,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Platform fee of ${(_kCommissionRate * 100).toStringAsFixed(0)}% is deducted from each completed booking.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required String subtitle,
    required List<double> data,
    required List<String> labels,
    Color? barColor,
  }) {
    final color = barColor ?? AppTheme.primary;
    final maxY = data.isEmpty
        ? 1000.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.3).clamp(
            100.0,
            double.infinity,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF90A4AE),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppTheme.outlineVariant, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  data.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        color: data[i] > 0 ? color : AppTheme.outlineVariant,
                        width: data.length <= 7 ? 22 : 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recent = _completedOrders.take(5).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            'No completed orders yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Earnings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 12),
        ...recent.map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EarningsListItem(order: order),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab({required bool allOrders}) {
    final orders = allOrders ? _completedOrders : _quotationOrders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allOrders
                  ? Icons.receipt_long_rounded
                  : Icons.request_quote_rounded,
              color: AppTheme.outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              allOrders
                  ? 'No earnings history yet'
                  : 'No quotation bookings completed yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF44474E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allOrders
                  ? 'Complete orders to see your earnings here'
                  : 'Accepted quotations that are completed will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF90A4AE),
              ),
            ),
          ],
        ),
      );
    }

    // Summary row for the tab
    double tabGross = 0;
    for (final o in orders) {
      final amountStr = o['amount'] as String? ?? '0';
      tabGross +=
          double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    final tabNet = tabGross * (1 - _kCommissionRate);
    final tabCommission = tabGross * _kCommissionRate;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length + 1,
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox(height: 16) : const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Summary header
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  AppTheme.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Gross',
                    value: _fmt(tabGross),
                    color: const Color(0xFF44474E),
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.outlineVariant),
                Expanded(
                  child: _MiniStat(
                    label: 'Commission',
                    value: '- ${_fmt(tabCommission)}',
                    color: const Color(0xFFE65100),
                  ),
                ),
                Container(width: 1, height: 36, color: AppTheme.outlineVariant),
                Expanded(
                  child: _MiniStat(
                    label: 'Net',
                    value: _fmt(tabNet),
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          );
        }
        return _EarningsListItem(
          order: orders[index - 1],
          showFull: true,
          showCommission: true,
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final totalHandled =
        _completedCount + (_providerProfile?['rejected_orders'] as int? ?? 0);
    final completionRate = totalHandled > 0
        ? (_completedCount / totalHandled) * 100
        : 0.0;
    final quotationCount = _quotationOrders.length;
    final regularCount = _completedCount - quotationCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AnalyticsCard(
          title: 'Performance Summary',
          children: [
            _AnalyticsRow(
              label: 'Completion Rate',
              value: '${completionRate.toStringAsFixed(1)}%',
              color: AppTheme.success,
            ),
            _AnalyticsRow(
              label: 'Total Completed',
              value: '$_completedCount',
              color: AppTheme.primary,
            ),
            _AnalyticsRow(
              label: 'Regular Bookings',
              value: '$regularCount',
              color: AppTheme.secondary,
            ),
            _AnalyticsRow(
              label: 'Quotation Bookings',
              value: '$quotationCount',
              color: const Color(0xFF7C3AED),
            ),
            _AnalyticsRow(
              label: 'Avg. Net Order Value',
              value: _fmt(_avgOrderValue),
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AnalyticsCard(
          title: 'Earnings Breakdown',
          children: [
            _AnalyticsRow(
              label: 'Today (Net)',
              value: _fmt(_todayNet),
              color: AppTheme.success,
            ),
            _AnalyticsRow(
              label: 'This Week (Net)',
              value: _fmt(_weekNet),
              color: AppTheme.primary,
            ),
            _AnalyticsRow(
              label: 'This Month (Net)',
              value: _fmt(_monthNet),
              color: AppTheme.secondary,
            ),
            _AnalyticsRow(
              label: 'All Time (Net)',
              value: _fmt(_totalNet),
              color: AppTheme.primaryDark,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AnalyticsCard(
          title: 'Commission Summary',
          children: [
            _AnalyticsRow(
              label: 'Platform Rate',
              value: '${(_kCommissionRate * 100).toStringAsFixed(0)}%',
              color: const Color(0xFFE65100),
            ),
            _AnalyticsRow(
              label: 'Total Gross Earned',
              value: _fmt(_totalGross),
              color: const Color(0xFF44474E),
            ),
            _AnalyticsRow(
              label: 'Total Commission Paid',
              value: _fmt(_totalCommission),
              color: const Color(0xFFE65100),
            ),
            _AnalyticsRow(
              label: 'This Month Commission',
              value: _fmt(_monthCommission),
              color: const Color(0xFFE65100),
            ),
            _AnalyticsRow(
              label: 'Total Net Received',
              value: _fmt(_totalNet),
              color: AppTheme.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCompletionDonut(completionRate),
      ],
    );
  }

  Widget _buildLocationDemandTab() {
    final filtered = _locationDemandFilter == 'all'
        ? _locationDemand
        : _locationDemand
              .where((r) => r['area_type'] == _locationDemandFilter)
              .toList();

    // Sort by requests desc
    final sorted = List<Map<String, dynamic>>.from(filtered)
      ..sort(
        (a, b) => ((b['total_requests'] as int?) ?? 0).compareTo(
          (a['total_requests'] as int?) ?? 0,
        ),
      );

    return _locationDemandLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location Demand Analysis',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'See which villages & talukas generate the most requests, bookings, and revenue to optimise your service coverage.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _DemandSummaryBadge(
                          label: 'Areas',
                          value: '${_locationDemand.length}',
                          icon: Icons.map_rounded,
                        ),
                        const SizedBox(width: 8),
                        _DemandSummaryBadge(
                          label: 'Villages',
                          value:
                              '${_locationDemand.where((r) => r['area_type'] == 'village').length}',
                          icon: Icons.home_rounded,
                        ),
                        const SizedBox(width: 8),
                        _DemandSummaryBadge(
                          label: 'Talukas',
                          value:
                              '${_locationDemand.where((r) => r['area_type'] == 'taluka').length}',
                          icon: Icons.account_balance_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Areas',
                      selected: _locationDemandFilter == 'all',
                      onTap: () =>
                          setState(() => _locationDemandFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Villages',
                      selected: _locationDemandFilter == 'village',
                      onTap: () =>
                          setState(() => _locationDemandFilter = 'village'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Talukas',
                      selected: _locationDemandFilter == 'taluka',
                      onTap: () =>
                          setState(() => _locationDemandFilter = 'taluka'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (sorted.isEmpty)
                _buildEmptyDemand()
              else ...[
                // Top 3 highlight cards
                if (sorted.isNotEmpty) ...[
                  Text(
                    'Top Demand Areas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sorted.take(3).toList().asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TopDemandCard(
                        rank: rank,
                        item: item,
                        fmtRevenue: _fmt,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Full list
                if (sorted.length > 3) ...[
                  Text(
                    'All Areas (${sorted.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: sorted.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isLast = idx == sorted.length - 1;
                        return _DemandListRow(
                          rank: idx + 1,
                          item: item,
                          fmtRevenue: _fmt,
                          showDivider: !isLast,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ],
          );
  }

  Widget _buildEmptyDemand() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching_rounded,
            size: 52,
            color: AppTheme.outline,
          ),
          const SizedBox(height: 14),
          Text(
            'No location data yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Once customers with saved locations place requests, you\'ll see demand by village and taluka here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionDonut(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Rate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: [
                  PieChartSectionData(
                    value: rate.clamp(0, 100),
                    color: AppTheme.success,
                    title: '${rate.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    radius: 40,
                  ),
                  PieChartSectionData(
                    value: (100 - rate).clamp(0, 100),
                    color: AppTheme.outlineVariant,
                    title: '',
                    radius: 36,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.success, label: 'Completed'),
              const SizedBox(width: 20),
              _LegendDot(color: AppTheme.outlineVariant, label: 'Remaining'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Location Demand Sub-widgets ────────────────────────────────────────────

class _DemandSummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DemandSummaryBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF44474E),
          ),
        ),
      ),
    );
  }
}

class _TopDemandCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> item;
  final String Function(double) fmtRevenue;

  const _TopDemandCard({
    required this.rank,
    required this.item,
    required this.fmtRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final areaType = item['area_type'] as String? ?? 'area';
    final areaName = item['area_name'] as String? ?? 'Unknown';
    final requests = (item['total_requests'] as int?) ?? 0;
    final bookings = (item['total_bookings'] as int?) ?? 0;
    final revenue =
        double.tryParse((item['total_revenue'] ?? '0').toString()) ?? 0;
    final conversionRate = requests > 0
        ? (bookings / requests * 100).toStringAsFixed(0)
        : '0';

    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppTheme.outline;

    final isVillage = areaType == 'village';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: rankColor,
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
                        areaName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVillage
                            ? AppTheme.successContainer
                            : const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVillage ? 'Village' : 'Taluka',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isVillage
                              ? AppTheme.success
                              : const Color(0xFF3949AB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DemandMetric(
                      icon: Icons.send_rounded,
                      label: 'Requests',
                      value: '$requests',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _DemandMetric(
                      icon: Icons.check_circle_rounded,
                      label: 'Bookings',
                      value: '$bookings',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    _DemandMetric(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Revenue',
                      value: fmtRevenue(revenue),
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Conversion bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conversion Rate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF90A4AE),
                          ),
                        ),
                        Text(
                          '$conversionRate%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: requests > 0 ? bookings / requests : 0,
                        backgroundColor: AppTheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.success,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DemandMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFF90A4AE),
          ),
        ),
      ],
    );
  }
}

class _DemandListRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> item;
  final String Function(double) fmtRevenue;
  final bool showDivider;

  const _DemandListRow({
    required this.rank,
    required this.item,
    required this.fmtRevenue,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final areaType = item['area_type'] as String? ?? 'area';
    final areaName = item['area_name'] as String? ?? 'Unknown';
    final requests = (item['total_requests'] as int?) ?? 0;
    final bookings = (item['total_bookings'] as int?) ?? 0;
    final revenue =
        double.tryParse((item['total_revenue'] ?? '0').toString()) ?? 0;
    final isVillage = areaType == 'village';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text(
                  '$rank',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF90A4AE),
                  ),
                ),
              ),
              // Area icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isVillage
                      ? AppTheme.successContainer
                      : const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVillage
                      ? Icons.home_rounded
                      : Icons.account_balance_rounded,
                  size: 14,
                  color: isVillage ? AppTheme.success : const Color(0xFF3949AB),
                ),
              ),
              const SizedBox(width: 10),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      areaName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isVillage ? 'Village' : 'Taluka',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$requests req',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '$bookings booked · ${fmtRevenue(revenue)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF44474E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Existing Sub-widgets ────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _HeaderBadge({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _CommissionRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF44474E),
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF90A4AE),
          ),
        ),
      ],
    );
  }
}

class _EarningsListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool showFull;
  final bool showCommission;

  const _EarningsListItem({
    required this.order,
    this.showFull = false,
    this.showCommission = false,
  });

  @override
  Widget build(BuildContext context) {
    final amountStr = order['amount'] as String? ?? '₹0';
    final gross =
        double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final net = gross * (1 - _kCommissionRate);
    final commission = gross * _kCommissionRate;
    final service = order['service'] as String? ?? 'Service';
    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'] as String)
        : null;
    final dateStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : '';
    final orderNum = order['order_number'] as String? ?? '';
    final isQuotation = orderNum.startsWith('ORD-Q-');

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isQuotation
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : AppTheme.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isQuotation
                  ? Icons.request_quote_rounded
                  : Icons.check_circle_rounded,
              color: isQuotation ? const Color(0xFF7C3AED) : AppTheme.success,
              size: 20,
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
                        service,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isQuotation)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Quotation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showFull && orderNum.isNotEmpty)
                  Text(
                    orderNum,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF90A4AE),
                    ),
                  ),
                Text(
                  dateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF90A4AE),
                  ),
                ),
                if (showCommission && gross > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _AmountChip(
                        label: 'Gross',
                        value: '₹${gross.toStringAsFixed(0)}',
                        color: const Color(0xFF44474E),
                      ),
                      const SizedBox(width: 6),
                      _AmountChip(
                        label: 'Fee',
                        value: '-₹${commission.toStringAsFixed(0)}',
                        color: const Color(0xFFE65100),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${net.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
              Text(
                'net',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFF90A4AE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AnalyticsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalyticsRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF44474E),
          ),
        ),
      ],
    );
  }
}
