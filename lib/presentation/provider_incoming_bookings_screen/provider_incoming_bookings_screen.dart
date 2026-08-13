import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ProviderIncomingBookingsScreen extends StatefulWidget {
  const ProviderIncomingBookingsScreen({super.key});

  @override
  State<ProviderIncomingBookingsScreen> createState() =>
      _ProviderIncomingBookingsScreenState();
}

class _ProviderIncomingBookingsScreenState
    extends State<ProviderIncomingBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  String? _providerId;

  // Bookings from quotations (ORD-Q- prefix)
  List<Map<String, dynamic>> _newBookings = [];
  List<Map<String, dynamic>> _confirmedBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];

  RealtimeChannel? _realtimeChannel;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadBookings() async {
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
      _providerId = provider['id'] as String;
      await _fetchBookings(_providerId!);
      _subscribeRealtime(_providerId!);
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookings(String providerId) async {
    try {
      final all = await SupabaseService.instance.getProviderQuotationBookings(
        providerId,
      );

      final newList = <Map<String, dynamic>>[];
      final confirmedList = <Map<String, dynamic>>[];
      final inProgressList = <Map<String, dynamic>>[];

      for (final b in all) {
        final status = (b['status'] as String?) ?? 'pending';
        switch (status) {
          case 'pending':
            newList.add(b);
            break;
          case 'active':
          case 'confirmed':
            confirmedList.add(b);
            break;
          case 'in_progress':
          case 'upcoming':
            inProgressList.add(b);
            break;
        }
      }

      if (mounted) {
        setState(() {
          _newBookings = newList;
          _confirmedBookings = confirmedList;
          _inProgressBookings = inProgressList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings.';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeRealtime(String providerId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.instance.client
        .channel('provider_quotation_bookings_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (_) {
            if (mounted) _fetchBookings(providerId);
          },
        )
        .subscribe();
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    setState(() => _processingIds.add(orderId));
    final success = await SupabaseService.instance.updateProviderOrderStatus(
      orderId,
      newStatus,
    );
    if (mounted) {
      setState(() => _processingIds.remove(orderId));
      if (success) {
        _showSnack(_statusActionLabel(newStatus), isSuccess: true);
        if (_providerId != null) await _fetchBookings(_providerId!);
      } else {
        _showSnack('Failed to update status. Please try again.');
      }
    }
  }

  String _statusActionLabel(String status) {
    switch (status) {
      case 'active':
      case 'confirmed':
        return 'Pickup confirmed!';
      case 'in_progress':
        return 'Delivery status updated!';
      case 'completed':
        return 'Booking marked as complete!';
      default:
        return 'Status updated!';
    }
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(body, style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
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
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Incoming Bookings',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildSummaryChip(
                      _newBookings.length +
                          _confirmedBookings.length +
                          _inProgressBookings.length,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  _buildTab('New', _newBookings.length),
                  _buildTab('Confirmed', _confirmedBookings.length),
                  _buildTab('In Progress', _inProgressBookings.length),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count total',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(
          _newBookings,
          emptyMsg: 'No new bookings yet',
          emptySubMsg:
              'New bookings from accepted quotations will appear here.',
          emptyIcon: Icons.inbox_outlined,
        ),
        _buildList(
          _confirmedBookings,
          emptyMsg: 'No confirmed bookings',
          emptySubMsg:
              'Bookings you\'ve confirmed pickup for will appear here.',
          emptyIcon: Icons.check_circle_outline_rounded,
        ),
        _buildList(
          _inProgressBookings,
          emptyMsg: 'No in-progress bookings',
          emptySubMsg: 'Active deliveries in progress will appear here.',
          emptyIcon: Icons.local_shipping_outlined,
        ),
      ],
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String emptyMsg,
    required String emptySubMsg,
    required IconData emptyIcon,
  }) {
    if (items.isEmpty) {
      return _buildEmpty(emptyMsg, emptySubMsg, emptyIcon);
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (_providerId != null) await _fetchBookings(_providerId!);
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildBookingCard(items[i]),
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String? ?? '';
    final orderNumber = booking['order_number'] as String? ?? '—';
    final service =
        booking['service'] as String? ??
        booking['category'] as String? ??
        'Service';
    final customerName = booking['customer_name'] as String? ?? 'Customer';
    final amount = booking['amount'] as String? ?? '—';
    final status = booking['status'] as String? ?? 'pending';
    final notes = booking['notes'] as String? ?? '';
    final scheduledDate = booking['scheduled_date'] as String? ?? '';
    final scheduledTime = booking['scheduled_time'] as String? ?? '';
    final createdAt = booking['created_at'] as String?;
    final isProcessing = _processingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              color: _statusBgColor(status),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    size: 18,
                    color: _statusColor(status),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _statusColor(status),
                        ),
                      ),
                      Text(
                        'Received ${_fmtDate(createdAt)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _statusColor(status).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service & customer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: const Color(0xFF74777F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customerName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        amount.startsWith('₹') ? amount : '₹$amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (scheduledDate.isNotEmpty || scheduledTime.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: const Color(0xFF74777F),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        [
                          scheduledDate,
                          scheduledTime,
                        ].where((s) => s.isNotEmpty).join(' • '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ],

                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 13,
                          color: const Color(0xFF74777F),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF74777F),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEEF0F3)),
                const SizedBox(height: 12),

                // Action buttons
                _buildActionButtons(id, status, isProcessing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String status, bool isProcessing) {
    if (isProcessing) {
      return const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Confirm Pickup',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.success,
                onTap: () async {
                  final ok = await _confirmDialog(
                    'Confirm Pickup',
                    'Confirm that you have received this booking and will proceed with pickup?',
                  );
                  if (ok) await _updateStatus(id, 'active');
                },
              ),
            ),
          ],
        );

      case 'active':
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Start Delivery',
                icon: Icons.local_shipping_outlined,
                color: AppTheme.primary,
                onTap: () async {
                  final ok = await _confirmDialog(
                    'Start Delivery',
                    'Mark this booking as in-progress and start delivery?',
                  );
                  if (ok) await _updateStatus(id, 'in_progress');
                },
              ),
            ),
          ],
        );

      case 'in_progress':
      case 'upcoming':
        return Row(
          children: [
            Expanded(
              child: _actionButton(
                label: 'Mark Complete',
                icon: Icons.task_alt_rounded,
                color: AppTheme.success,
                onTap: () async {
                  final ok = await _confirmDialog(
                    'Mark Complete',
                    'Mark this booking as completed? This action cannot be undone.',
                  );
                  if (ok) await _updateStatus(id, 'completed');
                },
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'New';
      case 'active':
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
      case 'upcoming':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'active':
      case 'confirmed':
        return AppTheme.primary;
      case 'in_progress':
      case 'upcoming':
        return const Color(0xFF6A1B9A);
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return const Color(0xFF74777F);
    }
  }

  Color _statusBgColor(String status) {
    return _statusColor(status).withValues(alpha: 0.06);
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.inbox_rounded;
      case 'active':
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'in_progress':
      case 'upcoming':
        return Icons.local_shipping_outlined;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

