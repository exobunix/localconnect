import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// ── Accent palette ────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFF43A047);
const _kGreenSurface = Color(0xFFE8F5E9);
const _kSeasonBadge = Color(0xFFFF8F00);
const _kBulkBadge = Color(0xFF1565C0);

// ── Vegetable data model ──────────────────────────────────────────────────────
class _VegetableItem {
  final String id;
  final String name;
  final String nameLocal;
  final String category;
  final String imageUrl;
  final double pricePerKg;
  final double price5kg;
  final double price10kg;
  final bool isSeasonal;
  final String? seasonLabel;
  final String freshnessLabel;
  final List<String> nutritionChips;

  const _VegetableItem({
    required this.id,
    required this.name,
    required this.nameLocal,
    required this.category,
    required this.imageUrl,
    required this.pricePerKg,
    required this.price5kg,
    required this.price10kg,
    required this.isSeasonal,
    this.seasonLabel,
    required this.freshnessLabel,
    required this.nutritionChips,
  });
}

// ── Bulk tier model ───────────────────────────────────────────────────────────
class _BulkTier {
  final String label;
  final double qty;
  final double price;
  final String? savingLabel;

  const _BulkTier({
    required this.label,
    required this.qty,
    required this.price,
    this.savingLabel,
  });
}

// ── Static product library ────────────────────────────────────────────────────
final List<_VegetableItem> _kVegetables = [
  _VegetableItem(
    id: 'tomato',
    name: 'Tomato',
    nameLocal: 'टोमॅटो',
    category: 'Everyday',
    imageUrl:
        'https://images.pexels.com/photos/533280/pexels-photo-533280.jpeg?w=400',
    pricePerKg: 40,
    price5kg: 185,
    price10kg: 350,
    isSeasonal: false,
    freshnessLabel: 'Farm Fresh',
    nutritionChips: ['Vitamin C', 'Lycopene', 'Low Cal'],
  ),
  _VegetableItem(
    id: 'onion',
    name: 'Onion',
    nameLocal: 'कांदा',
    category: 'Everyday',
    imageUrl:
        'https://images.pixabay.com/photo/2016/09/10/17/47/onions-1659503_1280.jpg',
    pricePerKg: 35,
    price5kg: 160,
    price10kg: 300,
    isSeasonal: false,
    freshnessLabel: 'Freshly Harvested',
    nutritionChips: ['Quercetin', 'Vitamin B6', 'Antioxidant'],
  ),
  _VegetableItem(
    id: 'potato',
    name: 'Potato',
    nameLocal: 'बटाटा',
    category: 'Everyday',
    imageUrl:
        'https://images.pexels.com/photos/144248/potatoes-vegetables-erdfrucht-bio-144248.jpeg?w=400',
    pricePerKg: 30,
    price5kg: 135,
    price10kg: 250,
    isSeasonal: false,
    freshnessLabel: 'Cold Storage Fresh',
    nutritionChips: ['Potassium', 'Vitamin C', 'Fiber'],
  ),
  _VegetableItem(
    id: 'spinach',
    name: 'Spinach',
    nameLocal: 'पालक',
    category: 'Leafy Greens',
    imageUrl:
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400',
    pricePerKg: 60,
    price5kg: 275,
    price10kg: 520,
    isSeasonal: true,
    seasonLabel: 'Winter Special',
    freshnessLabel: 'Morning Harvest',
    nutritionChips: ['Iron', 'Vitamin K', 'Folate', 'Protein'],
  ),
  _VegetableItem(
    id: 'cauliflower',
    name: 'Cauliflower',
    nameLocal: 'फुलकोबी',
    category: 'Seasonal',
    imageUrl:
        'https://images.pexels.com/photos/6316515/pexels-photo-6316515.jpeg?w=400',
    pricePerKg: 55,
    price5kg: 250,
    price10kg: 470,
    isSeasonal: true,
    seasonLabel: 'Winter Season',
    freshnessLabel: 'Farm Direct',
    nutritionChips: ['Vitamin C', 'Choline', 'Low Carb'],
  ),
  _VegetableItem(
    id: 'carrot',
    name: 'Carrot',
    nameLocal: 'गाजर',
    category: 'Root Vegetables',
    imageUrl:
        'https://images.pixabay.com/photo/2016/08/09/10/30/carrots-1580456_1280.jpg',
    pricePerKg: 50,
    price5kg: 230,
    price10kg: 430,
    isSeasonal: true,
    seasonLabel: 'Winter Fresh',
    freshnessLabel: 'Freshly Pulled',
    nutritionChips: ['Beta-Carotene', 'Vitamin A', 'Fiber'],
  ),
  _VegetableItem(
    id: 'brinjal',
    name: 'Brinjal',
    nameLocal: 'वांगी',
    category: 'Everyday',
    imageUrl:
        'https://images.pexels.com/photos/4197447/pexels-photo-4197447.jpeg?w=400',
    pricePerKg: 45,
    price5kg: 205,
    price10kg: 390,
    isSeasonal: false,
    freshnessLabel: 'Farm Fresh',
    nutritionChips: ['Nasunin', 'Fiber', 'Manganese'],
  ),
  _VegetableItem(
    id: 'capsicum',
    name: 'Capsicum',
    nameLocal: 'ढोबळी मिरची',
    category: 'Everyday',
    imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400',
    pricePerKg: 80,
    price5kg: 370,
    price10kg: 700,
    isSeasonal: false,
    freshnessLabel: 'Greenhouse Fresh',
    nutritionChips: ['Vitamin C', 'Vitamin B6', 'Antioxidant'],
  ),
  _VegetableItem(
    id: 'peas',
    name: 'Green Peas',
    nameLocal: 'वाटाणे',
    category: 'Seasonal',
    imageUrl:
        'https://images.pixabay.com/photo/2016/03/05/19/02/peas-1238248_1280.jpg',
    pricePerKg: 90,
    price5kg: 420,
    price10kg: 800,
    isSeasonal: true,
    seasonLabel: 'Winter Harvest',
    freshnessLabel: 'Freshly Shelled',
    nutritionChips: ['Protein', 'Vitamin K', 'Thiamine'],
  ),
  _VegetableItem(
    id: 'cucumber',
    name: 'Cucumber',
    nameLocal: 'काकडी',
    category: 'Everyday',
    imageUrl:
        'https://images.pexels.com/photos/37528/cucumber-salad-food-healthy-37528.jpeg?w=400',
    pricePerKg: 35,
    price5kg: 160,
    price10kg: 300,
    isSeasonal: false,
    freshnessLabel: 'Hydroponic Fresh',
    nutritionChips: ['Hydration', 'Vitamin K', 'Low Cal'],
  ),
  _VegetableItem(
    id: 'bitter_gourd',
    name: 'Bitter Gourd',
    nameLocal: 'कारले',
    category: 'Everyday',
    imageUrl:
        'https://images.pixabay.com/photo/2017/08/11/09/28/bitter-melon-2631404_1280.jpg',
    pricePerKg: 70,
    price5kg: 320,
    price10kg: 600,
    isSeasonal: false,
    freshnessLabel: 'Farm Fresh',
    nutritionChips: ['Blood Sugar', 'Vitamin C', 'Iron'],
  ),
  _VegetableItem(
    id: 'fenugreek',
    name: 'Fenugreek Leaves',
    nameLocal: 'मेथी',
    category: 'Leafy Greens',
    imageUrl:
        'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=400',
    pricePerKg: 80,
    price5kg: 370,
    price10kg: 700,
    isSeasonal: true,
    seasonLabel: 'Winter Special',
    freshnessLabel: 'Morning Harvest',
    nutritionChips: ['Iron', 'Fiber', 'Vitamin K'],
  ),
];

