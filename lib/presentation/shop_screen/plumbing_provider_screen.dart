import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Dedicated Provider Screen for Plumbing & Hardware shops
/// Features: Add/Edit products with technical specs (brand, material, dimensions),
/// inventory management, stock status toggle, order processing by category
class PlumbingProviderScreen extends StatefulWidget {
  const PlumbingProviderScreen({super.key});

  @override
  State<PlumbingProviderScreen> createState() => _PlumbingProviderScreenState();
}

class _PlumbingProviderScreenState extends State<PlumbingProviderScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF0277BD);
  static const Color _accentDark = Color(0xFF01579B);
  static const Color _accentLight = Color(0xFFE1F5FE);

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  String _selectedCategoryFilter = 'All';

  // Stats
  int _totalProducts = 0;
  int _pendingOrdersCount = 0;
  double _todayEarnings = 0;
  int _lowStockCount = 0;

  final _supabase = Supabase.instance.client;

  static const List<String> _categoryTabs = [
    'All',
    'Pipes',
    'Fittings',
    'Tools',
    'Building Materials',
  ];

  static const List<String> _orderStatusFlow = [
    'pending',
    'accepted',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  // Mock products for demo
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': 'pp_001',
      'name': 'CPVC Pipe 1/2 inch',
      'category': 'Pipes',
      'price': 85.0,
      'unit': 'piece',
      'stock_quantity': 150,
      'is_available': true,
      'description': 'High-quality CPVC pipe for hot & cold water supply',
      'brand': 'Astral',
      'material': 'CPVC',
      'diameter': '1/2 inch',
      'length': '3 meters',
      'weight': '0.45 kg',
      'pressure_rating': '10 kg/cm²',
    },
    {
      'id': 'pp_002',
      'name': 'uPVC Pipe 1 inch',
      'category': 'Pipes',
      'price': 120.0,
      'unit': 'piece',
      'stock_quantity': 8,
      'is_available': true,
      'description': 'Rigid uPVC pipe for drainage and water supply',
      'brand': 'Supreme',
      'material': 'uPVC',
      'diameter': '1 inch',
      'length': '3 meters',
      'weight': '0.65 kg',
      'pressure_rating': '6 kg/cm²',
    },
    {
      'id': 'pp_003',
      'name': 'GI Pipe 3/4 inch',
      'category': 'Pipes',
      'price': 210.0,
      'unit': 'piece',
      'stock_quantity': 0,
      'is_available': false,
      'description': 'Galvanized iron pipe for heavy-duty applications',
      'brand': 'Tata',
      'material': 'Galvanized Iron',
      'diameter': '3/4 inch',
      'length': '6 meters',
      'weight': '2.1 kg',
      'pressure_rating': '25 kg/cm²',
    },
    {
      'id': 'pp_004',
      'name': 'CPVC Elbow 90° 1/2"',
      'category': 'Fittings',
      'price': 18.0,
      'unit': 'piece',
      'stock_quantity': 500,
      'is_available': true,
      'description': '90-degree elbow fitting for CPVC pipe connections',
      'brand': 'Astral',
      'material': 'CPVC',
      'diameter': '1/2 inch',
      'length': 'N/A',
      'weight': '0.05 kg',
      'pressure_rating': '10 kg/cm²',
    },
    {
      'id': 'pp_005',
      'name': 'Ball Valve 1/2 inch',
      'category': 'Fittings',
      'price': 95.0,
      'unit': 'piece',
      'stock_quantity': 60,
      'is_available': true,
      'description': 'Brass ball valve for water flow control',
      'brand': 'Zoloto',
      'material': 'Brass',
      'diameter': '1/2 inch',
      'length': 'N/A',
      'weight': '0.18 kg',
      'pressure_rating': '20 bar',
    },
    {
      'id': 'pp_006',
      'name': 'Pipe Wrench 14 inch',
      'category': 'Tools',
      'price': 380.0,
      'unit': 'piece',
      'stock_quantity': 25,
      'is_available': true,
      'description': 'Heavy-duty pipe wrench for plumbing work',
      'brand': 'Taparia',
      'material': 'Drop Forged Steel',
      'diameter': 'N/A',
      'length': '14 inch',
      'weight': '0.95 kg',
      'pressure_rating': 'N/A',
    },
    {
      'id': 'pp_007',
      'name': 'Pipe Cutter 1-3 inch',
      'category': 'Tools',
      'price': 520.0,
      'unit': 'piece',
      'stock_quantity': 12,
      'is_available': true,
      'description': 'Rotary pipe cutter for clean cuts on copper/PVC',
      'brand': 'Stanley',
      'material': 'Alloy Steel',
      'diameter': '1-3 inch capacity',
      'length': '20 cm',
      'weight': '0.42 kg',
      'pressure_rating': 'N/A',
    },
    {
      'id': 'pp_008',
      'name': 'Portland Cement 50kg',
      'category': 'Building Materials',
      'price': 380.0,
      'unit': 'bag',
      'stock_quantity': 200,
      'is_available': true,
      'description': 'OPC 53 grade Portland cement for construction',
      'brand': 'UltraTech',
      'material': 'Portland Cement',
      'diameter': 'N/A',
      'length': 'N/A',
      'weight': '50 kg',
      'pressure_rating': '53 MPa',
    },
    {
      'id': 'pp_009',
      'name': 'River Sand (Fine) 1 cu.ft',
      'category': 'Building Materials',
      'price': 45.0,
      'unit': 'bag',
      'stock_quantity': 5,
      'is_available': true,
      'description': 'Washed river sand for plastering and masonry',
      'brand': 'Local',
      'material': 'Natural Sand',
      'diameter': 'N/A',
      'length': 'N/A',
      'weight': '25 kg',
      'pressure_rating': 'N/A',
    },
  ];

  // Mock orders for demo
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'ord_001',
      'customer_name': 'Ramesh Patil',
      'customer_phone': '9876543210',
      'order_status': 'pending',
      'total_amount': 850.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'items': [
        {
          'name': 'CPVC Pipe 1/2 inch',
          'category': 'Pipes',
          'quantity': 10,
          'price': 85.0,
        },
      ],
      'delivery_address': '12, Shivaji Nagar, Pune',
      'delivery_type': 'Home Delivery',
    },
    {
      'id': 'ord_002',
      'customer_name': 'Suresh Kumar',
      'customer_phone': '9123456789',
      'order_status': 'accepted',
      'total_amount': 1140.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'items': [
        {
          'name': 'Ball Valve 1/2 inch',
          'category': 'Fittings',
          'quantity': 6,
          'price': 95.0,
        },
        {
          'name': 'CPVC Elbow 90°',
          'category': 'Fittings',
          'quantity': 20,
          'price': 18.0,
        },
      ],
      'delivery_address': '45, MG Road, Nashik',
      'delivery_type': 'Self Pickup',
    },
    {
      'id': 'ord_003',
      'customer_name': 'Priya Sharma',
      'customer_phone': '9988776655',
      'order_status': 'preparing',
      'total_amount': 2280.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 5))
          .toIso8601String(),
      'items': [
        {
          'name': 'Portland Cement 50kg',
          'category': 'Building Materials',
          'quantity': 6,
          'price': 380.0,
        },
      ],
      'delivery_address': '78, Parvati, Pune',
      'delivery_type': 'Home Delivery',
    },
    {
      'id': 'ord_004',
      'customer_name': 'Anil Deshmukh',
      'customer_phone': '9765432100',
      'order_status': 'delivered',
      'total_amount': 760.0,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'items': [
        {
          'name': 'Pipe Wrench 14 inch',
          'category': 'Tools',
          'quantity': 2,
          'price': 380.0,
        },
      ],
      'delivery_address': '33, Kothrud, Pune',
      'delivery_type': 'Home Delivery',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        final products = await _supabase
            .from('shop_products')
            .select()
            .eq('provider_id', userId)
            .eq('shop_subcategory', 'plumbing_hardware')
            .order('created_at', ascending: false);

        final orders = await _supabase
            .from('shop_orders')
            .select()
            .eq('provider_id', userId)
            .eq('shop_subcategory', 'plumbing_hardware')
            .order('created_at', ascending: false);

        final productList = (products as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
        final orderList = (orders as List)
            .map((o) => Map<String, dynamic>.from(o as Map))
            .toList();

        _computeStats(productList, orderList);

        if (mounted) {
          setState(() {
            _products = productList.isNotEmpty ? productList : _mockProducts;
            _orders = orderList.isNotEmpty ? orderList : _mockOrders;
            _isLoading = false;
          });
        }
      } else {
        _computeStats(_mockProducts, _mockOrders);
        if (mounted) {
          setState(() {
            _products = _mockProducts;
            _orders = _mockOrders;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      _computeStats(_mockProducts, _mockOrders);
      if (mounted) {
        setState(() {
          _products = _mockProducts;
          _orders = _mockOrders;
          _isLoading = false;
        });
      }
    }
  }

  void _computeStats(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> orders,
  ) {
    final pending = orders.where((o) => o['order_status'] == 'pending').length;
    final today = DateTime.now();
    double todayEarnings = 0;
    for (final o in orders) {
      if (o['order_status'] == 'delivered') {
        final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
        if (createdAt != null &&
            createdAt.year == today.year &&
            createdAt.month == today.month &&
            createdAt.day == today.day) {
          todayEarnings += (o['total_amount'] as num?)?.toDouble() ?? 0;
        }
      }
    }
    final lowStock = products.where((p) {
      final qty = (p['stock_quantity'] as num?)?.toInt() ?? 0;
      return qty > 0 && qty <= 10;
    }).length;

    _totalProducts = products.length;
    _pendingOrdersCount = pending;
    _todayEarnings = todayEarnings;
    _lowStockCount = lowStock;
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryFilter == 'All') return _products;
    return _products
        .where((p) => p['category'] == _selectedCategoryFilter)
        .toList();
  }

  Future<void> _toggleStock(Map<String, dynamic> product) async {
    final id = product['id'] as String;
    final current = product['is_available'] as bool? ?? true;
    try {
      await _supabase
          .from('shop_products')
          .update({'is_available': !current})
          .eq('id', id);
      await _loadData();
    } catch (_) {
      // Update locally for demo
      if (mounted) {
        setState(() {
          final idx = _products.indexWhere((p) => p['id'] == id);
          if (idx != -1) {
            _products[idx] = Map<String, dynamic>.from(_products[idx])
              ..['is_available'] = !current;
          }
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('shop_orders')
          .update({'order_status': newStatus})
          .eq('id', orderId);
      await _loadData();
    } catch (_) {
      if (mounted) {
        setState(() {
          final idx = _orders.indexWhere((o) => o['id'] == orderId);
          if (idx != -1) {
            _orders[idx] = Map<String, dynamic>.from(_orders[idx])
              ..['order_status'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${_statusLabel(newStatus)}'),
            backgroundColor: _accent,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _supabase.from('shop_products').delete().eq('id', productId);
        await _loadData();
      } catch (_) {
        if (mounted) {
          setState(() {
            _products.removeWhere((p) => p['id'] == productId);
          });
        }
      }
    }
  }

  void _showProductForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlumbingProductFormSheet(
        existing: existing,
        accent: _accent,
        onSave: (data) async {
          Navigator.pop(ctx);
          await _saveProduct(data, existing?['id'] as String?);
        },
      ),
    );
  }

  Future<void> _saveProduct(
    Map<String, dynamic> data,
    String? existingId,
  ) async {
    final userId = SupabaseService.instance.currentUser?.id;
    final payload = {
      ...data,
      'provider_id': userId ?? 'demo_provider',
      'shop_subcategory': 'plumbing_hardware',
    };
    try {
      if (existingId != null) {
        await _supabase
            .from('shop_products')
            .update(payload)
            .eq('id', existingId);
      } else {
        await _supabase.from('shop_products').insert(payload);
      }
      await _loadData();
    } catch (_) {
      // Demo mode: update locally
      if (mounted) {
        setState(() {
          if (existingId != null) {
            final idx = _products.indexWhere((p) => p['id'] == existingId);
            if (idx != -1) _products[idx] = {..._products[idx], ...data};
          } else {
            _products.insert(0, {
              'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
              ...data,
            });
          }
          _computeStats(_products, _orders);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingId != null ? 'Product updated' : 'Product added',
            ),
            backgroundColor: _accent,
          ),
        );
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'accepted':
        return const Color(0xFF1976D2);
      case 'preparing':
        return const Color(0xFF7B1FA2);
      case 'out_for_delivery':
        return const Color(0xFF00897B);
      case 'delivered':
        return const Color(0xFF388E3C);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  String? _nextStatus(String current) {
    final idx = _orderStatusFlow.indexOf(current);
    if (idx == -1 || idx >= _orderStatusFlow.length - 1) return null;
    return _orderStatusFlow[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plumbing & Hardware',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Provider Dashboard',
              style: GoogleFonts.dmSans(
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
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.card_membership_rounded),
            tooltip: 'Subscription',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.providerSubscriptionScreen,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmSignOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(160),
          labelStyle: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 18),
              text: 'Products',
            ),
            Tab(
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              text: _pendingOrdersCount > 0
                  ? 'Orders ($_pendingOrdersCount)'
                  : 'Orders',
            ),
            const Tab(
              icon: Icon(Icons.bar_chart_rounded, size: 18),
              text: 'Analytics',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showProductForm(),
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Product',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }

  // ── Products Tab ──────────────────────────────────────────────────────────

  Widget _buildProductsTab() {
    return Column(
      children: [
        _buildStatsRow(),
        _buildCategoryFilterBar(),
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState(
                  Icons.inventory_2_outlined,
                  'No products yet',
                  'Tap + Add Product to get started',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (ctx, i) =>
                      _buildProductCard(_filteredProducts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: _accent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatChip(
            label: 'Products',
            value: '$_totalProducts',
            icon: Icons.inventory_2_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Pending',
            value: '$_pendingOrdersCount',
            icon: Icons.pending_actions_rounded,
            color: _pendingOrdersCount > 0
                ? const Color(0xFFFFCC02)
                : Colors.white,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Low Stock',
            value: '$_lowStockCount',
            icon: Icons.warning_amber_rounded,
            color: _lowStockCount > 0 ? const Color(0xFFFF7043) : Colors.white,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: "Today's ₹",
            value: '₹${_todayEarnings.toStringAsFixed(0)}',
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF69F0AE),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categoryTabs.length,
        itemBuilder: (ctx, i) {
          final cat = _categoryTabs[i];
          final selected = _selectedCategoryFilter == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryFilter = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? _accent : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _accent : Colors.transparent,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF546E7A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isAvailable = product['is_available'] as bool? ?? true;
    final stock = (product['stock_quantity'] as num?)?.toInt() ?? 0;
    final isLowStock = stock > 0 && stock <= 10;
    final isOutOfStock = stock == 0;

    Color stockColor;
    String stockLabel;
    if (isOutOfStock) {
      stockColor = const Color(0xFFD32F2F);
      stockLabel = 'Out of Stock';
    } else if (isLowStock) {
      stockColor = const Color(0xFFF57C00);
      stockLabel = 'Low Stock ($stock)';
    } else {
      stockColor = const Color(0xFF388E3C);
      stockLabel = 'In Stock ($stock)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isAvailable ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _accentLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product['category'] as String? ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _accentDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stockLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
                const Spacer(),
                // Stock toggle
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isAvailable,
                    onChanged: (_) => _toggleStock(product),
                    activeColor: _accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // Product name & price
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product['name'] as String? ?? '',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2332),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(product['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                    Text(
                      'per ${product['unit'] ?? 'piece'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Technical specs grid
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _buildSpecsGrid(product),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showProductForm(existing: product),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStockUpdateDialog(product),
                    icon: const Icon(Icons.warehouse_rounded, size: 14),
                    label: Text(
                      'Stock',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF388E3C),
                      side: const BorderSide(color: Color(0xFF388E3C)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () =>
                      _deleteProduct(product['id'] as String? ?? ''),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid(Map<String, dynamic> product) {
    final specs = <_SpecItem>[];
    if ((product['brand'] as String?)?.isNotEmpty == true &&
        product['brand'] != 'N/A') {
      specs.add(
        _SpecItem(Icons.business_rounded, 'Brand', product['brand'] as String),
      );
    }
    if ((product['material'] as String?)?.isNotEmpty == true &&
        product['material'] != 'N/A') {
      specs.add(
        _SpecItem(
          Icons.layers_rounded,
          'Material',
          product['material'] as String,
        ),
      );
    }
    if ((product['diameter'] as String?)?.isNotEmpty == true &&
        product['diameter'] != 'N/A') {
      specs.add(
        _SpecItem(
          Icons.radio_button_unchecked_rounded,
          'Diameter',
          product['diameter'] as String,
        ),
      );
    }
    if ((product['length'] as String?)?.isNotEmpty == true &&
        product['length'] != 'N/A') {
      specs.add(
        _SpecItem(
          Icons.straighten_rounded,
          'Length',
          product['length'] as String,
        ),
      );
    }
    if ((product['weight'] as String?)?.isNotEmpty == true &&
        product['weight'] != 'N/A') {
      specs.add(
        _SpecItem(Icons.scale_rounded, 'Weight', product['weight'] as String),
      );
    }
    if ((product['pressure_rating'] as String?)?.isNotEmpty == true &&
        product['pressure_rating'] != 'N/A') {
      specs.add(
        _SpecItem(
          Icons.compress_rounded,
          'Pressure',
          product['pressure_rating'] as String,
        ),
      );
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: specs.map((s) => _SpecChip(spec: s)).toList(),
    );
  }

  void _showStockUpdateDialog(Map<String, dynamic> product) {
    final ctrl = TextEditingController(
      text: (product['stock_quantity'] as num?)?.toString() ?? '0',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Stock',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'] as String? ?? '',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: product['unit'] as String? ?? 'piece',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _accent, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(ctrl.text) ?? 0;
              Navigator.pop(ctx);
              try {
                await _supabase
                    .from('shop_products')
                    .update({'stock_quantity': qty})
                    .eq('id', product['id'] as String);
                await _loadData();
              } catch (_) {
                if (mounted) {
                  setState(() {
                    final idx = _products.indexWhere(
                      (p) => p['id'] == product['id'],
                    );
                    if (idx != -1) {
                      _products[idx] = Map<String, dynamic>.from(_products[idx])
                        ..['stock_quantity'] = qty
                        ..['is_available'] = qty > 0;
                    }
                    _computeStats(_products, _orders);
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: Text(
              'Update',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Orders Tab ────────────────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    // Group orders by category
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Pipes': [],
      'Fittings': [],
      'Tools': [],
      'Building Materials': [],
      'Mixed': [],
    };

    for (final order in _orders) {
      final items = order['items'] as List? ?? [];
      final categories = items
          .map((i) => (i as Map)['category'] as String? ?? '')
          .toSet();
      if (categories.length == 1) {
        final cat = categories.first;
        if (grouped.containsKey(cat)) {
          grouped[cat]!.add(order);
        } else {
          grouped['Mixed']!.add(order);
        }
      } else {
        grouped['Mixed']!.add(order);
      }
    }

    final hasOrders = _orders.isNotEmpty;

    return hasOrders
        ? ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Active orders summary
              _buildOrdersSummaryRow(),
              const SizedBox(height: 16),
              // Category sections
              ...grouped.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((e) => _buildOrderCategorySection(e.key, e.value)),
            ],
          )
        : _buildEmptyState(
            Icons.receipt_long_outlined,
            'No orders yet',
            'Orders from customers will appear here',
          );
  }

  Widget _buildOrdersSummaryRow() {
    final pending = _orders.where((o) => o['order_status'] == 'pending').length;
    final active = _orders
        .where(
          (o) =>
              o['order_status'] == 'accepted' ||
              o['order_status'] == 'preparing' ||
              o['order_status'] == 'out_for_delivery',
        )
        .length;
    final delivered = _orders
        .where((o) => o['order_status'] == 'delivered')
        .length;

    return Row(
      children: [
        Expanded(
          child: _OrderSummaryTile(
            label: 'Pending',
            count: pending,
            color: const Color(0xFFF57C00),
            icon: Icons.pending_actions_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OrderSummaryTile(
            label: 'Active',
            count: active,
            color: const Color(0xFF1976D2),
            icon: Icons.local_shipping_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _OrderSummaryTile(
            label: 'Delivered',
            count: delivered,
            color: const Color(0xFF388E3C),
            icon: Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCategorySection(
    String category,
    List<Map<String, dynamic>> orders,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(_categoryIcon(category), size: 16, color: _accent),
              const SizedBox(width: 6),
              Text(
                category,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2332),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${orders.length}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accentDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...orders.map((o) => _buildOrderCard(o)),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Pipes':
        return Icons.plumbing_rounded;
      case 'Fittings':
        return Icons.settings_rounded;
      case 'Tools':
        return Icons.build_rounded;
      case 'Building Materials':
        return Icons.foundation_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['order_status'] as String? ?? 'pending';
    final statusColor = _statusColor(status);
    final items = order['items'] as List? ?? [];
    final nextStatus = _nextStatus(status);
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customer_name'] as String? ?? 'Customer',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2332),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            order['customer_phone'] as String? ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeAgo,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(order['total_amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Items list
            ...items.take(3).map((item) {
              final i = item as Map;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 5, color: Color(0xFF90A4AE)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${i['name']} × ${i['quantity']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF546E7A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${((i['price'] as num?)?.toDouble() ?? 0) * ((i['quantity'] as num?)?.toInt() ?? 1)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (items.length > 3)
              Text(
                '+${items.length - 3} more items',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            // Delivery info
            if ((order['delivery_address'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order['delivery_address'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order['delivery_type'] as String? ?? '',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF546E7A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Action button
            if (nextStatus != null && status != 'cancelled') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateOrderStatus(order['id'] as String, nextStatus),
                  icon: Icon(_nextStatusIcon(nextStatus), size: 16),
                  label: Text(
                    'Mark as ${_statusLabel(nextStatus)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusColor(nextStatus),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _nextStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_rounded;
      case 'preparing':
        return Icons.handyman_rounded;
      case 'out_for_delivery':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Analytics Tab ─────────────────────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    final totalRevenue = _orders
        .where((o) => o['order_status'] == 'delivered')
        .fold<double>(
          0,
          (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0),
        );

    final Map<String, int> categoryOrderCount = {
      'Pipes': 0,
      'Fittings': 0,
      'Tools': 0,
      'Building Materials': 0,
    };
    for (final order in _orders) {
      final items = order['items'] as List? ?? [];
      for (final item in items) {
        final cat = (item as Map)['category'] as String? ?? '';
        if (categoryOrderCount.containsKey(cat)) {
          categoryOrderCount[cat] = categoryOrderCount[cat]! + 1;
        }
      }
    }

    final inStockCount = _products
        .where((p) => p['is_available'] == true)
        .length;
    final outOfStockCount = _products.length - inStockCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue cards
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                title: "Today's Revenue",
                value: '₹${_todayEarnings.toStringAsFixed(0)}',
                icon: Icons.today_rounded,
                color: const Color(0xFF388E3C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Revenue',
                value: '₹${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                color: _accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Orders',
                value: '${_orders.length}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Products',
                value: '$_totalProducts',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFF57C00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Inventory status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Status',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2332),
                ),
              ),
              const SizedBox(height: 14),
              _InventoryBar(
                label: 'In Stock',
                count: inStockCount,
                total: _totalProducts,
                color: const Color(0xFF388E3C),
              ),
              const SizedBox(height: 8),
              _InventoryBar(
                label: 'Low Stock (≤10)',
                count: _lowStockCount,
                total: _totalProducts,
                color: const Color(0xFFF57C00),
              ),
              const SizedBox(height: 8),
              _InventoryBar(
                label: 'Out of Stock',
                count: outOfStockCount,
                total: _totalProducts,
                color: const Color(0xFFD32F2F),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Orders by category
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders by Category',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2332),
                ),
              ),
              const SizedBox(height: 14),
              ...categoryOrderCount.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(_categoryIcon(e.key), size: 16, color: _accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${e.value} orders',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Subscription banner
        GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.providerSubscriptionScreen,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentDark, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.card_membership_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Subscription',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'View your plan, upgrade or renew',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(217),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loginScreen,
          (_) => false,
        );
      }
    }
  }
}

// ── Product Form Sheet ────────────────────────────────────────────────────────

class _PlumbingProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Color accent;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _PlumbingProductFormSheet({
    required this.accent,
    required this.onSave,
    this.existing,
  });

  @override
  State<_PlumbingProductFormSheet> createState() =>
      _PlumbingProductFormSheetState();
}

class _PlumbingProductFormSheetState extends State<_PlumbingProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _diameterCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _pressureCtrl = TextEditingController();

  String _selectedCategory = 'Pipes';
  String _selectedUnit = 'piece';
  bool _isAvailable = true;
  bool _isSaving = false;

  static const List<String> _categories = [
    'Pipes',
    'Fittings',
    'Tools',
    'Building Materials',
  ];

  static const List<String> _units = [
    'piece',
    'meter',
    'kg',
    'bag',
    'set',
    'bundle',
    'box',
    'litre',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['name'] as String? ?? '';
      _priceCtrl.text = (e['price'] as num?)?.toString() ?? '';
      _stockCtrl.text = (e['stock_quantity'] as num?)?.toString() ?? '';
      _descCtrl.text = e['description'] as String? ?? '';
      _brandCtrl.text = e['brand'] as String? ?? '';
      _materialCtrl.text = e['material'] as String? ?? '';
      _diameterCtrl.text = e['diameter'] as String? ?? '';
      _lengthCtrl.text = e['length'] as String? ?? '';
      _weightCtrl.text = e['weight'] as String? ?? '';
      _pressureCtrl.text = e['pressure_rating'] as String? ?? '';
      _selectedCategory = e['category'] as String? ?? 'Pipes';
      _selectedUnit = e['unit'] as String? ?? 'piece';
      _isAvailable = e['is_available'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _materialCtrl.dispose();
    _diameterCtrl.dispose();
    _lengthCtrl.dispose();
    _weightCtrl.dispose();
    _pressureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                  color: widget.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Edit Product' : 'Add New Product',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2332),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Basic Information'),
                    const SizedBox(height: 8),
                    // Name
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Product Name *',
                      hint: 'e.g. CPVC Pipe 1/2 inch',
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    // Category + Unit row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Category',
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Unit',
                            value: _selectedUnit,
                            items: _units,
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price + Stock row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceCtrl,
                            label: 'Price (₹) *',
                            hint: '0.00',
                            keyboardType: TextInputType.number,
                            prefixText: '₹ ',
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _stockCtrl,
                            label: 'Stock Qty *',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Brief product description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('Technical Specifications'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _brandCtrl,
                            label: 'Brand',
                            hint: 'e.g. Astral, Tata',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _materialCtrl,
                            label: 'Material',
                            hint: 'e.g. CPVC, Brass',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _diameterCtrl,
                            label: 'Diameter / Size',
                            hint: 'e.g. 1/2 inch',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _lengthCtrl,
                            label: 'Length / Dimension',
                            hint: 'e.g. 3 meters',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _weightCtrl,
                            label: 'Weight',
                            hint: 'e.g. 0.45 kg',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _pressureCtrl,
                            label: 'Pressure Rating',
                            hint: 'e.g. 10 kg/cm²',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Availability toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAvailable
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: _isAvailable
                                ? const Color(0xFF388E3C)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAvailable
                                  ? 'Product is Available'
                                  : 'Product is Unavailable',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF37474F),
                              ),
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (v) => setState(() => _isAvailable = v),
                            activeColor: widget.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEdit ? 'Update Product' : 'Add Product',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: widget.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A2332),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: Colors.grey.shade400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF1A2332)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.accent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
      ),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
      'description': _descCtrl.text.trim(),
      'brand': _brandCtrl.text.trim(),
      'material': _materialCtrl.text.trim(),
      'diameter': _diameterCtrl.text.trim(),
      'length': _lengthCtrl.text.trim(),
      'weight': _weightCtrl.text.trim(),
      'pressure_rating': _pressureCtrl.text.trim(),
      'is_available': _isAvailable,
    };
    await widget.onSave(data);
    if (mounted) setState(() => _isSaving = false);
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _SpecItem {
  final IconData icon;
  final String key;
  final String value;
  const _SpecItem(this.icon, this.key, this.value);
}

class _SpecChip extends StatelessWidget {
  final _SpecItem spec;
  const _SpecChip({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 11, color: const Color(0xFF546E7A)),
          const SizedBox(width: 4),
          Text(
            '${spec.key}: ',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF78909C),
            ),
          ),
          Text(
            spec.value,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: Colors.white.withAlpha(180),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _OrderSummaryTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2332),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _InventoryBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF546E7A),
                ),
              ),
            ),
            Text(
              '$count / $total',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
