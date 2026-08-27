import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/delivery_realtime_service.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';

class DeliveryCustomerScreen extends StatefulWidget {
  const DeliveryCustomerScreen({super.key});

  @override
  State<DeliveryCustomerScreen> createState() => _DeliveryCustomerScreenState();
}

class _DeliveryCustomerScreenState extends State<DeliveryCustomerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSubIndex = 0;
  final bool _showPricingSheet = false;
  String get _selectedCity => SupabaseService.instance.selectedCity;
  set _selectedCity(String val) => SupabaseService.instance.selectedCity = val;

  // ─── Realtime ─────────────────────────────────────────────────────────────
  final DeliveryRealtimeService _realtimeService =
      DeliveryRealtimeService.instance;
  final Map<String, String> _liveOrderStatuses = {}; // orderId → live status

  final List<Map<String, dynamic>> _subcategories = [
    {
      'id': 'food',
      'name': 'Food Delivery',
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFFF6B35),
      'desc': 'Hot meals delivered fast',
      'baseCharge': 25,
      'perKm': 8,
    },
    {
      'id': 'grocery',
      'name': 'Grocery',
      'icon': Icons.shopping_basket_rounded,
      'color': const Color(0xFF2ECC71),
      'desc': 'Fresh groceries at your door',
      'baseCharge': 20,
      'perKm': 6,
    },
    {
      'id': 'medicine',
      'name': 'Medicine',
      'icon': Icons.medication_rounded,
      'color': const Color(0xFF3498DB),
      'desc': 'Medicines & health products',
      'baseCharge': 15,
      'perKm': 5,
    },
    {
      'id': 'parcel',
      'name': 'Parcel & Docs',
      'icon': Icons.inventory_2_rounded,
      'color': const Color(0xFF9B59B6),
      'desc': 'Parcels & documents',
      'baseCharge': 30,
      'perKm': 10,
    },
    {
      'id': 'shop_purchase',
      'name': 'Shop Purchase',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFFE67E22),
      'desc': 'Buy from any local shop',
      'baseCharge': 35,
      'perKm': 10,
    },
    {
      'id': 'pickup_drop',
      'name': 'Pickup & Drop',
      'icon': Icons.swap_horiz_rounded,
      'color': const Color(0xFF1ABC9C),
      'desc': 'Point-to-point delivery',
      'baseCharge': 40,
      'perKm': 12,
    },
    {
      'id': 'heavy',
      'name': 'Heavy Item',
      'icon': Icons.help_outline,
      'color': const Color(0xFF7F8C8D),
      'desc': 'Furniture & heavy goods',
      'baseCharge': 100,
      'perKm': 20,
    },
    {
      'id': 'express',
      'name': 'Express',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFF39C12),
      'desc': 'Ultra-fast 30-min delivery',
      'baseCharge': 60,
      'perKm': 15,
    },
    {
      'id': 'scheduled',
      'name': 'Scheduled',
      'icon': Icons.schedule_rounded,
      'color': const Color(0xFF2980B9),
      'desc': 'Book for later delivery',
      'baseCharge': 20,
      'perKm': 7,
    },
    {
      'id': 'intercity',
      'name': 'Intercity',
      'icon': Icons.connecting_airports_rounded,
      'color': const Color(0xFF8E44AD),
      'desc': 'Coming soon',
      'baseCharge': 200,
      'perKm': 5,
      'comingSoon': true,
    },
  ];

  final List<Map<String, dynamic>> _activeOrders = [];

  final Map<String, List<Map<String, dynamic>>> _providersBySubcategory = {
    'food': [
      {
        'name': 'Sharma Restaurant',
        'rating': 4.8,
        'distance': '1.2 km',
        'time': '25-35 min',
        'image':
            'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        'tag': 'Popular',
        'minOrder': 100,
      },
      {
        'name': 'Punjabi Dhaba',
        'rating': 4.6,
        'distance': '2.1 km',
        'time': '30-40 min',
        'image':
            'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
        'tag': 'Top Rated',
        'minOrder': 150,
      },
      {
        'name': 'South Indian Corner',
        'rating': 4.5,
        'distance': '0.8 km',
        'time': '20-30 min',
        'image':
            'https://images.pexels.com/photos/2474661/pexels-photo-2474661.jpeg',
        'tag': 'Fast',
        'minOrder': 80,
      },
    ],
    'grocery': [
      {
        'name': 'Fresh Mart',
        'rating': 4.7,
        'distance': '0.5 km',
        'time': '20-30 min',
        'image':
            'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg',
        'tag': 'Nearest',
        'minOrder': 200,
      },
      {
        'name': 'Daily Needs Store',
        'rating': 4.4,
        'distance': '1.8 km',
        'time': '30-45 min',
        'image':
            'https://images.pexels.com/photos/3962285/pexels-photo-3962285.jpeg',
        'tag': 'Budget',
        'minOrder': 100,
      },
    ],
    'medicine': [
      {
        'name': 'City Pharmacy',
        'rating': 4.9,
        'distance': '0.7 km',
        'time': '15-25 min',
        'image':
            'https://images.pexels.com/photos/3683074/pexels-photo-3683074.jpeg',
        'tag': '24/7',
        'minOrder': 50,
      },
      {
        'name': 'MedPlus',
        'rating': 4.6,
        'distance': '1.5 km',
        'time': '20-30 min',
        'image':
            'https://images.pexels.com/photos/4386466/pexels-photo-4386466.jpeg',
        'tag': 'Trusted',
        'minOrder': 0,
      },
    ],
    'parcel': [
      {
        'name': 'QuickSend Logistics',
        'rating': 4.7,
        'distance': 'Any',
        'time': '1-2 hrs',
        'image':
            'https://images.pexels.com/photos/4393668/pexels-photo-4393668.jpeg',
        'tag': 'Reliable',
        'minOrder': 0,
      },
      {
        'name': 'City Courier',
        'rating': 4.5,
        'distance': 'Any',
        'time': '2-3 hrs',
        'image':
            'https://images.pexels.com/photos/6169668/pexels-photo-6169668.jpeg',
        'tag': 'Affordable',
        'minOrder': 0,
      },
    ],
    'shop_purchase': [
      {
        'name': 'LocalConnect Shopper',
        'rating': 4.8,
        'distance': 'Any shop',
        'time': '45-90 min',
        'image':
            'https://images.pexels.com/photos/5632399/pexels-photo-5632399.jpeg',
        'tag': 'Trusted',
        'minOrder': 0,
      },
    ],
    'pickup_drop': [
      {
        'name': 'Express Riders',
        'rating': 4.6,
        'distance': 'City-wide',
        'time': '30-60 min',
        'image':
            'https://images.pexels.com/photos/4391470/pexels-photo-4391470.jpeg',
        'tag': 'Fast',
        'minOrder': 0,
      },
      {
        'name': 'City Runners',
        'rating': 4.4,
        'distance': 'City-wide',
        'time': '45-75 min',
        'image':
            'https://images.pexels.com/photos/4391478/pexels-photo-4391478.jpeg',
        'tag': 'Budget',
        'minOrder': 0,
      },
    ],
    'heavy': [
      {
        'name': 'Heavy Movers',
        'rating': 4.5,
        'distance': 'City-wide',
        'time': '2-4 hrs',
        'image':
            'https://images.pexels.com/photos/4246120/pexels-photo-4246120.jpeg',
        'tag': 'Specialized',
        'minOrder': 0,
      },
    ],
    'express': [
      {
        'name': 'Flash Delivery',
        'rating': 4.9,
        'distance': '5 km radius',
        'time': '15-30 min',
        'image':
            'https://images.pexels.com/photos/4391471/pexels-photo-4391471.jpeg',
        'tag': 'Ultra Fast',
        'minOrder': 0,
      },
    ],
    'scheduled': [
      {
        'name': 'Reliable Delivery Co.',
        'rating': 4.7,
        'distance': 'City-wide',
        'time': 'As scheduled',
        'image':
            'https://images.pexels.com/photos/4391472/pexels-photo-4391472.jpeg',
        'tag': 'On-Time',
        'minOrder': 0,
      },
    ],
    'intercity': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToActiveOrders();
  }

  void _subscribeToActiveOrders() {
    // Subscribe to all delivery changes — filter for this customer's orders
    _realtimeService.subscribeToAllDeliveries(
      onUpdate: (eventType, record) {
        if (!mounted) return;
        final deliveryId = record['delivery_id'] as String?;
        final status = record['delivery_status'] as String?;
        if (deliveryId != null && status != null) {
          setState(() {
            _liveOrderStatuses[deliveryId] = status;
            // Update matching active order
            for (int i = 0; i < _activeOrders.length; i++) {
              if (_activeOrders[i]['id'] == deliveryId) {
                _activeOrders[i] = {..._activeOrders[i], 'status': status};
              }
            }
          });
        }
      },
    );
  }

  String _getLiveStatus(String orderId, String fallback) {
    return _liveOrderStatuses[orderId] ?? fallback;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeService.unsubscribeAll();
    super.dispose();
  }

  Color get _currentColor =>
      _subcategories[_selectedSubIndex]['color'] as Color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSubcategoryScroll()),
          SliverToBoxAdapter(child: _buildActiveOrdersBanner()),
          SliverToBoxAdapter(child: _buildPricingBanner()),
          SliverToBoxAdapter(child: _buildProviderList()),
        ],
      ),
      floatingActionButton: _buildRequestFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: _currentColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notificationScreen),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_currentColor, _currentColor.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _subcategories[_selectedSubIndex]['icon'] as IconData,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _subcategories[_selectedSubIndex]['desc']
                                  as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showCitySelector,
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
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCity,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryScroll() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: List.generate(_subcategories.length, (i) {
            final sub = _subcategories[i];
            final isSelected = _selectedSubIndex == i;
            final color = sub['color'] as Color;
            final comingSoon = sub['comingSoon'] == true;
            return GestureDetector(
              onTap: () {
                if (!comingSoon) setState(() => _selectedSubIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sub['icon'] as IconData,
                      color: isSelected ? Colors.white : color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        if (comingSoon)
                          Text(
                            'Coming Soon',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: isSelected
                                  ? Colors.white70
                                  : color.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveOrdersBanner() {
    if (_activeOrders.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 12, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  'Active Orders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live Tracking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B7A3E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ..._activeOrders.map((order) => _buildActiveOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    // Use live realtime status if available
    final liveStatus = _getLiveStatus(
      order['id'] as String,
      order['status'] as String,
    );
    final isLive = _liveOrderStatuses.containsKey(order['id']);

    final statusMap = {
      'accepted': (
        'Accepted',
        Icons.check_circle_outline_rounded,
        const Color(0xFF3498DB),
      ),
      'picked_up': (
        'Picked Up',
        Icons.inventory_rounded,
        const Color(0xFFFF6B35),
      ),
      'on_way': (
        'On the Way',
        Icons.directions_bike_rounded,
        const Color(0xFF2ECC71),
      ),
      'delivered': (
        'Delivered',
        Icons.check_circle_rounded,
        const Color(0xFF27AE60),
      ),
    };
    final statusInfo =
        statusMap[liveStatus] ??
        ('Processing', Icons.hourglass_empty_rounded, Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (order['color'] as Color).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (order['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusInfo.$2,
              color: order['color'] as Color,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['type'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '${order['from']} → ${order['to']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo.$3.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusInfo.$3,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            statusInfo.$1,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusInfo.$3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ETA: ${order['eta']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order['amount']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showTrackingSheet(order),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: order['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Track',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBanner() {
    final sub = _subcategories[_selectedSubIndex];
    final comingSoon = sub['comingSoon'] == true;
    if (comingSoon) {
      return Container(
        margin: EdgeInsets.fromLTRB(4.w, 12, 4.w, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (_currentColor).withValues(alpha: 0.15),
              (_currentColor).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _currentColor.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rocket_launch_rounded, color: _currentColor, size: 40),
              const SizedBox(height: 8),
              Text(
                'Intercity Delivery — Coming Soon!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _currentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We are expanding to intercity deliveries across India.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showPricingCalculator(),
      child: Container(
        margin: EdgeInsets.fromLTRB(4.w, 12, 4.w, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_currentColor, _currentColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calculate_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Pricing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Base ₹${sub['baseCharge']} + ₹${sub['perKm']}/km • Tap to calculate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
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
      ),
    );
  }

  Widget _buildProviderList() {
    final sub = _subcategories[_selectedSubIndex];
    final comingSoon = sub['comingSoon'] == true;
    if (comingSoon) return const SizedBox.shrink();

    final providers = _providersBySubcategory[sub['id'] as String] ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 4;
        } else if (width >= 850) {
          crossAxisCount = 3;
        } else if (width >= 550) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 16, 4.w, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${sub['name']} Providers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '${providers.length} available',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  crossAxisCount > 1
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 250,
                          ),
                          itemCount: providers.length,
                          itemBuilder: (ctx, i) =>
                              _buildProviderCard(providers[i], isGrid: true),
                        )
                      : Column(
                          children: providers
                              .map((p) => _buildProviderCard(p, isGrid: false))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider, {bool isGrid = false}) {
    return GestureDetector(
      onTap: () => _showDeliveryRequestSheet(provider),
      child: Container(
        margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomImageWidget(
                  imageUrl: provider['image'] as String,
                  fit: BoxFit.cover,
                  semanticLabel: '${provider['name']} delivery service',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _currentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          provider['tag'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _currentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${provider['rating']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.grey[500],
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        provider['distance'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.grey[500],
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          provider['time'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildRequestFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showDeliveryRequestSheet(null),
      backgroundColor: _currentColor,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'New Delivery',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showPricingCalculator() {
    final sub = _subcategories[_selectedSubIndex];
    double distance = 3.0;
    double weight = 1.0;
    bool isExpress = false;
    bool isPeakHour = false;
    bool isNight = false;
    bool isRain = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          double base = (sub['baseCharge'] as int).toDouble();
          double distCharge = distance * (sub['perKm'] as int);
          double weightCharge = weight > 5 ? (weight - 5) * 10 : 0;
          double expressCharge = isExpress ? 30 : 0;
          double peakCharge = isPeakHour ? 15 : 0;
          double nightCharge = isNight ? 20 : 0;
          double rainCharge = isRain ? 10 : 0;
          double total =
              base +
              distCharge +
              weightCharge +
              expressCharge +
              peakCharge +
              nightCharge +
              rainCharge;

          return Container(
            height: 75.h,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: _currentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Delivery Price Calculator',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSliderRow(
                          'Distance',
                          '${distance.toStringAsFixed(1)} km',
                          distance,
                          1,
                          20,
                          (v) => setModalState(() => distance = v),
                          _currentColor,
                        ),
                        _buildSliderRow(
                          'Weight',
                          '${weight.toStringAsFixed(1)} kg',
                          weight,
                          0.5,
                          50,
                          (v) => setModalState(() => weight = v),
                          _currentColor,
                        ),
                        const SizedBox(height: 12),
                        _buildToggleRow(
                          'Express Delivery (+₹30)',
                          isExpress,
                          (v) => setModalState(() => isExpress = v),
                          _currentColor,
                        ),
                        _buildToggleRow(
                          'Peak Hour (+₹15)',
                          isPeakHour,
                          (v) => setModalState(() => isPeakHour = v),
                          _currentColor,
                        ),
                        _buildToggleRow(
                          'Night Delivery (+₹20)',
                          isNight,
                          (v) => setModalState(() => isNight = v),
                          _currentColor,
                        ),
                        _buildToggleRow(
                          'Rain Surcharge (+₹10)',
                          isRain,
                          (v) => setModalState(() => isRain = v),
                          _currentColor,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _currentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _currentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow('Base Charge', base),
                              _buildPriceRow(
                                'Distance (${distance.toStringAsFixed(1)} km)',
                                distCharge,
                              ),
                              if (weightCharge > 0)
                                _buildPriceRow('Extra Weight', weightCharge),
                              if (expressCharge > 0)
                                _buildPriceRow('Express Fee', expressCharge),
                              if (peakCharge > 0)
                                _buildPriceRow('Peak Hour', peakCharge),
                              if (nightCharge > 0)
                                _buildPriceRow('Night Charge', nightCharge),
                              if (rainCharge > 0)
                                _buildPriceRow('Rain Surcharge', rainCharge),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Estimate',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '₹${total.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _currentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showDeliveryRequestSheet(null);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Book Now — ₹${total.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        Slider(
          value: current,
          min: min,
          max: max,
          activeColor: color,
          inactiveColor: color.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: color),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCitySelector() {
    List<Map<String, dynamic>> savedAddresses = [];
    bool loadingAddresses = true;
    bool showAddAddressForm = false;
    bool gpsLoading = false;
    bool hasFetched = false;

    final labelCtrl = TextEditingController();
    final line1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final stateCtrl = TextEditingController(text: 'Maharashtra');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (!hasFetched) {
            hasFetched = true;
            SupabaseService.instance.getSavedAddresses().then((list) {
              setSheetState(() {
                savedAddresses = list;
                loadingAddresses = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (showAddAddressForm)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setSheetState(() => showAddAddressForm = false);
                            },
                          ),
                        Text(
                          showAddAddressForm ? 'Add New Address' : 'Select Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (showAddAddressForm) ...[
                      // Address Form
                      TextField(
                        controller: labelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Label (e.g. Home, Work, Other)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: line1Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Address Line 1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'City / Village',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: districtCtrl,
                              decoration: InputDecoration(
                                  labelText: 'District',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: pincodeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Pincode',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final label = labelCtrl.text.trim();
                            final line1 = line1Ctrl.text.trim();
                            final city = cityCtrl.text.trim();
                            final dist = districtCtrl.text.trim();
                            final pin = pincodeCtrl.text.trim();
                            
                            if (label.isEmpty || line1.isEmpty || city.isEmpty || pin.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }

                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              await SupabaseService.instance.addAddress(
                                label: label,
                                addressLine1: line1,
                                city: city,
                                pincode: pin,
                                district: dist,
                                fullAddress: '$line1, $city, ${stateCtrl.text}, $pin',
                              );

                              final loc = LocationData(
                                latitude: 18.5204,
                                longitude: 73.8567,
                                fullAddress: '$line1, $city, ${stateCtrl.text}, $pin',
                                village: '',
                                city: city,
                                taluka: '',
                                district: dist,
                                state: stateCtrl.text,
                                pincode: pin,
                                method: 'manual',
                              );

                              await LocationService.instance.saveCustomerLocation(loc);
                              setState(() {
                                _selectedCity = city;
                              });

                              if (context.mounted) {
                                Navigator.pop(context); // Pop loading dialog
                                Navigator.pop(context); // Pop sheet
                              }
                            } catch (e) {
                              if (context.mounted) Navigator.pop(context); // Pop loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save address. Please try again.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Save Address & Select',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      // GPS Button
                      GestureDetector(
                        onTap: gpsLoading
                            ? null
                            : () async {
                                setSheetState(() => gpsLoading = true);
                                final loc = await LocationService.instance.getGpsLocation();
                                if (loc != null) {
                                  await LocationService.instance.saveCustomerLocation(loc);
                                  setState(() {
                                    _selectedCity = loc.city.isNotEmpty ? loc.city : loc.district;
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Location updated to ${loc.city}!'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                } else {
                                  setSheetState(() => gpsLoading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to detect GPS location.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              gpsLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  : Icon(Icons.gps_fixed, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                gpsLoading ? 'Detecting Location…' : 'Use Current GPS Location',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved Addresses:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setSheetState(() => showAddAddressForm = true);
                            },
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              'Add New',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (loadingAddresses)
                        const Center(child: CircularProgressIndicator())
                      else if (savedAddresses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No saved addresses found.\nAdd one using the "Add New" button above.',
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedAddresses.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final addr = savedAddresses[index];
                            final city = addr['city'] as String? ?? '';
                            final label = addr['label'] as String? ?? 'Address';
                            final line1 = addr['address_line1'] as String? ?? '';
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  label.toLowerCase() == 'home'
                                      ? Icons.home_outlined
                                      : label.toLowerCase() == 'work'
                                          ? Icons.work_outline
                                          : Icons.location_on_outlined,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                line1.isNotEmpty ? '$line1, $city' : city,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                final lat = (addr['latitude'] as num?)?.toDouble() ?? 18.5204;
                                final lng = (addr['longitude'] as num?)?.toDouble() ?? 73.8567;
                                final loc = LocationData(
                                  latitude: lat,
                                  longitude: lng,
                                  fullAddress: addr['full_address'] as String? ?? '',
                                  village: addr['village'] as String? ?? '',
                                  city: city,
                                  taluka: addr['taluka'] as String? ?? '',
                                  district: addr['district'] as String? ?? '',
                                  state: addr['state'] as String? ?? 'Maharashtra',
                                  pincode: addr['pincode'] as String? ?? '',
                                  method: addr['location_method'] as String? ?? 'manual',
                                );

                                await LocationService.instance.saveCustomerLocation(loc);
                                setState(() {
                                  _selectedCity = city;
                                });
                                if (mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeliveryRequestSheet(Map<String, dynamic>? provider) {
    final sub = _subcategories[_selectedSubIndex];
    final TextEditingController pickupCtrl = TextEditingController(
      text: 'Home, $_selectedCity',
    );
    final TextEditingController dropCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 70.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(sub['icon'] as IconData, color: _currentColor),
                    const SizedBox(width: 10),
                    Text(
                      'Request ${sub['name']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _currentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store_rounded,
                                color: _currentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider['name'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _currentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Pickup Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pickupCtrl,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.my_location_rounded,
                            color: _currentColor,
                          ),
                          hintText: 'Enter pickup address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _currentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dropCtrl,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: Colors.red[400],
                          ),
                          hintText: 'Enter delivery address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _currentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.note_rounded),
                          hintText: 'Special instructions (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _currentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Charge',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${sub['baseCharge']} – ₹${(sub['baseCharge'] as int) + 60}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _currentColor,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showPricingCalculator();
                              },
                              child: Text(
                                'Calculate exact',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: _currentColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            
                            // Show loading overlay
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final defaultDeliveryProviderId = sub['id'] == 'food'
                                ? 'c03f8af9-e13f-4310-964e-2a3a427aa458'
                                : 'ed788ac6-2004-417f-bae8-3381ae40d2ec';
                            final defaultDeliveryProviderName = sub['id'] == 'food'
                                ? 'QuickBite Food Delivery'
                                : 'SpeedyCourier Parcel Delivery';

                            final order = await SupabaseService.instance.createOrder(
                              providerId: provider?['id'] ?? defaultDeliveryProviderId,
                              providerName: provider?['business_name'] ?? provider?['full_name'] ?? defaultDeliveryProviderName,
                              service: sub['name'] ?? 'Delivery',
                              category: 'delivery',
                              scheduledDate: DateTime.now().toString().split(' ').first,
                              scheduledTime: 'Now',
                              amount: '₹${sub['baseCharge'] ?? 80}',
                              paymentMethod: 'cash',
                            );

                            if (mounted) {
                              Navigator.pop(context); // pop loading dialog
                            }

                            if (order != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Delivery request created! Finding nearest rider...',
                                      style: GoogleFonts.plusJakartaSans(),
                                    ),
                                    backgroundColor: _currentColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                final errorMsg = SupabaseService.instance.lastOrderError != null
                                    ? 'Failed to place delivery order: ${SupabaseService.instance.lastOrderError}'
                                    : 'Failed to place delivery order. Please try again.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Confirm Delivery Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackingSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 65.h,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: order['color'] as Color,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Live Tracking — ${order['id']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 50,
                      color: order['color'] as Color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live Map Tracking',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Rider is ${order['eta']} away',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rider',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            order['rider'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (order['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.call_rounded,
                      color: order['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_rounded,
                      color: Colors.grey[700],
                      size: 22,
                    ),
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
