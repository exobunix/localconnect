import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class EventSubscriptionScreen extends StatefulWidget {
  const EventSubscriptionScreen({super.key});

  @override
  State<EventSubscriptionScreen> createState() =>
      _EventSubscriptionScreenState();
}

class _EventSubscriptionScreenState extends State<EventSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubcategory = 'photography';
  String _selectedPlan = 'standard';
  String _selectedDuration = '30';

  static const _subcategories = [
    {'id': 'photography', 'label': 'Photography', 'color': Color(0xFFAD1457)},
    {'id': 'videography', 'label': 'Videography', 'color': Color(0xFF6A1B9A)},
    {'id': 'sound', 'label': 'Sound & DJ', 'color': Color(0xFF0277BD)},
    {'id': 'mandap', 'label': 'Mandap Decor', 'color': Color(0xFFE65100)},
    {'id': 'birthday', 'label': 'Birthday Decor', 'color': Color(0xFFC62828)},
    {'id': 'catering', 'label': 'Catering', 'color': Color(0xFF00695C)},
    {'id': 'makeup', 'label': 'Makeup Artist', 'color': Color(0xFF880E4F)},
    {'id': 'mehendi', 'label': 'Mehendi Artist', 'color': Color(0xFF4E342E)},
    {'id': 'lighting', 'label': 'Lighting Decor', 'color': Color(0xFFF9A825)},
    {'id': 'planner', 'label': 'Event Planner', 'color': Color(0xFF1A237E)},
    {'id': 'anchor', 'label': 'Anchor / Host', 'color': Color(0xFF37474F)},
    {'id': 'band', 'label': 'Live Band', 'color': Color(0xFF4A148C)},
    {'id': 'orchestra', 'label': 'Orchestra', 'color': Color(0xFF1B5E20)},
    {'id': 'dance', 'label': 'Dance Group', 'color': Color(0xFFBF360C)},
    {
      'id': 'generator',
      'label': 'Generator Rental',
      'color': Color(0xFF263238),
    },
    {'id': 'chair_table', 'label': 'Chair & Table', 'color': Color(0xFF4E342E)},
    {'id': 'tent', 'label': 'Tent House', 'color': Color(0xFF37474F)},
  ];

  static const Map<String, Map<String, dynamic>> _pricingConfig = {
    'photography': {
      'basic': 299,
      'standard': 599,
      'premium': 999,
      'payPerLead': false,
      'tier': 'standard',
    },
    'videography': {
      'basic': 299,
      'standard': 599,
      'premium': 999,
      'payPerLead': false,
      'tier': 'standard',
    },
    'sound': {
      'basic': 249,
      'standard': 499,
      'premium': 799,
      'payPerLead': false,
      'tier': 'basic',
    },
    'mandap': {
      'basic': 499,
      'standard': 899,
      'premium': 1499,
      'payPerLead': false,
      'tier': 'premium',
    },
    'birthday': {
      'basic': 199,
      'standard': 399,
      'premium': 699,
      'payPerLead': false,
      'tier': 'basic',
    },
    'catering': {
      'basic': 499,
      'standard': 899,
      'premium': 1499,
      'payPerLead': false,
      'tier': 'premium',
    },
    'makeup': {
      'basic': 199,
      'standard': 399,
      'premium': 699,
      'payPerLead': true,
      'tier': 'basic',
    },
    'mehendi': {
      'basic': 149,
      'standard': 299,
      'premium': 499,
      'payPerLead': true,
      'tier': 'basic',
    },
    'lighting': {
      'basic': 249,
      'standard': 499,
      'premium': 799,
      'payPerLead': false,
      'tier': 'basic',
    },
    'planner': {
      'basic': 499,
      'standard': 999,
      'premium': 1999,
      'payPerLead': false,
      'tier': 'premium',
    },
    'anchor': {
      'basic': 149,
      'standard': 299,
      'premium': 499,
      'payPerLead': true,
      'tier': 'basic',
    },
    'band': {
      'basic': 299,
      'standard': 599,
      'premium': 999,
      'payPerLead': false,
      'tier': 'standard',
    },
    'orchestra': {
      'basic': 299,
      'standard': 599,
      'premium': 999,
      'payPerLead': false,
      'tier': 'standard',
    },
    'dance': {
      'basic': 249,
      'standard': 499,
      'premium': 799,
      'payPerLead': false,
      'tier': 'standard',
    },
    'generator': {
      'basic': 199,
      'standard': 399,
      'premium': 699,
      'payPerLead': false,
      'tier': 'basic',
    },
    'chair_table': {
      'basic': 149,
      'standard': 299,
      'premium': 499,
      'payPerLead': false,
      'tier': 'basic',
    },
    'tent': {
      'basic': 399,
      'standard': 799,
      'premium': 1299,
      'payPerLead': false,
      'tier': 'premium',
    },
  };

  Color get _activeColor {
    final sub = _subcategories.firstWhere(
      (s) => s['id'] == _selectedSubcategory,
    );
    return sub['color'] as Color;
  }

  Map<String, dynamic> get _pricing =>
      _pricingConfig[_selectedSubcategory] ?? _pricingConfig['photography']!;

  int _getAdjustedPrice(int basePrice) {
    switch (_selectedDuration) {
      case '90':
        return (basePrice * 2.7).round();
      case '180':
        return (basePrice * 5.0).round();
      case '365':
        return (basePrice * 9.0).round();
      default:
        return basePrice;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'List Your Service',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _activeColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Add-ons'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlansTab(
            subcategories: _subcategories,
            selectedSubcategory: _selectedSubcategory,
            selectedPlan: _selectedPlan,
            selectedDuration: _selectedDuration,
            pricing: _pricing,
            activeColor: _activeColor,
            isDark: isDark,
            getAdjustedPrice: _getAdjustedPrice,
            onSubcategoryChanged: (s) =>
                setState(() => _selectedSubcategory = s),
            onPlanChanged: (p) => setState(() => _selectedPlan = p),
            onDurationChanged: (d) => setState(() => _selectedDuration = d),
          ),
          _AddonsTab(activeColor: _activeColor, isDark: isDark),
          _MyListingsTab(activeColor: _activeColor, isDark: isDark),
        ],
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────
class _PlansTab extends StatelessWidget {
  final List<Map<String, dynamic>> subcategories;
  final String selectedSubcategory;
  final String selectedPlan;
  final String selectedDuration;
  final Map<String, dynamic> pricing;
  final Color activeColor;
  final bool isDark;
  final int Function(int) getAdjustedPrice;
  final ValueChanged<String> onSubcategoryChanged;
  final ValueChanged<String> onPlanChanged;
  final ValueChanged<String> onDurationChanged;

