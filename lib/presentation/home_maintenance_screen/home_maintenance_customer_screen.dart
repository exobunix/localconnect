import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/category_service.dart';

class HomeMaintenanceCustomerScreen extends StatefulWidget {
  const HomeMaintenanceCustomerScreen({super.key});

  @override
  State<HomeMaintenanceCustomerScreen> createState() =>
      _HomeMaintenanceCustomerScreenState();
}

class _HomeMaintenanceCustomerScreenState
    extends State<HomeMaintenanceCustomerScreen> {
  String _activeSubcategory = 'plumber';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _sortBy = 'nearest';
  double _maxDistance = 15.0;
  bool _verifiedOnly = false;
  bool _emergencyOnly = false;
  bool _availableOnly = true;
  final Set<String> _favourites = {};

  // Dynamic subcategories loaded from Supabase
  List<Map<String, dynamic>> _dynamicSubcategories = [];
  bool _subcategoriesLoaded = false;

  // Fallback hardcoded subcategories (used only if Supabase fails)
  static const _fallbackSubcategories = [
    {
      'id': 'plumber',
      'label': 'Plumber',
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF0277BD),
    },
    {
      'id': 'electrician',
      'label': 'Electrician',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFFF57F17),
    },
    {
      'id': 'painter',
      'label': 'Painter',
      'icon': Icons.format_paint_rounded,
      'color': Color(0xFF6A1B9A),
    },
    {
      'id': 'mason',
      'label': 'Mason',
      'icon': Icons.construction_rounded,
      'color': Color(0xFF4E342E),
    },
    {
      'id': 'carpenter',
      'label': 'Carpenter',
      'icon': Icons.carpenter_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'id': 'daily_wage',
      'label': 'Helper',
      'icon': Icons.engineering_rounded,
      'color': Color(0xFF00695C),
    },
    {
      'id': 'cleaning',
      'label': 'Cleaning',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF1565C0),
    },
  ];

  List<Map<String, dynamic>> get _subcategories =>
      _subcategoriesLoaded && _dynamicSubcategories.isNotEmpty
      ? _dynamicSubcategories
      : _fallbackSubcategories;

  static final Map<String, List<Map<String, dynamic>>> _mockProviders = {
    'plumber': [
      {
        'id': 'p1',
        'name': 'Ramesh Plumbing Works',
        'rating': 4.8,
        'reviews': 124,
        'distance': 1.2,
        'charge': 300,
        'experience': 8,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Pipe Leakage & Bathroom Fitting',
        'completedJobs': 340,
        'phone': '+919876543210',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_131b0a68b-1764663629659.png',
        'gallery': [
          'https://images.pexels.com/photos/8486944/pexels-photo-8486944.jpeg?w=300',
          'https://images.pexels.com/photos/6419128/pexels-photo-6419128.jpeg?w=300',
        ],
      },
      {
        'id': 'p2',
        'name': 'Suresh Kumar Plumber',
        'rating': 4.5,
        'reviews': 89,
        'distance': 2.5,
        'charge': 250,
        'experience': 5,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Water Tank & Motor Installation',
        'completedJobs': 210,
        'phone': '+919812345678',
        'image': 'https://images.unsplash.com/photo-1723407653103-7a9c6b579acf',
        'gallery': [
          'https://images.pexels.com/photos/8486972/pexels-photo-8486972.jpeg?w=300',
        ],
      },
      {
        'id': 'p3',
        'name': 'Mohan Pipe Services',
        'rating': 4.2,
        'reviews': 56,
        'distance': 3.8,
        'charge': 200,
        'experience': 3,
        'verified': false,
        'emergency': true,
        'available': false,
        'speciality': 'Drain Blockage & Tap Repair',
        'completedJobs': 98,
        'phone': '+919823456789',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_11fcbce8b-1772357500449.png',
        'gallery': [],
      },
    ],
    'electrician': [
      {
        'id': 'e1',
        'name': 'Vijay Electrical Services',
        'rating': 4.9,
        'reviews': 201,
        'distance': 0.8,
        'charge': 350,
        'experience': 12,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Wiring, MCB & Inverter Installation',
        'completedJobs': 520,
        'phone': '+919834567890',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_14068230d-1783271524011.png',
        'gallery': [
          'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg?w=300',
        ],
      },
      {
        'id': 'e2',
        'name': 'Prakash Electrician',
        'rating': 4.6,
        'reviews': 143,
        'distance': 1.9,
        'charge': 280,
        'experience': 7,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Fan, Light & Switchboard Repair',
        'completedJobs': 380,
        'phone': '+919845678901',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1118faa9d-1768844919530.png',
        'gallery': [
          'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg?w=300',
        ],
      },
    ],
    'painter': [
      {
        'id': 'pa1',
        'name': 'ColorCraft Painters',
        'rating': 4.7,
        'reviews': 98,
        'distance': 2.1,
        'charge': 15,
        'experience': 10,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Interior & Texture Painting',
        'completedJobs': 180,
        'chargeUnit': '/sq.ft',
        'phone': '+919856789012',
        'image': 'https://images.unsplash.com/photo-1693200430042-a37503921b88',
        'gallery': [
          'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=300',
          'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg?w=300',
        ],
      },
      {
        'id': 'pa2',
        'name': 'Shyam Painting Works',
        'rating': 4.4,
        'reviews': 67,
        'distance': 3.2,
        'charge': 12,
        'experience': 6,
        'verified': false,
        'emergency': false,
        'available': true,
        'speciality': 'Exterior & Waterproof Coating',
        'completedJobs': 120,
        'chargeUnit': '/sq.ft',
        'phone': '+919867890123',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1dfbcd802-1783271523283.png',
        'gallery': [],
      },
    ],
    'mason': [
      {
        'id': 'm1',
        'name': 'Ganesh Construction',
        'rating': 4.6,
        'reviews': 77,
        'distance': 2.8,
        'charge': 700,
        'experience': 15,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Tile Fitting & Flooring',
        'completedJobs': 230,
        'chargeUnit': '/day',
        'phone': '+919878901234',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_112d89bc5-1773104737112.png',
        'gallery': [
          'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?w=300',
        ],
      },
    ],
    'carpenter': [
      {
        'id': 'c1',
        'name': 'WoodCraft Carpentry',
        'rating': 4.8,
        'reviews': 112,
        'distance': 1.5,
        'charge': 500,
        'experience': 9,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Modular Furniture & Wardrobe',
        'completedJobs': 290,
        'chargeUnit': '/day',
        'phone': '+919889012345',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_145d460fd-1765180551539.png',
        'gallery': [
          'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg?w=300',
        ],
      },
    ],
    'daily_wage': [
      {
        'id': 'd1',
        'name': 'Raju Helper Services',
        'rating': 4.3,
        'reviews': 45,
        'distance': 0.9,
        'charge': 400,
        'experience': 2,
        'verified': false,
        'emergency': true,
        'available': true,
        'speciality': 'Loading, Moving & Garden Work',
        'completedJobs': 88,
        'chargeUnit': '/day',
        'phone': '+919890123456',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1405eb26b-1783271524814.png',
        'gallery': [],
      },
      {
        'id': 'd2',
        'name': 'Santosh Labour Group',
        'rating': 4.5,
        'reviews': 62,
        'distance': 1.7,
        'charge': 350,
        'experience': 4,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Construction Helper & Loader',
        'completedJobs': 145,
        'chargeUnit': '/day',
        'phone': '+919901234567',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_112d89bc5-1773104737112.png',
        'gallery': [],
      },
    ],
    'cleaning': [
      {
        'id': 'cl1',
        'name': 'SparkleClean Services',
        'rating': 4.9,
        'reviews': 187,
        'distance': 1.1,
        'charge': 800,
        'experience': 6,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Deep Cleaning & Sofa Cleaning',
        'completedJobs': 420,
        'phone': '+919912345678',
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1b758300c-1772483659351.png',
        'gallery': [
          'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg?w=300',
        ],
      },
      {
        'id': 'cl2',
        'name': 'HomeFresh Cleaners',
        'rating': 4.6,
        'reviews': 134,
        'distance': 2.3,
        'charge': 600,
        'experience': 4,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Home & Kitchen Cleaning',
        'completedJobs': 310,
        'phone': '+919923456789',
        'image':
            'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg?w=400',
        'gallery': [],
      },
    ],
  };

  List<Map<String, dynamic>> get _filteredProviders {
    final list = List<Map<String, dynamic>>.from(
      _mockProviders[_activeSubcategory] ?? [],
    );
    return list.where((p) {
      if (_verifiedOnly && p['verified'] != true) return false;
      if (_emergencyOnly && p['emergency'] != true) return false;
      if (_availableOnly && p['available'] != true) return false;
      if ((p['distance'] as num) > _maxDistance) return false;
      if (_searchQuery.isNotEmpty &&
          !(p['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return (b['rating'] as num).compareTo(a['rating'] as num);
        case 'price_low':
          return (a['charge'] as num).compareTo(b['charge'] as num);
        case 'experience':
          return (b['experience'] as num).compareTo(a['experience'] as num);
        default:
          return (a['distance'] as num).compareTo(b['distance'] as num);
      }
    });
  }

  Color get _activeColor {
    final subs = _subcategories;
    final match = subs.where((s) => s['id'] == _activeSubcategory);
    if (match.isNotEmpty) return match.first['color'] as Color;
    return const Color(0xFF0277BD);
  }

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    // Always use fallback subcategories to align with mock data keys and prevent TabController crashes
    if (!mounted) return;
    setState(() {
      _subcategoriesLoaded = true;
    });
  }

  /// Assign a consistent color per subcategory id/name
  Color _colorForSubcategory(String id, String name) {
    const colorMap = <String, Color>{
      'plumber': Color(0xFF0277BD),
      'electrician': Color(0xFFF57F17),
      'painter': Color(0xFF6A1B9A),
      'mason': Color(0xFF4E342E),
      'carpenter': Color(0xFF2E7D32),
      'daily_wage': Color(0xFF00695C),
      'cleaning': Color(0xFF1565C0),
      'waterproofing': Color(0xFF00838F),
      'waterproof': Color(0xFF00838F),
    };
    final lId = id.toLowerCase();
    final lName = name.toLowerCase();
    for (final entry in colorMap.entries) {
      if (lId.contains(entry.key) || lName.contains(entry.key)) {
        return entry.value;
      }
    }
    // Generate a deterministic color from the id
    final hash = id.codeUnits.fold(0, (prev, e) => prev + e);
    const palette = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFF00695C),
      Color(0xFFF57F17),
      Color(0xFF4E342E),
      Color(0xFF0277BD),
      Color(0xFF00838F),
      Color(0xFFAD1457),
    ];
    return palette[hash % palette.length];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['subcategory'] != null) {
      final sub = args['subcategory'] as String;
      final subs = _subcategories;
      final idx = subs.indexWhere((s) => s['id'] == sub);
      if (idx >= 0) {
        setState(() => _activeSubcategory = sub);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter Providers',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort By',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    [
                      {'id': 'nearest', 'label': 'Nearest'},
                      {'id': 'rating', 'label': 'Top Rated'},
                      {'id': 'price_low', 'label': 'Lowest Price'},
                      {'id': 'experience', 'label': 'Most Experienced'},
                    ].map((s) {
                      final selected = _sortBy == s['id'];
                      return ChoiceChip(
                        label: Text(s['label']!),
                        selected: selected,
                        selectedColor: _activeColor.withValues(alpha: 0.15),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: selected ? _activeColor : Colors.grey[700],
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        onSelected: (_) => setModal(() => _sortBy = s['id']!),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Max Distance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_maxDistance.toStringAsFixed(1)} km',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: _activeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 30,
                activeColor: _activeColor,
                onChanged: (v) => setModal(() => _maxDistance = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _filterToggle(
                      'Verified Only',
                      _verifiedOnly,
                      (v) => setModal(() => _verifiedOnly = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filterToggle(
                      'Emergency',
                      _emergencyOnly,
                      (v) => setModal(() => _emergencyOnly = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _filterToggle(
                'Available Now',
                _availableOnly,
                (v) => setModal(() => _availableOnly = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value ? _activeColor.withValues(alpha: 0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: value
              ? _activeColor.withValues(alpha: 0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: value ? _activeColor : Colors.grey[700],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _activeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _handleCall(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: p);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch phone dialer.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    }
  }

  void _handleWhatsApp(String phone) async {
    final p = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    final number = p.startsWith('+') ? p.replaceFirst('+', '') : '91$p';
    if (p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No contact number available for WhatsApp.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
      return;
    }
    final message = Uri.encodeComponent(
      'Hi, I found your profile on LocalConnect and would like to inquire about your services.',
    );
    final whatsappUri = Uri.parse('https://wa.me/$number?text=$message');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open WhatsApp.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    }
  }

  void _showProviderDetail(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: Image.network(
                      provider['image'] as String,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: _activeColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person_rounded,
                          color: _activeColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider['verified'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider['speciality'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            Text(
                              ' ${provider['rating']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' (${provider['reviews']} reviews)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Contact number row
              if ((provider['phone'] as String? ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _activeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: _activeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: _activeColor),
                      const SizedBox(width: 8),
                      Text(
                        provider['phone'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statChip(
                    Icons.work_history_rounded,
                    '${provider['completedJobs']} Jobs',
                    _activeColor,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    Icons.location_on_rounded,
                    '${provider['distance']} km',
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    Icons.timer_rounded,
                    '${provider['experience']} yrs',
                    Colors.orange[700]!,
                  ),
                ],
              ),
              if ((provider['gallery'] as List).isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Work Gallery',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (provider['gallery'] as List).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        (provider['gallery'] as List)[i] as String,
                        width: 120,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Call, Message, WhatsApp row
              Row(
                children: [
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      color: Colors.green[700]!,
                      onTap: () {
                        Navigator.pop(context);
                        _handleCall(provider['phone'] as String? ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: _activeColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chatDetailScreen,
                          arguments: {
                            'providerId': provider['id'],
                            'providerName': provider['name'],
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.help_outline,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.pop(context);
                        _handleWhatsApp(provider['phone'] as String? ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Chat and Book Now row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Chat',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _activeColor,
                        side: BorderSide(color: _activeColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chatDetailScreen,
                          arguments: {
                            'providerId': provider['id'],
                            'providerName': provider['name'],
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Book Now',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showBookingSheet(provider);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(Map<String, dynamic> provider) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding: const EdgeInsets.all(24),
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
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Book Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider['name'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (d != null) setModal(() => selectedDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: _activeColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate != null
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Select Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: selectedDate != null
                                      ? Colors.black87
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null) setModal(() => selectedTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: _activeColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(ctx)
                                    : 'Select Time',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: selectedTime != null
                                      ? Colors.black87
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the problem or work needed...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _activeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 16,
                        color: _activeColor,
                      ),
                      Text(
                        'Service Charge: ₹${provider['charge']}${provider['chargeUnit'] ?? '/visit'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: _activeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Booking request sent to ${provider['name']}!',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: _activeColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Confirm Booking',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = _filteredProviders;
    final activeColor = _activeColor;
    final subs = _subcategories;
    final activeSub = subs.isNotEmpty
        ? subs.firstWhere(
            (s) => s['id'] == _activeSubcategory,
            orElse: () => subs.first,
          )
        : {
            'id': '',
            'label': 'Services',
            'icon': Icons.home_repair_service_rounded,
            'color': const Color(0xFF0277BD),
          };

    return DefaultTabController(
      length: subs.length,
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: activeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.mapDiscoveryScreen),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activeColor, activeColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Maintenance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find trusted professionals near you',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: activeColor,
                child: TabBar(
                  onTap: (index) {
                    setState(() {
                      _activeSubcategory = subs[index]['id'] as String;
                    });
                  },
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                  ),
                  tabs: subs
                      .map(
                        (s) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(s['icon'] as IconData, size: 14),
                              const SizedBox(width: 5),
                              Text(s['label'] as String),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search ${activeSub['label']} providers...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${providers.length} providers found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_verifiedOnly || _emergencyOnly || !_availableOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'Filtered',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Provider list
            Expanded(
              child: providers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            activeSub['icon'] as IconData,
                            size: 56,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No providers found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your filters',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: providers.length,
                      itemBuilder: (_, i) => _ProviderCard(
                        provider: providers[i],
                        activeColor: activeColor,
                        isFavourite: _favourites.contains(providers[i]['id']),
                        onFavourite: () => setState(() {
                          final id = providers[i]['id'] as String;
                          _favourites.contains(id)
                              ? _favourites.remove(id)
                              : _favourites.add(id);
                        }),
                        onTap: () => _showProviderDetail(providers[i]),
                        onBook: () => _showBookingSheet(providers[i]),
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

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color activeColor;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const _ProviderCard({
    required this.provider,
    required this.activeColor,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                  child: Image.network(
                    provider['image'] as String,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: activeColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.home_repair_service_rounded,
                        size: 48,
                        color: activeColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                // Favourite
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onFavourite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: isFavourite ? Colors.red : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                // Badges
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (provider['verified'] == true)
                        _badge(
                          'Verified',
                          Colors.green[700]!,
                          Icons.verified_rounded,
                        ),
                      if (provider['emergency'] == true) ...[
                        const SizedBox(width: 6),
                        _badge(
                          'Emergency',
                          Colors.red[700]!,
                          Icons.flash_on_rounded,
                        ),
                      ],
                      if (provider['available'] != true) ...[
                        const SizedBox(width: 6),
                        _badge(
                          'Unavailable',
                          Colors.grey[600]!,
                          Icons.block_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          Text(
                            ' ${provider['rating']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' (${provider['reviews']})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider['speciality'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      Text(
                        ' ${provider['distance']} km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 13,
                        color: activeColor,
                      ),
                      Text(
                        '${provider['charge']}${provider['chargeUnit'] ?? '/visit'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.timer_rounded,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      Text(
                        ' ${provider['experience']} yrs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Book',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  static Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
