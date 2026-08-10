import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Customer side: send enquiries and view received quotations
class CustomerEnquiryScreen extends StatefulWidget {
  final Map<String, dynamic>? provider;
  const CustomerEnquiryScreen({super.key, this.provider});

  @override
  State<CustomerEnquiryScreen> createState() => _CustomerEnquiryScreenState();
}

class _CustomerEnquiryScreenState extends State<CustomerEnquiryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _quotations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuotations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.getCustomerQuotations();
      if (mounted) setState(() => _quotations = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load quotations.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendEnquiry() {
    if (widget.provider == null) {
      _showSendEnquiryDialog(null);
      return;
    }
    _showSendEnquiryDialog(widget.provider);
  }

  void _showSendEnquiryDialog(Map<String, dynamic>? provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 4.w,
          right: 4.w,
          top: 3.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_rounded, color: AppTheme.primary),
                SizedBox(width: 2.w),
                Text(
                  'Send Enquiry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (provider != null) ...[
              SizedBox(height: 1.h),
              Text(
                'To: ${provider['business_name'] ?? 'Provider'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 2.h),
            _sheetField(
              titleCtrl,
              'Service Title *',
              'e.g. Fix leaking pipe in bathroom',
            ),
            SizedBox(height: 2.h),
            _sheetField(
              descCtrl,
              'Describe your requirement *',
              'Provide details about what you need, location, urgency, etc.',
              maxLines: 4,
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      descCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fill all required fields.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await SupabaseService.instance.sendEnquiry(
                      providerId: provider?['id'] as String? ?? '',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      category: provider?['category'] as String? ?? '',
                      subcategory: provider?['subcategory'] as String? ?? '',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Enquiry sent! Provider will respond soon.',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      _loadQuotations();
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to send enquiry.',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Send Enquiry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.8.h),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFFB0BEC5),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
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
          'My Quotations',
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
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Received Quotes'),
            Tab(text: 'My Enquiries'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendEnquiry,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded),
        label: Text(
          'New Enquiry',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 40,
                  ),
                  SizedBox(height: 1.h),
                  Text(_error!, style: GoogleFonts.plusJakartaSans()),
                  SizedBox(height: 1.h),
                  ElevatedButton(
                    onPressed: _loadQuotations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildQuotationsList(), _buildEnquiriesList()],
            ),
    );
  }

  Widget _buildQuotationsList() {
    final quotes = _quotations.where((q) => q['status'] != 'draft').toList();
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.request_quote_rounded,
              color: Colors.grey[300],
              size: 60,
            ),
            SizedBox(height: 1.h),
            Text(
              'No quotations yet',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
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
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: quotes.length,
        itemBuilder: (ctx, i) => _buildQuotationCard(quotes[i]),
      ),
    );
  }

  Widget _buildEnquiriesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.instance.getCustomerEnquiries(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        final enquiries = snap.data ?? [];
        if (enquiries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, color: Colors.grey[300], size: 60),
                SizedBox(height: 1.h),
                Text(
                  'No enquiries sent yet',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          itemCount: enquiries.length,
          itemBuilder: (ctx, i) => _buildEnquiryCard(enquiries[i]),
        );
      },
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> quotation) {
    final status = quotation['status'] ?? 'sent';
    final provider = quotation['provider'] as Map<String, dynamic>? ?? {};
    final providerName = provider['business_name'] ?? 'Provider';
    final providerWhatsapp =
        provider['whatsapp_number'] ?? provider['whatsapp'] ?? '';
    final providerPhone = provider['phone'] ?? '';
    final total = (quotation['total_amount'] ?? 0).toDouble();
    final validityDays = quotation['validity_days'] ?? 7;
    final enquiry = quotation['enquiry'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
        border: Border.all(
          color: status == 'accepted'
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    providerName.isNotEmpty
                        ? providerName[0].toUpperCase()
                        : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
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
                      ),
                      Text(
                        enquiry['title'] ?? 'Service Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
          ),

          // Quotation details
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total amount highlight
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.08),
                        AppTheme.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.5.h),

                // Breakdown
                if ((quotation['labour_charges'] ?? 0) > 0)
                  _detailRow('Labour', quotation['labour_charges']),
                if ((quotation['material_charges'] ?? 0) > 0)
                  _detailRow('Material', quotation['material_charges']),
                if ((quotation['visiting_charges'] ?? 0) > 0)
                  _detailRow('Visiting', quotation['visiting_charges']),
                if ((quotation['transportation_charges'] ?? 0) > 0)
                  _detailRow('Transport', quotation['transportation_charges']),
                if ((quotation['equipment_charges'] ?? 0) > 0)
                  _detailRow('Equipment', quotation['equipment_charges']),
                if ((quotation['discount'] ?? 0) > 0)
                  _detailRow(
                    'Discount',
                    -(quotation['discount'] as num).toDouble(),
                    isDiscount: true,
                  ),
                if ((quotation['tax_amount'] ?? 0) > 0)
                  _detailRow('Tax', quotation['tax_amount']),

                SizedBox(height: 1.h),

                // Meta
                Row(
                  children: [
                    if ((quotation['expected_completion_time'] ?? '')
                        .isNotEmpty)
                      _metaChip(
                        Icons.schedule_rounded,
                        quotation['expected_completion_time'],
                        Colors.blue,
                      ),
                    SizedBox(width: 2.w),
                    _metaChip(
                      Icons.event_available_rounded,
                      'Valid $validityDays days',
                      Colors.orange,
                    ),
                  ],
                ),

                if ((quotation['additional_notes'] ?? '').isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Container(
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
                            quotation['additional_notes'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 1.5.h),

                // Action buttons
                if (status == 'sent') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateQuotationStatus(
                            quotation['id'],
                            'rejected',
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(
                            'Reject',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateQuotationStatus(
                            quotation['id'],
                            'accepted',
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            'Accept',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                ],

                // Negotiate row
                Row(
                  children: [
                    if (providerPhone.isNotEmpty)
                      _actionBtn(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => _launchUrl('tel:$providerPhone'),
                      ),
                    SizedBox(width: 2.w),
                    if (providerWhatsapp.isNotEmpty)
                      _actionBtn(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _launchUrl(
                          'https://wa.me/${providerWhatsapp.replaceAll('+', '')}',
                        ),
                      ),
                    if (status == 'sent') ...[
                      SizedBox(width: 2.w),
                      _actionBtn(
                        icon: Icons.handshake_rounded,
                        label: 'Negotiate',
                        color: Colors.purple,
                        onTap: () => _updateQuotationStatus(
                          quotation['id'],
                          'negotiating',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryCard(Map<String, dynamic> enquiry) {
    final status = enquiry['status'] ?? 'pending';
    final provider = enquiry['provider'] as Map<String, dynamic>? ?? {};
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inbox_rounded, color: AppTheme.primary, size: 20),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry['title'] ?? 'Service Request',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'To: ${provider['business_name'] ?? 'Provider'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic amount, {bool isDiscount = false}) {
    final val = (amount as num?)?.toDouble() ?? 0;
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
                ? '-₹${val.toStringAsFixed(0)}'
                : '₹${val.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5.sp,
              color: isDiscount ? Colors.green : Colors.black87,
              fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            SizedBox(width: 1.w),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 8.5.sp,
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
      case 'sent':
        return Colors.blue;
      case 'quoted':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return AppTheme.secondary;
      case 'negotiating':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateQuotationStatus(String quotationId, String status) async {
    try {
      await SupabaseService.instance.updateQuotationStatus(
        quotationId: quotationId,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Quotation accepted! Provider will contact you.'
                  : status == 'rejected'
                  ? 'Quotation rejected.'
                  : 'Status updated.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: status == 'accepted'
                ? Colors.green
                : AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadQuotations();
      }
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }
}
