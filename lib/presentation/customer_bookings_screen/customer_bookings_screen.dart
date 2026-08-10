import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _activeBookings = [];
  List<Map<String, dynamic>> _pastOrders = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _ratingsGiven = [];

  // Summary stats
  double _totalSpent = 0;
  double _monthSpent = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _completionRate = 0;
  double _avgRatingGiven = 0;
  int _totalReviews = 0;

  // Realtime
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    _ordersChannel?.unsubscribe();
    _ordersChannel = SupabaseService.instance.client
        .channel('customer_orders_bookings_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (_) {
            if (mounted) _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Please log in to view your bookings.';
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        // Active bookings — from orders table
        SupabaseService.instance.client
            .from('orders')
            .select(
              'id, created_at, scheduled_date, scheduled_time, status, amount, service, notes, provider_id, payment_method, order_number, service_providers(business_name, category, subcategory, phone)',
            )
            .eq('customer_id', userId)
            .inFilter('status', ['pending', 'active', 'upcoming'])
            .order('created_at', ascending: false),
        // Past orders — from orders table
        SupabaseService.instance.client
            .from('orders')
            .select(
              'id, created_at, scheduled_date, status, amount, service, notes, provider_id, reviewed, payment_method, service_providers(business_name, category, subcategory)',
            )
            .eq('customer_id', userId)
            .inFilter('status', ['completed', 'cancelled'])
            .order('created_at', ascending: false),
        // Payments — from razorpay_transactions table
        SupabaseService.instance.client
            .from('razorpay_transactions')
            .select(
              'id, created_at, amount, status, payment_type, description, order_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(50),
        // Reviews given by customer
        SupabaseService.instance.client
            .from('reviews')
            .select(
              'id, created_at, rating, review_text, provider_id, order_id, service_providers(business_name, category)',
            )
            .eq('customer_id', userId)
            .order('created_at', ascending: false),
      ]);

      final active = List<Map<String, dynamic>>.from(results[0] as List);
      final past = List<Map<String, dynamic>>.from(results[1] as List);
      final payments = List<Map<String, dynamic>>.from(results[2] as List);
      final ratings = List<Map<String, dynamic>>.from(results[3] as List);

      // Compute stats from past orders
      double totalSpent = 0, monthSpent = 0;
      int completed = 0, cancelled = 0;
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      for (final order in past) {
        final status = (order['status'] as String?) ?? '';
        final amount = _parseAmount(order['amount']);
        final createdAt = order['created_at'] != null
            ? DateTime.tryParse(order['created_at'] as String)
            : null;

        if (status == 'completed') {
          completed++;
          totalSpent += amount;
          if (createdAt != null && createdAt.isAfter(monthAgo)) {
            monthSpent += amount;
          }
        } else if (status == 'cancelled') {
          cancelled++;
        }
      }

      final totalHandled = completed + cancelled;
      final rate = totalHandled > 0 ? (completed / totalHandled) * 100 : 0.0;

      double ratingSum = 0;
      for (final r in ratings) {
        ratingSum += ((r['rating'] as num?) ?? 0).toDouble();
      }
      final avgRating = ratings.isNotEmpty ? ratingSum / ratings.length : 0.0;

      if (mounted) {
        setState(() {
          _activeBookings = active;
          _pastOrders = past;
          _payments = payments;
          _ratingsGiven = ratings;
          _totalSpent = totalSpent;
          _monthSpent = monthSpent;
          _completedCount = completed;
          _cancelledCount = cancelled;
          _completionRate = rate;
          _avgRatingGiven = avgRating;
          _totalReviews = ratings.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
  }

  String _fmtAmount(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _fmtAmountRaw(dynamic val) => _fmtAmount(_parseAmount(val));

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return dateStr;
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
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
  }

  String _providerName(Map<String, dynamic> item) {
    final sp = item['service_providers'];
    if (sp is Map) return sp['business_name'] as String? ?? 'Unknown Provider';
    return item['provider_name'] as String? ?? 'Unknown Provider';
  }

  String _categoryLabel(Map<String, dynamic> item) {
    final sp = item['service_providers'];
    if (sp is Map) {
      final sub = sp['subcategory'] as String?;
      final cat = sp['category'] as String?;
      if (sub != null && sub.isNotEmpty) return _capitalize(sub);
      if (cat != null && cat.isNotEmpty) return _capitalize(cat);
    }
    final svc = item['service'] as String?;
    return svc != null && svc.isNotEmpty ? _capitalize(svc) : 'Service';
  }

  String _capitalize(String s) => s.isEmpty
      ? s
      : s
            .split('_')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppTheme.success;
      case 'cancelled':
      case 'failed':
        return AppTheme.error;
      case 'active':
        return const Color(0xFF1565C0);
      case 'upcoming':
      case 'in_progress':
        return const Color(0xFF6A1B9A);
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.outline;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppTheme.successContainer;
      case 'cancelled':
      case 'failed':
        return AppTheme.errorContainer;
      case 'active':
        return const Color(0xFFE3F2FD);
      case 'upcoming':
      case 'in_progress':
        return const Color(0xFFF3E5F5);
      case 'pending':
        return const Color(0xFFFFF8E1);
      default:
        return AppTheme.surfaceVariant;
    }
  }

  IconData _categoryIcon(Map<String, dynamic> item) {
    final sp = item['service_providers'];
    final cat = sp is Map ? (sp['category'] as String? ?? '') : '';
    switch (cat.toLowerCase()) {
      case 'transport':
        return Icons.directions_car_rounded;
      case 'home_maintenance':
      case 'home maintenance':
        return Icons.home_repair_service_rounded;
      case 'event_management':
      case 'event management':
        return Icons.celebration_rounded;
      case 'shop':
        return Icons.storefront_rounded;
      case 'rent':
        return Icons.apartment_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
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
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          title: Text(
            'My Bookings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                  child: _buildStatsRow(),
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              Tab(text: 'Active (${_activeBookings.length})'),
              Tab(text: 'Past Orders (${_pastOrders.length})'),
              Tab(text: 'Payments (${_payments.length})'),
              Tab(text: 'Ratings ($_totalReviews)'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildPastOrdersTab(),
          _buildPaymentsTab(),
          _buildRatingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatChip(
            label: 'Total Spent',
            value: _fmtAmount(_totalSpent),
            icon: Icons.payments_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'This Month',
            value: _fmtAmount(_monthSpent),
            icon: Icons.calendar_month_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Completion',
            value: '${_completionRate.toStringAsFixed(0)}%',
            icon: Icons.check_circle_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Avg Rating',
            value: _avgRatingGiven > 0
                ? _avgRatingGiven.toStringAsFixed(1)
                : '—',
            icon: Icons.star_rounded,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeBookings.isEmpty) {
      return _buildEmpty(
        icon: Icons.event_available_rounded,
        title: 'No Active Bookings',
        subtitle: 'Your active and upcoming bookings will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _activeBookings.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActiveCard(_activeBookings[i]),
        ),
      ),
    );
  }

  Widget _buildActiveCard(Map<String, dynamic> booking) {
    final status = (booking['status'] as String?) ?? 'pending';
    final providerName = _providerName(booking);
    final category = _categoryLabel(booking);
    final date = _fmtDate(
      booking['scheduled_date'] as String? ?? booking['created_at'] as String?,
    );
    final amount = _fmtAmountRaw(booking['amount']);
    final catIcon = _categoryIcon(booking);
    final stageColor = _statusColor(status);
    final stageBg = _statusBg(status);
    final sp = booking['service_providers'];
    final providerPhone = sp is Map ? (sp['phone'] as String?) : null;
    final providerId = booking['provider_id'] as String?;
    final orderId = booking['id'] as String?;

    String stageLabel;
    IconData stageIcon;
    switch (status.toLowerCase()) {
      case 'active':
        stageLabel = 'Accepted';
        stageIcon = Icons.handshake_rounded;
        break;
      case 'upcoming':
        stageLabel = 'Upcoming';
        stageIcon = Icons.directions_walk_rounded;
        break;
      default:
        stageLabel = 'Pending';
        stageIcon = Icons.pending_actions_rounded;
    }

    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: stageBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stageIcon, color: stageColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stageColor,
                        ),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: stageColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: stageColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                if (providerPhone != null && providerPhone.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:$providerPhone')),
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: Text(
                        'Call',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (providerPhone != null && providerPhone.isNotEmpty)
                  const SizedBox(width: 8),
                if (orderId != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.bookingStatusScreen,
                        arguments: {'booking_id': orderId},
                      ),
                      icon: const Icon(Icons.track_changes_rounded, size: 16),
                      label: Text(
                        'Track',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrdersTab() {
    if (_pastOrders.isEmpty) {
      return _buildEmpty(
        icon: Icons.history_rounded,
        title: 'No Past Orders',
        subtitle: 'Your completed and cancelled orders will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _pastOrders.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPastCard(_pastOrders[i]),
        ),
      ),
    );
  }

  Widget _buildPastCard(Map<String, dynamic> order) {
    final status = (order['status'] as String?) ?? 'completed';
    final providerName = _providerName(order);
    final category = _categoryLabel(order);
    final date = _fmtDate(
      order['scheduled_date'] as String? ?? order['created_at'] as String?,
    );
    final amount = _fmtAmountRaw(order['amount']);
    final stageColor = _statusColor(status);
    final stageBg = _statusBg(status);
    final reviewed = order['reviewed'] as bool? ?? false;
    final orderId = order['id'] as String?;
    final providerId = order['provider_id'] as String?;

    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: stageBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: stageColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: stageColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$category • $date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (status == 'completed' &&
                    !reviewed &&
                    orderId != null &&
                    providerId != null)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.reviewSubmissionScreen,
                      arguments: {
                        'order_id': orderId,
                        'provider_id': providerId,
                        'provider_name': providerName,
                        'service': category,
                      },
                    ).then((_) => _loadData()),
                    child: Text(
                      'Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return _buildEmpty(
        icon: Icons.receipt_long_rounded,
        title: 'No Payments',
        subtitle: 'Your payment history will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _payments.length,
        itemBuilder: (context, i) {
          final p = _payments[i];
          final status = (p['status'] as String?) ?? 'success';
          final amount = _fmtAmountRaw(p['amount']);
          final desc =
              p['description'] as String? ??
              p['payment_type'] as String? ??
              'Payment';
          final date = _fmtDate(p['created_at'] as String?);
          final isSuccess = status == 'success' || status == 'captured';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? AppTheme.successContainer
                        : AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isSuccess ? AppTheme.success : AppTheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSuccess ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingsTab() {
    if (_ratingsGiven.isEmpty) {
      return _buildEmpty(
        icon: Icons.star_outline_rounded,
        title: 'No Reviews Yet',
        subtitle: 'Reviews you submit will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _ratingsGiven.length,
        itemBuilder: (context, i) {
          final r = _ratingsGiven[i];
          final sp = r['service_providers'];
          final provName = sp is Map
              ? (sp['business_name'] as String? ?? 'Provider')
              : 'Provider';
          final rating = (r['rating'] as num?)?.toInt() ?? 0;
          final comment = r['review_text'] as String? ?? '';
          final date = _fmtDate(r['created_at'] as String?);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (idx) => Icon(
                          idx < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    comment,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF44474E),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF44474E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