const List<String> _kCategories = [
  'All',
  'Everyday',
  'Leafy Greens',
  'Root Vegetables',
  'Seasonal',
];

// ── Screen ────────────────────────────────────────────────────────────────────
class VegetablesOrderingScreen extends StatefulWidget {
  const VegetablesOrderingScreen({super.key});

  @override
  State<VegetablesOrderingScreen> createState() =>
      _VegetablesOrderingScreenState();
}

class _VegetablesOrderingScreenState extends State<VegetablesOrderingScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showSeasonalOnly = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // Cart: productId → {qty, tierLabel, tierQty, tierPrice}
  final Map<String, Map<String, dynamic>> _cart = {};

  // Reorder history (simulated from SharedPreferences / Supabase)
  List<Map<String, dynamic>> _reorderHistory = [];
  bool _loadingHistory = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReorderHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReorderHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('shop_orders')
            .select('id, created_at, cart_items, total_amount')
            .eq('customer_id', userId)
            .eq('shop_subcategory', 'vegetables')
            .order('created_at', ascending: false)
            .limit(5);
        if (mounted) {
          setState(() {
            _reorderHistory = (data as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingHistory = false);
  }

  List<_VegetableItem> get _filtered {
    return _kVegetables.where((v) {
      final matchCat =
          _selectedCategory == 'All' || v.category == _selectedCategory;
      final matchSearch =
          _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.nameLocal.contains(_searchQuery);
      final matchSeasonal = !_showSeasonalOnly || v.isSeasonal;
      return matchCat && matchSearch && matchSeasonal;
    }).toList();
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + (b['qty'] as int));
  double get _cartTotal => _cart.values.fold(
    0.0,
    (a, b) => a + (b['tierPrice'] as double) * (b['qty'] as int),
  );

  List<_BulkTier> _tiersFor(_VegetableItem v) => [
    _BulkTier(label: '1 kg', qty: 1, price: v.pricePerKg),
    _BulkTier(
      label: '5 kg',
      qty: 5,
      price: v.price5kg,
      savingLabel:
          'Save ₹${(v.pricePerKg * 5 - v.price5kg).toStringAsFixed(0)}',
    ),
    _BulkTier(
      label: '10 kg',
      qty: 10,
      price: v.price10kg,
      savingLabel:
          'Save ₹${(v.pricePerKg * 10 - v.price10kg).toStringAsFixed(0)}',
    ),
  ];

  void _addToCart(_VegetableItem v, _BulkTier tier, {double? customQty}) {
    setState(() {
      if (customQty != null && customQty > 0) {
        // Custom quantity: store as a custom entry (qty=1, tierQty=customQty)
        _cart[v.id] = {
          'item': v,
          'tierLabel': '${customQty.toStringAsFixed(2)} kg',
          'tierQty': customQty,
          'tierPrice': customQty * v.pricePerKg,
          'qty': 1,
        };
      } else if (_cart.containsKey(v.id)) {
        _cart[v.id]!['qty'] = (_cart[v.id]!['qty'] as int) + 1;
      } else {
        _cart[v.id] = {
          'item': v,
          'tierLabel': tier.label,
          'tierQty': tier.qty,
          'tierPrice': tier.price,
          'qty': 1,
        };
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${v.name} (${tier.label}) added to cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeFromCart(String id) {
    setState(() {
      if ((_cart[id]?['qty'] as int? ?? 0) > 1) {
        _cart[id]!['qty'] = (_cart[id]!['qty'] as int) - 1;
      } else {
        _cart.remove(id);
      }
    });
  }

  void _quickReorder(Map<String, dynamic> order) {
    final items = (order['cart_items'] as List? ?? []);
    for (final item in items) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final vegId = itemMap['product_id'] as String? ?? '';
      final veg = _kVegetables.where((v) => v.id == vegId).firstOrNull;
      if (veg != null) {
        final tier = _tiersFor(veg).first;
        setState(() {
          _cart[veg.id] = {
            'item': veg,
            'tierLabel': tier.label,
            'tierQty': tier.qty,
            'tierPrice': tier.price,
            'qty': (itemMap['quantity'] as int? ?? 1),
          };
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Previous order added to cart!'),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _proceedToCheckout() {
    if (_cart.isEmpty) return;
    final cartItems = _cart.entries.map((e) {
      final v = e.value['item'] as _VegetableItem;
      return {
        'product_id': v.id,
        'name': '${v.name} (${e.value['tierLabel']})',
        'price': e.value['tierPrice'],
        'unit': e.value['tierLabel'],
        'quantity': e.value['qty'],
      };
    }).toList();

    Navigator.pushNamed(
      context,
      AppRoutes.shopCheckoutScreen,
      arguments: {
        'providerId': null,
        'providerName': 'Vegetables Shop',
        'subcategoryId': 'vegetables',
        'subcategoryName': 'Vegetables & Fruits',
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
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildShopTab(), _buildReorderTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cartCount > 0 ? _buildCartBar() : null,
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _kGreen,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_rounded),
          tooltip: 'Request Items',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.shopPhotoRequestScreen,
            arguments: {
              'subcategoryId': 'vegetables',
              'subcategoryName': 'Vegetables & Fruits',
              'providerId': '',
              'providerName': 'Vegetable Shop',
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
              'providerName': 'Vegetable Shop',
              'orderItems': <Map<String, dynamic>>[],
            },
          ),
        ),
        if (_cartCount > 0)
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
                    '$_cartCount',
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
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: _showFilterSheet,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: -30,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Fresh Vegetables',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Farm-fresh • Bulk pricing • Seasonal picks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withAlpha(217),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(77)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search vegetables...',
          hintStyle: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withAlpha(204),
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withAlpha(204),
                    size: 16,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _kGreen,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: _kGreen,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Shop'),
          Tab(text: 'Reorder'),
        ],
      ),
    );
  }

  // ── Shop Tab ────────────────────────────────────────────────────────────────
  Widget _buildShopTab() {
    final items = _filtered;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildCategoryFilter()),
        if (_showSeasonalOnly)
          SliverToBoxAdapter(child: _buildSeasonalBanner()),
        items.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 56,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No vegetables found',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _VegetableCard(
                      item: items[i],
                      tiers: _tiersFor(items[i]),
                      cartEntry: _cart[items[i].id],
                      onAdd: (tier, {double? customQty}) =>
                          _addToCart(items[i], tier, customQty: customQty),
                      onRemove: () => _removeFromCart(items[i].id),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Seasonal toggle chip
            GestureDetector(
              onTap: () =>
                  setState(() => _showSeasonalOnly = !_showSeasonalOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _showSeasonalOnly ? _kSeasonBadge : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showSeasonalOnly
                        ? _kSeasonBadge
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: _showSeasonalOnly ? Colors.white : _kSeasonBadge,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Seasonal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _showSeasonalOnly ? Colors.white : _kSeasonBadge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ..._kCategories.map((cat) {
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? _kGreen : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seasonal Freshness',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Showing winter-special & seasonal vegetables',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reorder Tab ─────────────────────────────────────────────────────────────
  Widget _buildReorderTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (_reorderHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No previous orders yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your past vegetable orders will appear here\nfor quick reordering.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.eco_rounded, size: 18),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _reorderHistory.length,
      itemBuilder: (context, i) {
        final order = _reorderHistory[i];
        final items = (order['cart_items'] as List? ?? []);
        final date = DateTime.tryParse(order['created_at'] as String? ?? '');
        final dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : 'Unknown date';
        final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: BoxDecoration(
                  color: _kGreenSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: _kGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order on $dateStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kGreen,
                        ),
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kGreen,
                      ),
                    ),
                  ],
                ),
              ),
              // Items list
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: items.take(3).map((item) {
                    final itemMap = Map<String, dynamic>.from(item as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kGreenLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              itemMap['name'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF37474F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'x${itemMap['quantity'] ?? 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    '+${items.length - 3} more items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              // Quick reorder button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _quickReorder(order),
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Quick Reorder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Cart Bar ────────────────────────────────────────────────────────────────
  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _proceedToCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_cartCount items',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Proceed to Checkout',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '₹${_cartTotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter Vegetables',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _showSeasonalOnly,
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _showSeasonalOnly = v);
                },
                title: Text(
                  'Seasonal only',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Show winter specials & seasonal picks',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                activeThumbColor: _kGreen,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vegetable Card ────────────────────────────────────────────────────────────
class _VegetableCard extends StatefulWidget {
  final _VegetableItem item;
  final List<_BulkTier> tiers;
  final Map<String, dynamic>? cartEntry;
  final void Function(_BulkTier, {double? customQty}) onAdd;
  final VoidCallback onRemove;

  const _VegetableCard({
    required this.item,
    required this.tiers,
    required this.cartEntry,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_VegetableCard> createState() => _VegetableCardState();
}

class _VegetableCardState extends State<_VegetableCard> {
  int _selectedTierIndex = 0;
  final TextEditingController _customQtyCtrl = TextEditingController();
  bool _useCustomQty = false;

  @override
  void dispose() {
    _customQtyCtrl.dispose();
    super.dispose();
  }

  double? get _parsedCustomQty {
    final v = double.tryParse(_customQtyCtrl.text.trim());
    if (v != null && v > 0) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final selectedTier = widget.tiers[_selectedTierIndex];
    final inCart = widget.cartEntry != null;
    final cartQty = widget.cartEntry?['qty'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + badges row
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  item.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Fresh ${item.name} vegetable product image',
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: _kGreenSurface,
                    child: const Center(
                      child: Icon(Icons.eco_rounded, color: _kGreen, size: 40),
                    ),
                  ),
                ),
              ),
              if (item.isSeasonal)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _kSeasonBadge,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _kSeasonBadge.withAlpha(102),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.seasonLabel ?? 'Seasonal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(235),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreenLight.withAlpha(102)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: _kGreen,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.freshnessLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          Text(
                            item.nameLocal,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kGreenSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.nutritionChips.map((chip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF90CAF9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_hospital_rounded,
                            size: 10,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chip,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Text(
                  'Bulk Pricing',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(widget.tiers.length, (i) {
                    final tier = widget.tiers[i];
                    final isSelected =
                        _selectedTierIndex == i && !_useCustomQty;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTierIndex = i;
                          _useCustomQty = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? _kGreen : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _kGreen : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                tier.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${tier.price.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : _kGreen,
                                ),
                              ),
                              if (tier.savingLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  tier.savingLabel!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white.withAlpha(217)
                                        : _kSeasonBadge,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // ── Manual quantity entry ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _useCustomQty ? _kGreenSurface : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _useCustomQty ? _kGreen : Colors.grey[300]!,
                      width: _useCustomQty ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: _useCustomQty ? _kGreen : Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter custom quantity (e.g. 2.5 kg)',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            setState(() {
                              _useCustomQty =
                                  v.trim().isNotEmpty &&
                                  double.tryParse(v.trim()) != null &&
                                  double.tryParse(v.trim())! > 0;
                            });
                          },
                        ),
                      ),
                      Text(
                        'kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _useCustomQty ? _kGreen : Colors.grey[500],
                        ),
                      ),
                      if (_useCustomQty && _parsedCustomQty != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${(_parsedCustomQty! * item.pricePerKg).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Add to cart / quantity control
                if (false) // all items in stock by default
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Out of Stock',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                else if (!inCart)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onAdd(
                        selectedTier,
                        customQty: _useCustomQty ? _parsedCustomQty : null,
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _useCustomQty && _parsedCustomQty != null
                            ? 'Add ${_parsedCustomQty!.toStringAsFixed(2)} kg — ₹${(_parsedCustomQty! * item.pricePerKg).toStringAsFixed(0)}'
                            : 'Add ${selectedTier.label} — ₹${selectedTier.price.toStringAsFixed(0)}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kGreen),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: widget.onRemove,
                                icon: const Icon(
                                  Icons.remove_rounded,
                                  size: 18,
                                ),
                                color: _kGreen,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$cartQty',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _kGreen,
                                    ),
                                  ),
                                  Text(
                                    widget.cartEntry?['tierLabel'] as String? ??
                                        '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => widget.onAdd(
                                  selectedTier,
                                  customQty: _useCustomQty
                                      ? _parsedCustomQty
                                      : null,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                color: _kGreen,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreenSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '₹${((widget.cartEntry?['tierPrice'] as double? ?? 0) * cartQty).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
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
  }
}
