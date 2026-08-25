import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminQuotationMonitoringScreen extends StatefulWidget {
  const AdminQuotationMonitoringScreen({super.key});

  @override
  State<AdminQuotationMonitoringScreen> createState() =>
      _AdminQuotationMonitoringScreenState();
}

class _AdminQuotationMonitoringScreenState
    extends State<AdminQuotationMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _enquiries = [];
  String? _error;

  // Analytics
  int _totalQuotations = 0;
  int _acceptedCount = 0;
  int _rejectedCount = 0;
  int _pendingCount = 0;
  int _sentCount = 0;
  int _negotiatingCount = 0;
  double _totalValue = 0;
  double _avgValue = 0;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  final List<String> _statusFilters = [
    'all',
    'sent',
    'accepted',
    'rejected',
    'negotiating',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quotations = await SupabaseService.instance.adminGetAllQuotations();
      final enquiries = await SupabaseService.instance.adminGetAllEnquiries();

      int accepted = 0, rejected = 0, pending = 0, sent = 0, negotiating = 0;
      double totalVal = 0;
      for (final q in quotations) {
        final status = (q['status'] ?? '').toString().toLowerCase();
        if (status == 'accepted') {
          accepted++;
        } else if (status == 'rejected') {
          rejected++;
        } else if (status == 'sent') {
          sent++;
          pending++;
        } else if (status == 'negotiating') {
          negotiating++;
          pending++;
        }
        totalVal += (q['total_amount'] ?? 0).toDouble();
      }

      final avg = quotations.isNotEmpty ? totalVal / quotations.length : 0.0;

      if (mounted) {
        setState(() {
          _quotations = quotations;
          _enquiries = enquiries;
          _totalQuotations = quotations.length;
          _acceptedCount = accepted;
          _rejectedCount = rejected;
          _pendingCount = pending;
          _sentCount = sent;
          _negotiatingCount = negotiating;
          _totalValue = totalVal;
          _avgValue = avg;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load data.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredQuotations {
    return _quotations.where((q) {
      final provider =
          (q['provider'] as Map<String, dynamic>?)?['business_name']
              ?.toString()
              .toLowerCase() ??
          '';
      final customer =
          (q['customer'] as Map<String, dynamic>?)?['full_name']
              ?.toString()
              .toLowerCase() ??
          '';
      final status = (q['status'] ?? '').toString().toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          provider.contains(_searchQuery) ||
          customer.contains(_searchQuery);

      final matchesStatus =
          _selectedStatusFilter == 'all' || status == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredEnquiries {
    return _enquiries.where((e) {
      final provider =
          (e['provider'] as Map<String, dynamic>?)?['business_name']
              ?.toString()
              .toLowerCase() ??
          '';
      final customer =
          (e['customer'] as Map<String, dynamic>?)?['full_name']
              ?.toString()
              .toLowerCase() ??
          '';
      return _searchQuery.isEmpty ||
          provider.contains(_searchQuery) ||
          customer.contains(_searchQuery);
    }).toList();
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
          'Quotation Monitoring',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
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
            Tab(text: 'Analytics'),
            Tab(text: 'All Quotations'),
            Tab(text: 'Enquiries'),
          ],
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
                    onPressed: _loadData,
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
              children: [
                _buildAnalyticsTab(),
                _buildQuotationsTab(),
                _buildEnquiriesTab(),
              ],
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Conversion rate: sent → accepted
    final conversionBase = _sentCount + _acceptedCount + _negotiatingCount;
    final conversionRate = conversionBase > 0
        ? _acceptedCount / conversionBase
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.6,
            children: [
              _kpiCard(
                'Total Quotations',
                _totalQuotations.toString(),
                Icons.request_quote_rounded,
                AppTheme.primary,
              ),
              _kpiCard(
                'Accepted',
                _acceptedCount.toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
              _kpiCard(
                'Rejected',
                _rejectedCount.toString(),
                Icons.cancel_rounded,
                Colors.red,
              ),
              _kpiCard(
                'Pending / Sent',
                _pendingCount.toString(),
                Icons.pending_rounded,
                Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Total value + Avg value row
          Row(
            children: [
              Expanded(
                child: _valueSummaryCard(
                  'Total Value',
                  '₹${_totalValue.toStringAsFixed(0)}',
                  Icons.currency_rupee_rounded,
                  const [Color(0xFF1565C0), Color(0xFF26C6A6)],
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _valueSummaryCard(
                  'Avg. Quotation Value',
                  '₹${_avgValue.toStringAsFixed(0)}',
                  Icons.bar_chart_rounded,
                  const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Conversion Rate Card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Conversion Rate (Sent → Accepted)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Text(
                      '${(conversionRate * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: conversionRate,
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.15,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                              minHeight: 10,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '$_acceptedCount accepted out of $conversionBase sent/negotiating',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Status breakdown
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Breakdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                SizedBox(height: 1.5.h),
                _rateBar(
                  'Accepted',
                  _acceptedCount,
                  _totalQuotations,
                  Colors.green,
                ),
                SizedBox(height: 1.h),
                _rateBar(
                  'Rejected',
                  _rejectedCount,
                  _totalQuotations,
                  Colors.red,
                ),
                SizedBox(height: 1.h),
                _rateBar('Sent', _sentCount, _totalQuotations, Colors.blue),
                SizedBox(height: 1.h),
                _rateBar(
                  'Negotiating',
                  _negotiatingCount,
                  _totalQuotations,
                  Colors.purple,
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Recent quotations
          Text(
            'Recent Quotations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          SizedBox(height: 1.h),
          ..._quotations.take(5).map((q) => _buildQuotationRow(q)),
        ],
      ),
    );
  }

  Widget _buildQuotationsTab() {
    final filtered = _filteredQuotations;
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: InputDecoration(
              hintText: 'Search by provider or customer...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FF),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Status filter chips
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 1.5.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatusFilter == status;
                final color = status == 'all'
                    ? AppTheme.primary
                    : _statusColor(status);
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStatusFilter = status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        status == 'all'
                            ? 'All (${_quotations.length})'
                            : '${status[0].toUpperCase()}${status.substring(1)} (${_quotations.where((q) => (q['status'] ?? '').toString().toLowerCase() == status).length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Results count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
          child: Row(
            children: [
              Text(
                '${filtered.length} quotation${filtered.length != 1 ? 's' : ''} found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
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
                        _searchQuery.isNotEmpty ||
                                _selectedStatusFilter != 'all'
                            ? 'No quotations match your filter'
                            : 'No quotations found',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildAdminQuotationCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEnquiriesTab() {
    final filtered = _filteredEnquiries;
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
            decoration: InputDecoration(
              hintText: 'Search by provider or customer...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: Colors.grey,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FF),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
          child: Row(
            children: [
              Text(
                '${filtered.length} enquir${filtered.length != 1 ? 'ies' : 'y'} found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        color: Colors.grey[300],
                        size: 60,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No enquiries match your search'
                            : 'No enquiries found',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _buildAdminEnquiryCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _valueSummaryCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
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
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateBar(String label, int count, int total, Color color) {
    final rate = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10.sp)),
            Text(
              '$count (${(rate * 100).toStringAsFixed(1)}%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationRow(Map<String, dynamic> q) {
    final status = q['status'] ?? 'sent';
    final provider = q['provider'] as Map<String, dynamic>? ?? {};
    final customer = q['customer'] as Map<String, dynamic>? ?? {};
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider['business_name'] ?? 'Provider'} → ${customer['full_name'] ?? 'Customer'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${(q['total_amount'] ?? 0).toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
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

  Widget _buildAdminQuotationCard(Map<String, dynamic> q) {
    final status = q['status'] ?? 'sent';
    final provider = q['provider'] as Map<String, dynamic>? ?? {};
    final customer = q['customer'] as Map<String, dynamic>? ?? {};
    final total = (q['total_amount'] ?? 0).toDouble();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['business_name'] ?? 'Provider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A237E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          customer['full_name'] ?? 'N/A',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.currency_rupee_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  Text(
                    total.toStringAsFixed(0),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(q['created_at']),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if ((q['additional_notes'] ?? '').isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              q['additional_notes'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminEnquiryCard(Map<String, dynamic> e) {
    final status = e['status'] ?? 'pending';
    final provider = e['provider'] as Map<String, dynamic>? ?? {};
    final customer = e['customer'] as Map<String, dynamic>? ?? {};

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
                  e['title'] ?? 'Service Request',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${customer['full_name'] ?? 'Customer'} → ${provider['business_name'] ?? 'Provider'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: Colors.grey,
                  ),
                ),
                if ((e['category'] ?? '').isNotEmpty)
                  Text(
                    e['category'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
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
          fontSize: 8.sp,
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
