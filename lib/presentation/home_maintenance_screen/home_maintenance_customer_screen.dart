import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/category_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/universal_enquiry_dialog.dart';

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
  static const List<Map<String, dynamic>> _fallbackSubcategories = [
    {
      'id': 'plumber',
      'label': 'Plumber',
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'electrician',
      'label': 'Electrician',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFF57C00),
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
    {
      'id': 'maid',
      'label': 'Maid / Housekeeping',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFFE91E63),
    },
    {
      'id': 'waterproofing',
      'label': 'Waterproofing',
      'icon': Icons.water_damage_rounded,
      'color': Color(0xFF00ACC1),
    },
  ];

  List<Map<String, dynamic>> get _subcategories =>
      _subcategoriesLoaded && _dynamicSubcategories.isNotEmpty
      ? _dynamicSubcategories
      : _fallbackSubcategories;

  static final Map<String, List<Map<String, dynamic>>> _mockProviders = {
    'plumber': [
      {
        'id': '53d09495-2bd2-478f-b686-3d856184d934',
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
            'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/8486944/pexels-photo-8486944.jpeg?w=300',
          'https://images.pexels.com/photos/6419128/pexels-photo-6419128.jpeg?w=300',
        ],
      },
      {
        'id': '474aaf7b-3110-40c1-a64f-34eeab2973d9',
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
        'phone': '+919876543211',
        'image': 'https://images.pexels.com/photos/1342609/pexels-photo-1342609.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/8486972/pexels-photo-8486972.jpeg?w=300',
        ],
      },
      {
        'id': '32dea8c2-53f4-4e8b-99aa-87552d511b18',
        'name': 'Mauli Plumbing Works',
        'rating': 4.3,
        'reviews': 56,
        'distance': 3.8,
        'charge': 200,
        'experience': 3,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Drain Blockage & Tap Repair',
        'completedJobs': 98,
        'phone': '+919823456789',
        'image':
            'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?w=600',
        'gallery': [],
      },
    ],
    'electrician': [
      {
        'id': '251e07e8-fbc0-471e-bfca-2a8d8a9c1e25',
        'name': 'Ravi Electricals & Power',
        'rating': 4.9,
        'reviews': 210,
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
            'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg?w=300',
        ],
      },
      {
        'id': 'de054c6f-251d-4e82-ae7e-c295f0b608f5',
        'name': 'Prakash Electrician & Appliances',
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
            'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg?w=300',
        ],
      },
    ],
    'painter': [
      {
        'id': '5284aac9-259b-44f8-8080-20a227deab25',
        'name': 'ColorCraft Professional Painters',
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
        'image': 'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=300',
          'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg?w=300',
        ],
      },
      {
        'id': '471d1d12-aa0d-4dad-8c4e-896a225c294f',
        'name': 'Anil Painting Services',
        'rating': 4.4,
        'reviews': 67,
        'distance': 3.2,
        'charge': 12,
        'experience': 6,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Exterior & Waterproof Coating',
        'completedJobs': 120,
        'chargeUnit': '/sq.ft',
        'phone': '+919867890123',
        'image':
            'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg?w=600',
        'gallery': [],
      },
    ],
    'mason': [
      {
        'id': 'a3074292-a225-40c7-9742-caf3148334ec',
        'name': 'Ganesh Construction & Masonry',
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
            'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?w=300',
        ],
      },
    ],
    'carpenter': [
      {
        'id': '43568142-4e0d-4341-b19c-7f093ce812b7',
        'name': 'WoodCraft Carpentry Services',
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
            'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg?w=300',
        ],
      },
    ],
    'daily_wage': [
      {
        'id': '62c700a2-635e-435a-9e10-daf905b49b2b',
        'name': 'Raju Helper & Labor Services',
        'rating': 4.3,
        'reviews': 45,
        'distance': 0.9,
        'charge': 450,
        'experience': 2,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Loading, Moving & Garden Work',
        'completedJobs': 150,
        'chargeUnit': '/day',
        'phone': '+919890123456',
        'image':
            'https://images.pexels.com/photos/585419/pexels-photo-585419.jpeg?w=600',
        'gallery': [],
      },
    ],
    'cleaning': [
      {
        'id': 'fddf2642-225e-4bf1-a61c-db8d855a3907',
        'name': 'SparkleClean Deep Cleaning',
        'rating': 4.8,
        'reviews': 198,
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
            'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg?w=600',
        'gallery': [
          'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg?w=300',
        ],
      },
      {
        'id': 'fe4372fa-7350-4af4-9315-780aefd6ff33',
        'name': 'Sunita Home Cleaning',
        'rating': 4.8,
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
    'maid': [
      {
        'id': 'maid-001',
        'name': 'Laxmi Domestic & Maid Services',
        'rating': 4.9,
        'reviews': 142,
        'distance': 1.2,
        'charge': 250,
        'chargeUnit': '/visit',
        'experience': 6,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Full House Cleaning, Utensils & Mopping',
        'completedJobs': 420,
        'phone': '+919822114455',
        'image':
            'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg?w=600',
        'gallery': [],
      },
      {
        'id': 'maid-002',
        'name': 'Seema House Help & Cooking',
        'rating': 4.8,
        'reviews': 98,
        'distance': 2.0,
        'charge': 300,
        'chargeUnit': '/visit',
        'experience': 8,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Daily Cooking, Dusting & Deep Kitchen Cleaning',
        'completedJobs': 290,
        'phone': '+919833225566',
        'image':
            'https://images.pexels.com/photos/3768911/pexels-photo-3768911.jpeg?w=600',
        'gallery': [],
      },
      {
        'id': 'maid-003',
        'name': 'Aarti Professional Home Helpers',
        'rating': 4.7,
        'reviews': 76,
        'distance': 3.1,
        'charge': 200,
        'chargeUnit': '/visit',
        'experience': 4,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Part-time & Full-time Domestic House Cleaning',
        'completedJobs': 180,
        'phone': '+919844336677',
        'image':
            'https://images.pexels.com/photos/4108715/pexels-photo-4108715.jpeg?w=600',
        'gallery': [],
      },
    ],
    'waterproofing': [
      {
        'id': 'wp-001',
        'name': 'Dr. Shield Waterproofing Experts',
        'rating': 4.9,
        'reviews': 186,
        'distance': 1.5,
        'charge': 35,
        'chargeUnit': '/sq.ft',
        'experience': 12,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'Terrace, Wall Seepage & Bathroom Waterproofing',
        'completedJobs': 310,
        'phone': '+919855447788',
        'image':
            'https://images.pexels.com/photos/2219024/pexels-photo-2219024.jpeg?w=600',
        'gallery': [],
      },
      {
        'id': 'wp-002',
        'name': 'AquaStop Solutions & Epoxy Grouting',
        'rating': 4.8,
        'reviews': 114,
        'distance': 2.7,
        'charge': 40,
        'chargeUnit': '/sq.ft',
        'experience': 9,
        'verified': true,
        'emergency': false,
        'available': true,
        'speciality': 'Roof Leakage Chemical Coating & Damp Proofing',
        'completedJobs': 240,
        'phone': '+919866558899',
        'image':
            'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?w=600',
        'gallery': [],
      },
      {
        'id': 'wp-003',
        'name': 'Apex Moisture Lock Systems',
        'rating': 4.6,
        'reviews': 68,
        'distance': 4.0,
        'charge': 30,
        'chargeUnit': '/sq.ft',
        'experience': 5,
        'verified': true,
        'emergency': true,
        'available': true,
        'speciality': 'External Wall Crack Filling & Terrace Coating',
        'completedJobs': 150,
        'phone': '+919877669900',
        'image':
            'https://images.pexels.com/photos/8486944/pexels-photo-8486944.jpeg?w=600',
        'gallery': [],
      },
    ],
  };

  Map<String, List<Map<String, dynamic>>> _liveProviders = {};
  bool _isLoadingProviders = false;

  Future<void> _fetchProvidersFromDb() async {
    setState(() => _isLoadingProviders = true);
    try {
      final response = await SupabaseService.instance.client
          .from('service_providers')
          .select('*, charges:provider_service_charges(*)')
          .or('category.ilike.%home_maintenance%,category.ilike.%Home Maintenance%')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final Set<String> seenIds = {};
      final Set<String> seenNames = {};

      for (final row in response) {
        final id = (row['id'] as String? ?? '').trim();
        final name = (row['business_name'] ?? row['owner_name'] ?? row['full_name'] ?? 'Provider').toString().trim();
        if (id.isEmpty || seenIds.contains(id) || seenNames.contains(name.toLowerCase())) continue;
        seenIds.add(id);
        seenNames.add(name.toLowerCase());

        final sub = (row['subcategory'] as String? ?? '').toLowerCase().trim();
        String subKey = 'plumber';
        if (sub.contains('plumb')) subKey = 'plumber';
        else if (sub.contains('elect')) subKey = 'electrician';
        else if (sub.contains('paint')) subKey = 'painter';
        else if (sub.contains('mason')) subKey = 'mason';
        else if (sub.contains('carpent')) subKey = 'carpenter';
        else if (sub.contains('wage') || sub.contains('labour') || sub.contains('labor') || sub.contains('helper')) subKey = 'daily_wage';
        else if (sub.contains('maid') || sub.contains('housekeep')) subKey = 'maid';
        else if (sub.contains('clean')) subKey = 'cleaning';
        else if (sub.contains('waterproof')) subKey = 'waterproofing';
        else if (sub.contains('pest')) subKey = 'pest_control';
        else if (sub.contains('ac') || sub.contains('air')) subKey = 'ac_repair';
        else if (sub.contains('appliance')) subKey = 'appliance_repair';
        else if (sub.contains('ro') || sub.contains('purifier') || sub.contains('filter')) subKey = 'ro_purifier';
        else if (sub.contains('cctv') || sub.contains('security')) subKey = 'cctv_security';
        else if (sub.contains('lock')) subKey = 'locksmith';
        else if (sub.contains('garden')) subKey = 'gardening';
        else subKey = sub.isNotEmpty ? sub : 'plumber';

        final charges = (row['charges'] as List?) ?? [];
        final firstCharge = charges.isNotEmpty ? charges.first : null;
        final chargeVal = firstCharge != null ? (firstCharge['base_price'] as num?)?.toDouble() ?? 300.0 : 300.0;
        final chargeUnit = firstCharge != null ? (firstCharge['unit'] as String? ?? '/visit') : '/visit';

        String img = (row['image_url'] as String? ?? '').trim();
        if (img.isEmpty || img.contains('placeholder') || img.contains('undefined')) {
          img = 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600&auto=format&fit=crop&q=80';
        }

        final mapped = {
          'id': id,
          'name': name,
          'rating': (row['rating'] as num?)?.toDouble() ?? 4.8,
          'reviews': (row['review_count'] as num?)?.toInt() ?? 100,
          'distance': 1.8,
          'charge': chargeVal.toInt(),
          'chargeUnit': chargeUnit.startsWith('/') ? chargeUnit : '/$chargeUnit',
          'experience': (row['years_experience'] as num?)?.toInt() ?? 6,
          'verified': row['is_verified'] == true || row['registration_status'] == 'approved',
          'emergency': true,
          'available': row['is_open'] != false,
          'speciality': row['description'] ?? '${row['subcategory'] ?? "Home Maintenance"} Services',
          'completedJobs': (row['completed_orders'] as num?)?.toInt() ?? 250,
          'phone': row['phone'] ?? '+919876543210',
          'image': img,
          'gallery': row['gallery_photos'] ?? [],
          'charges': charges,
        };
        grouped.putIfAbsent(subKey, () => []).add(mapped);
      }
      if (mounted) {
        setState(() {
          _liveProviders = grouped;
          _isLoadingProviders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProviders = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProviders {
    final liveList = _liveProviders[_activeSubcategory];
    final list = List<Map<String, dynamic>>.from(
      (liveList != null && liveList.isNotEmpty)
          ? liveList
          : (_mockProviders[_activeSubcategory] ?? []),
    );
    return list.where((p) {
      if (_verifiedOnly && p['verified'] != true) return false;
      if (_emergencyOnly && p['emergency'] != true) return false;
      if (_availableOnly && p['available'] != true) return false;
      final dist = (p['distance'] as num?)?.toDouble() ?? 0.0;
      if (dist > _maxDistance) return false;
      if (_searchQuery.isNotEmpty &&
          !(p['name'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
          final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
          return rB.compareTo(rA);
        case 'price_low':
          final cA = (a['charge'] as num?)?.toDouble() ?? 0.0;
          final cB = (b['charge'] as num?)?.toDouble() ?? 0.0;
          return cA.compareTo(cB);
        case 'experience':
          final eA = (a['experience'] as num?)?.toDouble() ?? 0.0;
          final eB = (b['experience'] as num?)?.toDouble() ?? 0.0;
          return eB.compareTo(eA);
        default:
          final dA = (a['distance'] as num?)?.toDouble() ?? 0.0;
          final dB = (b['distance'] as num?)?.toDouble() ?? 0.0;
          return dA.compareTo(dB);
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
    _fetchProvidersFromDb();
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
    showModalBottomSheet<String>(
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
                      onTap: () => Navigator.pop(context, 'call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: _activeColor,
                      onTap: () => Navigator.pop(context, 'message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _contactActionButton(
                      icon: Icons.help_outline,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => Navigator.pop(context, 'whatsapp'),
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
                        'Make Enquiry',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
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
                      onPressed: () => Navigator.pop(context, 'enquiry'),
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
                      onPressed: () => Navigator.pop(context, 'book'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((result) {
      if (result == 'call') {
        _handleCall(provider['phone'] as String? ?? '');
      } else if (result == 'message') {
        Navigator.pushNamed(
          context,
          AppRoutes.chatDetailScreen,
          arguments: {
            'providerId': provider['id'],
            'providerName': provider['name'],
          },
        );
      } else if (result == 'whatsapp') {
        _handleWhatsApp(provider['phone'] as String? ?? '');
      } else if (result == 'enquiry') {
        UniversalEnquiryDialog.show(
          context,
          providerId: provider['id'] as String? ?? 'p_1',
          providerName: provider['name'] as String? ?? 'Provider',
          providerImage: provider['image'] as String?,
          providerPhone: provider['phone'] as String?,
          providerRating: (provider['rating'] as num?)?.toDouble() ?? 4.8,
          category: 'Home Maintenance',
          subcategory: _activeSubcategory,
          serviceTitle: provider['speciality'] as String? ?? 'Home Maintenance Service',
          basePrice: '₹${provider['charge']}${provider['chargeUnit'] ?? '/visit'}',
          themeColor: _activeColor,
        );
      } else if (result == 'book') {
        _showBookingSheet(provider);
      }
    });
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
                    onPressed: () async {
                      final dateStr = selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Now';
                      final timeStr = selectedTime != null
                          ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, "0")}'
                          : 'On Demand';

                      Navigator.pop(context); // Pop booking sheet
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookingCheckoutScreen,
                        arguments: {
                          'providerId': provider['id'] as String?,
                          'providerName': provider['name'] as String? ?? 'Provider',
                          'providerImage': provider['avatar_url'] as String? ?? '',
                          'providerRating': provider['rating'] as double? ?? 4.8,
                          'service': provider['speciality'] as String? ?? 'Home Maintenance',
                          'category': 'home_maintenance',
                          'scheduledDate': dateStr,
                          'scheduledTime': timeStr,
                          'amount': provider['charge'] != null ? '₹${provider['charge']}' : '₹300',
                        },
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
    final subs = _subcategories;
    final activeColor = _activeColor;
    final providers = _filteredProviders;
    Map<String, dynamic> activeSub = {
      'id': '',
      'label': 'Services',
      'icon': Icons.home_repair_service_rounded,
      'color': const Color(0xFF0277BD),
    };
    for (final s in subs) {
      if (s['id'] == _activeSubcategory) {
        activeSub = s;
        break;
      }
    }
    if (activeSub['id'] == '' && subs.isNotEmpty) {
      activeSub = subs.first;
    }
    return DefaultTabController(
      length: subs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: activeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Home Maintenance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
                        onEnquiry: () => UniversalEnquiryDialog.show(
                          context,
                          providerId: providers[i]['id'] as String? ?? 'p_1',
                          providerName: providers[i]['name'] as String? ?? 'Provider',
                          providerImage: providers[i]['image'] as String?,
                          providerPhone: providers[i]['phone'] as String?,
                          providerRating: (providers[i]['rating'] as num?)?.toDouble() ?? 4.8,
                          category: 'Home Maintenance',
                          subcategory: _activeSubcategory,
                          serviceTitle: providers[i]['speciality'] as String? ?? 'Home Maintenance Service',
                          basePrice: '₹${providers[i]['charge']}${providers[i]['chargeUnit'] ?? '/visit'}',
                          themeColor: activeColor,
                        ),
                        onBook: () => _showBookingSheet(providers[i]),
                      ),
                    ),
            ),
          ],
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
  final VoidCallback onEnquiry;
  final VoidCallback onBook;

  const _ProviderCard({
    required this.provider,
    required this.activeColor,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
    required this.onEnquiry,
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
                      const SizedBox(width: 8),
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
                      const Spacer(),
                      OutlinedButton(
                        onPressed: onEnquiry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: activeColor,
                          side: BorderSide(color: activeColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Enquiry',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
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
