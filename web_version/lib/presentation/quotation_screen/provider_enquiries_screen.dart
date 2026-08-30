import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../services/quotation_realtime_service.dart';
import '../../theme/app_theme.dart';
import './provider_quotation_builder_screen.dart';

/// Provider side: View incoming customer enquiries, reply with messages/quotes, and manage leads
class ProviderEnquiriesScreen extends StatefulWidget {
  final String? initialStatusFilter;
  const ProviderEnquiriesScreen({super.key, this.initialStatusFilter});

  @override
  State<ProviderEnquiriesScreen> createState() => _ProviderEnquiriesScreenState();
}

class _ProviderEnquiriesScreenState extends State<ProviderEnquiriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _enquiries = [];
  String? _error;

  final List<String> _tabs = [
    'All',
    'Pending',
    'Quoted',
    'Accepted',
    'Completed',
  ];

  RealtimeChannel? _enquiriesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    if (widget.initialStatusFilter != null) {
      final tabIndex = _tabs.indexWhere(
        (t) => t.toLowerCase() == widget.initialStatusFilter!.toLowerCase(),
      );
      if (tabIndex >= 0) _tabController.index = tabIndex;
    }
    _loadEnquiries();
    _subscribeToEnquiries();
    QuotationRealtimeService.instance.startListening();
  }

  @override
  void dispose() {
    _enquiriesSubscription?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToEnquiries() {
    try {
      final client = SupabaseService.instance.client;
      _enquiriesSubscription = client
          .channel('public:enquiries_provider_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'enquiries',
            callback: (payload) {
              debugPrint('[ProviderEnquiriesScreen] Realtime change: ${payload.eventType}');
              _loadEnquiries();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[ProviderEnquiriesScreen] Subscription error: $e');
    }
  }

  Future<void> _loadEnquiries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.getProviderEnquiries();
      if (mounted) setState(() => _enquiries = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load enquiries. Please pull to refresh.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filteredEnquiries(String tab) {
    if (tab == 'All') return _enquiries;
    final tabLower = tab.toLowerCase();
    return _enquiries.where((e) {
      final status = (e['status'] ?? '').toString().toLowerCase();
      if (tabLower == 'quoted') {
        return status == 'quoted' || (e['provider_reply'] != null && e['provider_reply'].toString().trim().isNotEmpty);
      }
      return status == tabLower;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _enquiries.where((e) => (e['status'] ?? 'pending').toLowerCase() == 'pending').length;
    final quotedCount = _enquiries.where((e) => (e['status'] ?? '').toLowerCase() == 'quoted' || (e['provider_reply'] != null && e['provider_reply'].toString().trim().isNotEmpty)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Customer Enquiries',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEnquiries,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w700,
          ),
          tabs: _tabs.map((t) {
            int count = _filteredEnquiries(t).length;
            return Tab(text: '$t ($count)');
          }).toList(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // Stats banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          _buildStatBadge(
                            'Total Leads',
                            '${_enquiries.length}',
                            const Color(0xFF2563EB),
                            Icons.inbox_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildStatBadge(
                            'Pending Reply',
                            '$pendingCount',
                            const Color(0xFFD97706),
                            Icons.hourglass_top_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildStatBadge(
                            'Responded',
                            '$quotedCount',
                            const Color(0xFF16A34A),
                            Icons.check_circle_rounded,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: _tabs.map((tab) {
                          final list = _filteredEnquiries(tab);
                          if (list.isEmpty) return _buildEmptyView(tab);
                          return RefreshIndicator(
                            onRefresh: _loadEnquiries,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (ctx, i) => _buildProviderEnquiryCard(list[i]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEnquiries,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, color: Colors.grey[300], size: 60),
            const SizedBox(height: 12),
            Text(
              'No $tab enquiries found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When customers send requirements or quote requests, they will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderEnquiryCard(Map<String, dynamic> item) {
    final enquiryId = item['id']?.toString() ?? '';
    final refDisplay = enquiryId.length > 12
        ? '#ENQ-${enquiryId.substring(0, 8)}'
        : (enquiryId.isNotEmpty ? '#$enquiryId' : '#ENQ');
    final customerName = item['customer_name'] as String? ?? 'Customer';
    final customerPhone = item['customer_phone'] as String? ?? '';
    final serviceTitle = item['service_title'] as String? ?? item['title'] as String? ?? 'Service Requirement';
    final category = item['category'] as String? ?? '';
    final subcategory = item['subcategory'] as String? ?? '';
    final preferredDate = item['preferred_date'] as String? ?? '';
    final preferredTime = item['preferred_time'] as String? ?? '';
    final message = item['message'] as String? ?? item['description'] as String? ?? '';
    final status = (item['status'] as String? ?? 'pending').toLowerCase();
    final providerReply = item['provider_reply'] as String? ?? '';
    final repliedAt = item['replied_at'] != null ? _formatDate(item['replied_at']) : '';
    final createdAt = _formatDate(item['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? Colors.amber.shade300
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    refDisplay,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subcategory.isNotEmpty ? '$category • $subcategory' : category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                const Spacer(),
                _statusBadge(status),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Title
                Text(
                  serviceTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Customer info card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (customerPhone.isNotEmpty)
                              Text(
                                customerPhone,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (customerPhone.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.call_rounded, color: Colors.green, size: 20),
                          onPressed: () => _launchUrl('tel:$customerPhone'),
                          tooltip: 'Call Customer',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                          onPressed: () => _launchUrl('https://wa.me/${customerPhone.replaceAll('+', '').replaceAll(RegExp(r'\D'), '')}'),
                          tooltip: 'WhatsApp Customer',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Preferred schedule
                if (preferredDate.isNotEmpty || preferredTime.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Requested for: $preferredDate ($preferredTime)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Customer message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Requirement Details:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.isNotEmpty ? message : 'No details provided.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Provider existing reply (if present)
                if (providerReply.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              'Your Reply to Customer:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const Spacer(),
                            if (repliedAt.isNotEmpty)
                              Text(
                                repliedAt,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          providerReply,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action buttons
                Row(
                  children: [
                    // Reply Modal Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReplyDialog(enquiryId, customerName, providerReply),
                        icon: const Icon(Icons.reply_rounded, size: 16),
                        label: Text(
                          providerReply.isNotEmpty ? 'Edit Reply' : 'Reply / Quote',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Live Chat Button
                    ElevatedButton.icon(
                      onPressed: () => _openChatWithCustomer(item),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                      label: Text(
                        'Live Chat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quotation Builder button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderQuotationBuilderScreen(
                              enquiry: item,
                            ),
                          ),
                        ).then((_) => _loadEnquiries());
                      },
                      icon: const Icon(Icons.request_quote_rounded, size: 16),
                      label: Text(
                        'Quote',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Status updater dropdown row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Received: $createdAt',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        await SupabaseService.instance.updateEnquiryStatus(
                          enquiryId: enquiryId,
                          status: val,
                        );
                        _loadEnquiries();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Change Status',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF475569)),
                          ],
                        ),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                        const PopupMenuItem(value: 'quoted', child: Text('Mark as Quoted')),
                        const PopupMenuItem(value: 'accepted', child: Text('Mark as Accepted')),
                        const PopupMenuItem(value: 'completed', child: Text('Mark as Completed')),
                        const PopupMenuItem(value: 'cancelled', child: Text('Mark as Cancelled')),
                      ],
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

  void _showReplyDialog(String enquiryId, String customerName, String existingReply) {
    final replyCtrl = TextEditingController(text: existingReply);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.reply_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reply to $customerName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your estimate, availability, or message for the customer:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: replyCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. Hi! I can visit tomorrow at 11 AM. Estimated charge will be ₹350. Please confirm if that works.',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final text = replyCtrl.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await SupabaseService.instance.replyToEnquiry(
                    enquiryId: enquiryId,
                    replyText: text,
                    status: 'quoted',
                  );
                  if (mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Reply sent to customer and synced to Live Chat!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    }
                    _loadEnquiries();
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Send Reply to Customer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithCustomer(Map<String, dynamic> enquiry) async {
    final customerId = enquiry['customer_id']?.toString() ?? '';
    final customerName = enquiry['customer_name']?.toString() ?? 'Customer';
    final providerId = enquiry['provider_id']?.toString() ?? '';
    final currentUserId = SupabaseService.instance.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a provider to chat')),
      );
      return;
    }

    final conv = await SupabaseService.instance.getOrCreateConversation(
      providerUserId: currentUserId,
      providerServiceId: providerId,
    );

    if (!mounted) return;

    if (conv != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetailScreen,
        arguments: {
          'conversationId': conv['id'],
          'otherUserId': customerId,
          'otherUserName': customerName,
          'otherUserAvatar': '',
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetailScreen,
        arguments: {
          'conversationId': 'conv_${enquiry['id']}',
          'otherUserId': customerId,
          'otherUserName': customerName,
          'otherUserAvatar': '',
        },
      );
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'quoted':
        return const Color(0xFF0284C7);
      case 'accepted':
        return Colors.green;
      case 'completed':
        return const Color(0xFF059669);
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