  const _PlansTab({
    required this.subcategories,
    required this.selectedSubcategory,
    required this.selectedPlan,
    required this.selectedDuration,
    required this.pricing,
    required this.activeColor,
    required this.isDark,
    required this.getAdjustedPrice,
    required this.onSubcategoryChanged,
    required this.onPlanChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        'id': 'basic',
        'name': 'Basic',
        'price': pricing['basic'] as int,
        'color': const Color(0xFF546E7A),
        'icon': Icons.star_border_rounded,
        'listings': '3 Active Listings',
        'features': [
          'Standard search visibility',
          '3 portfolio photos',
          'Basic analytics',
          'Customer inquiries',
        ],
        'recommended': false,
      },
      {
        'id': 'standard',
        'name': 'Standard',
        'price': pricing['standard'] as int,
        'color': activeColor,
        'icon': Icons.star_half_rounded,
        'listings': '10 Active Listings',
        'features': [
          'Priority search ranking',
          '15 portfolio photos',
          'Business analytics',
          'Featured badge',
          'Customer inquiries',
          'WhatsApp integration',
        ],
        'recommended': true,
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'price': pricing['premium'] as int,
        'color': const Color(0xFFFFB300),
        'icon': Icons.star_rounded,
        'listings': 'Unlimited Listings',
        'features': [
          'Top search placement',
          'Unlimited portfolio',
          'Advanced analytics',
          'Verified badge',
          'Priority support',
          'Featured listing included',
          'Promotional campaigns',
          'Festival season boost',
        ],
        'recommended': false,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Subcategory Selector
        Text(
          'Select Your Category',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subcategories.length,
            itemBuilder: (_, i) {
              final sub = subcategories[i];
              final isSelected = sub['id'] == selectedSubcategory;
              return GestureDetector(
                onTap: () => onSubcategoryChanged(sub['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (sub['color'] as Color)
                        : (sub['color'] as Color).withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : sub['color'] as Color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Duration Selector
        Text(
          'Subscription Duration',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              [
                {'id': '30', 'label': '30 Days'},
                {'id': '90', 'label': '90 Days', 'save': '10%'},
                {'id': '180', 'label': '180 Days', 'save': '17%'},
                {'id': '365', 'label': '1 Year', 'save': '25%'},
              ].map((d) {
                final isSelected = d['id'] == selectedDuration;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDurationChanged(d['id']!),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor
                            : activeColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d['label']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : activeColor,
                            ),
                          ),
                          if (d['save'] != null)
                            Text(
                              'Save ${d['save']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                color: isSelected
                                    ? Colors.white70
                                    : activeColor.withAlpha(150),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        // Plan Cards
        ...plans.map((plan) {
          final isSelected = plan['id'] == selectedPlan;
          final planColor = plan['color'] as Color;
          final adjustedPrice = getAdjustedPrice(plan['price'] as int);
          final features = (plan['features'] as List).cast<String>();

          return GestureDetector(
            onTap: () => onPlanChanged(plan['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2023) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? planColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? planColor.withAlpha(40)
                        : Colors.black.withAlpha(8),
                    blurRadius: isSelected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Plan Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: planColor.withAlpha(isSelected ? 25 : 12),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: planColor.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            plan['icon'] as IconData,
                            color: planColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan['name'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: planColor,
                                    ),
                                  ),
                                  if (plan['recommended'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: planColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Popular',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                plan['listings'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$adjustedPrice',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: planColor,
                              ),
                            ),
                            Text(
                              'for $selectedDuration days',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Features
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        ...features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: planColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showPaymentSheet(
                              context,
                              plan['name'] as String,
                              adjustedPrice,
                              planColor,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? planColor
                                  : planColor.withAlpha(20),
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : planColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isSelected ? 'Subscribe Now' : 'Select Plan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Pay Per Lead Option
        if (pricing['payPerLead'] == true) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2023) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: activeColor.withAlpha(40)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bolt_rounded, color: activeColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Per Lead',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Pay only when you receive a customer inquiry. ₹49/lead',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Enable',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _showPaymentSheet(
    BuildContext context,
    String planName,
    int price,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PaymentSheet(planName: planName, price: price, color: color),
    );
  }
}

// ── Add-ons Tab ───────────────────────────────────────────────────────────────
class _AddonsTab extends StatelessWidget {
  final Color activeColor;
  final bool isDark;

  const _AddonsTab({required this.activeColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final addons = [
      {
        'title': 'Featured Listing',
        'subtitle': 'Appear at the top of search results',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFB300),
        'options': [
          {'label': '7 Days', 'price': 199},
          {'label': '15 Days', 'price': 349},
          {'label': '30 Days', 'price': 599},
        ],
      },
      {
        'title': 'Verified Provider Badge',
        'subtitle': 'Build trust with a verified badge on your profile',
        'icon': Icons.verified_rounded,
        'color': AppTheme.success,
        'options': [
          {'label': 'Annual', 'price': 999},
        ],
      },
      {
        'title': 'Sponsored Listing',
        'subtitle': 'Appear in sponsored section across the app',
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFF6A1B9A),
        'options': [
          {'label': '7 Days', 'price': 299},
          {'label': '15 Days', 'price': 499},
          {'label': '30 Days', 'price': 799},
        ],
      },
      {
        'title': 'Portfolio Upgrade',
        'subtitle': 'Add up to 50 photos and 10 videos to your portfolio',
        'icon': Icons.photo_library_rounded,
        'color': const Color(0xFF0277BD),
        'options': [
          {'label': 'Monthly', 'price': 149},
          {'label': 'Annual', 'price': 999},
        ],
      },
      {
        'title': 'Business Analytics',
        'subtitle':
            'Detailed insights on profile views, inquiries, and conversions',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFF00695C),
        'options': [
          {'label': 'Monthly', 'price': 199},
        ],
      },
      {
        'title': 'Festival Campaign',
        'subtitle': 'Boost visibility during wedding season and festivals',
        'icon': Icons.celebration_rounded,
        'color': const Color(0xFFE65100),
        'options': [
          {'label': 'Per Campaign', 'price': 499},
        ],
      },
      {
        'title': 'Priority Search Ranking',
        'subtitle': 'Always appear in top 5 search results for your category',
        'icon': Icons.trending_up_rounded,
        'color': activeColor,
        'options': [
          {'label': '30 Days', 'price': 399},
          {'label': '90 Days', 'price': 999},
        ],
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: addons.map((addon) {
        final options = (addon['options'] as List).cast<Map<String, dynamic>>();
        final color = addon['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2023) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
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
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      addon['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          addon['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: options
                    .map(
                      (opt) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.withAlpha(20),
                              foregroundColor: color,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  opt['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₹${opt['price']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── My Listings Tab ───────────────────────────────────────────────────────────
class _MyListingsTab extends StatelessWidget {
  final Color activeColor;
  final bool isDark;

  const _MyListingsTab({required this.activeColor, required this.isDark});

  static final _mockListings = [
    {
      'title': 'Wedding Photography Package',
      'subcategory': 'Photography',
      'status': 'active',
      'plan': 'Standard',
      'views': 234,
      'inquiries': 18,
      'expiresIn': 12,
      'isFeatured': true,
    },
    {
      'title': 'Pre-Wedding Shoot',
      'subcategory': 'Photography',
      'status': 'active',
      'plan': 'Basic',
      'views': 89,
      'inquiries': 6,
      'expiresIn': 5,
      'isFeatured': false,
    },
    {
      'title': 'Birthday Photography',
      'subcategory': 'Photography',
      'status': 'expired',
      'plan': 'Basic',
      'views': 45,
      'inquiries': 3,
      'expiresIn': 0,
      'isFeatured': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Subscription Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [activeColor, activeColor.withAlpha(200)],
            ),
            borderRadius: BorderRadius.circular(16),
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
                      'Standard Plan Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Expires in 12 days • 7/10 listings used',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  'Renew',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'My Listings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 14),
              label: Text(
                'Add Listing',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._mockListings.map((listing) {
          final isActive = listing['status'] == 'active';
          final expiresIn = listing['expiresIn'] as int;
          final isExpiringSoon = isActive && expiresIn <= 7;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2023) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpiringSoon
                    ? AppTheme.warning.withAlpha(60)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8),
              ],
            ),
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
                            listing['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.success.withAlpha(20)
                                      : AppTheme.error.withAlpha(20),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Expired',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: activeColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  listing['plan'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: activeColor,
                                  ),
                                ),
                              ),
                              if (listing['isFeatured'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFB300,
                                    ).withAlpha(20),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Featured',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFFB300),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isExpiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Expires in $expiresIn days',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.visibility_rounded,
                      value: '${listing['views']}',
                      label: 'Views',
                      color: activeColor,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.message_rounded,
                      value: '${listing['inquiries']}',
                      label: 'Inquiries',
                      color: activeColor,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Edit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: activeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        isActive ? 'Boost' : 'Renew',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────────
class _PaymentSheet extends StatelessWidget {
  final String planName;
  final int price;
  final Color color;

  const _PaymentSheet({
    required this.planName,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2023) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete Payment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '$planName Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹$price',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...['UPI / GPay / PhonePe', 'Credit / Debit Card', 'Net Banking'].map(
            (method) => ListTile(
              leading: Icon(Icons.payment_rounded, color: color, size: 20),
              title: Text(
                method,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: () => Navigator.pop(context),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Pay ₹$price',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
