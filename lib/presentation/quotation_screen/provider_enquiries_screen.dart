import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../services/quotation_realtime_service.dart';
import '../../theme/app_theme.dart';
import './provider_quotation_builder_screen.dart';
import '../../routes/app_routes.dart';

/// Provider side: view all enquiries and respond with quotations
class ProviderEnquiriesScreen extends StatefulWidget {
  final String? initialStatusFilter;
  const ProviderEnquiriesScreen({super.key, this.initialStatusFilter});

  @override
  State<ProviderEnquiriesScreen> createState() =>
      _ProviderEnquiriesScreenState();
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Apply initial filter from dashboard if provided
    if (widget.initialStatusFilter != null) {
      final filterMap = {
        'pending': 'Pending',
        'accepted': 'Accepted',
        'rejected': 'Completed',
        'expired': 'All',
      };
      final tabLabel = filterMap[widget.initialStatusFilter] ?? 'All';
      final tabIndex = _tabs.indexOf(tabLabel);
      if (tabIndex >= 0) {
        _tabController.index = tabIndex;
      }
    }
    _loadEnquiries();
    // Start real-time subscription for quotation status changes
    QuotationRealtimeService.instance.startListening();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _error = 'Failed to load enquiries.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filteredEnquiries(String tab) {
    if (tab == 'All') return _enquiries;
    return _enquiries
        .where((e) => (e['status'] ?? '').toLowerCase() == tab.toLowerCase())
        .toList();
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
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
                    onPressed: _loadEnquiries,
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
              children: _tabs.map((tab) {
                final items = _filteredEnquiries(tab);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          color: Colors.grey[300],
                          size: 50,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'No ${tab == 'All' ? '' : tab.toLowerCase()} enquiries',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadEnquiries,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _buildEnquiryCard(items[i]),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEnquiryCard(Map<String, dynamic> enquiry) {
    final status = enquiry['status'] ?? 'pending';
    final customer = enquiry['customer'] as Map<String, dynamic>? ?? {};
    final customerName = customer['full_name'] ?? 'Customer';
    final customerPhone = customer['phone'] ?? '';

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
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : 'C',
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
                        customerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatDate(enquiry['created_at']),
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
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry['title'] ?? 'Service Request',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  enquiry['description'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    _chip(enquiry['category'] ?? '', Colors.blue),
                    if ((enquiry['subcategory'] ?? '').isNotEmpty) ...[
                      SizedBox(width: 2.w),
                      _chip(enquiry['subcategory'], Colors.purple),
                    ],
                  ],
                ),
                SizedBox(height: 1.5.h),

                // Action buttons
                Row(
                  children: [
                    if (customerPhone.isNotEmpty) ...[
                      _actionBtn(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => _launchUrl('tel:$customerPhone'),
                      ),
                      SizedBox(width: 2.w),
                      _actionBtn(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _launchUrl(
                          'https://wa.me/${customerPhone.replaceAll('+', '')}',
                        ),
                      ),
                      SizedBox(width: 2.w),
                    ],
                    if (status == 'pending' || status == 'negotiating')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderQuotationBuilderScreen(
                                  enquiry: enquiry,
                                ),
                              ),
                            );
                            if (result == true) _loadEnquiries();
                          },
                          icon: const Icon(
                            Icons.request_quote_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Send Quote',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                    if (status == 'quoted')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final quotation = await SupabaseService.instance
                                .getQuotationByEnquiry(enquiry['id'] as String);
                            if (quotation != null && mounted) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderQuotationBuilderScreen(
                                        enquiry: enquiry,
                                        existingQuotation: quotation,
                                      ),
                                ),
                              );
                              if (result == true) _loadEnquiries();
                            }
                          },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text(
                            'Edit Quote',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.h),
                          ),
                        ),
                      ),
                  ],
                ),
                // Negotiate button for quoted or negotiating status
                if (status == 'quoted' || status == 'negotiating') ...[
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final quotation = await SupabaseService.instance
                            .getQuotationByEnquiry(enquiry['id'] as String);
                        if (quotation != null && mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.quotationNegotiationScreen,
                            arguments: {
                              'quotation': quotation,
                              'role': 'provider',
                            },
                          );
                        }
                      },
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
                        padding: EdgeInsets.symmetric(vertical: 1.h),
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w600,
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }
}
