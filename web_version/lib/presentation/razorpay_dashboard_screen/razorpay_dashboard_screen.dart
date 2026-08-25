import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';

class RazorpayDashboardScreen extends StatefulWidget {
  const RazorpayDashboardScreen({super.key});

  @override
  State<RazorpayDashboardScreen> createState() =>
      _RazorpayDashboardScreenState();
}

class _RazorpayDashboardScreenState extends State<RazorpayDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];

  // Computed stats
  double _totalCollections = 0;
  double _thisMonthCollections = 0;
  int _successCount = 0;
  int _failedCount = 0;
  int _pendingCount = 0;
  double _subscriptionRevenue = 0;
  double _refundedAmount = 0;
  int _refundCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await RazorpayService.instance.getTransactionHistory(
        limit: 200,
      );

      // Also fetch refunds from supabase if available
      double refundedAmt = 0;
      int refundCnt = 0;
      try {
        final user = SupabaseService.instance.client.auth.currentUser;
        if (user != null) {
          final refunds = await SupabaseService.instance.client
              .from('razorpay_transactions')
              .select('amount')
              .eq('user_id', user.id)
              .eq('payment_type', 'refund');
          final refundList = List<Map<String, dynamic>>.from(refunds as List);
          refundCnt = refundList.length;
          refundedAmt = refundList.fold(
            0.0,
            (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0.0),
          );
        }
      } catch (_) {}

      if (mounted) {
        final now = DateTime.now();
        double total = 0;
        double monthTotal = 0;
        double subRevenue = 0;
        int success = 0;
        int failed = 0;
        int pending = 0;

        for (final t in all) {
          final status = t['status'] as String? ?? '';
          final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
          final paymentType = t['payment_type'] as String? ?? '';
          final createdAt = t['created_at'] as String? ?? '';

          if (status == 'success') {
            total += amount;
            success++;
            if (paymentType == 'subscription') subRevenue += amount;
            try {
              final dt = DateTime.parse(createdAt);
              if (dt.year == now.year && dt.month == now.month) {
                monthTotal += amount;
              }
            } catch (_) {}
          } else if (status == 'failed') {
            failed++;
          } else {
            pending++;
          }
        }

        setState(() {
          _transactions = all;
          _totalCollections = total;
          _thisMonthCollections = monthTotal;
          _successCount = success;
          _failedCount = failed;
          _pendingCount = pending;
          _subscriptionRevenue = subRevenue;
          _refundedAmount = refundedAmt;
          _refundCount = refundCnt;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
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
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Razorpay Dashboard',
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
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildStatusBreakdown(),
                  const SizedBox(height: 16),
                  _buildQuickLinks(),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
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
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Total Collections',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_totalCollections.toStringAsFixed(_totalCollections == _totalCollections.truncateToDouble() ? 0 : 2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF80DEEA),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'This month: ${_formatAmount(_thisMonthCollections)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF80DEEA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withAlpha(40)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  '${_transactions.length}',
                  'Total Txns',
                  Icons.receipt_long_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withAlpha(40),
              ),
              Expanded(
                child: _buildHeroStat(
                  '$_successCount',
                  'Successful',
                  Icons.check_circle_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withAlpha(40),
              ),
              Expanded(
                child: _buildHeroStat(
                  _formatAmount(_subscriptionRevenue),
                  'Subscriptions',
                  Icons.subscriptions_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_rupee_rounded,
            iconBg: AppTheme.successContainer,
            iconColor: AppTheme.success,
            label: 'This Month',
            value: _formatAmount(_thisMonthCollections),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.replay_rounded,
            iconBg: AppTheme.warningContainer,
            iconColor: AppTheme.warning,
            label: 'Refunds',
            value: _refundCount > 0
                ? '${_formatAmount(_refundedAmount)} ($_refundCount)'
                : '₹0',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF74777F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final total = _successCount + _failedCount + _pendingCount;
    final successPct = total > 0 ? _successCount / total : 0.0;
    final failedPct = total > 0 ? _failedCount / total : 0.0;
    final pendingPct = total > 0 ? _pendingCount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (successPct > 0)
                  Expanded(
                    flex: (_successCount * 100).round(),
                    child: Container(height: 10, color: AppTheme.success),
                  ),
                if (failedPct > 0)
                  Expanded(
                    flex: (_failedCount * 100).round(),
                    child: Container(height: 10, color: AppTheme.error),
                  ),
                if (pendingPct > 0)
                  Expanded(
                    flex: (_pendingCount * 100).round(),
                    child: Container(height: 10, color: AppTheme.warning),
                  ),
                if (total == 0)
                  Expanded(
                    child: Container(
                      height: 10,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatusLegend(
                  color: AppTheme.success,
                  label: 'Success',
                  count: _successCount,
                  pct: successPct,
                ),
              ),
              Expanded(
                child: _buildStatusLegend(
                  color: AppTheme.error,
                  label: 'Failed',
                  count: _failedCount,
                  pct: failedPct,
                ),
              ),
              Expanded(
                child: _buildStatusLegend(
                  color: AppTheme.warning,
                  label: 'Pending',
                  count: _pendingCount,
                  pct: pendingPct,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend({
    required Color color,
    required String label,
    required int count,
    required double pct,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF74777F),
              ),
            ),
            Text(
              '$count (${(pct * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickLinkCard(
                icon: Icons.history_rounded,
                label: 'All Transactions',
                subtitle: '${_transactions.length} records',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.razorpayTransactionHistoryScreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickLinkCard(
                icon: Icons.subscriptions_rounded,
                label: 'Subscriptions',
                subtitle: _formatAmount(_subscriptionRevenue),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.razorpayTransactionHistoryScreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickLinkCard(
                icon: Icons.replay_rounded,
                label: 'Refunds',
                subtitle: _refundCount > 0
                    ? '$_refundCount refunds'
                    : 'No refunds',
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.razorpayTransactionHistoryScreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recent = _transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.razorpayTransactionHistoryScreen,
              ),
              child: Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 36,
                    color: AppTheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No transactions yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: recent.asMap().entries.map((entry) {
                final i = entry.key;
                final txn = entry.value;
                final isLast = i == recent.length - 1;
                return _buildRecentTxnRow(txn, isLast);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentTxnRow(Map<String, dynamic> txn, bool isLast) {
    final status = txn['status'] as String? ?? 'pending';
    final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
    final description = txn['description'] as String? ?? 'Payment';
    final paymentType = txn['payment_type'] as String? ?? 'one_time';
    final createdAt = txn['created_at'] as String? ?? '';

    final isSuccess = status == 'success';
    final statusColor = isSuccess
        ? AppTheme.success
        : status == 'failed'
        ? AppTheme.error
        : AppTheme.warning;
    final statusBg = isSuccess
        ? AppTheme.successContainer
        : status == 'failed'
        ? AppTheme.errorContainer
        : AppTheme.warningContainer;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: paymentType == 'subscription'
                      ? AppTheme.primaryContainer
                      : AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  paymentType == 'subscription'
                      ? Icons.subscriptions_rounded
                      : Icons.payment_rounded,
                  size: 18,
                  color: paymentType == 'subscription'
                      ? AppTheme.primary
                      : AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: AppTheme.outlineVariant,
          ),
      ],
    );
  }
}
