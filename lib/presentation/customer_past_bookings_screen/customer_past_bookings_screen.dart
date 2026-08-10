import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class CustomerPastBookingsScreen extends StatefulWidget {
  const CustomerPastBookingsScreen({super.key});

  @override
  State<CustomerPastBookingsScreen> createState() =>
      _CustomerPastBookingsScreenState();
}

class _CustomerPastBookingsScreenState extends State<CustomerPastBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _activeBookings = [];
  bool _loading = true;
  String? _error;

  // Filter
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Cancelled'];

  // Realtime channels
  RealtimeChannel? _bookingsRealtimeChannel;
  RealtimeChannel? _ordersRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _filters[_tabController.index];
        });
      }
    });
    _loadBookings();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    // Subscribe to orders table status changes (bookings table does not exist)
    _bookingsRealtimeChannel?.unsubscribe();
    _bookingsRealtimeChannel = SupabaseService.instance.client
        .channel('customer_past_orders_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (_) {
            if (mounted) _loadBookings();
          },
        )
        .subscribe();

    // Subscribe to orders table status changes (single channel)
    _ordersRealtimeChannel?.unsubscribe();
    _ordersRealtimeChannel = SupabaseService.instance.client
        .channel('customer_past_orders_insert_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (_) {
            if (mounted) _loadBookings();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingsRealtimeChannel?.unsubscribe();
    _ordersRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        setState(() {
          _loading = false;
          _error = 'Please log in to view your bookings.';
        });
        return;
      }

      final results = await Future.wait([
        SupabaseService.instance.client
            .from('orders')
            .select(
              'id, created_at, scheduled_date, status, amount, service, notes, provider_id, reviewed, service_providers(business_name, category, subcategory)',
            )
            .eq('customer_id', userId)
            .inFilter('status', ['completed', 'cancelled'])
            .order('created_at', ascending: false),
        SupabaseService.instance.client
            .from('orders')
            .select(
              'id, created_at, scheduled_date, scheduled_time, status, amount, service, notes, provider_id, order_number, payment_method, reviewed, service_providers(business_name, category, subcategory, phone)',
            )
            .eq('customer_id', userId)
            .inFilter('status', ['pending', 'active', 'upcoming'])
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _allBookings = List<Map<String, dynamic>>.from(results[0] as List);
          _activeBookings = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load bookings. Please try again.';
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedFilter == 'All') return _allBookings;
    return _allBookings
        .where(
          (b) =>
              (b['status'] as String? ?? '').toLowerCase() ==
              _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
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
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$min $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '—';
    final num val = amount is num
        ? amount
        : num.tryParse(amount.toString()) ?? 0;
    return '₹${val.toStringAsFixed(0)}';
  }

  String _providerName(Map<String, dynamic> booking) {
    final sp = booking['service_providers'];
    if (sp is Map) {
      return sp['business_name'] as String? ?? 'Unknown Provider';
    }
    return 'Unknown Provider';
  }

  String _categoryLabel(Map<String, dynamic> booking) {
    final sp = booking['service_providers'];
    if (sp is Map) {
      final sub = sp['subcategory'] as String?;
      final cat = sp['category'] as String?;
      if (sub != null && sub.isNotEmpty) return _capitalize(sub);
      if (cat != null && cat.isNotEmpty) return _capitalize(cat);
    }
    final svc = booking['service'] as String?;
    return svc != null && svc.isNotEmpty ? _capitalize(svc) : 'Service';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successContainer;
      case 'cancelled':
        return AppTheme.errorContainer;
      default:
        return AppTheme.surfaceVariant;
    }
  }

  IconData _categoryIcon(Map<String, dynamic> booking) {
    final sp = booking['service_providers'];
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

  void _rebook(Map<String, dynamic> booking) {
    Navigator.pushNamed(
      context,
      AppRoutes.serviceBookingScreen,
      arguments: {
        'provider_id': booking['provider_id'],
        'provider_name': _providerName(booking),
        'service': booking['service'] ?? _categoryLabel(booking),
        'rebook': true,
      },
    );
  }

  void _leaveReview(Map<String, dynamic> booking) {
    Navigator.pushNamed(
      context,
      AppRoutes.reviewSubmissionScreen,
      arguments: {
        'order_id': booking['id'],
        'provider_id': booking['provider_id'],
        'provider_name': _providerName(booking),
        'service': booking['service'] ?? _categoryLabel(booking),
      },
    ).then((result) {
      if (result == true) {
        _loadBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
            onPressed: _loadBookings,
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
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: _filters
              .map(
                (f) => Tab(
                  text: f == 'All'
                      ? 'All (${_allBookings.length})'
                      : f == 'Completed'
                      ? 'Completed (${_allBookings.where((b) => (b['status'] as String? ?? '').toLowerCase() == 'completed').length})'
                      : 'Cancelled (${_allBookings.where((b) => (b['status'] as String? ?? '').toLowerCase() == 'cancelled').length})',
                ),
              )
              .toList(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: _filters.map((f) => _buildList(f)).toList(),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh_rounded),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String filter) {
    final bookings = filter == 'All'
        ? _allBookings
        : _allBookings
              .where(
                (b) =>
                    (b['status'] as String? ?? '').toLowerCase() ==
                    filter.toLowerCase(),
              )
              .toList();

    if (bookings.isEmpty && _activeBookings.isEmpty && filter == 'All') {
      return _buildEmpty(filter);
    }
    if (bookings.isEmpty && filter != 'All') {
      return _buildEmpty(filter);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Active bookings section (only on 'All' tab)
          if (filter == 'All' && _activeBookings.isNotEmpty) ...[
            _buildActiveSectionHeader(),
            const SizedBox(height: 10),
            ..._activeBookings.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActiveBookingCard(b),
              ),
            ),
            const SizedBox(height: 8),
            _buildPastSectionHeader(),
            const SizedBox(height: 10),
          ],
          if (bookings.isEmpty && filter == 'All')
            _buildEmpty(filter)
          else
            ...bookings.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBookingCard(b),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSectionHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF6A1B9A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Active Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_activeBookings.length}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6A1B9A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastSectionHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Past Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? 'pending';
    final providerName = _providerName(booking);
    final category = _categoryLabel(booking);
    final date = _formatDate(
      booking['scheduled_date'] as String? ?? booking['created_at'] as String?,
    );
    final amount = _formatAmount(booking['amount']);
    final catIcon = _categoryIcon(booking);

    Color stageColor;
    String stageLabel;
    IconData stageIcon;
    switch (status.toLowerCase()) {
      case 'accepted':
        stageColor = const Color(0xFF1565C0);
        stageLabel = 'Accepted';
        stageIcon = Icons.handshake_rounded;
        break;
      case 'in_progress':
        stageColor = const Color(0xFF6A1B9A);
        stageLabel = 'In Progress';
        stageIcon = Icons.directions_walk_rounded;
        break;
      default:
        stageColor = const Color(0xFFF57C00);
        stageLabel = 'Pending';
        stageIcon = Icons.pending_actions_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stageColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stageColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: stageColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(catIcon, color: stageColor, size: 20),
                ),
                const SizedBox(width: 10),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: stageColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stageIcon, size: 12, color: stageColor),
                      const SizedBox(width: 4),
                      Text(
                        stageLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: stageColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _detailChip(
                  icon: Icons.calendar_today_rounded,
                  label: date,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _detailChip(
                  icon: Icons.currency_rupee_rounded,
                  label: amount,
                  flex: 1,
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.bookingStatusScreen,
                  arguments: {'booking_id': booking['id'], 'booking': booking},
                ),
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  'Track Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: stageColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String filter) {
    final isAll = filter == 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAll ? 'No Past Bookings' : 'No $filter Bookings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAll
                  ? 'Your completed and cancelled bookings will appear here.'
                  : 'You have no ${filter.toLowerCase()} bookings yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? '';
    final isCompleted = status.toLowerCase() == 'completed';
    final reviewed = booking['reviewed'] as bool? ?? false;
    final providerName = _providerName(booking);
    final category = _categoryLabel(booking);
    final date = _formatDate(
      booking['scheduled_date'] as String? ?? booking['created_at'] as String?,
    );
    final amount = _formatAmount(booking['amount']);
    final catIcon = _categoryIcon(booking);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 10),

          // Details row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _detailChip(
                  icon: Icons.calendar_today_rounded,
                  label: date,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                _detailChip(
                  icon: Icons.currency_rupee_rounded,
                  label: amount,
                  flex: 1,
                  highlight: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // View Summary button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.bookingSummaryScreen,
                  arguments: {
                    'orderNumber':
                        booking['order_number'] ?? booking['id'] ?? '',
                    'service': booking['service'] ?? _categoryLabel(booking),
                    'providerName': _providerName(booking),
                    'amount': booking['amount'] != null
                        ? '₹${booking['amount']}'
                        : '',
                    'scheduledDate': booking['scheduled_date'] ?? '',
                    'scheduledTime': booking['scheduled_time'] ?? '',
                    'paymentMethod': booking['payment_method'] ?? 'cash',
                    'paymentStatus':
                        booking['payment_status'] ??
                        (booking['status'] ?? 'Completed'),
                    'address': booking['address'] ?? '',
                    'category': _categoryLabel(booking),
                  },
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: Text(
                  'View Invoice & Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.info,
                  side: const BorderSide(color: AppTheme.info),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Rebook button (always shown for completed/cancelled)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rebook(booking),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: Text(
                      'Rebook',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Leave Review button (only for completed & not yet reviewed)
                if (isCompleted && !reviewed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _leaveReview(booking),
                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                      label: Text(
                        'Leave Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
                // Reviewed badge
                if (isCompleted && reviewed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.successContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reviewed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
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

  Widget _detailChip({
    required IconData icon,
    required String label,
    int flex = 1,
    bool highlight = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.primaryContainer.withValues(alpha: 0.4)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: highlight ? AppTheme.primary : const Color(0xFF74777F),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? AppTheme.primary : const Color(0xFF4A4C50),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
