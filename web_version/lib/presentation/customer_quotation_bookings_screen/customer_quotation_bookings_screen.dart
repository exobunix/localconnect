import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class CustomerQuotationBookingsScreen extends StatefulWidget {
  const CustomerQuotationBookingsScreen({super.key});

  @override
  State<CustomerQuotationBookingsScreen> createState() =>
      _CustomerQuotationBookingsScreenState();
}

class _CustomerQuotationBookingsScreenState
    extends State<CustomerQuotationBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _newBookings = [];
  List<Map<String, dynamic>> _confirmedBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];

  RealtimeChannel? _realtimeChannel;
  final Set<String> _processingIds = {};

  static const _tabs = [
    {'label': 'New', 'icon': Icons.fiber_new_rounded},
    {'label': 'Confirmed', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'In Progress', 'icon': Icons.autorenew_rounded},
    {'label': 'Completed', 'icon': Icons.task_alt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      await _fetchBookings();
      _subscribeRealtime();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBookings() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _error = 'Please log in to view your bookings.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await SupabaseService.instance.client
          .from('orders')
          .select(
            '*, provider:provider_id(id, business_name, phone, whatsapp, rating, image_url, city, category, address)',
          )
          .eq('customer_id', userId)
          .like('order_number', 'ORD-Q-%')
          .order('created_at', ascending: false);

      final all = List<Map<String, dynamic>>.from(response);

      final newList = <Map<String, dynamic>>[];
      final confirmedList = <Map<String, dynamic>>[];
      final inProgressList = <Map<String, dynamic>>[];
      final completedList = <Map<String, dynamic>>[];

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
          case 'completed':
            completedList.add(b);
            break;
          default:
            if (status != 'cancelled') newList.add(b);
        }
      }

      if (mounted) {
        setState(() {
          _newBookings = newList;
          _confirmedBookings = confirmedList;
          _inProgressBookings = inProgressList;
          _completedBookings = completedList;
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

  void _subscribeRealtime() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.instance.client
        .channel('customer_quotation_bookings_$userId')
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
            if (mounted) _fetchBookings();
          },
        )
        .subscribe();
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final id = booking['id'] as String?;
    if (id == null) return;

    final confirmed = await _confirmDialog(
      'Cancel Booking',
      'Are you sure you want to cancel this booking? This action cannot be undone.',
      confirmLabel: 'Cancel Booking',
      confirmColor: AppTheme.error,
    );
    if (!confirmed) return;

    setState(() => _processingIds.add(id));
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      if (mounted) {
        _showSnack('Booking cancelled successfully.', isSuccess: true);
        await _fetchBookings();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to cancel booking. Please try again.');
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _rescheduleBooking(Map<String, dynamic> booking) async {
    final id = booking['id'] as String?;
    if (id == null) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() => _processingIds.add(id));
    try {
      final newDate =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      final newTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00';

      await SupabaseService.instance.client
          .from('orders')
          .update({
            'scheduled_date': newDate,
            'scheduled_time': newTime,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      if (mounted) {
        _showSnack('Booking rescheduled successfully!', isSuccess: true);
        await _fetchBookings();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to reschedule. Please try again.');
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _callProvider(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnack('Provider phone number not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) _showSnack('Unable to make call.');
    }
  }

  Future<void> _whatsappProvider(String? phone) async {
    if (phone == null || phone.isEmpty) {
      _showSnack('Provider WhatsApp number not available.');
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) _showSnack('Unable to open WhatsApp.');
    }
  }

  Future<bool> _confirmDialog(
    String title,
    String body, {
    String confirmLabel = 'Confirm',
    Color? confirmColor,
  }) async {
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
            child: Text(
              'Go Back',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
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

  String _fmtAmount(dynamic val) {
    if (val == null) return '₹0';
    final amount = val is num
        ? val.toDouble()
        : double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _providerName(Map<String, dynamic> booking) {
    final p = booking['provider'];
    if (p is Map) return (p['business_name'] as String?) ?? 'Unknown Provider';
    return 'Unknown Provider';
  }

  String _providerPhone(Map<String, dynamic> booking) {
    final p = booking['provider'];
    if (p is Map) return (p['phone'] as String?) ?? '';
    return '';
  }

  String _providerWhatsapp(Map<String, dynamic> booking) {
    final p = booking['provider'];
    if (p is Map) {
      final wa = p['whatsapp'] as String?;
      if (wa != null && wa.isNotEmpty) return wa;
      return (p['phone'] as String?) ?? '';
    }
    return '';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF1565C0);
      case 'active':
      case 'confirmed':
        return const Color(0xFF2E7D32);
      case 'in_progress':
      case 'upcoming':
        return const Color(0xFF6A1B9A);
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  Color _statusBg(String status) {
    return _statusColor(status).withValues(alpha: 0.1);
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
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
        return status.toUpperCase();
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.fiber_new_rounded;
      case 'active':
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'in_progress':
      case 'upcoming':
        return Icons.autorenew_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
    final total =
        _newBookings.length +
        _confirmedBookings.length +
        _inProgressBookings.length +
        _completedBookings.length;

    return PreferredSize(
      preferredSize: const Size.fromHeight(116),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Bookings',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'From accepted quotations',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$total total',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _loadBookings,
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  _buildTab('New', _newBookings.length),
                  _buildTab('Confirmed', _confirmedBookings.length),
                  _buildTab('In Progress', _inProgressBookings.length),
                  _buildTab('Completed', _completedBookings.length),
                ],
              ),
            ],
          ),
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
          emptyMsg: 'No new bookings',
          emptySubMsg: 'Bookings from accepted quotations will appear here.',
          emptyIcon: Icons.inbox_outlined,
          showCancel: true,
          showReschedule: true,
        ),
        _buildList(
          _confirmedBookings,
          emptyMsg: 'No confirmed bookings',
          emptySubMsg: 'Bookings confirmed by the provider will appear here.',
          emptyIcon: Icons.check_circle_outline_rounded,
          showCancel: true,
          showReschedule: true,
        ),
        _buildList(
          _inProgressBookings,
          emptyMsg: 'No in-progress bookings',
          emptySubMsg: 'Active service bookings will appear here.',
          emptyIcon: Icons.autorenew_rounded,
          showCancel: false,
          showReschedule: false,
        ),
        _buildList(
          _completedBookings,
          emptyMsg: 'No completed bookings',
          emptySubMsg: 'Your completed service bookings will appear here.',
          emptyIcon: Icons.task_alt_rounded,
          showCancel: false,
          showReschedule: false,
          showReview: true,
          onReview: _leaveReview,
        ),
      ],
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String emptyMsg,
    required String emptySubMsg,
    required IconData emptyIcon,
    required bool showCancel,
    required bool showReschedule,
    bool showReview = false,
    void Function(Map<String, dynamic>)? onReview,
  }) {
    if (items.isEmpty) {
      return _buildEmpty(emptyMsg, emptySubMsg, emptyIcon);
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _BookingCard(
          booking: items[i],
          isProcessing: _processingIds.contains(items[i]['id']),
          showCancel: showCancel,
          showReschedule: showReschedule,
          showReview: showReview,
          onCancel: () => _cancelBooking(items[i]),
          onReschedule: () => _rescheduleBooking(items[i]),
          onCall: () => _callProvider(_providerPhone(items[i])),
          onWhatsApp: () => _whatsappProvider(_providerWhatsapp(items[i])),
          onReview: onReview != null ? () => onReview(items[i]) : null,
          fmtDate: _fmtDate,
          fmtAmount: _fmtAmount,
          providerName: _providerName(items[i]),
          statusColor: _statusColor,
          statusBg: _statusBg,
          statusLabel: _statusLabel,
          statusIcon: _statusIcon,
        ),
      ),
    );
  }

  Widget _buildEmpty(String msg, String sub, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
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
              child: Icon(icon, size: 38, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Try Again',
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

  void _leaveReview(Map<String, dynamic> booking) {
    final provider = booking['provider'];
    final providerName = provider is Map
        ? (provider['business_name'] as String?) ?? 'Provider'
        : 'Provider';
    Navigator.pushNamed(
      context,
      '/review-submission-screen',
      arguments: {
        'order_id': booking['id'],
        'provider_id': booking['provider_id'],
        'provider_name': providerName,
        'service': (booking['service_name'] as String?) ?? 'Service',
        'order_number': (booking['order_number'] as String?) ?? '',
      },
    ).then((result) {
      if (result == true && mounted) _fetchBookings();
    });
  }
}

// ─── Booking Card Widget ───────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isProcessing;
  final bool showCancel;
  final bool showReschedule;
  final bool showReview;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback? onReview;
  final String Function(String?) fmtDate;
  final String Function(dynamic) fmtAmount;
  final String providerName;
  final Color Function(String) statusColor;
  final Color Function(String) statusBg;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;

  const _BookingCard({
    required this.booking,
    required this.isProcessing,
    required this.showCancel,
    required this.showReschedule,
    this.showReview = false,
    required this.onCancel,
    required this.onReschedule,
    required this.onCall,
    required this.onWhatsApp,
    this.onReview,
    required this.fmtDate,
    required this.fmtAmount,
    required this.providerName,
    required this.statusColor,
    required this.statusBg,
    required this.statusLabel,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final status = (booking['status'] as String?) ?? 'pending';
    final orderNum = (booking['order_number'] as String?) ?? '—';
    final serviceName = (booking['service_name'] as String?) ?? 'Service';
    final scheduledDate = booking['scheduled_date'] as String?;
    final scheduledTime = booking['scheduled_time'] as String?;
    final amount = booking['total_amount'];
    final notes = (booking['notes'] as String?) ?? '';
    final address = (booking['address'] as String?) ?? '';

    final sColor = statusColor(status);
    final sBg = statusBg(status);
    final sLabel = statusLabel(status);
    final sIcon = statusIcon(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: sBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(sIcon, size: 16, color: sColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNum,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.outline,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        serviceName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    color: sBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    sLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sColor,
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
                // Provider
                _InfoRow(
                  icon: Icons.store_rounded,
                  label: 'Provider',
                  value: providerName,
                  iconColor: AppTheme.primary,
                ),
                const SizedBox(height: 8),

                // Schedule
                if (scheduledDate != null) ...[
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Scheduled',
                    value: [
                      fmtDate(scheduledDate),
                      if (scheduledTime != null && scheduledTime.isNotEmpty)
                        _fmtTime(scheduledTime),
                    ].join(' at '),
                    iconColor: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 8),
                ],

                // Amount
                _InfoRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Amount',
                  value: fmtAmount(amount),
                  iconColor: const Color(0xFF2E7D32),
                ),

                // Address
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: address,
                    iconColor: AppTheme.error,
                  ),
                ],

                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    value: notes,
                    iconColor: AppTheme.outline,
                  ),
                ],

                // Status progress indicator
                const SizedBox(height: 14),
                _StatusProgress(status: status),

                // Action buttons
                const SizedBox(height: 14),
                _buildActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $ampm';
  }

  Widget _buildActions(BuildContext context) {
    final reviewed = booking['reviewed'] as bool? ?? false;
    final paymentStatus = (booking['payment_status'] as String?) ?? 'pending';
    final status = (booking['status'] as String?) ?? 'pending';
    final isPaid = paymentStatus == 'paid';
    final canPay =
        !isPaid &&
        (status == 'pending' ||
            status == 'confirmed' ||
            status == 'active' ||
            status == 'in_progress' ||
            status == 'upcoming');

    return Column(
      children: [
        // Pay Now button (shown when not yet paid)
        if (canPay) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/quotation-payment-screen',
                  arguments: {'booking': booking},
                );
              },
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: Text(
                'Pay Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Paid badge
        if (isPaid) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Payment Completed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Contact buttons
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: const Color(0xFF1565C0),
                onTap: onCall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF2E7D32),
                onTap: onWhatsApp,
              ),
            ),
          ],
        ),

        // Cancel / Reschedule buttons
        if (showCancel || showReschedule) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (showReschedule)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : onReschedule,
                    icon: const Icon(Icons.schedule_rounded, size: 15),
                    label: Text(
                      'Reschedule',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (showCancel && showReschedule) const SizedBox(width: 8),
              if (showCancel)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : onCancel,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined, size: 15),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Rate & Review button for completed bookings
        if (showReview) ...[
          const SizedBox(height: 8),
          reviewed
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reviewed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: Text(
                      'Rate & Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57F17),
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
      ],
    );
  }
}

