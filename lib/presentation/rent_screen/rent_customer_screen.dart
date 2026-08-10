import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import './rent_listing_detail_screen.dart';
import './rent_subscription_screen.dart';

class RentCustomerScreen extends StatefulWidget {
  const RentCustomerScreen({super.key});

  @override
  State<RentCustomerScreen> createState() => _RentCustomerScreenState();
}

class _RentCustomerScreenState extends State<RentCustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeSubcategory = 'room';
  String _sortBy = 'nearest';
  double _maxPrice = 50000;
  bool _showAvailableOnly = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final bool _isLoading = false;
  final Set<String> _favourites = {};
  final Set<String> _selectedAmenities = {};

  static const _subcategories = [
    {
      'id': 'room',
      'label': 'Room',
      'icon': Icons.bedroom_parent_rounded,
      'color': Color(0xFF26A69A),
      'hint': 'Furnished, AC, Wi-Fi...',
    },
    {
      'id': 'pg',
      'label': 'PG',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF7B1FA2),
      'hint': 'Food, Laundry, CCTV...',
    },
    {
      'id': 'hostel',
      'label': 'Hostel',
      'icon': Icons.hotel_rounded,
      'color': Color(0xFF1565C0),
      'hint': 'Dorms, Security, Wi-Fi...',
    },
    {
      'id': 'hotel',
      'label': 'Hotel',
      'icon': Icons.business_rounded,
      'color': Color(0xFFD84315),
      'hint': 'Rooms, Amenities, Check-in...',
    },
    {
      'id': 'villa',
      'label': 'Villa',
      'icon': Icons.villa_rounded,
      'color': Color(0xFFE65100),
      'hint': 'Pool, Garden, Bedrooms...',
    },
    {
      'id': 'tools',
      'label': 'Tools',
      'icon': Icons.build_rounded,
      'color': Color(0xFF2E7D32),
      'hint': 'JCB, Tractor, Generator...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeSubcategory =
              _subcategories[_tabController.index]['id'] as String;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['subcategory'] != null) {
      final sub = args['subcategory'] as String;
      final idx = _subcategories.indexWhere((s) => s['id'] == sub);
      if (idx >= 0) {
        _activeSubcategory = sub;
        _tabController.animateTo(idx);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color get _activeColor {
    final sub = _subcategories.firstWhere((s) => s['id'] == _activeSubcategory);
    return sub['color'] as Color;
  }

  List<Map<String, dynamic>> _getListings(String sub) {
    switch (sub) {
      case 'room':
        return [
          {
            'id': 'r1',
            'title': 'Spacious 1BHK Furnished Room',
            'location': 'Shivaji Nagar, Pune',
            'price': 8500,
            'priceUnit': '/month',
            'rating': 4.7,
            'reviews': 23,
            'distance': 1.2,
            'available': true,
            'furnished': 'Furnished',
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_167d892f5-1783271528086.png',
            'amenities': ['Wi-Fi', 'AC', 'Parking'],
            'deposit': 17000,
            'provider': 'Rajesh Sharma',
            'occupancy': 'Single',
            'isFeatured': true,
            'isVerified': true,
            'gender': 'Any',
            'bathroom': 'Attached',
          },
          {
            'id': 'r2',
            'title': 'Budget Room Near IT Park',
            'location': 'Hinjewadi, Pune',
            'price': 5500,
            'priceUnit': '/month',
            'rating': 4.2,
            'reviews': 15,
            'distance': 2.8,
            'available': true,
            'furnished': 'Semi-Furnished',
            'image':
                'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
            'amenities': ['Wi-Fi', 'Kitchen'],
            'deposit': 11000,
            'provider': 'Priya Patil',
            'occupancy': 'Double',
            'isFeatured': false,
            'isVerified': false,
            'gender': 'Male',
            'bathroom': 'Common',
          },
          {
            'id': 'r3',
            'title': 'Premium Studio Apartment',
            'location': 'Koregaon Park, Pune',
            'price': 14000,
            'priceUnit': '/month',
            'rating': 4.9,
            'reviews': 41,
            'distance': 3.5,
            'available': false,
            'furnished': 'Fully Furnished',
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_1cb1dae90-1782961019728.png',
            'amenities': ['Wi-Fi', 'AC', 'Parking', 'Gym'],
            'deposit': 28000,
            'provider': 'Amit Joshi',
            'occupancy': 'Single',
            'isFeatured': true,
            'isVerified': true,
            'gender': 'Any',
            'bathroom': 'Attached',
          },
          {
            'id': 'r4',
            'title': 'Cozy Room with Balcony',
            'location': 'Viman Nagar, Pune',
            'price': 7200,
            'priceUnit': '/month',
            'rating': 4.4,
            'reviews': 9,
            'distance': 4.1,
            'available': true,
            'furnished': 'Semi-Furnished',
            'image':
                'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
            'amenities': ['Wi-Fi', 'Parking'],
            'deposit': 14400,
            'provider': 'Meena Kulkarni',
            'occupancy': 'Single',
            'isFeatured': false,
            'isVerified': true,
            'gender': 'Female',
            'bathroom': 'Attached',
          },
        ];
      case 'pg':
        return [
          {
            'id': 'pg1',
            'title': 'Sunrise PG for Girls',
            'location': 'Kothrud, Pune',
            'price': 7000,
            'priceUnit': '/month',
            'rating': 4.6,
            'reviews': 38,
            'distance': 0.9,
            'available': true,
            'type': 'Girls PG',
            'image':
                'https://images.pexels.com/photos/1571453/pexels-photo-1571453.jpeg',
            'amenities': ['Wi-Fi', 'Laundry', 'CCTV', 'Food'],
            'deposit': 7000,
            'provider': 'Sunita Deshpande',
            'sharing': 'Double Sharing',
            'isFeatured': true,
            'isVerified': true,
            'food': 'Included',
            'gender': 'Female',
          },
          {
            'id': 'pg2',
            'title': 'Working Professionals PG',
            'location': 'Baner, Pune',
            'price': 9500,
            'priceUnit': '/month',
            'rating': 4.4,
            'reviews': 27,
            'distance': 2.1,
            'available': true,
            'type': 'Co-ed PG',
            'image':
                'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
            'amenities': ['Wi-Fi', 'AC', 'Laundry', 'Kitchen'],
            'deposit': 9500,
            'provider': 'Vikram Nair',
            'sharing': 'Single Sharing',
            'isFeatured': false,
            'isVerified': true,
            'food': 'Optional',
            'gender': 'Any',
          },
          {
            'id': 'pg3',
            'title': 'Boys PG with Gym Access',
            'location': 'Wakad, Pune',
            'price': 8000,
            'priceUnit': '/month',
            'rating': 4.3,
            'reviews': 19,
            'distance': 3.2,
            'available': true,
            'type': 'Boys PG',
            'image':
                'https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg',
            'amenities': ['Wi-Fi', 'Gym', 'CCTV', 'Parking'],
            'deposit': 8000,
            'provider': 'Ravi Sharma',
            'sharing': 'Triple Sharing',
            'isFeatured': false,
            'isVerified': false,
            'food': 'Not Included',
            'gender': 'Male',
          },
        ];
      case 'hostel':
        return [
          {
            'id': 'h1',
            'title': 'City Boys Hostel',
            'location': 'Camp, Pune',
            'price': 4500,
            'priceUnit': '/month',
            'rating': 4.1,
            'reviews': 62,
            'distance': 1.5,
            'available': true,
            'image':
                'https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg',
            'amenities': ['Wi-Fi', 'CCTV', 'Laundry'],
            'deposit': 4500,
            'provider': 'Hostel Management',
            'roomType': '6-Bed Dorm',
            'isFeatured': false,
            'isVerified': true,
            'type': 'Boys Hostel',
            'food': 'Included',
          },
          {
            'id': 'h2',
            'title': 'Student Hostel Near University',
            'location': 'Deccan, Pune',
            'price': 5500,
            'priceUnit': '/month',
            'rating': 4.3,
            'reviews': 44,
            'distance': 0.7,
            'available': true,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_1f6170a29-1777070208986.png',
            'amenities': ['Wi-Fi', 'Kitchen', 'CCTV'],
            'deposit': 5500,
            'provider': 'Ganesh Hostel',
            'roomType': '4-Bed Dorm',
            'isFeatured': true,
            'isVerified': true,
            'type': 'Student Hostel',
            'food': 'Optional',
          },
          {
            'id': 'h3',
            'title': 'Girls Hostel with Security',
            'location': 'Pimpri, Pune',
            'price': 5000,
            'priceUnit': '/month',
            'rating': 4.5,
            'reviews': 33,
            'distance': 2.4,
            'available': true,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_1dc7e45d6-1767457233992.png',
            'amenities': ['Wi-Fi', 'CCTV', 'Security Guard', 'Laundry'],
            'deposit': 5000,
            'provider': 'Priya Hostel',
            'roomType': '3-Bed Dorm',
            'isFeatured': false,
            'isVerified': true,
            'type': 'Girls Hostel',
            'food': 'Included',
          },
        ];
      case 'hotel':
        return [
          {
            'id': 'ht1',
            'title': 'Hotel Sunrise Premium',
            'location': 'MG Road, Pune',
            'price': 2500,
            'priceUnit': '/night',
            'rating': 4.5,
            'reviews': 128,
            'distance': 2.1,
            'available': true,
            'image':
                'https://images.pexels.com/photos/258154/pexels-photo-258154.jpeg',
            'amenities': ['AC', 'Wi-Fi', 'Breakfast', 'Parking'],
            'deposit': 0,
            'provider': 'Sunrise Hotels',
            'roomType': 'Deluxe Room',
            'isFeatured': true,
            'isVerified': true,
            'checkIn': '12:00 PM',
            'checkOut': '11:00 AM',
          },
          {
            'id': 'ht2',
            'title': 'Budget Inn City Centre',
            'location': 'Deccan, Pune',
            'price': 1200,
            'priceUnit': '/night',
            'rating': 3.9,
            'reviews': 67,
            'distance': 1.8,
            'available': true,
            'image':
                'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
            'amenities': ['AC', 'Wi-Fi', 'TV'],
            'deposit': 0,
            'provider': 'City Inn',
            'roomType': 'Standard Room',
            'isFeatured': false,
            'isVerified': false,
            'checkIn': '2:00 PM',
            'checkOut': '12:00 PM',
          },
          {
            'id': 'ht3',
            'title': 'Grand Palace Hotel',
            'location': 'Koregaon Park, Pune',
            'price': 5500,
            'priceUnit': '/night',
            'rating': 4.8,
            'reviews': 214,
            'distance': 3.5,
            'available': true,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_1aa7e92d4-1766077571316.png',
            'amenities': ['AC', 'Wi-Fi', 'Pool', 'Spa', 'Restaurant'],
            'deposit': 0,
            'provider': 'Grand Palace',
            'roomType': 'Suite',
            'isFeatured': true,
            'isVerified': true,
            'checkIn': '3:00 PM',
            'checkOut': '11:00 AM',
          },
        ];
      case 'villa':
        return [
          {
            'id': 'v1',
            'title': 'Luxury Villa with Pool',
            'location': 'Lonavala, Pune',
            'price': 8000,
            'priceUnit': '/night',
            'rating': 4.9,
            'reviews': 18,
            'distance': 65.0,
            'available': true,
            'guests': 10,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_17ee2b451-1769399463524.png',
            'amenities': ['Pool', 'Parking', 'BBQ', 'Garden'],
            'deposit': 16000,
            'provider': 'Luxury Stays',
            'bedrooms': 4,
            'isFeatured': true,
            'isVerified': true,
            'bathrooms': 3,
            'rentalType': 'Daily',
          },
          {
            'id': 'v2',
            'title': 'Cozy Holiday Cottage',
            'location': 'Mahabaleshwar',
            'price': 3500,
            'priceUnit': '/night',
            'rating': 4.5,
            'reviews': 31,
            'distance': 120.0,
            'available': true,
            'guests': 6,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_1bf76b0b1-1771085039072.png',
            'amenities': ['Parking', 'Garden', 'Kitchen'],
            'deposit': 7000,
            'provider': 'Hill Retreats',
            'bedrooms': 3,
            'isFeatured': false,
            'isVerified': true,
            'bathrooms': 2,
            'rentalType': 'Daily/Weekly',
          },
          {
            'id': 'v3',
            'title': 'Beach Villa Monthly Rental',
            'location': 'Alibaug, Maharashtra',
            'price': 45000,
            'priceUnit': '/month',
            'rating': 4.7,
            'reviews': 12,
            'distance': 180.0,
            'available': true,
            'guests': 8,
            'image':
                'https://img.rocket.new/generatedImages/rocket_gen_img_137c61c8e-1766727665465.png',
            'amenities': ['Pool', 'Beach Access', 'Parking', 'Garden', 'BBQ'],
            'deposit': 90000,
            'provider': 'Coastal Villas',
            'bedrooms': 4,
            'isFeatured': true,
            'isVerified': true,
            'bathrooms': 4,
            'rentalType': 'Monthly',
          },
        ];
      case 'tools':
        return [
          {
            'id': 't1',
            'title': 'Bosch Drill Machine',
            'location': 'Hadapsar, Pune',
            'price': 200,
            'priceUnit': '/day',
            'rating': 4.6,
            'reviews': 19,
            'distance': 2.3,
            'available': true,
            'brand': 'Bosch',
            'image':
                'https://images.pexels.com/photos/1249611/pexels-photo-1249611.jpeg',
            'condition': 'Excellent',
            'deposit': 1000,
            'provider': 'Tool Rentals Pune',
            'category': 'Power Tools',
            'amenities': ['Delivery', 'Pickup', 'Safety Kit'],
            'isFeatured': false,
            'isVerified': true,
            'rentalPeriod': 'Hourly/Daily',
          },
          {
            'id': 't2',
            'title': 'JCB Excavator – Daily Rental',
            'location': 'Wakad, Pune',
            'price': 4500,
            'priceUnit': '/day',
            'rating': 4.4,
            'reviews': 8,
            'distance': 5.2,
            'available': true,
            'brand': 'JCB',
            'image':
                'https://images.unsplash.com/photo-1676287241277-c14188fde5c8',
            'condition': 'Good',
            'deposit': 10000,
            'provider': 'Heavy Equipment Co.',
            'category': 'Construction',
            'amenities': ['Operator Available', 'Delivery'],
            'isFeatured': true,
            'isVerified': true,
            'rentalPeriod': 'Daily/Weekly',
          },
          {
            'id': 't3',
            'title': 'Concrete Mixer (Small)',
            'location': 'Wakad, Pune',
            'price': 800,
            'priceUnit': '/day',
            'rating': 4.3,
            'reviews': 11,
            'distance': 4.1,
            'available': true,
            'brand': 'Generic',
            'image':
                'https://images.pexels.com/photos/4239031/pexels-photo-4239031.jpeg',
            'condition': 'Good',
            'deposit': 3000,
            'provider': 'Construction Tools',
            'category': 'Construction',
            'amenities': ['Delivery', 'Operator Available'],
            'isFeatured': false,
            'isVerified': false,
            'rentalPeriod': 'Daily',
          },
          {
            'id': 't4',
            'title': 'Generator 10KVA',
            'location': 'Kharadi, Pune',
            'price': 1200,
            'priceUnit': '/day',
            'rating': 4.5,
            'reviews': 22,
            'distance': 3.6,
            'available': true,
            'brand': 'Honda',
            'image':
                'https://images.pexels.com/photos/1249611/pexels-photo-1249611.jpeg',
            'condition': 'Excellent',
            'deposit': 5000,
            'provider': 'Power Solutions',
            'category': 'Power',
            'amenities': ['Delivery', 'Fuel Included'],
            'isFeatured': false,
            'isVerified': true,
            'rentalPeriod': 'Daily/Weekly',
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _filteredListings(String sub) {
    final listings = _getListings(sub);
    return listings.where((l) {
      if (_showAvailableOnly && l['available'] == false) return false;
      if (_searchQuery.isNotEmpty) {
        final title = (l['title'] as String).toLowerCase();
        final loc = (l['location'] as String).toLowerCase();
        if (!title.contains(_searchQuery.toLowerCase()) &&
            !loc.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      final price = (l['price'] as num).toDouble();
      if (price > _maxPrice) return false;
      if (_selectedAmenities.isNotEmpty) {
        final amenities = List<String>.from(l['amenities'] as List);
        if (!_selectedAmenities.every((a) => amenities.contains(a))) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) {
      if (_sortBy == 'price_low') {
        return (a['price'] as num).compareTo(b['price'] as num);
      }
      if (_sortBy == 'price_high') {
        return (b['price'] as num).compareTo(a['price'] as num);
      }
      if (_sortBy == 'rating') {
        return (b['rating'] as num).compareTo(a['rating'] as num);
      }
      if (_sortBy == 'newest') return 0;
      return (a['distance'] as num).compareTo(b['distance'] as num);
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        maxPrice: _maxPrice,
        showAvailableOnly: _showAvailableOnly,
        selectedAmenities: _selectedAmenities,
        subcategory: _activeSubcategory,
        onApply: (price, avail, amenities) {
          setState(() {
            _maxPrice = price;
            _showAvailableOnly = avail;
            _selectedAmenities.clear();
            _selectedAmenities.addAll(amenities);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: _activeColor,
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
                    colors: [_activeColor, _activeColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rent',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Find your perfect space',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RentSubscriptionScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'List Property',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search rooms, PGs, tools...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: _activeColor,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
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
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _subcategories
                      .map(
                        (s) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(s['icon'] as IconData, size: 14),
                              const SizedBox(width: 4),
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
        body: TabBarView(
          controller: _tabController,
          children: _subcategories
              .map(
                (s) => _buildSubcategoryTab(
                  s['id'] as String,
                  s['color'] as Color,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSubcategoryTab(String sub, Color color) {
    final listings = _filteredListings(sub);
    final featured = listings.where((l) => l['isFeatured'] == true).toList();
    final regular = listings.where((l) => l['isFeatured'] != true).toList();

    return RefreshIndicator(
      color: color,
      onRefresh: () async => setState(() {}),
      child: CustomScrollView(
        slivers: [
          // Sort bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildSortBar(listings.length, color),
            ),
          ),
          // Featured listings
          if (featured.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF9A825),
                            const Color(0xFFFF8F00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Featured',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Top Picks',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (_, i) => _buildFeaturedCard(featured[i], color),
                ),
              ),
            ),
          ],
          // All listings header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'All Listings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Regular listings
          if (listings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No listings found',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try adjusting your filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildListingCard(listings[i], color),
                  childCount: listings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortBar(int count, Color color) {
    return Row(
      children: [
        Text(
          '$count listings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              isDense: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: 'nearest', child: Text('Nearest')),
                DropdownMenuItem(value: 'price_low', child: Text('Price: Low')),
                DropdownMenuItem(
                  value: 'price_high',
                  child: Text('Price: High'),
                ),
                DropdownMenuItem(value: 'rating', child: Text('Top Rated')),
                DropdownMenuItem(value: 'newest', child: Text('Newest')),
              ],
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> listing, Color color) {
    final isFav = _favourites.contains(listing['id']);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RentListingDetailScreen(
            listing: listing,
            subcategory: _activeSubcategory,
            color: color,
          ),
        ),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: listing['image'] as String,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      color: color.withValues(alpha: 0.1),
                      child: Icon(Icons.image_rounded, color: color, size: 32),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Featured',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (listing['isVerified'] == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                if (listing['available'] == false)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 10,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing['location'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${_formatPrice(listing['price'] as num)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        listing['priceUnit'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.amber.shade600,
                      ),
                      Text(
                        '${listing['rating']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

  Widget _buildListingCard(Map<String, dynamic> listing, Color color) {
    final isFav = _favourites.contains(listing['id']);
    final isAvailable = listing['available'] as bool;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RentListingDetailScreen(
            listing: listing,
            subcategory: _activeSubcategory,
            color: color,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: listing['image'] as String,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: color.withValues(alpha: 0.1),
                      child: Icon(Icons.image_rounded, color: color, size: 40),
                    ),
                  ),
                ),
                // Badges row
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (listing['isFeatured'] == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9A825), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Featured',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (listing['isVerified'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Fav + availability
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(
                      () => isFav
                          ? _favourites.remove(listing['id'])
                          : _favourites.add(listing['id'] as String),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFav ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                if (!isAvailable)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Distance
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${listing['distance']} km',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
                          listing['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${listing['rating']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            Text(
                              ' (${listing['reviews']})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing['location'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Amenity chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (listing['amenities'] as List)
                        .take(4)
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${_formatPrice(listing['price'] as num)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              Text(
                                listing['priceUnit'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          if ((listing['deposit'] as num) > 0)
                            Text(
                              'Deposit: ₹${_formatPrice(listing['deposit'] as num)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Contact actions
                      _buildContactBtn(
                        Icons.chat_bubble_rounded,
                        color,
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.chatDetailScreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildContactBtn(
                        Icons.phone_rounded,
                        Colors.green.shade600,
                        () {},
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isAvailable
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RentListingDetailScreen(
                                    listing: listing,
                                    subcategory: _activeSubcategory,
                                    color: color,
                                  ),
                                ),
                              )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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

  Widget _buildContactBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  String _formatPrice(num price) {
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}K';
    }
    return price.toString();
  }
}

// ── Filter Bottom Sheet ────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final double maxPrice;
  final bool showAvailableOnly;
  final Set<String> selectedAmenities;
  final String subcategory;
  final Function(double, bool, Set<String>) onApply;

  const _FilterSheet({
    required this.maxPrice,
    required this.showAvailableOnly,
    required this.selectedAmenities,
    required this.subcategory,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _maxPrice;
  late bool _showAvailableOnly;
  late Set<String> _selectedAmenities;

  static const _allAmenities = [
    'Wi-Fi',
    'AC',
    'Parking',
    'Kitchen',
    'Laundry',
    'CCTV',
    'Gym',
    'Pool',
    'Food',
    'Security',
    'Delivery',
    'Garden',
  ];

  @override
  void initState() {
    super.initState();
    _maxPrice = widget.maxPrice;
    _showAvailableOnly = widget.showAvailableOnly;
    _selectedAmenities = Set.from(widget.selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _maxPrice = 50000;
                    _showAvailableOnly = true;
                    _selectedAmenities.clear();
                  }),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Price',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${_maxPrice.toInt()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 500,
                    max: 100000,
                    divisions: 100,
                    activeColor: AppTheme.catRent,
                    onChanged: (v) => setState(() => _maxPrice = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Only',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: _showAvailableOnly,
                        onChanged: (v) =>
                            setState(() => _showAvailableOnly = v),
                        activeColor: AppTheme.catRent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amenities',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allAmenities.map((a) {
                      final sel = _selectedAmenities.contains(a);
                      return GestureDetector(
                        onTap: () => setState(
                          () => sel
                              ? _selectedAmenities.remove(a)
                              : _selectedAmenities.add(a),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.catRent
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.catRent
                                  : AppTheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            a,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    _maxPrice,
                    _showAvailableOnly,
                    _selectedAmenities,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.catRent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply Filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
