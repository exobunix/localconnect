import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Dedicated Provider Screen for Electrical & Hardware shops
/// Features: Add/Edit products with technical specs (wattage, voltage, warranty, brand),
/// category management (Wires, Switches, Lights, Tools, etc.),
/// stock status tracking, and order processing by category.
class ElectricalProviderScreen extends StatefulWidget {
  const ElectricalProviderScreen({super.key});

  @override
  State<ElectricalProviderScreen> createState() =>
      _ElectricalProviderScreenState();
}

class _ElectricalProviderScreenState extends State<ElectricalProviderScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFF57C00);
  static const Color _accentDark = Color(0xFFE65100);
  static const Color _accentLight = Color(0xFFFFF3E0);

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  String _selectedCategoryFilter = 'All';

  int _totalProducts = 0;
  int _pendingOrdersCount = 0;
  double _todayEarnings = 0;
  int _lowStockCount = 0;

  final _supabase = Supabase.instance.client;

  static const List<String> _categoryTabs = [
    'All',
    'Wires',
    'Switches',
    'Lights',
    'Fans',
    'Tools',
    'MCBs',
    'Accessories',
  ];

  static const List<String> _orderStatusFlow = [
    'pending',
    'accepted',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  // ── Mock Products ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': 'ep_001',
      'name': 'Finolex FR Wire 1.5 sq.mm',
      'category': 'Wires',
      'price': 1250.0,
      'unit': '90m coil',
      'stock_quantity': 40,
      'is_available': true,
      'description':
          'Flame retardant PVC insulated copper wire for home wiring',
      'brand': 'Finolex',
      'wattage': 'N/A',
      'voltage': '1100V',
      'warranty': '2 years',
      'material': 'Copper',
    },
    {
      'id': 'ep_002',
      'name': 'Polycab Wire 2.5 sq.mm',
      'category': 'Wires',
      'price': 2100.0,
      'unit': '90m coil',
      'stock_quantity': 7,
      'is_available': true,
      'description': 'FRLS copper wire for power circuits and heavy loads',
      'brand': 'Polycab',
      'wattage': 'N/A',
      'voltage': '1100V',
      'warranty': '3 years',
      'material': 'Copper',
    },
    {
      'id': 'ep_003',
      'name': 'Havells 6A Modular Switch',
      'category': 'Switches',
      'price': 85.0,
      'unit': 'piece',
      'stock_quantity': 200,
      'is_available': true,
      'description': 'Crabtree Athena 6A one-way modular switch',
      'brand': 'Havells',
      'wattage': '1380W max',
      'voltage': '240V AC',
      'warranty': '2 years',
      'material': 'Polycarbonate',
    },
    {
      'id': 'ep_004',
      'name': 'Legrand 16A Socket',
      'category': 'Switches',
      'price': 145.0,
      'unit': 'piece',
      'stock_quantity': 120,
      'is_available': true,
      'description': '16A 3-pin modular socket with shutter',
      'brand': 'Legrand',
      'wattage': '3680W max',
      'voltage': '240V AC',
      'warranty': '2 years',
      'material': 'Polycarbonate',
    },
    {
      'id': 'ep_005',
      'name': 'Philips 9W LED Bulb',
      'category': 'Lights',
      'price': 95.0,
      'unit': 'piece',
      'stock_quantity': 300,
      'is_available': true,
      'description': '9W E27 LED bulb, 900 lumens, cool daylight',
      'brand': 'Philips',
      'wattage': '9W',
      'voltage': '220-240V',
      'warranty': '2 years',
      'material': 'Plastic + Aluminium',
    },
    {
      'id': 'ep_006',
      'name': 'Syska 20W LED Batten',
      'category': 'Lights',
      'price': 320.0,
      'unit': 'piece',
      'stock_quantity': 0,
      'is_available': false,
      'description': '2-feet LED batten light for offices and homes',
      'brand': 'Syska',
      'wattage': '20W',
      'voltage': '220V AC',
      'warranty': '3 years',
      'material': 'Polycarbonate',
    },
    {
      'id': 'ep_007',
      'name': 'Crompton Ceiling Fan 48"',
      'category': 'Fans',
      'price': 1850.0,
      'unit': 'piece',
      'stock_quantity': 15,
      'is_available': true,
      'description': 'High-speed 3-blade ceiling fan with anti-dust coating',
      'brand': 'Crompton',
      'wattage': '75W',
      'voltage': '230V AC',
      'warranty': '2 years',
      'material': 'Aluminium Blades',
    },
    {
      'id': 'ep_008',
      'name': 'Bajaj Exhaust Fan 9"',
      'category': 'Fans',
      'price': 680.0,
      'unit': 'piece',
      'stock_quantity': 30,
      'is_available': true,
      'description': 'Wall-mount exhaust fan for kitchen and bathroom',
      'brand': 'Bajaj',
      'wattage': '30W',
      'voltage': '230V AC',
      'warranty': '1 year',
      'material': 'ABS Plastic',
    },
    {
      'id': 'ep_009',
      'name': 'Stanley Screwdriver Set',
      'category': 'Tools',
      'price': 450.0,
      'unit': 'set',
      'stock_quantity': 25,
      'is_available': true,
      'description': '6-piece insulated screwdriver set for electricians',
      'brand': 'Stanley',
      'wattage': 'N/A',
      'voltage': '1000V insulated',
      'warranty': '1 year',
      'material': 'Chrome Vanadium Steel',
    },
    {
      'id': 'ep_010',
      'name': 'Fluke Digital Multimeter',
      'category': 'Tools',
      'price': 3200.0,
      'unit': 'piece',
      'stock_quantity': 8,
      'is_available': true,
      'description': 'Auto-ranging digital multimeter for AC/DC measurements',
      'brand': 'Fluke',
      'wattage': 'N/A',
      'voltage': 'Measures up to 600V',
      'warranty': '3 years',
      'material': 'ABS Housing',
    },
    {
      'id': 'ep_011',
      'name': 'Schneider 32A MCB',
      'category': 'MCBs',
      'price': 280.0,
      'unit': 'piece',
      'stock_quantity': 60,
      'is_available': true,
      'description':
          'Single-pole MCB for overload and short-circuit protection',
      'brand': 'Schneider',
      'wattage': 'N/A',
      'voltage': '240V AC',
      'warranty': '5 years',
      'material': 'Thermoplastic',
    },
    {
      'id': 'ep_012',
      'name': 'Anchor 3-Pin Plug Top',
      'category': 'Accessories',
      'price': 35.0,
      'unit': 'piece',
      'stock_quantity': 500,
      'is_available': true,
      'description': '3-pin 6A plug top with brass pins',
      'brand': 'Anchor',
      'wattage': '1380W max',
      'voltage': '240V AC',
      'warranty': '1 year',
      'material': 'Bakelite',
    },
  ];

  // ── Mock Orders ────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'eord_001',
      'customer_name': 'Rajesh Sharma',
      'customer_phone': '9876543210',
      'order_status': 'pending',
      'total_amount': 5000.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'items': [
        {
          'name': 'Finolex FR Wire 1.5 sq.mm',
          'category': 'Wires',
          'quantity': 4,
          'price': 1250.0,
        },
      ],
      'delivery_address': '12, Shivaji Nagar, Pune',
      'delivery_type': 'Home Delivery',
    },
    {
      'id': 'eord_002',
      'customer_name': 'Meena Kulkarni',
      'customer_phone': '9123456789',
      'order_status': 'accepted',
      'total_amount': 1140.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'items': [
        {
          'name': 'Havells 6A Modular Switch',
          'category': 'Switches',
          'quantity': 8,
          'price': 85.0,
        },
        {
          'name': 'Legrand 16A Socket',
          'category': 'Switches',
          'quantity': 4,
          'price': 145.0,
        },
      ],
      'delivery_address': '45, MG Road, Nashik',
      'delivery_type': 'Self Pickup',
    },
    {
      'id': 'eord_003',
      'customer_name': 'Sunil Patil',
      'customer_phone': '9988776655',
      'order_status': 'preparing',
      'total_amount': 3700.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 5))
          .toIso8601String(),
      'items': [
        {
          'name': 'Crompton Ceiling Fan 48"',
          'category': 'Fans',
          'quantity': 2,
          'price': 1850.0,
        },
      ],
      'delivery_address': '78, Parvati, Pune',
      'delivery_type': 'Home Delivery',
    },
    {
      'id': 'eord_004',
      'customer_name': 'Anil Deshmukh',
      'customer_phone': '9765432100',
      'order_status': 'out_for_delivery',
      'total_amount': 3200.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 8))
          .toIso8601String(),
      'items': [
        {
          'name': 'Fluke Digital Multimeter',
          'category': 'Tools',
          'quantity': 1,
          'price': 3200.0,
        },
      ],
      'delivery_address': '33, Kothrud, Pune',
      'delivery_type': 'Home Delivery',
    },
    {
      'id': 'eord_005',
      'customer_name': 'Priya Joshi',
      'customer_phone': '9654321098',
      'order_status': 'delivered',
      'total_amount': 1680.0,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
      'items': [
        {
          'name': 'Schneider 32A MCB',
          'category': 'MCBs',
          'quantity': 6,
          'price': 280.0,
        },
      ],
      'delivery_address': '22, Baner, Pune',
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
            .eq('shop_subcategory', 'electrical')
            .order('created_at', ascending: false);

        final orders = await _supabase
            .from('shop_orders')
            .select()
            .eq('provider_id', userId)
            .eq('shop_subcategory', 'electrical')
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
    setState(() {
      final idx = _products.indexWhere((p) => p['id'] == id);
      if (idx != -1) _products[idx]['is_available'] = !current;
    });
    try {
      await _supabase
          .from('shop_products')
          .update({'is_available': !current})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _products.removeWhere((p) => p['id'] == id));
    try {
      await _supabase.from('shop_products').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> _advanceOrderStatus(Map<String, dynamic> order) async {
    final id = order['id'] as String;
    final current = order['order_status'] as String? ?? 'pending';
    final idx = _orderStatusFlow.indexOf(current);
    if (idx == -1 || idx >= _orderStatusFlow.length - 1) return;
    final next = _orderStatusFlow[idx + 1];
    setState(() {
      final oi = _orders.indexWhere((o) => o['id'] == id);
      if (oi != -1) _orders[oi]['order_status'] = next;
    });
    _computeStats(_products, _orders);
    try {
      await _supabase
          .from('shop_orders')
          .update({'order_status': next})
          .eq('id', id);
    } catch (_) {}
  }

  void _showAddEditProductSheet({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? product['name'] as String? : '',
    );
    final priceCtrl = TextEditingController(
      text: isEdit ? (product['price'] as num?)?.toString() : '',
    );
    final unitCtrl = TextEditingController(
      text: isEdit ? product['unit'] as String? : '',
    );
    final stockCtrl = TextEditingController(
      text: isEdit ? (product['stock_quantity'] as num?)?.toString() : '',
    );
    final descCtrl = TextEditingController(
      text: isEdit ? product['description'] as String? : '',
    );
    final brandCtrl = TextEditingController(
      text: isEdit ? product['brand'] as String? : '',
    );
    final wattageCtrl = TextEditingController(
      text: isEdit ? product['wattage'] as String? : '',
    );
    final voltageCtrl = TextEditingController(
      text: isEdit ? product['voltage'] as String? : '',
    );
    final warrantyCtrl = TextEditingController(
      text: isEdit ? product['warranty'] as String? : '',
    );
    final materialCtrl = TextEditingController(
      text: isEdit ? product['material'] as String? : '',
    );

    String selectedCategory = isEdit
        ? (product['category'] as String? ?? _categoryTabs[1])
        : _categoryTabs[1];
    bool isAvailable = isEdit
        ? (product['is_available'] as bool? ?? true)
        : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentLight,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Icon(
                          Icons.electrical_services_rounded,
                          color: _accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Product' : 'Add New Product',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionLabel('Basic Info'),
                      const SizedBox(height: 10),
                      _formField(
                        nameCtrl,
                        'Product Name *',
                        Icons.inventory_2_rounded,
                      ),
                      const SizedBox(height: 12),
                      // Category dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFF9E9E9E),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: _categoryTabs
                            .where((c) => c != 'All')
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: GoogleFonts.manrope()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => selectedCategory = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              priceCtrl,
                              'Price (₹) *',
                              Icons.currency_rupee_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              unitCtrl,
                              'Unit (piece/set/coil)',
                              Icons.straighten_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        stockCtrl,
                        'Stock Quantity *',
                        Icons.warehouse_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        descCtrl,
                        'Description',
                        Icons.description_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Technical Specifications'),
                      const SizedBox(height: 10),
                      _formField(brandCtrl, 'Brand *', Icons.business_rounded),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              wattageCtrl,
                              'Wattage',
                              Icons.bolt_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              voltageCtrl,
                              'Voltage',
                              Icons.electric_bolt_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              warrantyCtrl,
                              'Warranty',
                              Icons.verified_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              materialCtrl,
                              'Material',
                              Icons.layers_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Availability toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.toggle_on_rounded,
                              color: _accent,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Available for Sale',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: isAvailable,
                              onChanged: (v) =>
                                  setModalState(() => isAvailable = v),
                              activeThumbColor: _accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty ||
                                priceCtrl.text.trim().isEmpty ||
                                stockCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill in all required fields',
                                  ),
                                ),
                              );
                              return;
                            }
                            final newProduct = {
                              'id': isEdit
                                  ? product['id']
                                  : 'ep_${DateTime.now().millisecondsSinceEpoch}',
                              'name': nameCtrl.text.trim(),
                              'category': selectedCategory,
                              'price': double.tryParse(priceCtrl.text) ?? 0,
                              'unit': unitCtrl.text.trim().isEmpty
                                  ? 'piece'
                                  : unitCtrl.text.trim(),
                              'stock_quantity':
                                  int.tryParse(stockCtrl.text) ?? 0,
                              'is_available': isAvailable,
                              'description': descCtrl.text.trim(),
                              'brand': brandCtrl.text.trim(),
                              'wattage': wattageCtrl.text.trim(),
                              'voltage': voltageCtrl.text.trim(),
                              'warranty': warrantyCtrl.text.trim(),
                              'material': materialCtrl.text.trim(),
                              'created_at': DateTime.now().toIso8601String(),
                            };
                            setState(() {
                              if (isEdit) {
                                final idx = _products.indexWhere(
                                  (p) => p['id'] == product['id'],
                                );
                                if (idx != -1) _products[idx] = newProduct;
                              } else {
                                _products.insert(0, newProduct);
                              }
                              _computeStats(_products, _orders);
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Product updated successfully'
                                      : 'Product added successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Update Product' : 'Add Product',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateStockDialog(Map<String, dynamic> product) {
    final ctrl = TextEditingController(
      text: (product['stock_quantity'] as num?)?.toString() ?? '0',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Text(
          'Update Stock',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'] as String? ?? '',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Quantity',
                prefixIcon: const Icon(Icons.warehouse_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(ctrl.text) ?? 0;
              setState(() {
                final idx = _products.indexWhere(
                  (p) => p['id'] == product['id'],
                );
                if (idx != -1) {
                  _products[idx]['stock_quantity'] = qty;
                  _products[idx]['is_available'] = qty > 0;
                }
                _computeStats(_products, _orders);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: Text(
              'Update',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _accent,
      letterSpacing: 0.5,
    ),
  );

  Widget _formField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
        body: Column(
          children: [
            _buildStatsBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(),
                  _buildOrdersTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditProductSheet(),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Product',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentDark, _accent, const Color(0xFFFFB74D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: const Icon(
                      Icons.electrical_services_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Electrical & Hardware',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Provider Dashboard',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.white.withAlpha(217),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _loadData,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.card_membership_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Subscription',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.providerSubscriptionScreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Sign Out',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.loginScreen,
                      (_) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _StatChip(
            label: 'Products',
            value: '$_totalProducts',
            icon: Icons.inventory_2_rounded,
            color: _accent,
          ),
          _StatChip(
            label: 'Pending',
            value: '$_pendingOrdersCount',
            icon: Icons.pending_actions_rounded,
            color: Colors.orange,
          ),
          _StatChip(
            label: 'Low Stock',
            value: '$_lowStockCount',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          _StatChip(
            label: "Today's ₹",
            value: '₹${_todayEarnings.toStringAsFixed(0)}',
            icon: Icons.currency_rupee_rounded,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _accent,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _accent,
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(
            text: 'Products',
            icon: Icon(Icons.inventory_2_rounded, size: 18),
          ),
          Tab(text: 'Orders', icon: Icon(Icons.receipt_long_rounded, size: 18)),
          Tab(text: 'Analytics', icon: Icon(Icons.bar_chart_rounded, size: 18)),
        ],
      ),
    );
  }

  // ── Products Tab ───────────────────────────────────────────────────────────
  Widget _buildProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filteredProducts;
    return Column(
      children: [
        _buildCategoryFilterChips(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products in this category',
                        style: GoogleFonts.manrope(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: filtered[i],
                    accent: _accent,
                    accentLight: _accentLight,
                    onEdit: () =>
                        _showAddEditProductSheet(product: filtered[i]),
                    onUpdateStock: () => _showUpdateStockDialog(filtered[i]),
                    onDelete: () => _deleteProduct(filtered[i]['id'] as String),
                    onToggleStock: () => _toggleStock(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categoryTabs.map((cat) {
            final selected = _selectedCategoryFilter == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  cat,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedCategoryFilter = cat),
                backgroundColor: const Color(0xFFF0F0F0),
                selectedColor: _accent,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Orders Tab ─────────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No orders yet',
              style: GoogleFonts.manrope(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group orders by category of first item
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final order in _orders) {
      final items = order['items'] as List?;
      final cat = items != null && items.isNotEmpty
          ? (items.first['category'] as String? ?? 'Other')
          : 'Other';
      grouped.putIfAbsent(cat, () => []).add(order);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _accentLight,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      entry.key,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accentDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value.length} order${entry.value.length > 1 ? 's' : ''}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (order) => _OrderCard(
                order: order,
                accent: _accent,
                accentLight: _accentLight,
                onAdvance: () => _advanceOrderStatus(order),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  // ── Analytics Tab ──────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    final Map<String, int> categoryCount = {};
    for (final p in _products) {
      final cat = p['category'] as String? ?? 'Other';
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    final Map<String, double> categoryRevenue = {};
    for (final o in _orders) {
      if (o['order_status'] == 'delivered') {
        final items = o['items'] as List?;
        if (items != null) {
          for (final item in items) {
            final cat = item['category'] as String? ?? 'Other';
            final rev =
                ((item['price'] as num?)?.toDouble() ?? 0) *
                ((item['quantity'] as num?)?.toDouble() ?? 1);
            categoryRevenue[cat] = (categoryRevenue[cat] ?? 0) + rev;
          }
        }
      }
    }

    final totalRevenue = categoryRevenue.values.fold(0.0, (a, b) => a + b);
    final totalOrders = _orders.length;
    final deliveredOrders = _orders
        .where((o) => o['order_status'] == 'delivered')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue cards
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Revenue',
                value: '₹${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Orders',
                value: '$totalOrders',
                icon: Icons.receipt_long_rounded,
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
                title: 'Delivered',
                value: '$deliveredOrders',
                icon: Icons.check_circle_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Products',
                value: '$_totalProducts',
                icon: Icons.inventory_2_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Inventory by category
        _buildSectionHeader('Inventory by Category'),
        const SizedBox(height: 12),
        ...categoryCount.entries.map(
          (e) => _buildBarRow(
            label: e.key,
            value: e.value.toDouble(),
            max: categoryCount.values
                .fold(0, (a, b) => a > b ? a : b)
                .toDouble(),
            color: _accent,
            suffix: '${e.value} items',
          ),
        ),
        const SizedBox(height: 20),
        // Revenue by category
        if (categoryRevenue.isNotEmpty) ...[
          _buildSectionHeader('Revenue by Category'),
          const SizedBox(height: 12),
          ...categoryRevenue.entries.map(
            (e) => _buildBarRow(
              label: e.key,
              value: e.value,
              max: categoryRevenue.values.fold(0.0, (a, b) => a > b ? a : b),
              color: Colors.green,
              suffix: '₹${e.value.toStringAsFixed(0)}',
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Stock status summary
        _buildSectionHeader('Stock Status'),
        const SizedBox(height: 12),
        _buildStockStatusSummary(),
        const SizedBox(height: 20),
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
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'View your plan, upgrade or renew',
                        style: GoogleFonts.manrope(
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1A1C1E),
    ),
  );

  Widget _buildBarRow({
    required String label,
    required double value,
    required double max,
    required Color color,
    required String suffix,
  }) {
    final fraction = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                suffix,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusSummary() {
    final inStock = _products
        .where((p) => (p['stock_quantity'] as num? ?? 0) > 10)
        .length;
    final lowStock = _products.where((p) {
      final q = (p['stock_quantity'] as num?)?.toInt() ?? 0;
      return q > 0 && q <= 10;
    }).length;
    final outOfStock = _products
        .where((p) => (p['stock_quantity'] as num? ?? 0) == 0)
        .length;

    return Row(
      children: [
        Expanded(
          child: _StockStatusTile(
            label: 'In Stock',
            count: inStock,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StockStatusTile(
            label: 'Low Stock',
            count: lowStock,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StockStatusTile(
            label: 'Out of Stock',
            count: outOfStock,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

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
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color accent;
  final Color accentLight;
  final VoidCallback onEdit;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;
  final VoidCallback onToggleStock;

  const _ProductCard({
    required this.product,
    required this.accent,
    required this.accentLight,
    required this.onEdit,
    required this.onUpdateStock,
    required this.onDelete,
    required this.onToggleStock,
  });

  @override
  Widget build(BuildContext context) {
    final qty = (product['stock_quantity'] as num?)?.toInt() ?? 0;
    final isAvailable = product['is_available'] as bool? ?? true;
    final stockLabel = qty == 0
        ? 'Out of Stock'
        : qty <= 10
        ? 'Low Stock'
        : 'In Stock';
    final stockColor = qty == 0
        ? Colors.red
        : qty <= 10
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.electrical_services_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] as String? ?? '',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentLight,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              product['category'] as String? ?? '',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              stockLabel,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: stockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stock toggle
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggleStock(),
                  activeThumbColor: accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Price & stock row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Text(
                  '₹${(product['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                Text(
                  ' / ${product['unit'] ?? 'piece'}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.warehouse_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '$qty in stock',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Technical specs chips
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if ((product['brand'] as String?)?.isNotEmpty == true)
                  _SpecChip(
                    icon: Icons.business_rounded,
                    label: 'Brand',
                    value: product['brand'] as String,
                  ),
                if ((product['wattage'] as String?)?.isNotEmpty == true &&
                    product['wattage'] != 'N/A')
                  _SpecChip(
                    icon: Icons.bolt_rounded,
                    label: 'Wattage',
                    value: product['wattage'] as String,
                  ),
                if ((product['voltage'] as String?)?.isNotEmpty == true &&
                    product['voltage'] != 'N/A')
                  _SpecChip(
                    icon: Icons.electric_bolt_rounded,
                    label: 'Voltage',
                    value: product['voltage'] as String,
                  ),
                if ((product['warranty'] as String?)?.isNotEmpty == true &&
                    product['warranty'] != 'N/A')
                  _SpecChip(
                    icon: Icons.verified_rounded,
                    label: 'Warranty',
                    value: product['warranty'] as String,
                  ),
                if ((product['material'] as String?)?.isNotEmpty == true &&
                    product['material'] != 'N/A')
                  _SpecChip(
                    icon: Icons.layers_rounded,
                    label: 'Material',
                    value: product['material'] as String,
                  ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUpdateStock,
                    icon: const Icon(Icons.warehouse_rounded, size: 15),
                    label: Text(
                      'Stock',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF757575)),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF757575),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color accent;
  final Color accentLight;
  final VoidCallback onAdvance;

  const _OrderCard({
    required this.order,
    required this.accent,
    required this.accentLight,
    required this.onAdvance,
  });

  static const Map<String, Color> _statusColors = {
    'pending': Color(0xFFFF9800),
    'accepted': Color(0xFF2196F3),
    'preparing': Color(0xFF9C27B0),
    'out_for_delivery': Color(0xFF00BCD4),
    'delivered': Color(0xFF4CAF50),
  };

  static const Map<String, String> _statusLabels = {
    'pending': 'Pending',
    'accepted': 'Accepted',
    'preparing': 'Preparing',
    'out_for_delivery': 'Out for Delivery',
    'delivered': 'Delivered',
  };

  static const Map<String, String> _nextActionLabels = {
    'pending': 'Accept Order',
    'accepted': 'Start Preparing',
    'preparing': 'Mark Out for Delivery',
    'out_for_delivery': 'Mark Delivered',
    'delivered': '',
  };

  @override
  Widget build(BuildContext context) {
    final status = order['order_status'] as String? ?? 'pending';
    final statusColor = _statusColors[status] ?? Colors.grey;
    final statusLabel = _statusLabels[status] ?? status;
    final nextAction = _nextActionLabels[status] ?? '';
    final items = order['items'] as List? ?? [];
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '') ??
        DateTime.now();
    final timeAgo = DateTime.now().difference(createdAt);
    final timeStr = timeAgo.inHours > 0
        ? '${timeAgo.inHours}h ago'
        : '${timeAgo.inMinutes}m ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customer_name'] as String? ?? 'Customer',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        order['customer_phone'] as String? ?? '',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) {
                  final i = item as Map;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.electrical_services_rounded,
                          size: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${i['name']} × ${i['quantity']}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF444444),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${((i['price'] as num?)?.toDouble() ?? 0) * ((i['quantity'] as num?)?.toDouble() ?? 1)}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          order['delivery_type'] == 'Home Delivery'
                              ? Icons.delivery_dining_rounded
                              : Icons.store_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order['delivery_type'] as String? ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ₹${(order['total_amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action button
          if (nextAction.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAdvance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    nextAction,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(14.0),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.grey.shade600,
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

class _StockStatusTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StockStatusTile({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
