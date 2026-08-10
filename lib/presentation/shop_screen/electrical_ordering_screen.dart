import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

/// Dedicated customer ordering screen for Electrical & Hardware shops
/// Features: product list, technical specs (wattage, voltage, warranty, brand),
/// stock badges, category filters (Wires, Switches, Lights, Fans, Tools, MCBs, Accessories),
/// and quantity selectors.
class ElectricalOrderingScreen extends StatefulWidget {
  const ElectricalOrderingScreen({super.key});

  @override
  State<ElectricalOrderingScreen> createState() =>
      _ElectricalOrderingScreenState();
}

class _ElectricalOrderingScreenState extends State<ElectricalOrderingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFFF57C00);
  static const Color _accentDark = Color(0xFFE65100);

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, int> _cart = {};
  final Map<String, TextEditingController> _qtyControllers = {};

  static const List<String> _categories = [
    'All',
    'Wires',
    'Switches',
    'Lights',
    'Fans',
    'Tools',
    'MCBs',
    'Accessories',
  ];

  // Mock product catalog for Electrical & Hardware
  final List<Map<String, dynamic>> _allProducts = [
    // ── Wires ──────────────────────────────────────────────────────────────
    {
      'id': 'el_001',
      'name': 'Finolex 1.5 sq mm FR Wire',
      'category': 'Wires',
      'price': 38,
      'unit': 'meter',
      'stock_quantity': 500,
      'description':
          'Flame retardant PVC insulated copper wire for domestic wiring',
      'image_icon': Icons.cable_rounded,
      'specifications': {
        'Brand': 'Finolex',
        'Voltage': '1100 V',
        'Cross Section': '1.5 sq mm',
        'Material': 'Copper',
        'Insulation': 'FR PVC',
        'Color': 'Red/Blue/Green',
      },
    },
    {
      'id': 'el_002',
      'name': 'Polycab 2.5 sq mm FRLS Wire',
      'category': 'Wires',
      'price': 58,
      'unit': 'meter',
      'stock_quantity': 350,
      'description': 'Flame retardant low smoke wire for commercial use',
      'image_icon': Icons.cable_rounded,
      'specifications': {
        'Brand': 'Polycab',
        'Voltage': '1100 V',
        'Cross Section': '2.5 sq mm',
        'Material': 'Copper',
        'Insulation': 'FRLS PVC',
        'Warranty': '3 Years',
      },
    },
    {
      'id': 'el_003',
      'name': 'Havells 4 sq mm House Wire',
      'category': 'Wires',
      'price': 92,
      'unit': 'meter',
      'stock_quantity': 200,
      'description': 'Heavy-duty copper wire for high-load circuits',
      'image_icon': Icons.cable_rounded,
      'specifications': {
        'Brand': 'Havells',
        'Voltage': '1100 V',
        'Cross Section': '4 sq mm',
        'Material': 'Copper',
        'Insulation': 'PVC',
        'Warranty': '5 Years',
      },
    },
    {
      'id': 'el_004',
      'name': 'Anchor 6 sq mm Flexible Wire',
      'category': 'Wires',
      'price': 145,
      'unit': 'meter',
      'stock_quantity': 0,
      'description': 'Flexible multi-strand copper wire for heavy appliances',
      'image_icon': Icons.cable_rounded,
      'specifications': {
        'Brand': 'Anchor',
        'Voltage': '1100 V',
        'Cross Section': '6 sq mm',
        'Material': 'Copper',
        'Type': 'Flexible',
        'Warranty': '2 Years',
      },
    },
    // ── Switches ───────────────────────────────────────────────────────────
    {
      'id': 'el_005',
      'name': 'Legrand Arteor 6A Switch',
      'category': 'Switches',
      'price': 185,
      'unit': 'piece',
      'stock_quantity': 120,
      'description': 'Premium modular switch with piano-key design',
      'image_icon': Icons.toggle_on_rounded,
      'specifications': {
        'Brand': 'Legrand',
        'Voltage': '240 V AC',
        'Current': '6 A',
        'Type': 'Modular',
        'Material': 'Polycarbonate',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_006',
      'name': 'Havells Crabtree 16A Switch',
      'category': 'Switches',
      'price': 220,
      'unit': 'piece',
      'stock_quantity': 85,
      'description': 'Heavy-duty switch for AC and high-load appliances',
      'image_icon': Icons.toggle_on_rounded,
      'specifications': {
        'Brand': 'Havells',
        'Voltage': '240 V AC',
        'Current': '16 A',
        'Type': 'Modular',
        'Color': 'White',
        'Warranty': '3 Years',
      },
    },
    {
      'id': 'el_007',
      'name': 'Anchor Roma 6A 2-Way Switch',
      'category': 'Switches',
      'price': 95,
      'unit': 'piece',
      'stock_quantity': 200,
      'description': 'Two-way switch for staircase and corridor lighting',
      'image_icon': Icons.toggle_on_rounded,
      'specifications': {
        'Brand': 'Anchor',
        'Voltage': '240 V AC',
        'Current': '6 A',
        'Type': '2-Way',
        'Finish': 'Glossy White',
        'Warranty': '1 Year',
      },
    },
    {
      'id': 'el_008',
      'name': 'Schneider Opale 5A Socket',
      'category': 'Switches',
      'price': 165,
      'unit': 'piece',
      'stock_quantity': 60,
      'description': 'Universal socket with safety shutters',
      'image_icon': Icons.power_rounded,
      'specifications': {
        'Brand': 'Schneider',
        'Voltage': '240 V AC',
        'Current': '5 A',
        'Type': 'Universal Socket',
        'Safety': 'Child-proof shutters',
        'Warranty': '2 Years',
      },
    },
    // ── Lights ─────────────────────────────────────────────────────────────
    {
      'id': 'el_009',
      'name': 'Philips 9W LED Bulb',
      'category': 'Lights',
      'price': 120,
      'unit': 'piece',
      'stock_quantity': 300,
      'description': 'Energy-saving LED bulb with 15000 hours lifespan',
      'image_icon': Icons.lightbulb_rounded,
      'specifications': {
        'Brand': 'Philips',
        'Wattage': '9 W',
        'Voltage': '220–240 V',
        'Lumens': '950 lm',
        'Color Temp': '6500 K (Cool)',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_010',
      'name': 'Syska 18W LED Panel Light',
      'category': 'Lights',
      'price': 380,
      'unit': 'piece',
      'stock_quantity': 75,
      'description': 'Slim recessed LED panel for false ceiling',
      'image_icon': Icons.wb_sunny_rounded,
      'specifications': {
        'Brand': 'Syska',
        'Wattage': '18 W',
        'Voltage': '220 V',
        'Lumens': '1440 lm',
        'Size': '6 inch round',
        'Warranty': '3 Years',
      },
    },
    {
      'id': 'el_011',
      'name': 'Havells 36W LED Batten',
      'category': 'Lights',
      'price': 650,
      'unit': 'piece',
      'stock_quantity': 45,
      'description': 'Surface-mount LED batten for offices and shops',
      'image_icon': Icons.highlight_rounded,
      'specifications': {
        'Brand': 'Havells',
        'Wattage': '36 W',
        'Voltage': '220 V',
        'Length': '4 ft (1200 mm)',
        'Color Temp': '6500 K',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_012',
      'name': 'Orient 7W LED Spotlight',
      'category': 'Lights',
      'price': 210,
      'unit': 'piece',
      'stock_quantity': 0,
      'description': 'Directional spotlight for accent and display lighting',
      'image_icon': Icons.flashlight_on_rounded,
      'specifications': {
        'Brand': 'Orient',
        'Wattage': '7 W',
        'Voltage': '220 V',
        'Beam Angle': '36°',
        'Color Temp': '3000 K (Warm)',
        'Warranty': '1 Year',
      },
    },
    // ── Fans ───────────────────────────────────────────────────────────────
    {
      'id': 'el_013',
      'name': 'Crompton Aura 1200mm Ceiling Fan',
      'category': 'Fans',
      'price': 2850,
      'unit': 'piece',
      'stock_quantity': 20,
      'description': 'High-speed ceiling fan with anti-dust coating',
      'image_icon': Icons.air_rounded,
      'specifications': {
        'Brand': 'Crompton',
        'Wattage': '75 W',
        'Voltage': '220 V',
        'Sweep': '1200 mm',
        'Speed': '380 RPM',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_014',
      'name': 'Havells Stealth 1200mm BLDC Fan',
      'category': 'Fans',
      'price': 4200,
      'unit': 'piece',
      'stock_quantity': 12,
      'description': 'Energy-efficient BLDC motor fan with remote control',
      'image_icon': Icons.air_rounded,
      'specifications': {
        'Brand': 'Havells',
        'Wattage': '28 W',
        'Voltage': '220 V',
        'Sweep': '1200 mm',
        'Motor': 'BLDC',
        'Warranty': '5 Years',
      },
    },
    {
      'id': 'el_015',
      'name': 'Orient Wall Fan 400mm',
      'category': 'Fans',
      'price': 1650,
      'unit': 'piece',
      'stock_quantity': 30,
      'description': 'Oscillating wall-mount fan for kitchens and workshops',
      'image_icon': Icons.air_rounded,
      'specifications': {
        'Brand': 'Orient',
        'Wattage': '55 W',
        'Voltage': '220 V',
        'Sweep': '400 mm',
        'Speeds': '3 Speed',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_016',
      'name': 'Usha Exhaust Fan 150mm',
      'category': 'Fans',
      'price': 780,
      'unit': 'piece',
      'stock_quantity': 50,
      'description': 'Ventilation exhaust fan for bathrooms and kitchens',
      'image_icon': Icons.air_rounded,
      'specifications': {
        'Brand': 'Usha',
        'Wattage': '30 W',
        'Voltage': '220 V',
        'Blade': '150 mm',
        'Airflow': '200 m³/hr',
        'Warranty': '1 Year',
      },
    },
    // ── Tools ──────────────────────────────────────────────────────────────
    {
      'id': 'el_017',
      'name': 'Stanley Screwdriver Set (6 pcs)',
      'category': 'Tools',
      'price': 450,
      'unit': 'set',
      'stock_quantity': 40,
      'description': 'Insulated screwdriver set for electrical work',
      'image_icon': Icons.build_rounded,
      'specifications': {
        'Brand': 'Stanley',
        'Pieces': '6 pcs',
        'Insulation': '1000 V rated',
        'Material': 'CRV Steel',
        'Handle': 'Bi-material',
        'Warranty': '1 Year',
      },
    },
    {
      'id': 'el_018',
      'name': 'Bosch Digital Multimeter',
      'category': 'Tools',
      'price': 1200,
      'unit': 'piece',
      'stock_quantity': 15,
      'description': 'Auto-ranging digital multimeter for AC/DC measurement',
      'image_icon': Icons.speed_rounded,
      'specifications': {
        'Brand': 'Bosch',
        'Voltage Range': '0–600 V',
        'Current': 'AC/DC',
        'Display': '3.5 digit LCD',
        'Battery': '9 V',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_019',
      'name': 'Taparia Wire Stripper',
      'category': 'Tools',
      'price': 185,
      'unit': 'piece',
      'stock_quantity': 60,
      'description': 'Automatic wire stripper for 0.5–6 sq mm cables',
      'image_icon': Icons.content_cut_rounded,
      'specifications': {
        'Brand': 'Taparia',
        'Wire Range': '0.5–6 sq mm',
        'Material': 'Drop Forged Steel',
        'Grip': 'Insulated Handle',
        'Length': '160 mm',
        'Warranty': '1 Year',
      },
    },
    {
      'id': 'el_020',
      'name': 'Dewalt Cordless Drill 12V',
      'category': 'Tools',
      'price': 4800,
      'unit': 'piece',
      'stock_quantity': 8,
      'description': 'Compact cordless drill for drilling and fastening',
      'image_icon': Icons.hardware_rounded,
      'specifications': {
        'Brand': 'Dewalt',
        'Voltage': '12 V',
        'Torque': '30 Nm',
        'Chuck': '10 mm',
        'Battery': 'Li-ion 1.5 Ah',
        'Warranty': '3 Years',
      },
    },
    // ── MCBs ───────────────────────────────────────────────────────────────
    {
      'id': 'el_021',
      'name': 'Legrand 6A Single Pole MCB',
      'category': 'MCBs',
      'price': 145,
      'unit': 'piece',
      'stock_quantity': 200,
      'description':
          'Miniature circuit breaker for overload and short-circuit protection',
      'image_icon': Icons.electrical_services_rounded,
      'specifications': {
        'Brand': 'Legrand',
        'Current': '6 A',
        'Voltage': '240 V AC',
        'Poles': 'Single Pole',
        'Breaking Cap': '10 kA',
        'Warranty': '5 Years',
      },
    },
    {
      'id': 'el_022',
      'name': 'Schneider 32A Double Pole MCB',
      'category': 'MCBs',
      'price': 480,
      'unit': 'piece',
      'stock_quantity': 80,
      'description': 'Double pole MCB for AC units and heavy appliances',
      'image_icon': Icons.electrical_services_rounded,
      'specifications': {
        'Brand': 'Schneider',
        'Current': '32 A',
        'Voltage': '415 V AC',
        'Poles': 'Double Pole',
        'Breaking Cap': '10 kA',
        'Warranty': '5 Years',
      },
    },
    {
      'id': 'el_023',
      'name': 'Havells 63A 4-Pole RCCB',
      'category': 'MCBs',
      'price': 1850,
      'unit': 'piece',
      'stock_quantity': 25,
      'description':
          'Residual current circuit breaker for earth fault protection',
      'image_icon': Icons.security_rounded,
      'specifications': {
        'Brand': 'Havells',
        'Current': '63 A',
        'Voltage': '415 V AC',
        'Poles': '4 Pole',
        'Sensitivity': '30 mA',
        'Warranty': '5 Years',
      },
    },
    {
      'id': 'el_024',
      'name': 'ABB 100A Main Switch MCB',
      'category': 'MCBs',
      'price': 2200,
      'unit': 'piece',
      'stock_quantity': 0,
      'description': 'Main isolator switch for distribution boards',
      'image_icon': Icons.power_off_rounded,
      'specifications': {
        'Brand': 'ABB',
        'Current': '100 A',
        'Voltage': '415 V AC',
        'Poles': '4 Pole',
        'Type': 'Isolator',
        'Warranty': '5 Years',
      },
    },
    // ── Accessories ────────────────────────────────────────────────────────
    {
      'id': 'el_025',
      'name': 'Anchor 8-Way Distribution Box',
      'category': 'Accessories',
      'price': 320,
      'unit': 'piece',
      'stock_quantity': 55,
      'description': 'Surface-mount distribution box for MCB mounting',
      'image_icon': Icons.dashboard_rounded,
      'specifications': {
        'Brand': 'Anchor',
        'Capacity': '8 Ways',
        'Material': 'ABS Plastic',
        'Mounting': 'Surface',
        'IP Rating': 'IP40',
        'Warranty': '1 Year',
      },
    },
    {
      'id': 'el_026',
      'name': 'Finolex PVC Conduit Pipe 20mm',
      'category': 'Accessories',
      'price': 65,
      'unit': 'piece',
      'stock_quantity': 400,
      'description': 'Rigid PVC conduit for wire protection and routing',
      'image_icon': Icons.linear_scale_rounded,
      'specifications': {
        'Brand': 'Finolex',
        'Diameter': '20 mm',
        'Length': '3 meters',
        'Material': 'Rigid PVC',
        'Color': 'Grey',
        'Warranty': '1 Year',
      },
    },
    {
      'id': 'el_027',
      'name': 'Polycab 5A Extension Board (3m)',
      'category': 'Accessories',
      'price': 280,
      'unit': 'piece',
      'stock_quantity': 90,
      'description': '6-socket extension board with surge protection',
      'image_icon': Icons.power_rounded,
      'specifications': {
        'Brand': 'Polycab',
        'Voltage': '240 V AC',
        'Current': '5 A',
        'Sockets': '6 Universal',
        'Cable Length': '3 meters',
        'Warranty': '2 Years',
      },
    },
    {
      'id': 'el_028',
      'name': 'Legrand Cable Tie 200mm (100 pcs)',
      'category': 'Accessories',
      'price': 95,
      'unit': 'pack',
      'stock_quantity': 150,
      'description': 'Nylon cable ties for wire management and bundling',
      'image_icon': Icons.link_rounded,
      'specifications': {
        'Brand': 'Legrand',
        'Length': '200 mm',
        'Width': '3.6 mm',
        'Material': 'Nylon 66',
        'Tensile': '18 kg',
        'Pack': '100 pcs',
      },
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      final matchesCat =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (p['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ((p['specifications'] as Map).values.any(
            (v) =>
                v.toString().toLowerCase().contains(_searchQuery.toLowerCase()),
          ));
      return matchesCat && matchesSearch;
    }).toList();
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);
  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _allProducts.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => <String, dynamic>{},
      );
      if (product.isNotEmpty) {
        total += ((product['price'] as num).toDouble()) * entry.value;
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

  void _removeFromCart(String id) {
    setState(() {
      if ((_cart[id] ?? 0) > 1) {
        _cart[id] = _cart[id]! - 1;
        _qtyControllers[id]?.text = '${_cart[id]}';
      } else {
        _cart.remove(id);
        _qtyControllers.remove(id)?.dispose();
      }
    });
  }

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildProductList()),
        ],
      ),
      bottomNavigationBar: _cartItemCount > 0 ? _buildCartBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Electrical & Hardware',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            '${_allProducts.length} products available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_rounded),
          tooltip: 'Request Items',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.shopPhotoRequestScreen,
            arguments: {
              'subcategoryId': 'electrical',
              'subcategoryName': 'Electrical & Hardware',
              'providerId': '',
              'providerName': 'Electrical Shop',
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
              'providerName': 'Electrical Shop',
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
                onPressed: () => _showCartSummary(),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _accent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search wires, switches, brands...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF90A4AE),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _accent,
              size: 20,
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
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _accent : const Color(0xFFCFD8DC),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(cat),
                    size: 13,
                    color: isSelected ? Colors.white : const Color(0xFF78909C),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF546E7A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Wires':
        return Icons.cable_rounded;
      case 'Switches':
        return Icons.toggle_on_rounded;
      case 'Lights':
        return Icons.lightbulb_rounded;
      case 'Fans':
        return Icons.air_rounded;
      case 'Tools':
        return Icons.build_rounded;
      case 'MCBs':
        return Icons.electrical_services_rounded;
      case 'Accessories':
        return Icons.extension_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildProductList() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: _accent.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF546E7A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search or category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF90A4AE),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _buildProductCard(products[i]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id'] as String;
    final qty = _cart[id] ?? 0;
    final price = (product['price'] as num).toDouble();
    final unit = product['unit'] as String;
    final stock = product['stock_quantity'] as int;
    final specs = product['specifications'] as Map<String, dynamic>;
    final icon = product['image_icon'] as IconData;
    final category = product['category'] as String;

    // Stock badge config
    final bool inStock = stock > 0;
    final bool lowStock = stock > 0 && stock <= 20;
    final Color stockColor = !inStock
        ? const Color(0xFFD32F2F)
        : lowStock
        ? const Color(0xFFF57F17)
        : const Color(0xFF2E7D32);
    final Color stockBg = !inStock
        ? const Color(0xFFFFEBEE)
        : lowStock
        ? const Color(0xFFFFFDE7)
        : const Color(0xFFE8F5E9);
    final String stockLabel = !inStock
        ? 'Out of Stock'
        : lowStock
        ? 'Low Stock ($stock left)'
        : 'In Stock';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withAlpha(40), width: 1),
                  ),
                  child: Icon(icon, color: _accent, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _accentDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2332),
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
                              color: const Color(0xFF78909C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Stock badge + quantity selector row ─────────────────────
            Row(
              children: [
                // Stock badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: stockColor.withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        stockLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Quantity selector
                if (inStock)
                  qty == 0
                      ? GestureDetector(
                          onTap: () => _addToCart(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withAlpha(80),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : _buildQtySelector(id, qty),
              ],
            ),

            const SizedBox(height: 10),

            // ── Technical specs grid ────────────────────────────────────
            _buildSpecsGrid(specs),

            // ── Description ─────────────────────────────────────────────
            if ((product['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                product['description'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF78909C),
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

  Widget _buildQtySelector(String id, int qty) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _accent, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _removeFromCart(id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent.withAlpha(20),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Icon(Icons.remove_rounded, color: _accent, size: 16),
            ),
          ),
          SizedBox(
            width: 44,
            height: 32,
            child: TextField(
              controller: _qtyControllers.putIfAbsent(
                id,
                () => TextEditingController(text: '$qty'),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _accentDark,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v.trim());
                if (parsed != null) _setCartQty(id, parsed);
              },
            ),
          ),
          GestureDetector(
            onTap: () => _addToCart(id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
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
    );
  }

  Widget _buildSpecsGrid(Map<String, dynamic> specs) {
    final entries = specs.entries.toList();
    return Wrap(
      spacing: 6,
      runSpacing: 5,
      children: entries.map((e) {
        // Highlight key electrical specs
        final isHighlight = [
          'Wattage',
          'Voltage',
          'Brand',
          'Warranty',
        ].contains(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlight
                ? _accent.withAlpha(22)
                : const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isHighlight
                  ? _accent.withAlpha(60)
                  : const Color(0xFFCFD8DC),
              width: 1,
            ),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${e.key}: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isHighlight ? _accentDark : const Color(0xFF78909C),
                  ),
                ),
                TextSpan(
                  text: e.value.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isHighlight ? _accentDark : const Color(0xFF37474F),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCartBar() {
    return Container(
      decoration: BoxDecoration(
        color: _accentDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _showCartSummary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_cartItemCount item${_cartItemCount != 1 ? 's' : ''}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'View Cart & Checkout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
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
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCartSummary() {
    final cartItems = _cart.entries.map((e) {
      final product = _allProducts.firstWhere((p) => p['id'] == e.key);
      return {
        'product_id': e.key,
        'name': product['name'],
        'price': product['price'],
        'unit': product['unit'],
        'quantity': e.value,
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cart Summary',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2332),
              ),
            ),
            const SizedBox(height: 12),
            ...cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '×${item['quantity']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '₹${_cartTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.shopCheckoutScreen,
                    arguments: {
                      'providerId': '',
                      'providerName': 'Electrical & Hardware Shop',
                      'subcategoryId': 'electrical',
                      'subcategoryName': 'Electrical & Hardware',
                      'cartItems': cartItems,
                      'cartTotal': _cartTotal,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Checkout',
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
