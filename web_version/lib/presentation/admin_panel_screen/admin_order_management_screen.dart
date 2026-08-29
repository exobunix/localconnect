import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Valid enum values for order_status in DB
  final List<String> _statuses = [
    'all',
    'pending',
    'active',
    'upcoming',
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
      final data = await SupabaseService.instance.getAdminAllOrders();
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
      case 'completed':
        return const Color(0xFF1DB954);
      case 'active':
        return const Color(0xFF2196F3);
      case 'upcoming':
        return const Color(0xFF9C27B0);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'active':
        return Icons.play_circle_rounded;
      case 'upcoming':
        return Icons.event_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
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
        title: Text(
          'All Orders',
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
                    status[0].toUpperCase() + status.substring(1),
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
          // Action buttons — only for pending orders
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      // 'confirmed' is NOT a valid enum — use 'active' to accept
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
                ],
              ),
            ),
        ],
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
}
