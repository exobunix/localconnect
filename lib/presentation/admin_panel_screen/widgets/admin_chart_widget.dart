import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class AdminChartWidget extends StatefulWidget {
  const AdminChartWidget({super.key});

  @override
  State<AdminChartWidget> createState() => _AdminChartWidgetState();
}

class _AdminChartWidgetState extends State<AdminChartWidget> {
  int _selectedChartIndex = 0;
  bool _isLoading = true;

  List<double> _ordersData = [0, 0, 0, 0, 0, 0, 0];
  List<double> _revenueData = [0, 0, 0, 0, 0, 0, 0];
  List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await SupabaseService.instance.getAdminWeeklyAnalytics();
      if (mounted) {
        setState(() {
          _days = List<String>.from(data['days'] as List);
          _ordersData = List<double>.from(data['orders'] as List);
          _revenueData = List<double>.from(data['revenue'] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOrders = _selectedChartIndex == 0;
    final data = isOrders ? _ordersData : _revenueData;
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.25 : 10.0;

    final totalOrders = _ordersData.fold(0.0, (a, b) => a + b);
    final totalRevenue = _revenueData.fold(0.0, (a, b) => a + b);
    final peakOrderIdx = _ordersData.isEmpty
        ? 0
        : _ordersData.indexOf(_ordersData.reduce((a, b) => a > b ? a : b));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Performance',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      _isLoading ? 'Loading...' : 'Last 7 days • Live data',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _ChartToggle(
                        label: 'Orders',
                        isSelected: _selectedChartIndex == 0,
                        onTap: () => setState(() => _selectedChartIndex = 0),
                      ),
                      _ChartToggle(
                        label: 'Revenue',
                        isSelected: _selectedChartIndex == 1,
                        onTap: () => setState(() => _selectedChartIndex = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!_isLoading) ...[
              Row(
                children: [
                  _ChartSummaryChip(
                    label: isOrders ? 'Total Orders' : 'Total Revenue',
                    value: isOrders
                        ? '${totalOrders.round()}'
                        : '₹${totalRevenue.toStringAsFixed(1)}K',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _ChartSummaryChip(
                    label: 'Daily Avg',
                    value: isOrders
                        ? '${(totalOrders / 7).round()}'
                        : '₹${(totalRevenue / 7).toStringAsFixed(1)}K',
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _ChartSummaryChip(
                    label: 'Peak Day',
                    value: isOrders
                        ? '${_days.isNotEmpty && peakOrderIdx < _days.length ? _days[peakOrderIdx] : ''} ${_ordersData.isNotEmpty ? _ordersData.reduce((a, b) => a > b ? a : b).round() : 0}'
                        : '${_days.isNotEmpty && peakOrderIdx < _days.length ? _days[peakOrderIdx] : ''} ₹${_revenueData.isNotEmpty ? _revenueData.reduce((a, b) => a > b ? a : b).toStringAsFixed(1) : 0}K',
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (_isLoading)
              const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF0D1B3E),
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, _, rod, __) {
                          return BarTooltipItem(
                            isOrders
                                ? '${rod.toY.round()} orders'
                                : '₹${rod.toY.toStringAsFixed(1)}K',
                            GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 11,
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
                            if (idx < 0 || idx >= _days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _days[idx],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: idx == data.length - 1
                                      ? AppTheme.primary
                                      : const Color(0xFF74777F),
                                  fontWeight: idx == data.length - 1
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == maxY) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              isOrders
                                  ? value.round().toString()
                                  : '${value.round()}K',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF90A4AE),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.outlineVariant,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      data.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i],
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            gradient: LinearGradient(
                              colors: i == data.length - 1
                                  ? [
                                      AppTheme.secondary,
                                      AppTheme.secondary.withValues(alpha: 0.7),
                                    ]
                                  : [
                                      AppTheme.primary,
                                      AppTheme.primaryLight.withValues(
                                        alpha: 0.7,
                                      ),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
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
      ),
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChartToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF74777F),
          ),
        ),
      ),
    );
  }
}

class _ChartSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ChartSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }
}
