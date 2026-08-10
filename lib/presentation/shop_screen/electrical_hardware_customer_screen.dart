import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Customer screen for Electrical & Hardware and Plumbing & Hardware shops
/// Features: technical specs, brand filter, stock availability
class ElectricalHardwareCustomerScreen extends StatefulWidget {
  const ElectricalHardwareCustomerScreen({super.key});

  @override
  State<ElectricalHardwareCustomerScreen> createState() =>
      _ElectricalHardwareCustomerScreenState();
}

class _ElectricalHardwareCustomerScreenState
    extends State<ElectricalHardwareCustomerScreen> {
  String _subcategoryId = 'electrical';
  String _subcategoryName = 'Electrical & Hardware';

  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _products = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<String, int> _cart = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  final _supabase = Supabase.instance.client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _subcategoryId = args['subcategoryId'] as String? ?? 'electrical';
      _subcategoryName =
          args['subcategoryName'] as String? ?? 'Electrical & Hardware';
    }
    _loadProviders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
        if (filtered.isNotEmpty) _selectProvider(filtered.first);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        setState(() {
          _products = (products as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          _selectedCategory = 'All';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = {'All'};
    for (final p in _products) {
      cats.add(p['category'] as String? ?? 'General');
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchesCat =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (p['name'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
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
        'providerId': _selectedProvider?['id'],
        'providerName':
            _selectedProvider?['business_name'] ??
            _selectedProvider?['full_name'],
        'subcategoryId': _subcategoryId,
        'subcategoryName': _subcategoryName,
        'cartItems': cartItems,
        'cartTotal': _cartTotal,
      },
    );
  }

  Color get _accentColor => _subcategoryId == 'electrical'
      ? const Color(0xFFF57C00)
      : const Color(0xFF0277BD);

  IconData get _categoryIcon => _subcategoryId == 'electrical'
      ? Icons.electrical_services_rounded
      : Icons.plumbing_rounded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Text(
          _subcategoryName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
          ? _buildNoProviders()
          : Column(
              children: [
                _buildSearchAndFilter(),
                _buildCategoryFilter(),
                Expanded(child: _buildProductList()),
              ],
            ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
    );
  }

  Widget _buildNoProviders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_categoryIcon, size: 64, color: _accentColor.withAlpha(120)),
          const SizedBox(height: 16),
          Text(
            'No $_subcategoryName shops nearby',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: _accentColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search products, brands...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF90A4AE),
            ),
            prefixIcon: Icon(Icons.search_rounded, color: _accentColor),
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

  Widget _buildCategoryFilter() {
    final cats = _categories;
    return Container(
      height: 48,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: cats.length,
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _accentColor : AppTheme.outlineVariant,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? _accentColor : const Color(0xFF44474E),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No products found',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: const Color(0xFF74777F),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final product = products[i];
        final productId = product['id'] as String;
        final qty = _cart[productId] ?? 0;
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        final unit = product['unit'] as String? ?? 'piece';
        final stock = product['stock_quantity'] as int? ?? 0;
        final specs = product['specifications'] as Map? ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _accentColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon, color: _accentColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _accentColor,
                                ),
                              ),
                              Text(
                                '/$unit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stock > 0
                                  ? AppTheme.successContainer
                                  : AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stock > 0 ? 'In Stock ($stock)' : 'Out of Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: stock > 0
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stock > 0)
                      qty == 0
                          ? GestureDetector(
                              onTap: () => _addToCart(productId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentColor,
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
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _removeFromCart(productId),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _accentColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      color: _accentColor,
                                      size: 16,
                                    ),
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
                                      color: _accentColor,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      final parsed = int.tryParse(v.trim());
                                      if (parsed != null) {
                                        _setCartQty(productId, parsed);
                                      }
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _addToCart(productId),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ],
                ),
                // Technical specs
                if (specs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: specs.entries.take(4).map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _accentColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (product['description'] != null &&
                    (product['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    product['description'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF74777F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: _accentColor),
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
}
