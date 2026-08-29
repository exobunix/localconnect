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

  final List<String> _statuses = [
    'all',
    'pending',
    'confirmed',
    'active',
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
        final customer = (o['customer_name'] ?? o['customer_id'] ?? '').toString().toLowerCase();
        final provider = (o['provider']?['business_name'] ?? o['provider']?['owner_name'] ?? '').toString().toLowerCase();
        final service = (o['service_name'] ?? o['description'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();

        final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
        final matchesSearch = q.isEmpty ||
            id.contains(q) ||
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
        return AppTheme.success;
      case 'active':
      case 'confirmed':
        return AppTheme.primary;
      case 'pending':
        return AppTheme.warning;
      case 'cancelled':
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'active':
        return Icons.play_circle_rounded;
      case 'confirmed':
        return Icons.thumb_up_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0';
    final n = (amount as num).toDouble();
    return '₹${n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _orders.where((o) => (o['status'] ?? '') == 'pending').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
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
                hintText: 'Search by order ID, customer, provider...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline),
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
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Status filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusFilter == s ? Colors.white : AppTheme.outline,
                              ),
                            ),
                            selected: _statusFilter == s,
                            selectedColor: s == 'all' ? AppTheme.primary : _statusColor(s),
                            backgroundColor: AppTheme.surfaceVariant,
                            onSelected: (_) {
                              _statusFilter = s;
                              _applyFilter();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceVariant,
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline),
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Error loading orders',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(_error!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
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
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.outline),
            const SizedBox(height: 12),
            Text(
              'No orders found',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.outline),
            ),
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
    final provider = order['provider'] as Map<String, dynamic>?;
    final providerName = provider?['business_name'] ?? provider?['owner_name'] ?? 'Unknown Provider';
    final providerCategory = provider?['category'] ?? '';
    final customerName = order['customer_name'] ?? order['customer_id'] ?? 'Unknown Customer';
    final serviceName = order['service_name'] ?? order['description'] ?? order['category'] ?? 'Service';
    final amount = _formatAmount(order['amount'] ?? order['total_amount']);
    final createdAt = _formatDate(order['created_at']?.toString());
    final orderId = (order['id'] ?? '').toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  '#$shortId',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                _infoRow(Icons.home_repair_service_rounded, 'Service', serviceName),
                const SizedBox(height: 8),
                _infoRow(Icons.person_rounded, 'Customer', customerName.toString()),
                const SizedBox(height: 8),
                _infoRow(Icons.store_rounded, 'Provider',
                    '$providerName${providerCategory.isNotEmpty ? '  •  $providerCategory' : ''}'),
                const SizedBox(height: 8),
                _infoRow(Icons.schedule_rounded, 'Placed At', createdAt),
                if (order['scheduled_date'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.event_rounded, 'Scheduled',
                      _formatDate(order['scheduled_date']?.toString())),
                ],
                if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_rounded, 'Address', order['address'].toString()),
                ],
                if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.notes_rounded, 'Notes', order['notes'].toString()),
                ],
              ],
            ),
          ),
          // Actions
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'cancelled'),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(order['id'].toString(), 'confirmed'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Confirm', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
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
          width: 74,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.outline,
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
        updates: {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $status successfully'),
            backgroundColor: status == 'confirmed' ? AppTheme.success : AppTheme.error,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
