import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
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
      final currentArea = SupabaseService.instance.currentAdminArea;
      final areaFilter = (currentArea.isNotEmpty && currentArea.toUpperCase() != 'ALL')
          ? currentArea
          : null;
      final quotations = await SupabaseService.instance.adminGetAllQuotations();
      final enquiries = await SupabaseService.instance.adminGetAllEnquiries(
        areaFilter: areaFilter,
      );

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

  String _selectedEnquiryStatusFilter = 'all';
  final List<String> _enquiryStatusFilters = [
    'all',
    'unassigned',
    'unresponsive',
    'pending',
    'dispatched',
    'quoted',
    'accepted',
    'completed',
    'cancelled',
  ];

  List<Map<String, dynamic>> get _filteredEnquiries {
    return _enquiries.where((e) {
      final provider = (e['provider_name'] ??
              (e['provider'] as Map<String, dynamic>?)?['business_name'] ??
              '')
          .toString()
          .toLowerCase();
      final customer = (e['customer_name'] ??
              (e['customer'] as Map<String, dynamic>?)?['full_name'] ??
              '')
          .toString()
          .toLowerCase();
      final service = (e['service_title'] ??
              e['title'] ??
              e['subcategory'] ??
              e['category'] ??
              '')
          .toString()
          .toLowerCase();
      final phone = (e['customer_phone'] ?? '').toString().toLowerCase();
      final msg = (e['message'] ?? e['description'] ?? '').toString().toLowerCase();
      final status = (e['status'] ?? 'pending').toString().toLowerCase();
      final provId = (e['provider_id'] ?? '').toString().trim();
      final provReply = (e['provider_reply'] ?? '').toString().trim();

      final matchesSearch = _searchQuery.isEmpty ||
          provider.contains(_searchQuery) ||
          customer.contains(_searchQuery) ||
          service.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          msg.contains(_searchQuery);

      bool matchesStatus;
      if (_selectedEnquiryStatusFilter == 'all') {
        matchesStatus = true;
      } else if (_selectedEnquiryStatusFilter == 'unassigned') {
        matchesStatus = provId.isEmpty || provId == 'null' || provider.isEmpty || provider == 'provider';
      } else if (_selectedEnquiryStatusFilter == 'unresponsive') {
        matchesStatus = (status == 'pending' || status == 'dispatched') && provReply.isEmpty;
      } else {
        matchesStatus = status == _selectedEnquiryStatusFilter;
      }

      return matchesSearch && matchesStatus;
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
          'Service Requests & Quotations',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_rounded),
            tooltip: 'Complaints & Reassignment',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.adminComplaintsScreen);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(text: 'Analytics'),
            Tab(text: 'Quotations (${_quotations.length})'),
            Tab(text: 'Service Requests (${_enquiries.length})'),
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
        // Status filter chips
        Container(
          color: Colors.white,
          height: 38,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _enquiryStatusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final filter = _enquiryStatusFilters[i];
              final isSelected = _selectedEnquiryStatusFilter == filter;
              String labelText;
              if (filter == 'all') {
                labelText = 'All (${_enquiries.length})';
              } else if (filter == 'unassigned') {
                final count = _enquiries.where((e) {
                  final pId = (e['provider_id'] ?? '').toString().trim();
                  final pName = (e['provider_name'] ??
                          (e['provider'] as Map<String, dynamic>?)?['business_name'] ??
                          '')
                      .toString()
                      .trim();
                  return pId.isEmpty || pId == 'null' || pName.isEmpty || pName.toLowerCase() == 'provider';
                }).length;
                labelText = '⚠️ Unassigned ($count)';
              } else if (filter == 'unresponsive') {
                final count = _enquiries.where((e) {
                  final st = (e['status'] ?? 'pending').toString().toLowerCase();
                  final rep = (e['provider_reply'] ?? '').toString().trim();
                  return (st == 'pending' || st == 'dispatched') && rep.isEmpty;
                }).length;
                labelText = '⏳ Unresponsive ($count)';
              } else {
                final count = _enquiries
                    .where((e) =>
                        (e['status'] ?? 'pending').toString().toLowerCase() ==
                        filter)
                    .length;
                labelText =
                    '${filter[0].toUpperCase()}${filter.substring(1)} ($count)';
              }

              final chipColor = filter == 'unassigned'
                  ? const Color(0xFFE11D48)
                  : filter == 'unresponsive'
                      ? const Color(0xFFD97706)
                      : AppTheme.primary;

              return FilterChip(
                label: Text(
                  labelText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                selected: isSelected,
                selectedColor: chipColor,
                backgroundColor: const Color(0xFFF1F5F9),
                checkmarkColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? chipColor : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedEnquiryStatusFilter = filter;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
          child: Row(
            children: [
              Text(
                '${filtered.length} service request${filtered.length != 1 ? 's' : ''} found',
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
    final enquiryId = e['id']?.toString() ?? '';
    final refDisplay = enquiryId.length > 12
        ? '#ENQ-${enquiryId.substring(0, 8)}'
        : (enquiryId.isNotEmpty ? '#$enquiryId' : '#ENQ');
    final customerName = e['customer_name'] as String? ?? (e['customer'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Customer';
    final customerPhone = e['customer_phone'] as String? ?? '';
    final providerName = e['provider_name'] as String? ?? (e['provider'] as Map<String, dynamic>?)?['business_name'] as String? ?? 'Provider';
    final serviceTitle = e['service_title'] as String? ?? e['title'] as String? ?? 'Service Request';
    final category = e['category'] as String? ?? '';
    final subcategory = e['subcategory'] as String? ?? '';
    final preferredDate = e['preferred_date'] as String? ?? '';
    final preferredTime = e['preferred_time'] as String? ?? '';
    final message = e['message'] as String? ?? e['description'] as String? ?? '';
    final status = (e['status'] as String? ?? 'pending').toLowerCase();
    final providerReply = e['provider_reply'] as String? ?? '';
    final repliedAt = e['replied_at'] != null ? _formatDate(e['replied_at']) : '';
    final createdAt = _formatDate(e['created_at']);
    final pId = (e['provider_id'] ?? '').toString().trim();
    final hasNoProvider = pId.isEmpty || pId == 'null' || providerName == 'Provider' || providerName.isEmpty;
    final isUnresponsive = (status == 'pending' || status == 'dispatched') && providerReply.isEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: providerReply.isNotEmpty
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.08),
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
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
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
                        fontSize: 9.sp,
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
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 1.h),

                // Customer & Partner info rows
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            'Customer: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$customerName ${customerPhone.isNotEmpty ? '($customerPhone)' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (customerPhone.isNotEmpty)
                            InkWell(
                              onTap: () => _launchUrl('tel:$customerPhone'),
                              child: const Icon(Icons.call_rounded, size: 16, color: Colors.green),
                            ),
                        ],
                      ),
                      const Divider(height: 12, color: Color(0xFFE2E8F0)),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text(
                            'Partner: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              providerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),

                // Schedule
                if (preferredDate.isNotEmpty || preferredTime.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Requested: $preferredDate ($preferredTime)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.8.h),
                ],

                // Customer message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Requirement: ${message.isNotEmpty ? message : "Enquiry initiated."}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5.sp,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),

                // Partner reply (if available)
                if (providerReply.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              'Partner Reply:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const Spacer(),
                            if (repliedAt.isNotEmpty)
                              Text(
                                repliedAt,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5.sp,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          providerReply,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.h),
                ],

                // Admin dispatch note banner
                if (e['admin_dispatch_note'] != null &&
                    e['admin_dispatch_note'].toString().trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: EdgeInsets.only(bottom: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.send_rounded,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dispatched to Area Providers:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e['admin_dispatch_note'].toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action required alert banner for Admin
                if (hasNoProvider) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: EdgeInsets.only(bottom: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE11D48)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No suitable provider assigned. Tap "Dispatch" below to forward to area providers.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9F1239),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isUnresponsive) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: EdgeInsets.only(bottom: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Awaiting partner response. If unavailable/delayed, dispatch to other area providers.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Admin action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: $createdAt',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Row(
                      children: [
                        // Dispatch to Providers button
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showDispatchToProvidersDialog(context, e),
                          icon: const Icon(Icons.send_rounded, size: 12),
                          label: Text(
                            hasNoProvider ? 'Dispatch Now' : 'Dispatch',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasNoProvider ? const Color(0xFFE11D48) : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            elevation: 0,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (val) async {
                            await SupabaseService.instance.updateEnquiryStatus(
                              enquiryId: enquiryId,
                              status: val,
                            );
                            _loadData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Set Status',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: Color(0xFF475569),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            const PopupMenuItem(
                              value: 'dispatched',
                              child: Text('Dispatched'),
                            ),
                            const PopupMenuItem(
                              value: 'quoted',
                              child: Text('Quoted'),
                            ),
                            const PopupMenuItem(
                              value: 'accepted',
                              child: Text('Accepted'),
                            ),
                            const PopupMenuItem(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                            const PopupMenuItem(
                              value: 'cancelled',
                              child: Text('Cancelled'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Enquiry'),
                                content: const Text(
                                  'Are you sure you want to delete this enquiry record?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await SupabaseService.instance.deleteEnquiry(
                                enquiryId,
                              );
                              _loadData();
                            }
                          },
                          tooltip: 'Delete Enquiry',
                        ),
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

  Widget _statusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.4),
        ),
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
      case 'dispatched':
        return const Color(0xFF2563EB);
      case 'sent':
        return Colors.blue;
      case 'quoted':
        return const Color(0xFF0284C7);
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return AppTheme.secondary;
      case 'negotiating':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showDispatchToProvidersDialog(
    BuildContext context,
    Map<String, dynamic> enquiry,
  ) async {
    final enquiryId = enquiry['id']?.toString() ?? '';
    final category = enquiry['category'] as String? ?? '';
    final subcategory = enquiry['subcategory'] as String? ?? '';
    final customerCity =
        (enquiry['customer'] as Map<String, dynamic>?)?['city'] as String? ??
            enquiry['city'] as String?;
    final serviceTitle = enquiry['service_title'] as String? ??
        enquiry['title'] as String? ??
        'Service Request';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _DispatchDialogContent(
        enquiryId: enquiryId,
        category: category,
        subcategory: subcategory,
        city: customerCity,
        serviceTitle: serviceTitle,
        enquiry: enquiry,
        onDispatched: () {
          Navigator.of(dialogCtx).pop();
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Service request successfully dispatched to selected providers!',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
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

class _DispatchDialogContent extends StatefulWidget {
  final String enquiryId;
  final String category;
  final String subcategory;
  final String? city;
  final String serviceTitle;
  final Map<String, dynamic> enquiry;
  final VoidCallback onDispatched;

  const _DispatchDialogContent({
    required this.enquiryId,
    required this.category,
    required this.subcategory,
    this.city,
    required this.serviceTitle,
    required this.enquiry,
    required this.onDispatched,
  });

  @override
  State<_DispatchDialogContent> createState() => _DispatchDialogContentState();
}

class _DispatchDialogContentState extends State<_DispatchDialogContent> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _providers = [];
  final Set<String> _selectedProviderIds = {};
  late TextEditingController _noteController;
  final TextEditingController _searchFilter = TextEditingController();
  String _providerSearch = '';

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text:
          'Urgent customer service request in your area (${widget.city ?? 'Local'}). Please check details and respond immediately.',
    );
    _fetchProviders();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchFilter.dispose();
    super.dispose();
  }

  Future<void> _fetchProviders({bool broadenSearch = false}) async {
    setState(() => _isLoading = true);
    try {
      final providers =
          await SupabaseService.instance.adminGetProvidersForDispatch(
        category: broadenSearch ? null : widget.category,
        subcategory: broadenSearch ? null : widget.subcategory,
        city: widget.city,
      );
      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProviders {
    if (_providerSearch.isEmpty) return _providers;
    final q = _providerSearch.toLowerCase();
    return _providers.where((p) {
      final name = (p['business_name'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final city = (p['city'] ?? '').toString().toLowerCase();
      final cat = (p['category'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          city.contains(q) ||
          cat.contains(q);
    }).toList();
  }

  Future<void> _submitDispatch() async {
    if (_selectedProviderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one provider to dispatch to.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final selectedList = _providers
        .where((p) => _selectedProviderIds.contains(p['id'].toString()))
        .toList();

    final custName = (widget.enquiry['customer_name'] as String?) ??
        (widget.enquiry['customer'] as Map<String, dynamic>?)?['full_name'] as String? ??
        'Customer';
    final custPhone = (widget.enquiry['customer_phone'] as String?) ??
        (widget.enquiry['customer'] as Map<String, dynamic>?)?['phone'] as String? ??
        '';
    final pDate = widget.enquiry['preferred_date']?.toString();
    final pTime = widget.enquiry['preferred_time']?.toString();
    final reqMsg = (widget.enquiry['message'] ?? widget.enquiry['description'])?.toString();

    final result = await SupabaseService.instance.adminDispatchEnquiryToProviders(
      enquiryId: widget.enquiryId,
      targetProviders: selectedList,
      dispatchNote: _noteController.text.trim(),
      customerName: custName,
      customerPhone: custPhone,
      serviceTitle: widget.serviceTitle,
      category: widget.category,
      subcategory: widget.subcategory,
      preferredDate: pDate,
      preferredTime: pTime,
      requirementMessage: reqMsg,
    );

    final ok = result['success'] == true;

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        widget.onDispatched();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to dispatch request: ${result['error'] ?? 'Please try again.'}',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProviders;
    final allSelected = filtered.isNotEmpty &&
        filtered.every((p) => _selectedProviderIds.contains(p['id'].toString()));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.forward_to_inbox_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch Service Request',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.serviceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service summary card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Area: ${widget.city ?? "Local"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                              if (widget.category.isNotEmpty) ...[
                                const Text(' • '),
                                Text(
                                  widget.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Requirement: ${(widget.enquiry['message'] ?? widget.enquiry['description'] ?? 'Service required').toString()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dispatch Note to Providers
                    Text(
                      'Dispatch Note / Instructions to Providers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5.sp),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        hintText: 'Enter dispatch instructions...',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Available Providers Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Providers (${_selectedProviderIds.length}/${filtered.length} selected)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (filtered.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (allSelected) {
                                  _selectedProviderIds.clear();
                                } else {
                                  for (final p in filtered) {
                                    _selectedProviderIds
                                        .add(p['id'].toString());
                                  }
                                }
                              });
                            },
                            child: Text(
                              allSelected ? 'Deselect All' : 'Select All',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Filter search inside dialog
                    TextField(
                      controller: _searchFilter,
                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5.sp),
                      decoration: InputDecoration(
                        hintText: 'Search provider name, phone, city...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _providerSearch = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Providers List
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_search_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matching providers found in this category/area.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () =>
                                  _fetchProviders(broadenSearch: true),
                              child: const Text('Show All Active Providers'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          final id = p['id'].toString();
                          final isChecked = _selectedProviderIds.contains(id);
                          final name = p['business_name'] ?? 'Provider';
                          final phone = p['phone'] ?? '';
                          final cat = p['category'] ?? '';
                          final city = p['city'] ?? '';

                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: const Color(0xFF2563EB),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Text(
                              '${cat.isNotEmpty ? '$cat • ' : ''}${city.isNotEmpty ? '$city • ' : ''}$phone',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedProviderIds.add(id);
                                } else {
                                  _selectedProviderIds.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitDispatch,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isSubmitting
                          ? 'Dispatching...'
                          : 'Dispatch to ${_selectedProviderIds.length} Providers',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

