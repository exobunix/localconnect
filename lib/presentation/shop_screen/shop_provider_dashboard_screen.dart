import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Shared Provider Dashboard for all Shop subcategories
/// Handles: Products, Orders, Inventory, Delivery Config, Analytics
class ShopProviderDashboardScreen extends StatefulWidget {
  const ShopProviderDashboardScreen({super.key});

  @override
  State<ShopProviderDashboardScreen> createState() =>
      _ShopProviderDashboardScreenState();
}

class _ShopProviderDashboardScreenState
    extends State<ShopProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Grocery';

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];

  // Stats
  int _totalProducts = 0;
  int _pendingCount = 0;
  double _todayEarnings = 0;
  double _totalEarnings = 0;

  // Product form
  final _productNameCtrl = TextEditingController();
  final _productPriceCtrl = TextEditingController();
  final _productStockCtrl = TextEditingController();
  final _productDescCtrl = TextEditingController();
  String _selectedCategory = '';
  String _selectedUnit = 'piece';
  bool _productAvailable = true;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _subcategoryId = args['subcategoryId'] as String? ?? 'grocery';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Grocery';
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productNameCtrl.dispose();
    _productPriceCtrl.dispose();
    _productStockCtrl.dispose();
    _productDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return;

      final products = await _supabase
          .from('shop_products')
          .select()
          .eq('provider_id', userId)
          .eq('shop_subcategory', _subcategoryId)
          .order('created_at', ascending: false);

      final orders = await _supabase
          .from('shop_orders')
          .select()
          .eq('provider_id', userId)
          .eq('shop_subcategory', _subcategoryId)
          .order('created_at', ascending: false);

      final pending = (orders as List)
          .where((o) => o['order_status'] == 'pending')
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
      final active = (orders)
          .where(
            (o) =>
                o['order_status'] == 'accepted' ||
                o['order_status'] == 'preparing' ||
                o['order_status'] == 'out_for_delivery',
          )
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();

      double todayEarnings = 0;
      double totalEarnings = 0;
      final today = DateTime.now();
      for (final o in orders) {
        if (o['order_status'] == 'delivered') {
          final amt = (o['total_amount'] as num?)?.toDouble() ?? 0;
          totalEarnings += amt;
          final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
          if (createdAt != null &&
              createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day) {
            todayEarnings += amt;
          }
        }
      }

      if (mounted) {
        setState(() {
          _products = (products as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          _pendingOrders = pending;
          _activeOrders = active;
          _totalProducts = _products.length;
          _pendingCount = pending.length;
          _todayEarnings = todayEarnings;
          _totalEarnings = totalEarnings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('shop_orders')
          .update({'order_status': status})
          .eq('id', orderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $status'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleProductAvailability(
    String productId,
    bool current,
  ) async {
    try {
      await _supabase
          .from('shop_products')
          .update({'is_available': !current})
          .eq('id', productId);
      await _loadData();
    } catch (_) {}
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _supabase.from('shop_products').delete().eq('id', productId);
      await _loadData();
    }
  }

  void _showAddProductSheet({Map<String, dynamic>? existing}) {
    if (existing != null) {
      _productNameCtrl.text = existing['name'] as String? ?? '';
      _productPriceCtrl.text = (existing['price'] as num?)?.toString() ?? '';
      _productStockCtrl.text =
          (existing['stock_quantity'] as num?)?.toString() ?? '';
      _productDescCtrl.text = existing['description'] as String? ?? '';
      _selectedCategory = existing['category'] as String? ?? '';
      _selectedUnit = existing['unit'] as String? ?? 'piece';
      _productAvailable = existing['is_available'] as bool? ?? true;
    } else {
      _productNameCtrl.clear();
      _productPriceCtrl.clear();
      _productStockCtrl.clear();
      _productDescCtrl.clear();
      _selectedCategory = _defaultCategories.first;
      _selectedUnit = 'piece';
      _productAvailable = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddProductSheet(
        subcategoryId: _subcategoryId,
        subcategoryName: _subcategoryName,
        nameCtrl: _productNameCtrl,
        priceCtrl: _productPriceCtrl,
        stockCtrl: _productStockCtrl,
        descCtrl: _productDescCtrl,
        categories: _defaultCategories,
        units: _units,
        selectedCategory: _selectedCategory,
        selectedUnit: _selectedUnit,
        isAvailable: _productAvailable,
        existingId: existing?['id'] as String?,
        onSave: (cat, unit, avail) async {
          _selectedCategory = cat;
          _selectedUnit = unit;
          _productAvailable = avail;
          await _saveProduct(existing?['id'] as String?);
        },
      ),
    );
  }

  Future<void> _saveProduct(String? existingId) async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    final data = {
      'provider_id': userId,
      'shop_subcategory': _subcategoryId,
      'name': _productNameCtrl.text.trim(),
      'description': _productDescCtrl.text.trim(),
      'category': _selectedCategory,
      'price': double.tryParse(_productPriceCtrl.text) ?? 0,
      'unit': _selectedUnit,
      'stock_quantity': int.tryParse(_productStockCtrl.text) ?? 0,
      'is_available': _productAvailable,
    };

    try {
      if (existingId != null) {
        await _supabase.from('shop_products').update(data).eq('id', existingId);
      } else {
        await _supabase.from('shop_products').insert(data);
      }
      if (mounted) Navigator.pop(context);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save product'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<String> get _defaultCategories {
    switch (_subcategoryId) {
      case 'grocery':
        return [
          'Fruits',
          'Vegetables',
          'Dairy',
          'Grains',
          'Pulses',
          'Rice & Flour',
          'Oil & Ghee',
          'Masala & Spices',
          'Snacks',
          'Beverages',
          'Household',
          'Personal Care',
          'Cleaning',
        ];
      case 'vegetables':
        return [
          'Leafy Greens',
          'Root Vegetables',
          'Gourds',
          'Beans & Peas',
          'Exotic Vegetables',
          'Fruits',
          'Herbs',
        ];
      case 'electrical':
        return [
          'Wires & Cables',
          'Switches & Sockets',
          'MCBs & Panels',
          'Fans',
          'Lights & LEDs',
          'Extension Boards',
          'Inverters & Batteries',
          'Accessories',
        ];
      case 'plumbing_hardware':
        return [
          'Pipes & Fittings',
          'Taps & Valves',
          'Bathroom Accessories',
          'Water Tanks',
          'Cement & Paint',
          'Fasteners & Nails',
          'Tools',
          'Adhesives',
          'Building Materials',
        ];
      case 'meat_fish':
        return ['Chicken', 'Mutton', 'Fish', 'Seafood', 'Eggs'];
      case 'seasonal':
        return [
          'Diwali',
          'Holi',
          'Ganesh Festival',
          'Mangoes',
          'Monsoon',
          'Winter',
          'School Supplies',
          'Christmas',
        ];
      default:
        return ['General'];
    }
  }

  static const List<String> _units = [
    'piece',
    'kg',
    'gram',
    'litre',
    'ml',
    'packet',
    'dozen',
    'bundle',
    'box',
    'bag',
    'meter',
    'set',
  ];

  Color get _subcategoryColor {
    switch (_subcategoryId) {
      case 'grocery':
        return AppTheme.catGrocery;
      case 'vegetables':
        return const Color(0xFF2E7D32);
      case 'meat_fish':
        return const Color(0xFFD32F2F);
      case 'electrical':
        return const Color(0xFFF57C00);
      case 'plumbing_hardware':
        return const Color(0xFF0277BD);
      case 'seasonal':
        return const Color(0xFFFFB300);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _subcategoryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _subcategoryName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Provider Dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.loginScreen,
              (_) => false,
            ),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(160),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 14),
                  const SizedBox(width: 4),
                  const Text('Products'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text('Orders${_pendingCount > 0 ? ' ($_pendingCount)' : ''}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 14),
                  const SizedBox(width: 4),
                  const Text('Analytics'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildAnalyticsTab(),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _bottomNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProductSheet(),
              backgroundColor: _subcategoryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Product',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: _subcategoryColor.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF44474E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to start selling',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final p in _products) {
      final cat = p['category'] as String? ?? 'General';
      grouped.putIfAbsent(cat, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row
        Row(
          children: [
            _StatChip(
              label: 'Total',
              value: '$_totalProducts',
              icon: Icons.inventory_2_rounded,
              color: _subcategoryColor,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Active',
              value:
                  '${_products.where((p) => p['is_available'] == true).length}',
              icon: Icons.check_circle_rounded,
              color: AppTheme.success,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Out of Stock',
              value:
                  '${_products.where((p) => (p['stock_quantity'] as int? ?? 0) == 0).length}',
              icon: Icons.warning_rounded,
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _subcategoryColor,
                  ),
                ),
              ),
              ...entry.value.map(
                (p) => _ProductListTile(
                  product: p,
                  accentColor: _subcategoryColor,
                  onToggle: () => _toggleProductAvailability(
                    p['id'] as String,
                    p['is_available'] as bool? ?? true,
                  ),
                  onEdit: () => _showAddProductSheet(existing: p),
                  onDelete: () => _deleteProduct(p['id'] as String),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: TabBar(
              labelColor: _subcategoryColor,
              unselectedLabelColor: const Color(0xFF74777F),
              indicatorColor: _subcategoryColor,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Pending (${_pendingOrders.length})'),
                Tab(text: 'Active (${_activeOrders.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrderList(_pendingOrders, isPending: true),
                _buildOrderList(_activeOrders, isPending: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders, {
    required bool isPending,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey.withAlpha(120),
            ),
            const SizedBox(height: 12),
            Text(
              isPending ? 'No pending orders' : 'No active orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final items = order['items'] as List? ?? [];
        final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
        final status = order['order_status'] as String? ?? 'pending';
        final createdAt =
            DateTime.tryParse(order['created_at'] as String? ?? '') ??
            DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${(order['id'] as String).substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _OrderStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${items.length} item${items.length != 1 ? 's' : ''} • ₹${total.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF44474E),
                  ),
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF74777F),
                  ),
                ),
                if (order['delivery_type'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        order['delivery_type'] == 'home_delivery'
                            ? Icons.delivery_dining_rounded
                            : Icons.store_rounded,
                        size: 14,
                        color: _subcategoryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order['delivery_type'] == 'home_delivery'
                            ? 'Home Delivery'
                            : 'Self Pickup',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _subcategoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateOrderStatus(
                            order['id'] as String,
                            'rejected',
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(
                            order['id'] as String,
                            'accepted',
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  _buildStatusProgressButtons(order),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusProgressButtons(Map<String, dynamic> order) {
    final status = order['order_status'] as String? ?? 'accepted';
    final nextStatus = {
      'accepted': 'preparing',
      'preparing': 'out_for_delivery',
      'out_for_delivery': 'delivered',
    }[status];

    final nextLabel = {
      'accepted': 'Mark Preparing',
      'preparing': 'Out for Delivery',
      'out_for_delivery': 'Mark Delivered',
    }[status];

    if (nextStatus == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _updateOrderStatus(order['id'] as String, nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: _subcategoryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          nextLabel ?? '',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earnings cards
        Row(
          children: [
            Expanded(
              child: _EarningsCard(
                title: "Today's Earnings",
                amount: _todayEarnings,
                icon: Icons.today_rounded,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EarningsCard(
                title: 'Total Earnings',
                amount: _totalEarnings,
                icon: Icons.account_balance_wallet_rounded,
                color: _subcategoryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Products',
                value: '$_totalProducts',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Pending Orders',
                value: '$_pendingCount',
                icon: Icons.pending_actions_rounded,
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Quick actions
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.chat_rounded,
          label: 'Customer Messages',
          color: AppTheme.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.chatListScreen),
        ),
        _QuickActionTile(
          icon: Icons.star_rounded,
          label: 'Ratings & Reviews',
          color: const Color(0xFFFFB300),
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.providerProfileScreen),
        ),
        _QuickActionTile(
          icon: Icons.local_offer_rounded,
          label: 'Manage Offers',
          color: AppTheme.secondary,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.providerProfileScreen),
        ),
        _QuickActionTile(
          icon: Icons.payments_rounded,
          label: 'Earnings & Payouts',
          color: AppTheme.success,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.providerEarningsDashboardScreen,
          ),
        ),
        _QuickActionTile(
          icon: Icons.card_membership_rounded,
          label: 'Subscription Plan',
          color: AppTheme.info,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.providerSubscriptionScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _bottomNavIndex == 0,
                color: _subcategoryColor,
                onTap: () {
                  setState(() => _bottomNavIndex = 0);
                  _tabController.animateTo(0);
                },
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                isSelected: _bottomNavIndex == 1,
                color: _subcategoryColor,
                badge: _pendingCount > 0 ? '$_pendingCount' : null,
                onTap: () {
                  setState(() => _bottomNavIndex = 1);
                  _tabController.animateTo(1);
                },
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isSelected: _bottomNavIndex == 2,
                color: _subcategoryColor,
                onTap: () {
                  setState(() => _bottomNavIndex = 2);
                  _tabController.animateTo(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.accentColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['is_available'] as bool? ?? true;
    final stock = product['stock_quantity'] as int? ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'piece';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable
              ? AppTheme.outlineVariant
              : AppTheme.error.withAlpha(80),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2_rounded, color: accentColor, size: 22),
        ),
        title: Text(
          product['name'] as String? ?? '',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '₹${price.toStringAsFixed(0)}/$unit • Stock: $stock',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: stock == 0 ? AppTheme.error : const Color(0xFF74777F),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isAvailable,
              onChanged: (_) => onToggle(),
              activeColor: accentColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;
  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config =
        {
          'pending': (AppTheme.warning, 'Pending'),
          'accepted': (AppTheme.info, 'Accepted'),
          'preparing': (AppTheme.primary, 'Preparing'),
          'out_for_delivery': (AppTheme.secondary, 'On the Way'),
          'delivered': (AppTheme.success, 'Delivered'),
          'rejected': (AppTheme.error, 'Rejected'),
          'cancelled': (AppTheme.error, 'Cancelled'),
        }[status] ??
        (AppTheme.outline, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.$1.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.$2,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.$1,
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _EarningsCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF74777F),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? color : const Color(0xFF74777F),
                size: 24,
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? color : const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Product Bottom Sheet ─────────────────────────────────────────────────

class _AddProductSheet extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController descCtrl;
  final List<String> categories;
  final List<String> units;
  final String selectedCategory;
  final String selectedUnit;
  final bool isAvailable;
  final String? existingId;
  final Function(String cat, String unit, bool avail) onSave;

  const _AddProductSheet({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.nameCtrl,
    required this.priceCtrl,
    required this.stockCtrl,
    required this.descCtrl,
    required this.categories,
    required this.units,
    required this.selectedCategory,
    required this.selectedUnit,
    required this.isAvailable,
    required this.onSave,
    this.existingId,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  late String _selectedCategory;
  late String _selectedUnit;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory.isNotEmpty
        ? widget.selectedCategory
        : widget.categories.first;
    _selectedUnit = widget.selectedUnit;
    _isAvailable = widget.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.existingId != null ? 'Edit Product' : 'Add Product',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                prefixIcon: Icon(Icons.inventory_2_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: widget.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: widget.units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity *',
                prefixIcon: Icon(Icons.warehouse_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Available for Sale',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeColor: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSave(
                  _selectedCategory,
                  _selectedUnit,
                  _isAvailable,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.existingId != null ? 'Update Product' : 'Add Product',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
