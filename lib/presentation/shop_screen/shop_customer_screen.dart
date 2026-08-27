import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Customer-facing shop screen for Grocery and Vegetables subcategories
/// Supports: product browsing, category filter, cart, checkout
class ShopCustomerScreen extends StatefulWidget {
  const ShopCustomerScreen({super.key});

  @override
  State<ShopCustomerScreen> createState() => _ShopCustomerScreenState();
}

class _ShopCustomerScreenState extends State<ShopCustomerScreen> {
  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Grocery';

  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _products = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Cart
  final Map<String, int> _cart = {};
  // Manual quantity controllers per product
  final Map<String, TextEditingController> _qtyControllers = {};

  final _supabase = Supabase.instance.client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _subcategoryId = args['subcategoryId'] as String? ?? 'grocery';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Grocery';
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
        setState(() {
          _providers = data
              .where(
                (p) {
                  final sub = (p['subcategory'] as String? ?? '').toLowerCase().trim();
                  final target = _subcategoryId.toLowerCase().trim();
                  if (sub.isEmpty) return true;
                  return sub.contains(target) ||
                      target.contains(sub) ||
                      (p['subcategories'] as List? ?? []).contains(_subcategoryId);
                },
              )
              .toList();
          _isLoading = false;
        });
        if (_providers.isNotEmpty) {
          _selectProvider(_providers.first);
        }
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

  void _addToCart(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
      _qtyControllers.putIfAbsent(
        productId,
        () => TextEditingController(text: '${_cart[productId]}'),
      );
      _qtyControllers[productId]!.text = '${_cart[productId]}';
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if ((_cart[productId] ?? 0) > 1) {
        _cart[productId] = _cart[productId]! - 1;
        _qtyControllers[productId]?.text = '${_cart[productId]}';
      } else {
        _cart.remove(productId);
        _qtyControllers.remove(productId)?.dispose();
      }
    });
  }

  void _setCartQty(String productId, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(productId);
        _qtyControllers.remove(productId)?.dispose();
      } else {
        _cart[productId] = qty;
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

  Color get _accentColor {
    switch (_subcategoryId) {
      case 'grocery':
        return AppTheme.catGrocery;
      case 'vegetables':
        return const Color(0xFF2E7D32);
      default:
        return AppTheme.primary;
    }
  }

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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          // Previous Lists button (grocery/vegetables only)
          if (_subcategoryId == 'grocery' || _subcategoryId == 'vegetables')
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Previous Lists',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.previousGroceryListsScreen,
                arguments: {
                  'subcategoryId': _subcategoryId,
                  'subcategoryName': _subcategoryName,
                },
              ),
            ),
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
          IconButton(
            icon: const Icon(Icons.map_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.mapDiscoveryScreen),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
          ? _buildNoProviders()
          : Column(
              children: [
                // Previous Lists Banner (grocery/vegetables only)
                if (_subcategoryId == 'grocery' ||
                    _subcategoryId == 'vegetables')
                  _buildPreviousListsBanner(),
                _buildSearchBar(),
                if (_providers.length > 1) _buildProviderSelector(),
                _buildCategoryFilter(),
                Expanded(child: _buildProductGrid()),
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
          Icon(
            Icons.store_outlined,
            size: 64,
            color: _accentColor.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'No shops nearby',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No $_subcategoryName shops found in your area',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
            hintText: 'Search products...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF90A4AE),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primary,
            ),
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

  Widget _buildProviderSelector() {
    return Container(
      height: 56,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _providers.length,
        itemBuilder: (ctx, i) {
          final p = _providers[i];
          final isSelected = _selectedProvider?['id'] == p['id'];
          return GestureDetector(
            onTap: () => _selectProvider(p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _accentColor : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p['business_name'] as String? ??
                    p['full_name'] as String? ??
                    'Shop',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF44474E),
                ),
              ),
            ),
          );
        },
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

  Widget _buildProductGrid() {
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

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final product = products[i];
        final productId = product['id'] as String;
        final qty = _cart[productId] ?? 0;
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        final mrp = (product['mrp'] as num?)?.toDouble();
        final unit = product['unit'] as String? ?? 'piece';
        final stock = product['stock_quantity'] as int? ?? 0;
        final discount = (product['discount_percent'] as num?)?.toDouble() ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image placeholder
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: _accentColor.withAlpha(20),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: _accentColor.withAlpha(120),
                          size: 40,
                        ),
                      ),
                      if (discount > 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${discount.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (stock == 0)
                        Container(
                          color: Colors.black.withAlpha(100),
                          child: Center(
                            child: Text(
                              'Out of Stock',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _accentColor,
                          ),
                        ),
                        Text(
                          '/$unit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                        if (mrp != null && mrp > price) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${mrp.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF90A4AE),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (stock == 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Out of Stock',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (qty == 0)
                      GestureDetector(
                        onTap: () => _addToCart(productId),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Add',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _removeFromCart(productId),
                            child: Container(
                              width: 28,
                              height: 28,
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
                          Expanded(
                            child: SizedBox(
                              height: 28,
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
                          ),
                          GestureDetector(
                            onTap: () => _addToCart(productId),
                            child: Container(
                              width: 28,
                              height: 28,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _accentColor,
        boxShadow: [
          BoxShadow(
            color: _accentColor.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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

  Widget _buildPreviousListsBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.previousGroceryListsScreen,
        arguments: {
          'subcategoryId': _subcategoryId,
          'subcategoryName': _subcategoryName,
        },
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _accentColor.withAlpha(18),
          border: Border(
            bottom: BorderSide(color: _accentColor.withAlpha(40), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history_rounded, color: _accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous $_subcategoryName Lists',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                  Text(
                    'Reorder from your past lists quickly',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: _accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

