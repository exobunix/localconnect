import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class DecorationCateringProviderDashboard extends StatefulWidget {
  final String
  subcategory; // 'mandap', 'birthday', 'wedding', 'balloon', 'flower', 'lighting', 'catering', 'tent', 'chair_table'
  const DecorationCateringProviderDashboard({
    super.key,
    this.subcategory = 'mandap',
  });

  @override
  State<DecorationCateringProviderDashboard> createState() =>
      _DecorationCateringProviderDashboardState();
}

class _DecorationCateringProviderDashboardState
    extends State<DecorationCateringProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> get _config {
    switch (widget.subcategory) {
      case 'catering':
        return {
          'title': 'Catering Dashboard',
          'color': const Color(0xFF00695C),
          'icon': Icons.restaurant_rounded,
          'name': 'Shree Caterers',
          'speciality': 'Veg & Non-Veg Catering',
        };
      case 'birthday':
        return {
          'title': 'Birthday Decoration',
          'color': const Color(0xFFC62828),
          'icon': Icons.cake_rounded,
          'name': 'Party Makers',
          'speciality': 'Birthday & Theme Decoration',
        };
      case 'wedding':
        return {
          'title': 'Wedding Decoration',
          'color': const Color(0xFF880E4F),
          'icon': Icons.favorite_rounded,
          'name': 'Royal Wedding Decor',
          'speciality': 'Wedding & Bridal Decoration',
        };
      case 'balloon':
        return {
          'title': 'Balloon Decoration',
          'color': const Color(0xFF1565C0),
          'icon': Icons.celebration_rounded,
          'name': 'Balloon Art Studio',
          'speciality': 'Balloon & Theme Decoration',
        };
      case 'flower':
        return {
          'title': 'Flower Decoration',
          'color': const Color(0xFF2E7D32),
          'icon': Icons.local_florist_rounded,
          'name': 'Floral Dreams',
          'speciality': 'Fresh Flower Decoration',
        };
      case 'lighting':
        return {
          'title': 'Lighting Decoration',
          'color': const Color(0xFFF9A825),
          'icon': Icons.lightbulb_rounded,
          'name': 'Bright Events Lighting',
          'speciality': 'LED & Fairy Light Setup',
        };
      case 'tent':
        return {
          'title': 'Tent House',
          'color': const Color(0xFF37474F),
          'icon': Icons.holiday_village_rounded,
          'name': 'Sharma Tent House',
          'speciality': 'Tent & Shamiana Setup',
        };
      case 'chair_table':
        return {
          'title': 'Chair & Table Rental',
          'color': const Color(0xFF4E342E),
          'icon': Icons.chair_rounded,
          'name': 'Event Furniture Rentals',
          'speciality': 'Chairs, Tables & Furniture',
        };
      default:
        return {
          'title': 'Mandap Decoration',
          'color': const Color(0xFFE65100),
          'icon': Icons.temple_hindu_rounded,
          'name': 'Royal Mandap Decorators',
          'speciality': 'Traditional & Floral Mandap',
        };
    }
  }

  Color get _primaryColor => _config['color'] as Color;

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'D001',
      'client': 'Sunita Patil',
      'event': 'Wedding',
      'date': '20 Jul 2026',
      'package': 'Premium ₹75,000',
      'status': 'confirmed',
      'location': 'Nashik',
    },
    {
      'id': 'D002',
      'client': 'Ravi Kumar',
      'event': 'Birthday',
      'date': '25 Jul 2026',
      'package': 'Standard ₹15,000',
      'status': 'pending',
      'location': 'Pune',
    },
    {
      'id': 'D003',
      'client': 'Kavita Joshi',
      'event': 'Engagement',
      'date': '2 Aug 2026',
      'package': 'Floral ₹40,000',
      'status': 'pending',
      'location': 'Mumbai',
    },
  ];

  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'Traditional',
      'price': '₹25,000',
      'desc': 'Classic Indian mandap with marigold & roses',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1bc1d5875-1772256929214.png',
    },
    {
      'name': 'Floral Premium',
      'price': '₹40,000',
      'desc': 'Full floral setup with orchids & lilies',
      'image': 'https://images.unsplash.com/photo-1735044029895-8e1c4397f978',
    },
    {
      'name': 'Modern Luxury',
      'price': '₹75,000',
      'desc': 'Contemporary design with LED & draping',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_17ff38260-1783271523591.png',
    },
    {
      'name': 'Custom Theme',
      'price': 'On Request',
      'desc': 'Fully customized as per your vision',
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15eee9980-1769720086590.png',
    },
  ];

  final List<String> _galleryImages = [
    'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
    'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=300',
    'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=300',
    'https://images.pexels.com/photos/3379934/pexels-photo-3379934.jpeg?w=300',
    'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?w=300',
    'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?w=300',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _signOut() => Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.loginScreen,
    (_) => false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(_primaryColor, Colors.white, 0.95)!,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _config['title'] as String,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.chatListScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            const Tab(text: 'Dashboard'),
            const Tab(text: 'Bookings'),
            Tab(text: widget.subcategory == 'catering' ? 'Menu' : 'Themes'),
            const Tab(text: 'Gallery'),
            const Tab(text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildBookings(),
          widget.subcategory == 'catering'
              ? _buildCateringMenu()
              : _buildThemes(),
          _buildGallery(),
          _buildEarnings(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _config['icon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _config['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _config['speciality'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber[300],
                            size: 15,
                          ),
                          Text(
                            ' 4.9  •  156 reviews',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
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
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _kpiCard(
                'This Month',
                '₹1,20,000',
                Icons.currency_rupee_rounded,
                Colors.green,
              ),
              _kpiCard('Bookings', '6', Icons.event_rounded, _primaryColor),
              _kpiCard(
                'Pending',
                '2',
                Icons.pending_actions_rounded,
                Colors.orange,
              ),
              _kpiCard('Rating', '4.9 ★', Icons.star_rounded, Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(),
          const SizedBox(height: 16),
          Text(
            'Upcoming Events',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._bookings
              .where((b) => b['status'] == 'confirmed')
              .map((b) => _bookingTile(b)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Plan Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Renews on 30 Jul 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.providerSubscriptionScreen,
            ),
            child: Text(
              'Manage',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'All Bookings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._bookings.map((b) => _bookingTile(b, showActions: true)),
      ],
    );
  }

  Widget _bookingTile(Map<String, dynamic> b, {bool showActions = false}) {
    final statusColors = {
      'pending': Colors.orange,
      'confirmed': Colors.green,
      'completed': Colors.blue,
    };
    final color = statusColors[b['status']] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                child: Text(
                  (b['client'] as String)[0],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['client'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${b['event']} • ${b['location']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (b['status'] as String).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 5),
              Text(
                b['date'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  b['package'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showActions && b['status'] == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => b['status'] = 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => b['status'] = 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemes() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Decoration Themes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Theme',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._themes.map(
          (theme) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.network(
                    theme['image'] as String,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: _primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_rounded,
                        color: _primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              theme['desc'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            theme['price'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCateringMenu() {
    final menus = [
      {
        'type': 'Veg Thali',
        'price': '₹350/person',
        'items': ['Dal Fry', 'Sabzi', 'Rice', 'Roti', 'Salad', 'Dessert'],
        'color': Colors.green,
      },
      {
        'type': 'Non-Veg Thali',
        'price': '₹500/person',
        'items': [
          'Chicken Curry',
          'Mutton',
          'Rice',
          'Roti',
          'Salad',
          'Dessert',
        ],
        'color': Colors.red,
      },
      {
        'type': 'Premium Buffet',
        'price': '₹800/person',
        'items': [
          'Live Counter',
          '20+ Dishes',
          'Dessert Counter',
          'Mocktails',
          'Ice Cream',
        ],
        'color': Colors.purple,
      },
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Menu Packages',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...menus.map(
          (menu) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (menu['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: menu['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        menu['type'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      menu['price'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (menu['items'] as List)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (menu['color'] as Color).withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: menu['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Work Gallery',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                label: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _galleryImages.length,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _galleryImages[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_rounded, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹5,40,000',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _earningChip('This Month', '₹1,20,000'),
                    const SizedBox(width: 12),
                    _earningChip('Pending', '₹40,000'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Transactions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...[
            {
              'client': 'Sunita Patil',
              'event': 'Wedding',
              'amount': '₹75,000',
              'date': '15 Jun 2026',
            },
            {
              'client': 'Ravi Kumar',
              'event': 'Birthday',
              'amount': '₹15,000',
              'date': '10 Jun 2026',
            },
          ].map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['client']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${t['event']} • ${t['date']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    t['amount']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
