import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _providerProfile;
  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _pastOrders = [];
  List<Map<String, dynamic>> _reviews = [];

  RealtimeChannel? _newBookingsChannel;

  // Summary stats
  double _totalEarnings = 0;
  double _monthEarnings = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _completionRate = 0;
  double _avgRating = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _newBookingsChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
      final providerId = provider['id'] as String;

      final orders = await SupabaseService.instance.getProviderOrders(
        providerId,
      );
      final reviews = await SupabaseService.instance.getProviderReviews(
        providerId,
      );

      final active = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];
      double total = 0, month = 0;
      int completed = 0, cancelled = 0;
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      for (final order in orders) {
        final status = (order['status'] as String?) ?? '';
        final amountStr = (order['amount'] as String?) ?? '0';
        final amount =
            double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        final createdAt = order['created_at'] != null
            ? DateTime.tryParse(order['created_at'] as String)
            : null;

        if (status == 'active' || status == 'upcoming' || status == 'pending') {
          active.add(order);
        } else {
          past.add(order);
          if (status == 'completed') {
            completed++;
            total += amount;
            if (createdAt != null && createdAt.isAfter(monthAgo)) {
              month += amount;
            }
          } else if (status == 'cancelled') {
            cancelled++;
          }
        }
      }

      final totalHandled = completed + cancelled;
      final rate = totalHandled > 0 ? (completed / totalHandled) * 100 : 0.0;

      double ratingSum = 0;
      for (final r in reviews) {
        ratingSum += ((r['rating'] as num?) ?? 0).toDouble();
      }
      final avgRating = reviews.isNotEmpty ? ratingSum / reviews.length : 0.0;

      if (mounted) {
        setState(() {
          _activeBookings = active;
          _pastOrders = past;
          _reviews = reviews;
          _totalEarnings = total;
          _monthEarnings = month;
          _completedCount = completed;
          _cancelledCount = cancelled;
          _completionRate = rate;
          _avgRating = avgRating;
          _isLoading = false;
        });
        _subscribeToNewBookings(providerId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Subscribe to new bookings for this provider via Supabase real-time.
  /// Fires a push notification + in-app toast when a new booking arrives.
  void _subscribeToNewBookings(String providerId) {
    _newBookingsChannel?.unsubscribe();
    _newBookingsChannel = SupabaseService.instance.client
        .channel('provider_new_bookings_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newBooking = payload.newRecord;
            if (newBooking.isEmpty) return;

            final bookingId = newBooking['id'] as String? ?? '';
            final customerName = newBooking['customer_name'] as String?;
            final serviceName = newBooking['service'] as String?;

            // Refresh the bookings list
            _loadData();

            // Push notification (mobile only)
            NotificationService.instance.showNewBookingNotification(
              bookingId: bookingId,
              customerName: customerName,
              serviceName: serviceName,
            );

            // In-app toast overlay
            NotificationService.instance.showNewBookingToast(
              customerName: customerName,
              serviceName: serviceName,
            );
          },
        )
        .subscribe();
  }

  String _fmtAmount(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '—';
    final months = [
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
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'upcoming':
        return AppTheme.primary;
      case 'pending':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.play_circle_rounded;
      case 'upcoming':
        return Icons.schedule_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
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
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            'My Bookings & Orders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Active'),
                    if (_activeBookings.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_activeBookings.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Past Orders'),
                    if (_pastOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pastOrders.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveTab(), _buildPastOrdersTab()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _providerProfile?['business_name'] as String? ??
                _providerProfile?['full_name'] as String? ??
                'My Business',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Earned',
                value: _fmtAmount(_totalEarnings),
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                icon: Icons.calendar_month_rounded,
                label: 'This Month',
                value: _fmtAmount(_monthEarnings),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.check_circle_rounded,
                label: 'Completion',
                value: '${_completionRate.toStringAsFixed(0)}%',
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                icon: Icons.star_rounded,
                label: 'Avg Rating',
                value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : 'N/A',
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Bookings Tab ────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    if (_activeBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_rounded,
        title: 'No Active Bookings',
        subtitle: 'Your active and upcoming bookings will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _activeBookings.length,
        itemBuilder: (context, index) =>
            _buildActiveBookingCard(_activeBookings[index]),
      ),
    );
  }

  Widget _buildActiveBookingCard(Map<String, dynamic> order) {
    final status = (order['status'] as String?) ?? 'pending';
    final customerName =
        (order['customer_name'] as String?) ??
        (order['user_profiles'] != null
            ? (order['user_profiles']['full_name'] as String?) ?? 'Customer'
            : 'Customer');
    final service = (order['service_type'] as String?) ?? 'Service';
    final amountStr = (order['amount'] as String?) ?? '0';
    final amount =
        double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final scheduledAt = order['scheduled_at'] as String?;
    final createdAt = order['created_at'] as String?;
    final notes = (order['notes'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            service,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF44474E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scheduledAt != null
                          ? 'Scheduled: ${_fmtDate(scheduledAt)}'
                          : 'Booked: ${_fmtDate(createdAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
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

  // ── Past Orders Tab ────────────────────────────────────────────────────────

  Widget _buildPastOrdersTab() {
    if (_pastOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No Past Orders',
        subtitle: 'Completed and cancelled orders will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPastOrderCard(_pastOrders[index]),
                childCount: _pastOrders.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildMiniStat(
            label: 'Completed',
            value: '$_completedCount',
            color: AppTheme.success,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(width: 8),
          _buildMiniStat(
            label: 'Cancelled',
            value: '$_cancelledCount',
            color: AppTheme.error,
            icon: Icons.cancel_rounded,
          ),
          const SizedBox(width: 8),
          _buildMiniStat(
            label: 'Reviews',
            value: '${_reviews.length}',
            color: const Color(0xFFF59E0B),
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: color.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] as String?) ?? '';
    final customerName =
        (order['customer_name'] as String?) ??
        (order['user_profiles'] != null
            ? (order['user_profiles']['full_name'] as String?) ?? 'Customer'
            : 'Customer');
    final service = (order['service_type'] as String?) ?? 'Service';
    final amountStr = (order['amount'] as String?) ?? '0';
    final amount =
        double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final createdAt = order['created_at'] as String?;
    final orderId = (order['id'] as String?) ?? '';

    // Find matching review
    final review = _reviews.firstWhere(
      (r) => (r['order_id'] as String?) == orderId,
      orElse: () => {},
    );
    final hasReview = review.isNotEmpty;
    final rating = hasReview
        ? ((review['rating'] as num?) ?? 0).toDouble()
        : 0.0;
    final reviewText = hasReview ? (review['comment'] as String?) ?? '' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (status == 'completed')
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.success,
                            ),
                          ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Date & completion info
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmtDate(createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (status == 'completed') ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                // Rating section
                if (hasReview) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 16,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        if (reviewText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"$reviewText"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

