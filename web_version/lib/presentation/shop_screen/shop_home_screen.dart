import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ShopHomeScreen extends StatefulWidget {
  const ShopHomeScreen({super.key});

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProvider = false;

  final List<_ShopSubcategory> _subcategories = [
    _ShopSubcategory(
      id: 'grocery',
      name: 'Grocery / Kirana',
      nameMarathi: 'किराणा',
      icon: Icons.shopping_basket_rounded,
      color: const Color(0xFF43A047),
      gradient: const LinearGradient(
        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Daily essentials, pulses, grains & more',
      imageUrl:
          'https://images.pexels.com/photos/1367242/pexels-photo-1367242.jpeg',
      tags: ['Fruits', 'Vegetables', 'Dairy', 'Grains', 'Snacks'],
    ),
    _ShopSubcategory(
      id: 'vegetables',
      name: 'Vegetables & Fruits',
      nameMarathi: 'भाजीपाला',
      icon: Icons.eco_rounded,
      color: const Color(0xFF2E7D32),
      gradient: const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Fresh farm vegetables & seasonal fruits',
      imageUrl:
          'https://images.pixabay.com/photo/2017/10/09/19/29/eat-2834549_1280.jpg',
      tags: ['Leafy Greens', 'Root Veg', 'Fruits', 'Organic'],
    ),
    _ShopSubcategory(
      id: 'meat_fish',
      name: 'Chicken, Mutton & Fish',
      nameMarathi: 'मटण, चिकन, मासे',
      icon: Icons.set_meal_rounded,
      color: const Color(0xFFD32F2F),
      gradient: const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Fresh meat, poultry & seafood daily',
      imageUrl:
          'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400',
      tags: ['Chicken', 'Mutton', 'Fish', 'Eggs', 'Seafood'],
    ),
    _ShopSubcategory(
      id: 'electrical',
      name: 'Electrical & Hardware',
      nameMarathi: 'इलेक्ट्रिकल',
      icon: Icons.electrical_services_rounded,
      color: const Color(0xFFF57C00),
      gradient: const LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Wires, switches, fans, lights & more',
      imageUrl:
          'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
      tags: ['Wires', 'Switches', 'LED', 'Fans', 'MCBs'],
    ),
    _ShopSubcategory(
      id: 'plumbing_hardware',
      name: 'Plumbing & Hardware',
      nameMarathi: 'प्लंबिंग',
      icon: Icons.plumbing_rounded,
      color: const Color(0xFF0277BD),
      gradient: const LinearGradient(
        colors: [Color(0xFF0277BD), Color(0xFF0288D1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Pipes, fittings, taps & building materials',
      imageUrl:
          'https://images.pixabay.com/photo/2016/11/18/17/20/pipe-1834859_1280.jpg',
      tags: ['Pipes', 'Taps', 'Cement', 'Tools', 'Fasteners'],
    ),
    _ShopSubcategory(
      id: 'seasonal',
      name: 'Seasonal Items',
      nameMarathi: 'हंगामी वस्तू',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFFB300),
      gradient: const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFFCA28)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      description: 'Festival items, seasonal specials & more',
      imageUrl:
          'https://images.unsplash.com/photo-1574169208507-84376144848b?w=400',
      tags: ['Diwali', 'Holi', 'Ganesh', 'Mangoes', 'Winter'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    final profile = await SupabaseService.instance.getUserProfile(userId);
    if (mounted) {
      setState(() {
        _isProvider = profile?['role'] == 'provider';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ShopSubcategory> get _filtered {
    if (_searchQuery.isEmpty) return _subcategories;
    final q = _searchQuery.toLowerCase();
    return _subcategories.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.nameMarathi.contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  void _openSubcategory(_ShopSubcategory sub) {
    if (_isProvider) {
      // Route electrical providers to dedicated electrical provider screen
      if (sub.id == 'electrical') {
        Navigator.pushNamed(context, AppRoutes.electricalProviderScreen);
        return;
      }
      // Route plumbing_hardware providers to dedicated plumbing provider screen
      if (sub.id == 'plumbing_hardware') {
        Navigator.pushNamed(context, AppRoutes.plumbingProviderScreen);
        return;
      }
      Navigator.pushNamed(
        context,
        AppRoutes.shopProviderDashboardScreen,
        arguments: {'subcategoryId': sub.id, 'subcategoryName': sub.name},
      );
    } else {
      // Route to dedicated customer screen per subcategory
      switch (sub.id) {
        case 'meat_fish':
          Navigator.pushNamed(context, AppRoutes.meatShopCustomerScreen);
          break;
        case 'electrical':
          Navigator.pushNamed(context, AppRoutes.electricalOrderingScreen);
          break;
        case 'plumbing_hardware':
          Navigator.pushNamed(
            context,
            AppRoutes.plumbingHardwareCustomerScreen,
          );
          break;
        case 'seasonal':
          Navigator.pushNamed(context, AppRoutes.seasonalItemsCustomerScreen);
          break;
        case 'vegetables':
          Navigator.pushNamed(context, AppRoutes.vegetablesOrderingScreen);
          break;
        case 'grocery':
        default:
          Navigator.pushNamed(
            context,
            AppRoutes.shopCustomerScreen,
            arguments: {'subcategoryId': sub.id, 'subcategoryName': sub.name},
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchBar(),
            ),
          ),
          if (_isProvider) SliverToBoxAdapter(child: _buildProviderBanner()),
          // Customer-only quick action buttons
          if (!_isProvider)
            SliverToBoxAdapter(child: _buildCustomerQuickActions()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Shop Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SubcategoryCard(
                  subcategory: filtered[index],
                  onTap: () => _openSubcategory(filtered[index]),
                ),
                childCount: filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCustomerQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionTile(
              icon: Icons.camera_alt_rounded,
              label: 'Request Items',
              sublabel: 'Upload photo & get quote',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.shopPhotoRequestScreen,
                arguments: {
                  'subcategoryId': 'grocery',
                  'subcategoryName': 'Shop',
                  'providerId': '',
                  'providerName': 'Shop',
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionTile(
              icon: Icons.assignment_return_rounded,
              label: 'Return Goods',
              sublabel: 'Quality or quantity issue',
              color: const Color(0xFFD32F2F),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.shopReturnRequestScreen,
                arguments: {
                  'orderId': '',
                  'orderNumber': 'Recent Order',
                  'providerName': 'Shop',
                  'orderItems': <Map<String, dynamic>>[],
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppTheme.catGrocery,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Shops',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Order from nearby shops',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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
        'Shop',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search grocery, meat, electrical...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF90A4AE),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProviderBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Mode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Tap a category to manage your shop',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
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
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final _ShopSubcategory subcategory;
  final VoidCallback onTap;

  const _SubcategoryCard({required this.subcategory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: subcategory.color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Image.network(
                      subcategory.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: subcategory.color.withAlpha(40),
                        child: Icon(
                          subcategory.icon,
                          color: subcategory.color,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          subcategory.color.withAlpha(180),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        subcategory.icon,
                        color: subcategory.color,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subcategory.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subcategory.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: subcategory.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: subcategory.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: subcategory.color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopSubcategory {
  final String id;
  final String name;
  final String nameMarathi;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String description;
  final String imageUrl;
  final List<String> tags;

  const _ShopSubcategory({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.description,
    required this.imageUrl,
    required this.tags,
  });
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
