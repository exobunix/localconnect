import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Dedicated customer screen for Plumbing & Hardware
/// Features: product list with technical specs (brand, material, dimensions),
/// stock badges, quantity input for pipes, fittings, tools, building materials
class PlumbingHardwareCustomerScreen extends StatefulWidget {
  const PlumbingHardwareCustomerScreen({super.key});

  @override
  State<PlumbingHardwareCustomerScreen> createState() =>
      _PlumbingHardwareCustomerScreenState();
}

class _PlumbingHardwareCustomerScreenState
    extends State<PlumbingHardwareCustomerScreen>
    with SingleTickerProviderStateMixin {
  static const String _subcategoryId = 'plumbing_hardware';
  static const String _subcategoryName = 'Plumbing & Hardware';
  static const Color _accent = Color(0xFF0277BD);
  static const Color _accentLight = Color(0xFF0288D1);

  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _products = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, int> _cart = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  late TabController _tabController;

  // Product categories for plumbing & hardware
  static const List<String> _productTabs = [
    'All',
    'Pipes',
    'Fittings',
    'Tools',
    'Building',
  ];

  final _supabase = Supabase.instance.client;

  // Mock product data for demo when no Supabase data
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': 'ph_001',
      'name': 'CPVC Pipe 1/2 inch',
      'category': 'Pipes',
      'price': 85,
      'unit': 'piece',
      'stock_quantity': 150,
      'is_available': true,
      'description': 'High-quality CPVC pipe for hot & cold water supply',
      'specifications': {
        'Brand': 'Astral',
        'Material': 'CPVC',
        'Diameter': '1/2 inch',
        'Length': '3 meters',
        'Pressure': '10 kg/cm²',
      },
    },
    {
      'id': 'ph_002',
      'name': 'uPVC Pipe 1 inch',
      'category': 'Pipes',
      'price': 120,
      'unit': 'piece',
      'stock_quantity': 80,
      'is_available': true,
      'description': 'Rigid uPVC pipe for drainage and water supply',
      'specifications': {
        'Brand': 'Supreme',
        'Material': 'uPVC',
        'Diameter': '1 inch',
        'Length': '3 meters',
        'Color': 'White',
      },
    },
    {
      'id': 'ph_003',
      'name': 'GI Pipe 3/4 inch',
      'category': 'Pipes',
      'price': 210,
      'unit': 'piece',
      'stock_quantity': 40,
      'is_available': true,
      'description': 'Galvanized iron pipe for heavy-duty applications',
      'specifications': {
        'Brand': 'Tata',
        'Material': 'Galvanized Iron',
        'Diameter': '3/4 inch',
        'Length': '6 meters',
        'Grade': 'IS 1239',
      },
    },
    {
      'id': 'ph_004',
      'name': 'CPVC Elbow 90° 1/2"',
      'category': 'Fittings',
      'price': 18,
      'unit': 'piece',
      'stock_quantity': 500,
      'is_available': true,
      'description': '90-degree elbow fitting for CPVC pipe connections',
      'specifications': {
        'Brand': 'Astral',
        'Material': 'CPVC',
        'Size': '1/2 inch',
        'Type': '90° Elbow',
        'Standard': 'IS 15778',
      },
    },
    {
      'id': 'ph_005',
      'name': 'Ball Valve 1/2 inch',
      'category': 'Fittings',
      'price': 95,
      'unit': 'piece',
      'stock_quantity': 60,
      'is_available': true,
      'description': 'Brass ball valve for water flow control',
      'specifications': {
        'Brand': 'Zoloto',
        'Material': 'Brass',
        'Size': '1/2 inch',
        'Type': 'Full Bore',
        'Pressure': '20 bar',
      },
    },
    {
      'id': 'ph_006',
      'name': 'PVC Tee 3/4 inch',
      'category': 'Fittings',
      'price': 22,
      'unit': 'piece',
      'stock_quantity': 300,
      'is_available': true,
      'description': 'Equal tee fitting for PVC pipe branching',
      'specifications': {
        'Brand': 'Finolex',
        'Material': 'PVC',
        'Size': '3/4 inch',
        'Type': 'Equal Tee',
        'Color': 'White',
      },
    },
    {
      'id': 'ph_007',
      'name': 'Pipe Wrench 14 inch',
      'category': 'Tools',
      'price': 450,
      'unit': 'piece',
      'stock_quantity': 25,
      'is_available': true,
      'description': 'Heavy-duty pipe wrench for plumbing work',
      'specifications': {
        'Brand': 'Stanley',
        'Material': 'Drop Forged Steel',
        'Size': '14 inch',
        'Jaw Capacity': '40mm',
        'Weight': '1.2 kg',
      },
    },
    {
      'id': 'ph_008',
      'name': 'Pipe Cutter 3-35mm',
      'category': 'Tools',
      'price': 320,
      'unit': 'piece',
      'stock_quantity': 18,
      'is_available': true,
      'description': 'Rotary pipe cutter for clean cuts on copper/PVC',
      'specifications': {
        'Brand': 'Taparia',
        'Material': 'Alloy Steel',
        'Range': '3-35mm',
        'Type': 'Rotary Cutter',
        'Blade': 'Hardened Steel',
      },
    },
    {
      'id': 'ph_009',
      'name': 'Thread Seal Tape (PTFE)',
      'category': 'Tools',
      'price': 35,
      'unit': 'roll',
      'stock_quantity': 200,
      'is_available': true,
      'description': 'PTFE thread seal tape for leak-proof pipe joints',
      'specifications': {
        'Brand': 'Henkel',
        'Material': 'PTFE',
        'Width': '12mm',
        'Length': '12 meters',
        'Thickness': '0.075mm',
      },
    },
    {
      'id': 'ph_010',
      'name': 'OPC Cement 50kg',
      'category': 'Building',
      'price': 380,
      'unit': 'bag',
      'stock_quantity': 100,
      'is_available': true,
      'description': 'Ordinary Portland Cement for construction work',
      'specifications': {
        'Brand': 'UltraTech',
        'Material': 'OPC 53 Grade',
        'Weight': '50 kg',
        'Standard': 'IS 269',
        'Setting Time': '30 min initial',
      },
    },
    {
      'id': 'ph_011',
      'name': 'M-Sand (River Sand)',
      'category': 'Building',
      'price': 55,
      'unit': 'kg',
      'stock_quantity': 2000,
      'is_available': true,
      'description': 'Manufactured sand for plastering and masonry',
      'specifications': {
        'Type': 'M-Sand',
        'Material': 'Crushed Stone',
        'Grade': 'Zone II',
        'Sieve Size': '4.75mm',
        'Use': 'Plastering/Masonry',
      },
    },
    {
      'id': 'ph_012',
      'name': 'Anchor Bolt M10×100',
      'category': 'Building',
      'price': 12,
      'unit': 'piece',
      'stock_quantity': 0,
      'is_available': false,
      'description': 'Expansion anchor bolt for concrete fastening',
      'specifications': {
        'Brand': 'Fischer',
        'Material': 'Zinc Plated Steel',
        'Size': 'M10×100mm',
        'Type': 'Expansion Bolt',
        'Load': '2.5 kN',
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _productTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _productTabs[_tabController.index];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getProvidersByCategory(
        'shop',
      );
      if (mounted) {
        final filtered = data
            .where(
              (p) =>
                  (p['subcategory'] as String? ?? '') == _subcategoryId ||
                  (p['subcategories'] as List? ?? []).contains(_subcategoryId),
            )
            .toList();
        setState(() {
          _providers = filtered;
          _isLoading = false;
        });
        if (filtered.isNotEmpty) {
          _selectProvider(filtered.first);
        } else {
          // Use mock data when no providers found
          setState(() {
            _products = _mockProducts;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = _mockProducts;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectProvider(Map<String, dynamic> provider) async {
    setState(() {
      _selectedProvider = provider;
      _isLoading = true;
    });
    try {
      final products = await _supabase
          .from('shop_products')
          .select()
          .eq('provider_id', provider['id'] as String)
          .eq('shop_subcategory', _subcategoryId)
          .eq('is_available', true)
          .order('category');

      if (mounted) {
        final fetched = (products as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
        setState(() {
          _products = fetched.isNotEmpty ? fetched : _mockProducts;
          _selectedCategory = 'All';
          _tabController.animateTo(0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = _mockProducts;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchesCat =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (p['name'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ((p['specifications'] as Map?) ?? {}).values.any(
            (v) =>
                v.toString().toLowerCase().contains(_searchQuery.toLowerCase()),
          );
      return matchesCat && matchesSearch;
    }).toList();
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => {},
      );
      if (product.isNotEmpty) {
        total += ((product['price'] as num?)?.toDouble() ?? 0) * entry.value;
      }
    }
    return total;
  }

  void _addToCart(String id) {
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
      _qtyControllers.putIfAbsent(
        id,
        () => TextEditingController(text: '${_cart[id]}'),
      );
      _qtyControllers[id]!.text = '${_cart[id]}';
    });
  }

  void _removeFromCart(String id) => setState(() {
    if ((_cart[id] ?? 0) > 1) {
      _cart[id] = _cart[id]! - 1;
      _qtyControllers[id]?.text = '${_cart[id]}';
    } else {
      _cart.remove(id);
      _qtyControllers.remove(id)?.dispose();
    }
  });

  void _setCartQty(String id, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(id);
        _qtyControllers.remove(id)?.dispose();
      } else {
        _cart[id] = qty;
      }
    });
  }

  void _proceedToCheckout() {
    if (_cart.isEmpty) return;
    final cartItems = _cart.entries.map((e) {
      final product = _products.firstWhere((p) => p['id'] == e.key);
      return {
        'product_id': e.key,
        'name': product['name'],
        'price': product['price'],
        'unit': product['unit'],
        'quantity': e.value,
      };
    }).toList();

    Navigator.pushNamed(
      context,
      AppRoutes.shopCheckoutScreen,
      arguments: {
        'providerId': _selectedProvider?['id'] ?? 'demo_provider',
        'providerName':
            _selectedProvider?['business_name'] ??
            _selectedProvider?['full_name'] ??
            'Plumbing & Hardware Store',
        'subcategoryId': _subcategoryId,
        'subcategoryName': _subcategoryName,
        'cartItems': cartItems,
        'cartTotal': _cartTotal,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _accent,
                unselectedLabelColor: const Color(0xFF74777F),
                indicatorColor: _accent,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: _productTabs
                    .map(
                      (t) => Tab(
                        text: t,
                        icon: t == 'All' ? null : Icon(_tabIcon(t), size: 14),
                        iconMargin: const EdgeInsets.only(bottom: 2),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _buildProductList(),
      ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _subcategoryName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_rounded),
          tooltip: 'Request Items',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.shopPhotoRequestScreen,
            arguments: {
              'subcategoryId': _subcategoryId,
              'subcategoryName': _subcategoryName,
              'providerId': _selectedProvider?['id'] ?? '',
              'providerName':
                  _selectedProvider?['business_name'] ??
                  _selectedProvider?['full_name'] ??
                  'Shop',
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.assignment_return_rounded),
          tooltip: 'Return Goods',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.shopReturnRequestScreen,
            arguments: {
              'orderId': '',
              'orderNumber': 'Recent Order',
              'providerName':
                  _selectedProvider?['business_name'] ??
                  _selectedProvider?['full_name'] ??
                  'Shop',
              'orderItems': <Map<String, dynamic>>[],
            },
          ),
        ),
        if (_cartItemCount > 0)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded),
                onPressed: _proceedToCheckout,
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_cartItemCount',
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
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF01579B), _accent, _accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.plumbing_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subcategoryName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Pipes • Fittings • Tools • Building Materials',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Provider selector chips
                  if (_providers.isNotEmpty)
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _providers.length,
                        itemBuilder: (ctx, i) {
                          final p = _providers[i];
                          final isSelected =
                              _selectedProvider?['id'] == p['id'];
                          return GestureDetector(
                            onTap: () => _selectProvider(p),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                p['business_name'] ?? p['full_name'] ?? 'Shop',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? _accent : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
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

  Widget _buildSearchBar() {
    return Container(
      color: _accent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search pipes, fittings, brand, material...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF90A4AE),
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: _accent),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.plumbing_rounded,
              size: 56,
              color: _accent.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _buildProductCard(products[i]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as String;
    final qty = _cart[productId] ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'piece';
    final stock = product['stock_quantity'] as int? ?? 0;
    final isAvailable = (product['is_available'] as bool? ?? true) && stock > 0;
    final specs = Map<String, dynamic>.from(
      product['specifications'] as Map? ?? {},
    );
    final category = product['category'] as String? ?? '';

    // Extract key technical specs
    final brand = specs['Brand'] as String?;
    final material = specs['Material'] as String?;
    final size = specs['Size'] ?? specs['Diameter'] ?? specs['Range'];
    final length = specs['Length'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? Colors.transparent
              : AppTheme.error.withAlpha(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name + price + add button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryProductIcon(category),
                    color: _accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + price + stock badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _accent,
                            ),
                          ),
                          Text(
                            '/$unit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStockBadge(stock, isAvailable),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity control
                _buildQuantityControl(productId, qty, isAvailable),
              ],
            ),

            // Key specs row (brand, material, size, length)
            if (brand != null ||
                material != null ||
                size != null ||
                length != null) ...[
              const SizedBox(height: 10),
              _buildKeySpecsRow(brand, material, size, length),
            ],

            // Full specs grid
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSpecsGrid(specs),
            ],

            // Description
            if (product['description'] != null &&
                (product['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                product['description'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool isAvailable) {
    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Out of Stock',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.error,
          ),
        ),
      );
    }
    if (stock <= 10) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Low Stock ($stock)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE65100),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.successContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'In Stock',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.success,
        ),
      ),
    );
  }

  Widget _buildKeySpecsRow(
    String? brand,
    String? material,
    dynamic size,
    dynamic length,
  ) {
    final items = <_SpecItem>[];
    if (brand != null) items.add(_SpecItem(Icons.business_rounded, brand));
    if (material != null) items.add(_SpecItem(Icons.layers_rounded, material));
    if (size != null) {
      items.add(_SpecItem(Icons.straighten_rounded, size.toString()));
    }
    if (length != null) {
      items.add(_SpecItem(Icons.height_rounded, length.toString()));
    }

    return Row(
      children: items
          .take(4)
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(item.icon, size: 14, color: _accent),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF01579B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpecsGrid(Map<String, dynamic> specs) {
    final entries = specs.entries.toList();
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withAlpha(12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _accent.withAlpha(30)),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${e.key}: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF74777F),
                  ),
                ),
                TextSpan(
                  text: e.value.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF01579B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantityControl(String productId, int qty, bool isAvailable) {
    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.outlineVariant.withAlpha(60),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Unavailable',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF74777F),
          ),
        ),
      );
    }

    if (qty == 0) {
      return GestureDetector(
        onTap: () => _addToCart(productId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Add',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _removeFromCart(productId),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded, color: _accent, size: 16),
          ),
        ),
        SizedBox(
          width: 44,
          height: 30,
          child: TextField(
            controller: _qtyControllers.putIfAbsent(
              productId,
              () => TextEditingController(text: '$qty'),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v.trim());
              if (parsed != null) _setCartQty(productId, parsed);
            },
          ),
        ),
        GestureDetector(
          onTap: () => _addToCart(productId),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: _accent),
      child: SafeArea(
        child: GestureDetector(
          onTap: _proceedToCheckout,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_cartItemCount item${_cartItemCount != 1 ? 's' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'View Cart',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '₹${_cartTotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _tabIcon(String tab) {
    switch (tab) {
      case 'Pipes':
        return Icons.water_rounded;
      case 'Fittings':
        return Icons.settings_rounded;
      case 'Tools':
        return Icons.build_rounded;
      case 'Building':
        return Icons.foundation_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  IconData _categoryProductIcon(String category) {
    switch (category) {
      case 'Pipes':
        return Icons.water_rounded;
      case 'Fittings':
        return Icons.settings_rounded;
      case 'Tools':
        return Icons.build_rounded;
      case 'Building':
        return Icons.foundation_rounded;
      default:
        return Icons.plumbing_rounded;
    }
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  const _SpecItem(this.icon, this.label);
}

/// SliverPersistentHeaderDelegate for pinned TabBar
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, color: AppTheme.outlineVariant),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

