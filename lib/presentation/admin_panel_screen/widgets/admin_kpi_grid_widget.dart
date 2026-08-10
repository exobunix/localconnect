import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class AdminKpiGridWidget extends StatefulWidget {
  const AdminKpiGridWidget({super.key});

  @override
  State<AdminKpiGridWidget> createState() => _AdminKpiGridWidgetState();
}

class _AdminKpiGridWidgetState extends State<AdminKpiGridWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalProviders': 0,
    'totalOrders': 0,
    'totalUsers': 0,
    'pendingOrders': 0,
  };

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToChanges() {
    _realtimeChannel = SupabaseService.instance.client
        .channel('admin_kpi_stats')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_providers',
          callback: (_) => _loadStats(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => _loadStats(),
        )
        .subscribe();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.instance.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.day} ${_monthName(today.month)}';

    final kpis = [
      _KpiData(
        label: 'Total Users',
        value: _isLoading ? '...' : '${_stats['totalUsers'] ?? 0}',
        change: 'Registered users',
        isPositive: true,
        icon: Icons.people_rounded,
        color: AppTheme.primary,
      ),
      _KpiData(
        label: 'Active Providers',
        value: _isLoading ? '...' : '${_stats['totalProviders'] ?? 0}',
        change: 'Service providers',
        isPositive: true,
        icon: Icons.store_rounded,
        color: AppTheme.success,
      ),
      _KpiData(
        label: "Total Orders",
        value: _isLoading ? '...' : '${_stats['totalOrders'] ?? 0}',
        change: 'All time orders',
        isPositive: true,
        icon: Icons.receipt_long_rounded,
        color: AppTheme.warning,
        isAlert: false,
      ),
      _KpiData(
        label: 'Pending Orders',
        value: _isLoading ? '...' : '${_stats['pendingOrders'] ?? 0}',
        change: 'Awaiting action',
        isPositive: false,
        icon: Icons.pending_actions_rounded,
        color: AppTheme.error,
        isAlert: (_stats['pendingOrders'] ?? 0) > 0,
      ),
      _KpiData(
        label: "Pending Approvals",
        value: _isLoading ? '...' : '${_stats['pendingApprovals'] ?? 0}',
        change: 'Provider requests',
        isPositive: false,
        icon: Icons.approval_rounded,
        color: const Color(0xFF7B1FA2),
        isAlert: (_stats['pendingApprovals'] ?? 0) > 0,
      ),
      _KpiData(
        label: 'Completed Orders',
        value: _isLoading ? '...' : '${_stats['completedOrders'] ?? 0}',
        change: 'Successfully done',
        isPositive: true,
        icon: Icons.check_circle_rounded,
        color: AppTheme.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              GestureDetector(
                onTap: _loadStats,
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
                        dateStr,
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: kpis.length,
            itemBuilder: (_, i) => _KpiCard(kpi: kpis[i]),
          ),
        ],
      ),
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
}

class _KpiData {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _KpiData({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;

  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kpi.isAlert ? kpi.color.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: kpi.isAlert
              ? kpi.color.withValues(alpha: 0.4)
              : AppTheme.outlineVariant,
          width: kpi.isAlert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 16),
              ),
              if (kpi.isAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kpi.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kpi.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kpi.isAlert ? kpi.color : const Color(0xFF1A1C1E),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                kpi.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    kpi.isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 12,
                    color: kpi.isPositive ? AppTheme.success : kpi.color,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      kpi.change,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: kpi.isPositive ? AppTheme.success : kpi.color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
