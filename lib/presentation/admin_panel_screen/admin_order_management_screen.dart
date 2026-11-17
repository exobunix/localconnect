import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filtered = [];
  String _statusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Valid lifecycle statuses
  final List<String> _statuses = [
    'all',
    'new',
    'pending',
    'assigned',
    'active',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final area = SupabaseService.instance.isSuperAdmin
          ? null
          : (SupabaseService.instance.currentAdminArea.isNotEmpty
              ? SupabaseService.instance.currentAdminArea
              : null);
      final data = await SupabaseService.instance.getAdminAllOrders(areaFilter: area);
      if (mounted) {
        setState(() {
          _orders = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _orders.where((o) {
        final status = (o['status'] ?? '').toString();
        final id = (o['id'] ?? '').toString().toLowerCase();
        final orderNum = (o['order_number'] ?? '').toString().toLowerCase();
        // customer_name is injected by getAdminAllOrders
        final customer = (o['customer_name'] ?? '').toString().toLowerCase();
        // provider name: prefer join result, fall back to denormalized column
        final providerJoin = (o['provider'] as Map<String, dynamic>?);
        final provider = (providerJoin?['business_name'] ??
                providerJoin?['owner_name'] ??
                o['provider_name'] ??
                '')
            .toString()
            .toLowerCase();
        final service = (o['service'] ?? o['description'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();

        final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
        final matchesSearch = q.isEmpty ||
            id.contains(q) ||
            orderNum.contains(q) ||
            customer.contains(q) ||
            provider.contains(q) ||
            service.contains(q);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'new request':
        return const Color(0xFF0288D1);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'assigned':
      case 'assigned to provider':
        return const Color(0xFF7B1FA2);
      case 'active':
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'in_progress':
      case 'upcoming':
        return const Color(0xFF3F51B5);
      case 'completed':
        return const Color(0xFF1DB954);
      case 'cancelled':
      case 'rejected':
      case 'rejected / cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'new request':
        return Icons.fiber_new_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'assigned':
      case 'assigned to provider':
        return Icons.person_pin_rounded;
      case 'active':
      case 'accepted':
        return Icons.thumb_up_rounded;
      case 'in_progress':
      case 'upcoming':
        return Icons.play_circle_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
      case 'rejected':
      case 'rejected / cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _statusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'New Request';
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned to Provider';
      case 'active':
        return 'Accepted';
      case 'in_progress':
      case 'upcoming':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Rejected / Cancelled';
      default:
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Unknown';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  // amount is stored as TEXT in the DB (e.g. "₹450")
  String _displayAmount(dynamic amount) {
    if (amount == null) return '₹0';
    final s = amount.toString().trim();
    if (s.isEmpty || s == '0') return '₹0';
    if (s.startsWith('₹')) return s;
    // Try numeric
    try {
      final n = double.parse(s);
      return '₹${n.truncateToDouble() == n ? n.toInt() : n.toStringAsFixed(2)}';
    } catch (_) {
      return s;
    }
  }

  String _resolveProviderName(Map<String, dynamic> order) {
    final providerJoin = order['provider'] as Map<String, dynamic>?;
    if (providerJoin != null) {
      final name = providerJoin['business_name'] ?? providerJoin['owner_name'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    final direct = order['provider_name'];
    if (direct != null && direct.toString().isNotEmpty) return direct.toString();
    return 'Provider';
  }

  String _resolveCustomerName(Map<String, dynamic> order) {
    final n = order['customer_name'];
    if (n != null && n.toString().isNotEmpty && n.toString() != 'Customer') {
      return n.toString();
    }
    return 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _orders.where((o) => (o['status'] ?? '') == 'pending').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SupabaseService.instance.isSuperAdmin ? 'All Orders' : 'Area Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!SupabaseService.instance.isSuperAdmin &&
                SupabaseService.instance.currentAdminArea.isNotEmpty)
              Text(
                'Area: ${SupabaseService.instance.currentAdminArea}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.adminPanelScreen);
            }
          },
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
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'All Orders (${_orders.length})'),
            Tab(text: 'Pending (${pendingOrders.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchQuery = v;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: 'Search order #, customer, provider, service...',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF9E9E9E)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _applyFilter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Status filter chips
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              s == 'all'
                                  ? 'All'
                                  : s[0].toUpperCase() + s.substring(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusFilter == s
                                    ? Colors.white
                                    : const Color(0xFF9E9E9E),
                              ),
                            ),
                            selected: _statusFilter == s,
                            selectedColor: s == 'all'
                                ? AppTheme.primary
                                : _statusColor(s),
                            backgroundColor: const Color(0xFFF5F6FA),
                            onSelected: (_) {
                              setState(() => _statusFilter = s);
                              _applyFilter();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Count bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFEEF0F5),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} orders shown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_orders.length}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_filtered),
                _buildOrderList(pendingOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFF44336)),
              const SizedBox(height: 12),
              Text('Error loading orders',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_error!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: const Color(0xFF9E9E9E))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),
      );
    }
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: Color(0xFF9E9E9E)),
            const SizedBox(height: 12),
            Text('No orders found',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: const Color(0xFF9E9E9E))),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildOrderCard(orders[i]),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);
    final providerName = _resolveProviderName(order);
    final providerJoin = order['provider'] as Map<String, dynamic>?;
    final providerCategory = providerJoin?['category'] ?? '';
    final customerName = _resolveCustomerName(order);
    final serviceName = (order['service'] ?? order['category'] ?? 'Service').toString();
    final amount = _displayAmount(order['amount']);
    final createdAt = _formatDate(order['created_at']?.toString());
    final orderNum = (order['order_number'] ?? order['id'] ?? '').toString();
    final shortNum = orderNum.length > 8
        ? '#${orderNum.substring(orderNum.length - 8).toUpperCase()}'
        : '#$orderNum';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  shortNum,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusDisplay(status),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _infoRow(Icons.home_repair_service_rounded, 'Service',
                    serviceName),
                const SizedBox(height: 8),
                _infoRow(Icons.person_rounded, 'Customer', customerName),
                const SizedBox(height: 8),
                _infoRow(
                    Icons.store_rounded,
                    'Provider',
                    providerCategory.isNotEmpty
                        ? '$providerName  •  $providerCategory'
                        : providerName),
                const SizedBox(height: 8),
                _infoRow(Icons.schedule_rounded, 'Placed At', createdAt),
                if ((order['scheduled_date'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                      Icons.event_rounded,
                      'Scheduled',
                      '${order['scheduled_date']}${(order['scheduled_time'] ?? '').toString().isNotEmpty ? '  ${order['scheduled_time']}' : ''}'),
                ],
                if ((order['notes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                      Icons.notes_rounded, 'Notes', order['notes'].toString()),
                ],
              ],
            ),
          ),
          // Action buttons — for pending or active orders needing intervention
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrderStatus(
                          order['id'].toString(), 'cancelled'),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text('Cancel',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF44336),
                        side: const BorderSide(color: Color(0xFFF44336)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(
                          order['id'].toString(), 'active'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Accept',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReassignProviderDialog(order),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      status == 'pending' ? 'Dispatch' : 'Reassign',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpdateStatusDialog(order),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text(
                      'Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReassignProviderDialog(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? '';
    final category = (order['category'] ?? order['service'] ?? '').toString();
    final city = (order['city'] ?? (order['provider'] as Map<String, dynamic>?)?['city'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReassignProviderModal(
        orderId: orderId,
        category: category,
        city: city,
        onReassigned: () {
          _loadOrders();
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await SupabaseService.instance.adminUpdateOrder(
        orderId: orderId,
        updates: {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                status == 'active' ? '✅ Order accepted!' : '❌ Order cancelled'),
            backgroundColor: status == 'active'
                ? const Color(0xFF1DB954)
                : const Color(0xFFF44336),
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: const Color(0xFFF44336)),
        );
      }
    }
  }

  void _showUpdateStatusDialog(Map<String, dynamic> order) {
    String currentStatus = (order['status'] ?? 'pending').toString().toLowerCase();
    if (currentStatus == 'active') currentStatus = 'accepted';
    String selectedStatus = currentStatus;
    final remarksCtrl = TextEditingController();

    final statusOptions = [
      {'val': 'new', 'label': 'New Request'},
      {'val': 'pending', 'label': 'Pending'},
      {'val': 'assigned', 'label': 'Assigned to Provider'},
      {'val': 'active', 'label': 'Accepted'},
      {'val': 'in_progress', 'label': 'In Progress'},
      {'val': 'completed', 'label': 'Completed'},
      {'val': 'cancelled', 'label': 'Rejected / Cancelled'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Update Request Status',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['order_number'] ?? order['id'].toString().substring(0, 8)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                Text('Select Status', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: statusOptions.any((o) => o['val'] == selectedStatus) ? selectedStatus : 'pending',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: statusOptions
                      .map((o) => DropdownMenuItem(value: o['val'], child: Text(o['label']!)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 14),
                Text('Admin Remarks / Audit History', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: remarksCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Assigned to area technician or follow-up note',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final remarks = remarksCtrl.text.trim();
                final existingNotes = (order['notes'] ?? '').toString();
                final timeStamp = DateTime.now().toLocal().toString().substring(0, 16);
                final updatedNotes = remarks.isNotEmpty
                    ? (existingNotes.isNotEmpty
                        ? '$existingNotes\n[$timeStamp Admin]: $remarks'
                        : '[$timeStamp Admin]: $remarks')
                    : existingNotes;

                await SupabaseService.instance.adminUpdateOrder(
                  orderId: order['id'].toString(),
                  updates: {
                    'status': selectedStatus,
                    'notes': updatedNotes,
                    'updated_at': DateTime.now().toIso8601String(),
                  },
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Request status updated to ${_statusDisplay(selectedStatus)}'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                  _loadOrders();
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReassignProviderModal extends StatefulWidget {
  final String orderId;
  final String category;
  final String city;
  final VoidCallback onReassigned;

  const _ReassignProviderModal({
    required this.orderId,
    required this.category,
    required this.city,
    required this.onReassigned,
  });

  @override
  State<_ReassignProviderModal> createState() => _ReassignProviderModalState();
}

class _ReassignProviderModalState extends State<_ReassignProviderModal> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _reasonCtrl =
      TextEditingController(text: 'Admin manual assignment / provider unresponsive');
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      var list = await SupabaseService.instance.getProviders(
        category: widget.category.isNotEmpty ? widget.category : null,
        city: widget.city.isNotEmpty ? widget.city : null,
        limit: 50,
      );
      if (list.isEmpty) {
        list = await SupabaseService.instance.getProviders(limit: 50);
      }
      if (mounted) {
        setState(() {
          _providers = list;
          _filtered = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _providers;
      } else {
        _filtered = _providers.where((p) {
          final bName = (p['business_name'] ?? '').toString().toLowerCase();
          final oName =
              (p['owner_name'] ?? p['full_name'] ?? '').toString().toLowerCase();
          final city = (p['city'] ?? '').toString().toLowerCase();
          final cat = (p['category'] ?? '').toString().toLowerCase();
          return bName.contains(q) ||
              oName.contains(q) ||
              city.contains(q) ||
              cat.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _submitReassignment() async {
    if (_selectedProvider == null) return;
    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.instance.adminReassignOrderProvider(
        orderId: widget.orderId,
        newProvider: _selectedProvider!,
        reasonNote: _reasonCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onReassigned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Dispatched to ${_selectedProvider!['business_name'] ?? _selectedProvider!['owner_name']} with continuous alert!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFF1DB954),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reassignment failed: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF0288D1), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Manual Provider Dispatch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Assign a qualified provider in the area and trigger an immediate continuous ringing alert.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search provider name, city, or trade...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No eligible providers found',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            final isSelected =
                                _selectedProvider?['id'] == p['id'];
                            final bName = (p['business_name'] ??
                                    p['owner_name'] ??
                                    'Provider')
                                .toString();
                            final cat = (p['category'] ?? '').toString();
                            final pCity = (p['city'] ?? '').toString();
                            final phone = (p['phone'] ?? '').toString();

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? const Color(0xFF0288D1)
                                    : const Color(0xFFE3F2FD),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0288D1),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                bName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF0288D1)
                                      : const Color(0xFF1A1C1E),
                                ),
                              ),
                              subtitle: Text(
                                '$cat • $pCity • $phone',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF0288D1))
                                  : null,
                              onTap: () {
                                setState(() => _selectedProvider = p);
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Reason for reassignment / dispatch note',
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedProvider == null || _isSubmitting)
                    ? null
                    : _submitReassignment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting
                      ? 'Dispatching Request...'
                      : 'Dispatch Request & Trigger Alert',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

