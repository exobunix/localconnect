import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/connectivity_service.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/offline_banner_widget.dart';
import '../../widgets/retry_widget.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _reorderingId;
  bool _isOnline = true;
  bool _hasError = false;
  String? _cacheAge;

  RealtimeChannel? _ordersRealtimeChannel;

  static const _cacheKey = 'order_management_orders';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) _loadOrders();
      }
    });
    _loadOrders();
    _subscribeToOrderUpdates();
  }

  void _subscribeToOrderUpdates() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    _ordersRealtimeChannel?.unsubscribe();
    _ordersRealtimeChannel = SupabaseService.instance.client
        .channel('customer_order_mgmt_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted && _isOnline) {
              // Show local notification for status changes
              final newRow = payload.newRecord;
              final oldRow = payload.oldRecord;
              final orderId = newRow['id'] as String? ?? '';
              final newStatus = newRow['status'] as String? ?? '';
              final oldStatus = oldRow['status'] as String? ?? '';
              final providerName = newRow['provider_name'] as String?;

              if (newStatus != oldStatus && newStatus.isNotEmpty) {
                // Map order status to notification-friendly status
                final notifStatus = newStatus == 'active'
                    ? 'accepted'
                    : newStatus;
                NotificationService.instance.showOrderStatusNotification(
                  orderId: orderId,
                  status: notifStatus,
                  providerName: providerName,
                );
                NotificationService.instance.showBookingStatusToast(
                  status: notifStatus,
                  providerName: providerName,
                );
              }

              _loadOrders();
            }
          },
        )
        .subscribe((status, [error]) {
          if (error != null) {
            debugPrint('[OrderMgmt] realtime error: $error');
          }
        });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedList(
        _cacheKey,
      );
      if (mounted) {
        final ts = cached != null
            ? await ConnectivityService.instance.getCachedData(_cacheKey)
            : null;
        setState(() {
          _orders = cached?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
          _cacheAge = ts != null
              ? ConnectivityService.instance.formatCacheAge(
                  ConnectivityService.instance.getCachedTimestamp(ts),
                )
              : null;
        });
      }
      return;
    }

    try {
      final data = await SupabaseService.instance.getOrders();
      await ConnectivityService.instance.cacheData(_cacheKey, data);
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoading = false;
          _hasError = false;
          _cacheAge = null;
        });
      }
    } catch (e) {
      // Try cache on error
      final cached = await ConnectivityService.instance.getCachedList(
        _cacheKey,
      );
      if (mounted) {
        setState(() {
          _orders = cached?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
          _hasError = cached == null;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredOrders(String tab) {
    switch (tab) {
      case 'active':
        return _orders.where((o) => o['status'] == 'active' || (o['status'] == 'completed' && o['rating'] == null && o['reviewed'] != true)).toList();
      case 'pending':
        return _orders.where((o) => o['status'] == 'pending').toList();
      case 'completed':
        return _orders.where((o) => o['status'] == 'completed' && (o['rating'] != null || o['reviewed'] == true)).toList();
      case 'cancelled':
        return _orders.where((o) => o['status'] == 'cancelled').toList();
      default:
        return _orders;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'home_maintenance':
        return Icons.home_repair_service_rounded;
      case 'shop':
        return Icons.shopping_basket_rounded;
      case 'transport':
        return Icons.electric_rickshaw_rounded;
      case 'delivery':
        return Icons.description_rounded;
      case 'events':
        return Icons.camera_alt_rounded;
      case 'beauty':
        return Icons.face_retouching_natural_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'home_maintenance':
        return AppTheme.catElectrician;
      case 'shop':
        return AppTheme.catGrocery;
      case 'transport':
        return AppTheme.catTransport;
      case 'delivery':
        return AppTheme.catDelivery;
      case 'events':
        return AppTheme.catEvents;
      case 'beauty':
        return AppTheme.catBeauty;
      default:
        return AppTheme.primary;
    }
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
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
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$min $period';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _handleReorder(Map<String, dynamic> order) async {
    final orderId = order['id'] as String?;
    if (orderId == null) return;

    setState(() => _reorderingId = orderId);

    final result = await SupabaseService.instance.reorderService(order);

    if (!mounted) return;
    setState(() => _reorderingId = null);

    if (result != null) {
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order placed! #${result['order_number']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order. Please try again.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'My Orders',
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
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.secondary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          tabs: [
            _buildTab('All', _orders.length),
            _buildTab('Active', _filteredOrders('active').length),
            _buildTab('Pending', _filteredOrders('pending').length),
            _buildTab('Completed', _filteredOrders('completed').length),
            _buildTab('Cancelled', _filteredOrders('cancelled').length),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineBannerWidget(onRetry: _loadOrders),
          if (_cacheAge != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8E1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Showing cached data · $_cacheAge',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFFE65100),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LoadingSkeletonWidget(
                        width: double.infinity,
                        height: 90,
                        borderRadius: 14,
                      ),
                    ),
                  )
                : _hasError
                ? RetryWidget(onRetry: _loadOrders)
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    color: AppTheme.primary,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OrderList(
                          orders: _orders,
                          onOrderTap: _showOrderDetail,
                          onReorder: _handleReorder,
                          reorderingId: _reorderingId,
                          getCategoryIcon: _getCategoryIcon,
                          getCategoryColor: _getCategoryColor,
                          formatTimestamp: _formatTimestamp,
                        ),
                        _OrderList(
                          orders: _filteredOrders('active'),
                          onOrderTap: _showOrderDetail,
                          onReorder: _handleReorder,
                          reorderingId: _reorderingId,
                          getCategoryIcon: _getCategoryIcon,
                          getCategoryColor: _getCategoryColor,
                          formatTimestamp: _formatTimestamp,
                        ),
                        _OrderList(
                          orders: _filteredOrders('pending'),
                          onOrderTap: _showOrderDetail,
                          onReorder: _handleReorder,
                          reorderingId: _reorderingId,
                          getCategoryIcon: _getCategoryIcon,
                          getCategoryColor: _getCategoryColor,
                          formatTimestamp: _formatTimestamp,
                        ),
                        _OrderList(
                          orders: _filteredOrders('completed'),
                          onOrderTap: _showOrderDetail,
                          onReorder: _handleReorder,
                          reorderingId: _reorderingId,
                          getCategoryIcon: _getCategoryIcon,
                          getCategoryColor: _getCategoryColor,
                          formatTimestamp: _formatTimestamp,
                        ),
                        _OrderList(
                          orders: _filteredOrders('cancelled'),
                          onOrderTap: _showOrderDetail,
                          onReorder: _handleReorder,
                          reorderingId: _reorderingId,
                          getCategoryIcon: _getCategoryIcon,
                          getCategoryColor: _getCategoryColor,
                          formatTimestamp: _formatTimestamp,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final color = _getCategoryColor(order['category'] as String?);
    final icon = _getCategoryIcon(order['category'] as String?);
    final provider = order['provider'] as Map<String, dynamic>?;
    final status = order['status'] as String? ?? '';
    final canReorder = status == 'completed' || status == 'cancelled';
    final canTrack =
        status == 'active' || status == 'pending' || status == 'upcoming';
    final canReview =
        status == 'completed' &&
        (order['reviewed'] == null || order['reviewed'] == false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['provider_name'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          Text(
                            order['service'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Status Timeline
                    _StatusTimeline(status: status),
                    const SizedBox(height: 16),

                    // Order Info Card
                    _SectionCard(
                      title: 'Order Details',
                      icon: Icons.receipt_long_rounded,
                      children: [
                        _DetailRow(
                          icon: Icons.tag_rounded,
                          label: 'Order ID',
                          value: order['order_number'] as String? ?? '',
                        ),
                        _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Placed On',
                          value: _formatTimestamp(
                            order['created_at'] as String?,
                          ),
                        ),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Scheduled',
                          value:
                              '${order['scheduled_date'] ?? ''} at ${order['scheduled_time'] ?? ''}',
                        ),
                        _DetailRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Amount',
                          value: order['amount'] != null
                              ? (order['amount'].toString().startsWith('₹')
                                  ? '${order['amount']}'
                                  : '₹${order['amount']}')
                              : '',
                        ),
                        if (order['status'] == 'active' || order['status'] == 'pending')
                          _DetailRow(
                            icon: Icons.pin_rounded,
                            label: 'Completion OTP',
                            value: '${order['completion_otp'] ?? 'N/A'}',
                          ),
                        if ((order['notes'] as String? ?? '').isNotEmpty)
                          _DetailRow(
                            icon: Icons.notes_rounded,
                            label: 'Notes',
                            value: order['notes'] as String? ?? '',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Provider Details Card
                    if (provider != null)
                      _SectionCard(
                        title: 'Provider Details',
                        icon: Icons.store_rounded,
                        children: [_ProviderDetailRow(provider: provider)],
                      ),

                    if (order['rating'] != null) ...[
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Your Rating',
                        icon: Icons.star_rounded,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (order['rating'] as int)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFC107),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (canTrack) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.orderStatusScreen,
                              arguments: {'order_id': order['id']},
                            );
                          },
                          icon: const Icon(Icons.location_on_rounded, size: 18),
                          label: Text(
                            'Track Order',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (canReview) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.pushNamed(
                              context,
                              AppRoutes.reviewSubmissionScreen,
                              arguments: {
                                'order_id': order['id'],
                                'provider_id': order['provider_id'],
                                'provider_name': order['provider_name'],
                                'service': order['service'],
                                'order_number': order['order_number'],
                              },
                            );
                            if (result == true) {
                              await _loadOrders();
                            }
                          },
                          icon: const Icon(
                            Icons.star_outline_rounded,
                            size: 18,
                            color: Color(0xFFFFC107),
                          ),
                          label: Text(
                            'Write a Review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFFFC107),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (canReorder) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _reorderingId == order['id']
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _handleReorder(order);
                                },
                          icon: _reorderingId == order['id']
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.replay_rounded, size: 18),
                          label: Text(
                            _reorderingId == order['id']
                                ? 'Placing Order...'
                                : 'Reorder This Service',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
      ),
    );
  }
}

// ─── ORDER LIST ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ValueChanged<Map<String, dynamic>> onOrderTap;
  final Future<void> Function(Map<String, dynamic>) onReorder;
  final String? reorderingId;
  final IconData Function(String?) getCategoryIcon;
  final Color Function(String?) getCategoryColor;
  final String Function(String?) formatTimestamp;

  const _OrderList({
    required this.orders,
    required this.onOrderTap,
    required this.onReorder,
    required this.reorderingId,
    required this.getCategoryIcon,
    required this.getCategoryColor,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppTheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your orders will appear here',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final color = getCategoryColor(order['category'] as String?);
        final icon = getCategoryIcon(order['category'] as String?);
        final status = order['status'] as String? ?? '';
        final canReorder = status == 'completed' || status == 'cancelled';
        final provider = order['provider'] as Map<String, dynamic>?;
        final isReordering = reorderingId == order['id'];

        return GestureDetector(
          onTap: () => onOrderTap(order),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
              border: Border(left: BorderSide(color: color, width: 3.5)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
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
                                    order['provider_name'] as String? ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1C1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _StatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order['service'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF74777F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Provider details row
                            if (provider != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.store_rounded,
                                    size: 12,
                                    color: Color(0xFF90A4AE),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      provider['business_name'] as String? ??
                                          '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: const Color(0xFF90A4AE),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if ((provider['rating'] as num?) != null) ...[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: Color(0xFFFFC107),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${provider['rating']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF44474E),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Color(0xFF90A4AE),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formatTimestamp(
                                      order['created_at'] as String?,
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF90A4AE),
                                    ),
                                  ),
                                ),
                                Text(
                                  order['amount'] != null
                                      ? (order['amount'].toString().startsWith('₹')
                                          ? '${order['amount']}'
                                          : '₹${order['amount']}')
                                      : '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Reorder quick action
                if (canReorder)
                  InkWell(
                    onTap: isReordering ? null : () => onReorder(order),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isReordering)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.replay_rounded,
                              size: 15,
                              color: AppTheme.primary,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isReordering ? 'Placing...' : 'Reorder',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── STATUS TIMELINE ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt_rounded},
    {
      'key': 'active',
      'label': 'In Progress',
      'icon': Icons.engineering_rounded,
    },
    {
      'key': 'completed',
      'label': 'Completed',
      'icon': Icons.check_circle_rounded,
    },
  ];

  int get _currentIndex {
    switch (status) {
      case 'pending':
        return 0;
      case 'active':
      case 'upcoming':
        return 1;
      case 'completed':
        return 2;
      default:
        return -1; // cancelled
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 20),
            const SizedBox(width: 10),
            Text(
              'This order was cancelled',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      );
    }

    final current = _currentIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone
                    ? AppTheme.primary
                    : AppTheme.outline.withValues(alpha: 0.3),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final step = _steps[stepIndex];
          final isDone = stepIndex < current;
          final isActive = stepIndex == current;
          final iconData = step['icon'] as IconData;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? AppTheme.primary
                      : AppTheme.outline.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 18,
                  color: isDone || isActive ? Colors.white : AppTheme.outline,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step['label'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppTheme.primary
                      : isDone
                      ? const Color(0xFF44474E)
                      : AppTheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── PROVIDER DETAIL ROW ─────────────────────────────────────────────────────

class _ProviderDetailRow extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _ProviderDetailRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final imageUrl = provider['image_url'] as String? ?? '';
    final rating = provider['rating'];
    final phone = provider['phone'] as String? ?? '';
    final city = provider['city'] as String? ?? '';
    final address = provider['address'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.surfaceVariant,
                        child: const Icon(
                          Icons.store_rounded,
                          color: AppTheme.outline,
                        ),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: AppTheme.outline,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['business_name'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  if (rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$rating',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: phone),
        ],
        if (city.isNotEmpty) ...[
          _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'City',
            value: city,
          ),
        ],
        if (address.isNotEmpty) ...[
          _DetailRow(icon: Icons.map_rounded, label: 'Address', value: address),
        ],
      ],
    );
  }
}

// ─── SECTION CARD ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF44474E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        bg = AppTheme.successContainer;
        fg = AppTheme.success;
        label = 'Done';
        icon = Icons.check_circle_rounded;
        break;
      case 'active':
        bg = const Color(0xFFE3F2FD);
        fg = AppTheme.primary;
        label = 'Active';
        icon = Icons.play_circle_rounded;
        break;
      case 'pending':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'upcoming':
        bg = const Color(0xFFF3E5F5);
        fg = const Color(0xFF7B1FA2);
        label = 'Upcoming';
        icon = Icons.schedule_rounded;
        break;
      case 'cancelled':
        bg = AppTheme.errorContainer;
        fg = AppTheme.error;
        label = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = AppTheme.surfaceVariant;
        fg = AppTheme.outline;
        label = status;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DETAIL ROW ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

