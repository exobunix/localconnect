import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAdminReportData();
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Reports',
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    _buildSectionTitle('Platform Summary'),
                    const SizedBox(height: 12),
                    _buildSummaryGrid(),
                    const SizedBox(height: 20),
                    // Order status breakdown
                    _buildSectionTitle('Order Status Breakdown'),
                    const SizedBox(height: 12),
                    _buildOrderStatusChart(),
                    const SizedBox(height: 20),
                    // Top categories
                    _buildSectionTitle('Top Categories by Orders'),
                    const SizedBox(height: 12),
                    _buildTopCategories(),
                    const SizedBox(height: 20),
                    // Recent activity
                    _buildSectionTitle('Recent Activity'),
                    const SizedBox(height: 12),
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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

  Widget _buildSummaryGrid() {
    final stats = _reportData['stats'] as Map<String, dynamic>? ?? {};
    final items = [
      (
        'Total Revenue',
        '₹${_formatNum(stats['totalRevenue'] ?? 0)}',
        AppTheme.success,
        Icons.currency_rupee_rounded,
      ),
      (
        'Total Orders',
        '${stats['totalOrders'] ?? 0}',
        AppTheme.primary,
        Icons.receipt_long_rounded,
      ),
      (
        'Active Providers',
        '${stats['totalProviders'] ?? 0}',
        AppTheme.warning,
        Icons.store_rounded,
      ),
      (
        'Open Complaints',
        '${stats['openComplaints'] ?? 0}',
        AppTheme.error,
        Icons.report_problem_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
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
              Icon(item.$4, color: item.$3, size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: item.$3,
                    ),
                  ),
                  Text(
                    item.$1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusChart() {
    final statusData =
        _reportData['ordersByStatus'] as Map<String, dynamic>? ?? {};
    if (statusData.isEmpty) {
      return _buildEmptyCard('No order data available');
    }

    final colors = {
      'pending': AppTheme.warning,
      'confirmed': AppTheme.info,
      'completed': AppTheme.success,
      'cancelled': AppTheme.error,
    };

    final sections = statusData.entries.map((e) {
      final val = (e.value as num).toDouble();
      return PieChartSectionData(
        value: val,
        title: val > 0 ? '${val.round()}' : '',
        color: colors[e.key] ?? AppTheme.outline,
        radius: 55,
        titleStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusData.entries.map((e) {
                final color = colors[e.key] ?? AppTheme.outline;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    final categories = _reportData['topCategories'] as List<dynamic>? ?? [];
    if (categories.isEmpty) {
      return _buildEmptyCard('No category data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: categories.take(5).map((c) {
          final cat = c as Map<String, dynamic>;
          final count = (cat['count'] as num?)?.toInt() ?? 0;
          final maxCount =
              (categories.first as Map<String, dynamic>)['count'] as num? ?? 1;
          final pct = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat['category'] ?? 'Unknown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$count orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.toDouble(),
                    backgroundColor: AppTheme.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = _reportData['recentActivity'] as List<dynamic>? ?? [];
    if (activity.isEmpty) {
      return _buildEmptyCard('No recent activity');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: activity.take(8).map((a) {
          final item = a as Map<String, dynamic>;
          final type = item['type'] ?? 'order';
          final icon = type == 'complaint'
              ? Icons.report_problem_rounded
              : type == 'provider'
              ? Icons.store_rounded
              : Icons.receipt_long_rounded;
          final color = type == 'complaint'
              ? AppTheme.error
              : type == 'provider'
              ? AppTheme.success
              : AppTheme.primary;

          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(
              item['title'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item['subtitle'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.outline,
              ),
            ),
            trailing: Text(
              item['time'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.outline,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.outline,
          ),
        ),
      ),
    );
  }

  String _formatNum(dynamic val) {
    final n = (val as num?)?.toDouble() ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
