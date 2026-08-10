import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../services/quotation_realtime_service.dart';
import '../../theme/app_theme.dart';

class CustomerReceivedQuotationsScreen extends StatefulWidget {
  final String? initialFilter;
  const CustomerReceivedQuotationsScreen({super.key, this.initialFilter});

  @override
  State<CustomerReceivedQuotationsScreen> createState() =>
      _CustomerReceivedQuotationsScreenState();
}

class _CustomerReceivedQuotationsScreenState
    extends State<CustomerReceivedQuotationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allQuotations = [];
  String? _error;
  String _activeFilter = 'all';

  static const List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'All', 'icon': Icons.list_alt_rounded},
    {'key': 'sent', 'label': 'Pending', 'icon': Icons.hourglass_empty_rounded},
    {
      'key': 'accepted',
      'label': 'Accepted',
      'icon': Icons.check_circle_rounded,
    },
    {'key': 'rejected', 'label': 'Rejected', 'icon': Icons.cancel_rounded},
    {'key': 'expired', 'label': 'Expired', 'icon': Icons.timer_off_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'all';
    _loadQuotations();
    // Start real-time subscription for quotation status changes
    QuotationRealtimeService.instance.startListening();
  }

  @override
  void dispose() {
    // Reload when returning to this screen; realtime service stays alive globally
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.getCustomerQuotations();
      if (mounted) setState(() => _allQuotations = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load quotations.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredQuotations {
    if (_activeFilter == 'all') return _allQuotations;
    if (_activeFilter == 'sent') {
      return _allQuotations
          .where((q) => q['status'] == 'sent' || q['status'] == 'negotiating')
          .toList();
    }
    return _allQuotations.where((q) => q['status'] == _activeFilter).toList();
  }

  int _countForFilter(String key) {
    if (key == 'all') return _allQuotations.length;
    if (key == 'sent') {
      return _allQuotations
          .where((q) => q['status'] == 'sent' || q['status'] == 'negotiating')
          .length;
    }
    return _allQuotations.where((q) => q['status'] == key).length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'expired':
        return const Color(0xFF757575);
      case 'negotiating':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'negotiating':
        return 'Negotiating';
      default:
        return status.toUpperCase();
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      case 'negotiating':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Future<void> _handleAction(
    Map<String, dynamic> quotation,
    String newStatus,
  ) async {
    final id = quotation['id'] as String?;
    if (id == null) return;

    final provider = quotation['provider'] as Map<String, dynamic>? ?? {};
    final enquiry = quotation['enquiry'] as Map<String, dynamic>? ?? {};
    final providerName = provider['business_name'] as String? ?? 'Provider';
    final providerId = provider['id'] as String?;
    final total = (quotation['total_amount'] ?? 0).toDouble();
    final serviceName = (enquiry['title'] as String? ?? '').isNotEmpty
        ? enquiry['title'] as String
        : 'Home Service';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          newStatus == 'accepted' ? 'Accept Quotation?' : 'Reject Quotation?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          newStatus == 'accepted'
              ? 'Accept this quotation from $providerName for ₹${total.toStringAsFixed(2)}? A booking will be created and you\'ll be taken to payment.'
              : 'Are you sure you want to reject this quotation?',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'accepted'
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              newStatus == 'accepted' ? 'Accept & Pay' : 'Reject',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 1. Update quotation status
      await SupabaseService.instance.updateQuotationStatus(
        quotationId: id,
        status: newStatus,
      );

      if (newStatus == 'accepted') {
        // 2. Auto-create a booking (order) from the accepted quotation
        final amountStr = '₹${total.toStringAsFixed(2)}';
        final order = await SupabaseService.instance.createOrderFromQuotation(
          quotationId: id,
          providerName: providerName,
          service: serviceName,
          category: 'Home Service',
          amountStr: amountStr,
          providerId: providerId,
        );

        // 3. Dismiss loading
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quotation accepted! Booking created — proceeding to payment.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        // 4. Navigate to payment screen with pre-filled quotation details
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.customerPaymentScreen,
            arguments: {
              'amount': amountStr,
              'service': serviceName,
              'providerName': providerName,
              'category': 'Home Service',
              'orderNumber':
                  order?['order_number'] as String? ??
                  'ORD-Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              'orderId': order?['id'] as String?,
              'quotationId': id,
              'providerId': providerId,
              'fromQuotation': true,
            },
          );
          _loadQuotations();
        }
      } else {
        // Reject flow — dismiss loading and show snack
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quotation rejected.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: const Color(0xFFC62828),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          _loadQuotations();
        }
      }
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action failed. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Received Quotations',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuotations,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.customerQuotationBookingsScreen,
            ),
            tooltip: 'My Bookings',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _error != null
                ? _buildErrorState()
                : _buildQuotationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.primary,
      child: Column(
        children: [
          // Summary counts row
          Container(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.5.h),
            child: Row(
              children: [
                _buildSummaryChip(
                  'Pending',
                  _countForFilter('sent'),
                  const Color(0xFF1565C0),
                ),
                SizedBox(width: 2.w),
                _buildSummaryChip(
                  'Accepted',
                  _countForFilter('accepted'),
                  const Color(0xFF2E7D32),
                ),
                SizedBox(width: 2.w),
                _buildSummaryChip(
                  'Rejected',
                  _countForFilter('rejected'),
                  const Color(0xFFC62828),
                ),
                SizedBox(width: 2.w),
                _buildSummaryChip(
                  'Expired',
                  _countForFilter('expired'),
                  const Color(0xFF757575),
                ),
              ],
            ),
          ),
          // Filter chips
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isActive = _activeFilter == f['key'];
                  final count = _countForFilter(f['key'] as String);
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _activeFilter = f['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primary
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              f['icon'] as IconData,
                              size: 14,
                              color: isActive ? Colors.white : Colors.grey[600],
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              f['label'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                            if (count > 0) ...[
                              SizedBox(width: 1.w),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : AppTheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0.8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.sp,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
          SizedBox(height: 1.h),
          Text(
            _error!,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[700]),
          ),
          SizedBox(height: 1.5.h),
          ElevatedButton.icon(
            onPressed: _loadQuotations,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: GoogleFonts.plusJakartaSans()),
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
    );
  }

  Widget _buildQuotationList() {
    final items = _filteredQuotations;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.request_quote_rounded,
              color: Colors.grey[300],
              size: 64,
            ),
            SizedBox(height: 1.5.h),
            Text(
              _activeFilter == 'all'
                  ? 'No quotations received yet'
                  : 'No ${_activeFilter == 'sent' ? 'pending' : _activeFilter} quotations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Send an enquiry to a provider to receive quotes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotations,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildQuotationCard(items[i]),
      ),
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> q) {
    final status = q['status'] as String? ?? 'sent';
    final provider = q['provider'] as Map<String, dynamic>? ?? {};
    final enquiry = q['enquiry'] as Map<String, dynamic>? ?? {};
    final providerName = provider['business_name'] as String? ?? 'Provider';
    final total = (q['total_amount'] ?? 0).toDouble();
    final validityDays = q['validity_days'] ?? 7;
    final isPending = status == 'sent' || status == 'negotiating';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    providerName.isNotEmpty
                        ? providerName[0].toUpperCase()
                        : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((enquiry['title'] as String? ?? '').isNotEmpty)
                        Text(
                          enquiry['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 12,
                        color: _statusColor(status),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _statusLabel(status),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Amount highlight ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.secondary.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if ((q['expected_completion_time'] as String? ?? '')
                          .isNotEmpty)
                        _metaChip(
                          Icons.schedule_rounded,
                          q['expected_completion_time'] as String,
                          Colors.blue,
                        ),
                      SizedBox(height: 0.5.h),
                      _metaChip(
                        Icons.event_available_rounded,
                        'Valid $validityDays days',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Charge breakdown ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Column(
              children: [
                if ((q['labour_charges'] ?? 0) > 0)
                  _chargeRow('Labour', q['labour_charges']),
                if ((q['material_charges'] ?? 0) > 0)
                  _chargeRow('Material', q['material_charges']),
                if ((q['visiting_charges'] ?? 0) > 0)
                  _chargeRow('Visiting', q['visiting_charges']),
                if ((q['transportation_charges'] ?? 0) > 0)
                  _chargeRow('Transport', q['transportation_charges']),
                if ((q['equipment_charges'] ?? 0) > 0)
                  _chargeRow('Equipment', q['equipment_charges']),
                if ((q['extra_charges'] ?? 0) > 0)
                  _chargeRow('Extra', q['extra_charges']),
                if ((q['discount'] ?? 0) > 0)
                  _chargeRow(
                    'Discount',
                    -(q['discount'] as num).toDouble(),
                    isDiscount: true,
                  ),
                if ((q['tax_amount'] ?? 0) > 0)
                  _chargeRow('Tax', q['tax_amount']),
              ],
            ),
          ),

          // ── Notes ────────────────────────────────────────────────────────
          if ((q['additional_notes'] as String? ?? '').isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
              child: Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                    SizedBox(width: 1.5.w),
                    Expanded(
                      child: Text(
                        q['additional_notes'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Contact + Actions ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            child: Column(
              children: [
                // Contact row
                Row(
                  children: [
                    if ((provider['phone'] as String? ?? '').isNotEmpty)
                      Expanded(
                        child: _contactButton(
                          icon: Icons.call_rounded,
                          label: 'Call',
                          color: const Color(0xFF1565C0),
                          onTap: () => _launchUrl('tel:${provider['phone']}'),
                        ),
                      ),
                    if ((provider['phone'] as String? ?? '').isNotEmpty &&
                        ((provider['whatsapp_number'] as String? ?? '')
                                .isNotEmpty ||
                            (provider['whatsapp'] as String? ?? '').isNotEmpty))
                      SizedBox(width: 2.w),
                    if ((provider['whatsapp_number'] as String? ?? '')
                            .isNotEmpty ||
                        (provider['whatsapp'] as String? ?? '').isNotEmpty)
                      Expanded(
                        child: _contactButton(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF2E7D32),
                          onTap: () {
                            final wa =
                                (provider['whatsapp_number'] as String? ?? '')
                                    .isNotEmpty
                                ? provider['whatsapp_number'] as String
                                : provider['whatsapp'] as String;
                            _launchUrl(
                              'https://wa.me/${wa.replaceAll(RegExp(r'[^0-9]'), '')}',
                            );
                          },
                        ),
                      ),
                  ],
                ),

                // Accept / Reject buttons (only for pending)
                if (isPending) ...[
                  SizedBox(height: 1.2.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleAction(q, 'rejected'),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(
                            'Reject',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            side: const BorderSide(
                              color: Color(0xFFC62828),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAction(q, 'accepted'),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            'Accept',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.quotationNegotiationScreen,
                        arguments: {'quotation': q, 'role': 'customer'},
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Negotiate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(
                          color: Color(0xFFE65100),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.2.h),
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

  Widget _chargeRow(String label, dynamic amount, {bool isDiscount = false}) {
    final val = (amount as num?)?.toDouble() ?? 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            isDiscount
                ? '-₹${val.abs().toStringAsFixed(0)}'
                : '₹${val.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 1.h),
      ),
    );
  }
}