// ─── Status Progress ──────────────────────────────────────────────────────

class _StatusProgress extends StatelessWidget {
  final String status;

  const _StatusProgress({required this.status});

  static const _steps = [
    {'key': 'pending', 'label': 'New'},
    {'key': 'confirmed', 'label': 'Confirmed'},
    {'key': 'in_progress', 'label': 'In Progress'},
    {'key': 'completed', 'label': 'Done'},
  ];

  int _stepIndex(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return 0;
      case 'active':
      case 'confirmed':
        return 1;
      case 'in_progress':
      case 'upcoming':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 14, color: AppTheme.error),
            const SizedBox(width: 6),
            Text(
              'This booking was cancelled',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final current = _stepIndex(status);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = (i + 1) ~/ 2;
          final isActive = stepIdx <= current;
          return Expanded(
            child: Container(
              height: 2,
              color: isActive
                  ? AppTheme.primary
                  : AppTheme.outline.withValues(alpha: 0.3),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx < current;
        final isCurrent = stepIdx == current;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isCurrent
                    ? AppTheme.primary
                    : AppTheme.outline.withValues(alpha: 0.3),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    )
                  : isCurrent
                  ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              _steps[stepIdx]['label']!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent || isDone
                    ? AppTheme.primary
                    : AppTheme.outline,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF1A1C1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

