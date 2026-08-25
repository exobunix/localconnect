import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class AdminOrderMetricsWidget extends StatefulWidget {
  const AdminOrderMetricsWidget({super.key});

  @override
  State<AdminOrderMetricsWidget> createState() =>
      _AdminOrderMetricsWidgetState();
}

class _AdminOrderMetricsWidgetState extends State<AdminOrderMetricsWidget> {
  bool _isLoading = true;
  int _pending = 0;
  int _completed = 0;
  int _cancelled = 0;
  int _other = 0;
  double _totalRevenue = 0;
  List<String> _timelineDays = [];
  List<double> _timelineCounts = [];
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final data = await SupabaseService.instance.getAdminOrderMetrics();
      if (mounted) {
        setState(() {
          _pending = data['pending'] as int? ?? 0;
          _completed = data['completed'] as int? ?? 0;
          _cancelled = data['cancelled'] as int? ?? 0;
          _other = data['other'] as int? ?? 0;
          _totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
          _timelineDays = List<String>.from(data['timelineDays'] as List);
          _timelineCounts = List<double>.from(data['timelineCounts'] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Analytics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isLoading = true);
                  _loadMetrics();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Revenue card + Pie chart row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue card
              Expanded(
                flex: 5,
                child: _RevenueCard(
                  totalRevenue: _totalRevenue,
                  isLoading: _isLoading,
                  totalOrders: _pending + _completed + _cancelled + _other,
                ),
              ),
              const SizedBox(width: 10),
              // Pie chart
              Expanded(
                flex: 6,
                child: _StatusPieCard(
                  pending: _pending,
                  completed: _completed,
                  cancelled: _cancelled,
                  other: _other,
                  isLoading: _isLoading,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Timeline chart
          _TimelineCard(
            days: _timelineDays,
            counts: _timelineCounts,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Card ─────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final double totalRevenue;
  final bool isLoading;
  final int totalOrders;

  const _RevenueCard({
    required this.totalRevenue,
    required this.isLoading,
    required this.totalOrders,
  });

  String _formatRevenue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total Revenue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? Container(
                  height: 22,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  _formatRevenue(totalRevenue),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLoading ? '...' : '$totalOrders bookings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Pie Chart ─────────────────────────────────────────────────────────

class _StatusPieCard extends StatelessWidget {
  final int pending;
  final int completed;
  final int cancelled;
  final int other;
  final bool isLoading;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _StatusPieCard({
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.other,
    required this.isLoading,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + completed + cancelled + other;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Distribution',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 10),
          isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              : total == 0
              ? SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'No orders yet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                onTouch(-1);
                                return;
                              }
                              onTouch(
                                response.touchedSection!.touchedSectionIndex,
                              );
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: [
                            _pieSection(
                              pending.toDouble(),
                              total.toDouble(),
                              const Color(0xFFF59E0B),
                              0,
                              touchedIndex,
                            ),
                            _pieSection(
                              completed.toDouble(),
                              total.toDouble(),
                              AppTheme.success,
                              1,
                              touchedIndex,
                            ),
                            _pieSection(
                              cancelled.toDouble(),
                              total.toDouble(),
                              AppTheme.error,
                              2,
                              touchedIndex,
                            ),
                            if (other > 0)
                              _pieSection(
                                other.toDouble(),
                                total.toDouble(),
                                const Color(0xFF90A4AE),
                                3,
                                touchedIndex,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                            color: const Color(0xFFF59E0B),
                            label: 'Pending',
                            count: pending,
                          ),
                          const SizedBox(height: 5),
                          _LegendItem(
                            color: AppTheme.success,
                            label: 'Completed',
                            count: completed,
                          ),
                          const SizedBox(height: 5),
                          _LegendItem(
                            color: AppTheme.error,
                            label: 'Cancelled',
                            count: cancelled,
                          ),
                          if (other > 0) ...[
                            const SizedBox(height: 5),
                            _LegendItem(
                              color: const Color(0xFF90A4AE),
                              label: 'Other',
                              count: other,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(
    double value,
    double total,
    Color color,
    int index,
    int touchedIndex,
  ) {
    final isTouched = index == touchedIndex;
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched ? '$pct%' : '',
      radius: isTouched ? 28 : 22,
      titleStyle: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: const Color(0xFF74777F),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}

// ─── Timeline Chart ───────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final List<String> days;
  final List<double> counts;
  final bool isLoading;

  const _TimelineCard({
    required this.days,
    required this.counts,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = counts.isEmpty
        ? 1.0
        : counts.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.3 : 5.0;

    return Container(
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
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Order Timeline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last 30 days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isLoading
              ? const SizedBox(
                  height: 130,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              : SizedBox(
                  height: 130,
                  child: LineChart(
                    LineChartData(
                      maxY: maxY,
                      minY: 0,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: const Color(0xFF0D1B3E),
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (spots) => spots
                              .map(
                                (s) => LineTooltipItem(
                                  '${s.y.round()} orders',
                                  GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
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
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) {
                                return const SizedBox.shrink();
                              }
                              final label = days[idx];
                              if (label.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF90A4AE),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == maxY) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.round().toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
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
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            counts.length,
                            (i) => FlSpot(i.toDouble(), counts[i]),
                          ),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppTheme.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, _) => spot.y > 0,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: AppTheme.primary,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withValues(alpha: 0.18),
                                AppTheme.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
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
}
