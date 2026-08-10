import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Customer screen for Seasonal Items shop
/// Features: admin-controlled categories, availability dates, festival highlights
class SeasonalItemsCustomerScreen extends StatefulWidget {
  const SeasonalItemsCustomerScreen({super.key});

  @override
  State<SeasonalItemsCustomerScreen> createState() =>
      _SeasonalItemsCustomerScreenState();
}

class _SeasonalItemsCustomerScreenState
    extends State<SeasonalItemsCustomerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _seasonalCategories = [];
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _products = [];
  String _selectedSeasonalCat = 'All';

  final Map<String, int> _cart = {};
  final Map<String, TextEditingController> _qtyControllers = {};
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load seasonal categories
      final cats = await _supabase
          .from('seasonal_categories')
          .select()
          .order('name');

      // Load providers
      final providerData = await SupabaseService.instance
          .getProvidersByCategory('shop');
      final seasonalProviders = providerData
          .where(
            (p) =>
                (p['subcategory'] as String? ?? '') == 'seasonal' ||
                (p['subcategories'] as List? ?? []).contains('seasonal'),
          )
          .toList();

      if (mounted) {
        setState(() {
          _seasonalCategories = (cats as List)
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
          _providers = seasonalProviders;
          _isLoading = false;
        });
        if (seasonalProviders.isNotEmpty) {
          _selectProvider(seasonalProviders.first);
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
          .eq('shop_subcategory', 'seasonal')
          .eq('is_available', true)
          .order('category');

      if (mounted) {
        setState(() {
          _products = (products as List)
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedSeasonalCat == 'All') return _products;
    return _products
        .where((p) => p['category'] == _selectedSeasonalCat)
        .toList();
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

  void _addToCart(String id) => setState(() {
    _cart[id] = (_cart[id] ?? 0) + 1;
    _qtyControllers.putIfAbsent(
      id,
      () => TextEditingController(text: '${_cart[id]}'),
    );
    _qtyControllers[id]!.text = '${_cart[id]}';
  });
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
        'subcategoryId': 'seasonal',
        'subcategoryName': 'Seasonal Items',
        'cartItems': cartItems,
        'cartTotal': _cartTotal,
      },
    );
  }

  static const Color _accentColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                if (_seasonalCategories.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSeasonalCategoryBanner()),
                SliverToBoxAdapter(child: _buildCategoryFilter()),
                if (_providers.isEmpty)
                  SliverFillRemaining(child: _buildNoProviders())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final products = _filteredProducts;
                        if (i >= products.length) return null;
                        return _buildProductCard(products[i]);
                      }, childCount: _filteredProducts.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      expandedHeight: 140,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_rounded),
          tooltip: 'Request Items',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.shopPhotoRequestScreen,
            arguments: {
              'subcategoryId': 'seasonal',
              'subcategoryName': 'Seasonal Items',
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
                    color: AppTheme.error,
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
              colors: [Color(0xFFFF8F00), Color(0xFFFFB300), Color(0xFFFFCA28)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Seasonal Items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Festival specials & seasonal products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        'Seasonal Items',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSeasonalCategoryBanner() {
    final active = _seasonalCategories
        .where((c) => c['is_active'] == true)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: _accentColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Active Seasons',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: active.length,
            itemBuilder: (ctx, i) {
              final cat = active[i];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const Spacer(),
                      Text(
                        cat['name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final cats = {
      'All',
      ..._products.map((p) => p['category'] as String? ?? 'General'),
    };
    return Container(
      height: 48,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: cats.length,
        itemBuilder: (ctx, i) {
          final cat = cats.elementAt(i);
          final isSelected = _selectedSeasonalCat == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonalCat = cat),
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

  Widget _buildNoProviders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 64,
            color: _accentColor.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'No seasonal shops nearby',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back during festival seasons',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as String;
    final qty = _cart[productId] ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'piece';
    final stock = product['stock_quantity'] as int? ?? 0;
    final isFeatured = product['is_featured'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: isFeatured ? Border.all(color: _accentColor, width: 1.5) : null,
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: _accentColor,
                    size: 28,
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Featured',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${price.toStringAsFixed(0)}/$unit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                  if (product['description'] != null &&
                      (product['description'] as String).isNotEmpty)
                    Text(
                      product['description'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (stock == 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sold Out',
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
            else
              Row(
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
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
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
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: _accentColor),
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
