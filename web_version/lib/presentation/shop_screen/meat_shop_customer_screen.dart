import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Dedicated customer screen for Chicken, Mutton & Fish shop
/// Features: cutting preferences, weight selection, delivery slots
class MeatShopCustomerScreen extends StatefulWidget {
  const MeatShopCustomerScreen({super.key});

  @override
  State<MeatShopCustomerScreen> createState() => _MeatShopCustomerScreenState();
}

class _MeatShopCustomerScreenState extends State<MeatShopCustomerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _products = [];
  String _selectedCategory = 'All';

  // Cart with cutting preferences
  final Map<String, _MeatCartItem> _cart = {};

  final _supabase = Supabase.instance.client;

  static const List<String> _categories = [
    'All',
    'Chicken',
    'Mutton',
    'Fish',
    'Seafood',
    'Eggs',
  ];

  static const List<String> _cutTypes = [
    'Whole',
    'Cut Pieces',
    'Boneless',
    'Bone-in',
    'Minced',
    'Curry Cut',
    'Biryani Cut',
  ];

  static const List<String> _deliverySlots = [
    '7:00 AM - 9:00 AM',
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getProvidersByCategory(
        'shop',
      );
      if (mounted) {
        final meatProviders = data
            .where(
              (p) =>
                  (p['subcategory'] as String? ?? '') == 'meat_fish' ||
                  (p['subcategories'] as List? ?? []).contains('meat_fish'),
            )
            .toList();
        setState(() {
          _providers = meatProviders;
          _isLoading = false;
        });
        if (meatProviders.isNotEmpty) {
          _selectProvider(meatProviders.first);
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
          .eq('shop_subcategory', 'meat_fish')
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
    if (_selectedCategory == 'All') return _products;
    return _products.where((p) => p['category'] == _selectedCategory).toList();
  }

  int get _cartItemCount => _cart.length;
  double get _cartTotal =>
      _cart.values.fold(0, (sum, item) => sum + item.totalPrice);

  void _showProductOptions(Map<String, dynamic> product) {
    final productId = product['id'] as String;
    final existing = _cart[productId];
    String selectedCut = existing?.cutType ?? 'Cut Pieces';
    double weight = existing?.weightKg ?? 0.5;
    final pricePerKg = (product['price'] as num?)?.toDouble() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.set_meal_rounded,
                      color: Color(0xFFD32F2F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] as String? ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '₹${pricePerKg.toStringAsFixed(0)}/kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFFD32F2F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Cutting Preference',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cutTypes.map((cut) {
                  final isSelected = selectedCut == cut;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCut = cut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD32F2F)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cut,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF44474E),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Weight: ${weight.toStringAsFixed(2)} kg',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: weight,
                min: 0.25,
                max: 5.0,
                divisions: 19,
                activeColor: const Color(0xFFD32F2F),
                label: '${weight.toStringAsFixed(2)} kg',
                onChanged: (v) => setModalState(() => weight = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.25 kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                  Text(
                    '5.0 kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Manual weight entry
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD32F2F).withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter exact weight (e.g. 1.75)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF90A4AE),
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.trim());
                          if (parsed != null &&
                              parsed >= 0.1 &&
                              parsed <= 10.0) {
                            setModalState(() => weight = parsed);
                          }
                        },
                      ),
                    ),
                    Text(
                      'kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate_rounded,
                      color: Color(0xFFD32F2F),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ₹${(pricePerKg * weight).toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      ' (${weight.toStringAsFixed(2)} kg × ₹${pricePerKg.toStringAsFixed(0)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cart[productId] = _MeatCartItem(
                        productId: productId,
                        productName: product['name'] as String? ?? '',
                        cutType: selectedCut,
                        weightKg: weight,
                        pricePerKg: pricePerKg,
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add to Cart',
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
      ),
    );
  }

  void _proceedToCheckout() {
    if (_cart.isEmpty) return;
    final cartItems = _cart.values
        .map(
          (item) => {
            'product_id': item.productId,
            'name': item.productName,
            'cut_type': item.cutType,
            'weight_kg': item.weightKg,
            'price_per_kg': item.pricePerKg,
            'total_price': item.totalPrice,
          },
        )
        .toList();

    Navigator.pushNamed(
      context,
      AppRoutes.shopCheckoutScreen,
      arguments: {
        'providerId': _selectedProvider?['id'],
        'providerName':
            _selectedProvider?['business_name'] ??
            _selectedProvider?['full_name'],
        'subcategoryId': 'meat_fish',
        'subcategoryName': 'Chicken, Mutton & Fish',
        'cartItems': cartItems,
        'cartTotal': _cartTotal,
        'deliverySlots': _deliverySlots,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: Text(
          'Chicken, Mutton & Fish',
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
                'subcategoryId': 'meat_fish',
                'subcategoryName': 'Chicken, Mutton & Fish',
                'providerId': _selectedProvider?['id'] ?? '',
                'providerName':
                    _selectedProvider?['business_name'] ??
                    _selectedProvider?['full_name'] ??
                    'Meat Shop',
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
                    'Meat Shop',
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
                _buildShopInfo(),
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
          Icon(
            Icons.set_meal_outlined,
            size: 64,
            color: const Color(0xFFD32F2F).withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'No meat shops nearby',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo() {
    if (_selectedProvider == null) return const SizedBox.shrink();
    final provider = _selectedProvider!;
    return Container(
      color: const Color(0xFFD32F2F),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider['business_name'] as String? ??
                      provider['full_name'] as String? ??
                      'Meat Shop',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${(provider['rating'] as num?)?.toStringAsFixed(1) ?? '4.5'} • Fresh Daily',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Same Day',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 48,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD32F2F).withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFD32F2F)
                      : AppTheme.outlineVariant,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF44474E),
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
          'No products available',
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
        final inCart = _cart.containsKey(productId);
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        final stock = product['stock_quantity'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: inCart
                ? Border.all(color: const Color(0xFFD32F2F), width: 1.5)
                : null,
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
                    color: const Color(0xFFD32F2F).withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.set_meal_rounded,
                    color: Color(0xFFD32F2F),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${price.toStringAsFixed(0)}/kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD32F2F),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
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
                              stock > 0 ? 'Fresh Available' : 'Not Available',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: stock > 0
                                    ? AppTheme.success
                                    : AppTheme.error,
                              ),
                            ),
                          ),
                          if (inCart) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F).withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_cart[productId]!.weightKg.toStringAsFixed(2)} kg • ${_cart[productId]!.cutType}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (stock > 0)
                  GestureDetector(
                    onTap: () => _showProductOptions(product),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: inCart
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFD32F2F).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        inCart ? 'Edit' : 'Add',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: inCart
                              ? Colors.white
                              : const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
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
      decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
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
                  'Proceed to Checkout',
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

class _MeatCartItem {
  final String productId;
  final String productName;
  final String cutType;
  final double weightKg;
  final double pricePerKg;

  const _MeatCartItem({
    required this.productId,
    required this.productName,
    required this.cutType,
    required this.weightKg,
    required this.pricePerKg,
  });

  double get totalPrice => weightKg * pricePerKg;
}

