import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class RentSubscriptionScreen extends StatefulWidget {
  const RentSubscriptionScreen({super.key});

  @override
  State<RentSubscriptionScreen> createState() => _RentSubscriptionScreenState();
}

class _RentSubscriptionScreenState extends State<RentSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubcategory = 'room';
  String _selectedPlan = 'standard';

  static const _subcategories = [
    {
      'id': 'room',
      'label': 'Room',
      'icon': Icons.bedroom_parent_rounded,
      'color': Color(0xFF26A69A),
    },
    {
      'id': 'pg',
      'label': 'PG',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF7B1FA2),
    },
    {
      'id': 'hostel',
      'label': 'Hostel',
      'icon': Icons.hotel_rounded,
      'color': Color(0xFF1565C0),
    },
    {
      'id': 'hotel',
      'label': 'Hotel',
      'icon': Icons.business_rounded,
      'color': Color(0xFFD84315),
    },
    {
      'id': 'villa',
      'label': 'Villa',
      'icon': Icons.villa_rounded,
      'color': Color(0xFFE65100),
    },
    {
      'id': 'tools',
      'label': 'Tools',
      'icon': Icons.build_rounded,
      'color': Color(0xFF2E7D32),
    },
  ];

  Map<String, List<Map<String, dynamic>>> get _plans => {
    'room': [
      {
        'id': 'free',
        'name': 'Free',
        'price': 0,
        'listings': 2,
        'badge': null,
        'color': Colors.grey.shade600,
        'features': [
          '2 free listings',
          'Standard visibility',
          'Basic analytics',
          'Email support',
        ],
      },
      {
        'id': 'basic',
        'name': 'Basic',
        'price': 299,
        'listings': 5,
        'badge': null,
        'color': const Color(0xFF26A69A),
        'features': [
          '5 active listings',
          'Better search ranking',
          'Basic analytics',
          'Chat support',
          'Pay-per-listing option',
        ],
      },
      {
        'id': 'standard',
        'name': 'Standard',
        'price': 599,
        'listings': 15,
        'badge': 'Popular',
        'color': AppTheme.primary,
        'features': [
          '15 active listings',
          'Priority search ranking',
          'Business analytics',
          'Featured listing discount',
          'Verified badge option',
          'Priority support',
        ],
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'price': 999,
        'listings': -1,
        'badge': 'Best Value',
        'color': const Color(0xFFF9A825),
        'features': [
          'Unlimited listings',
          'Top search placement',
          'Detailed analytics',
          'Free featured listing/month',
          'Verified Owner badge',
          '24/7 priority support',
          'Promotional campaigns',
        ],
      },
    ],
    'pg': [
      {
        'id': 'basic',
        'name': 'Basic',
        'price': 499,
        'listings': 3,
        'badge': null,
        'color': const Color(0xFF7B1FA2),
        'features': [
          '3 active listings',
          'Standard visibility',
          'Basic analytics',
          'Chat support',
        ],
      },
      {
        'id': 'standard',
        'name': 'Standard',
        'price': 899,
        'listings': 10,
        'badge': 'Popular',
        'color': AppTheme.primary,
        'features': [
          '10 active listings',
          'Priority ranking',
          'Business analytics',
          'Featured listing option',
          'Priority support',
        ],
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'price': 1499,
        'listings': -1,
        'badge': 'Best Value',
        'color': const Color(0xFFF9A825),
        'features': [
          'Unlimited listings',
          'Top placement',
          'Detailed analytics',
          'Free featured listings',
          'Verified badge',
          '24/7 support',
          'Promotional campaigns',
        ],
      },
    ],
    'tools': [
      {
        'id': 'free',
        'name': 'Free',
        'price': 0,
        'listings': 2,
        'badge': null,
        'color': Colors.grey.shade600,
        'features': [
          '2 free listings',
          'Standard visibility',
          'Basic analytics',
        ],
      },
      {
        'id': 'basic',
        'name': 'Basic',
        'price': 399,
        'listings': 10,
        'badge': null,
        'color': const Color(0xFF2E7D32),
        'features': [
          '10 active listings',
          'Better ranking',
          'Basic analytics',
          'Delivery badge',
        ],
      },
      {
        'id': 'standard',
        'name': 'Standard',
        'price': 799,
        'listings': 30,
        'badge': 'Popular',
        'color': AppTheme.primary,
        'features': [
          '30 active listings',
          'Priority ranking',
          'Business analytics',
          'Featured listing option',
          'Premium Supplier badge',
        ],
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'price': 1299,
        'listings': -1,
        'badge': 'Best Value',
        'color': const Color(0xFFF9A825),
        'features': [
          'Unlimited listings',
          'Top placement',
          'Detailed analytics',
          'Free featured listings',
          'Verified badge',
          '24/7 support',
        ],
      },
    ],
  };

  List<Map<String, dynamic>> get _currentPlans {
    final sub = _selectedSubcategory;
    return _plans[sub] ?? _plans['room']!;
  }

  Color get _activeColor {
    final sub = _subcategories.firstWhere(
      (s) => s['id'] == _selectedSubcategory,
    );
    return sub['color'] as Color;
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _activeColor,
        title: Text(
          'List Your Property',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
        children: [_buildPlansTab(), _buildAddOnsTab(), _buildMyListingsTab()],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategory selector
          Container(
            color: _activeColor.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _subcategories.map((s) {
                  final sel = _selectedSubcategory == s['id'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedSubcategory = s['id'] as String;
                      _selectedPlan = 'standard';
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? (s['color'] as Color) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? (s['color'] as Color)
                              : AppTheme.outlineVariant,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: (s['color'] as Color).withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s['icon'] as IconData,
                            size: 14,
                            color: sel ? Colors.white : (s['color'] as Color),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start free, scale as you grow. Cancel anytime.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Plan cards
          ..._currentPlans.map((plan) => _buildPlanCard(plan)),

          // Pay per listing section
          _buildPayPerListingSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan['id'];
    final planColor = plan['color'] as Color;
    final isFree = plan['price'] == 0;
    final isUnlimited = plan['listings'] == -1;
    final badge = plan['badge'] as String?;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan['id'] as String),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? planColor : AppTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: planColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Plan header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? planColor.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: planColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
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
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: planColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge,
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
                          isUnlimited
                              ? 'Unlimited listings'
                              : '${plan['listings']} active listings',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      isFree
                          ? Text(
                              'FREE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: planColor,
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: planColor,
                                  ),
                                ),
                                Text(
                                  '${plan['price']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: planColor,
                                  ),
                                ),
                              ],
                            ),
                      if (!isFree)
                        Text(
                          '/month',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Features
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...(plan['features'] as List<String>).map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: planColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            f,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handlePlanSelect(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? planColor
                            : AppTheme.surfaceVariant,
                        foregroundColor: isSelected ? Colors.white : planColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isFree ? 'Get Started Free' : 'Subscribe Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
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
  }

  void _handlePlanSelect(Map<String, dynamic> plan) {
    if (plan['price'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Free plan activated! You can now post ${plan['listings']} listings.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.upiPaymentScreen,
        arguments: {
          'amount': plan['price'],
          'description': '${plan['name']} Plan - Rent Marketplace',
        },
      );
    }
  }

  Widget _buildPayPerListingSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay Per Listing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Post individual listings without a subscription',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹99/listing',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.upiPaymentScreen,
                arguments: {
                  'amount': 99,
                  'description': 'Pay Per Listing - Rent Marketplace',
                },
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Post Single Listing – ₹99',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsTab() {
    final addOns = [
      {
        'icon': Icons.star_rounded,
        'title': 'Featured Listing – 7 Days',
        'desc': 'Appear at the top of search results for 7 days',
        'price': 299,
        'color': const Color(0xFFF9A825),
        'badge': null,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Featured Listing – 15 Days',
        'desc': 'Top placement for 15 days with priority visibility',
        'price': 499,
        'color': const Color(0xFFF9A825),
        'badge': 'Popular',
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Featured Listing – 30 Days',
        'desc': 'Maximum exposure for a full month',
        'price': 799,
        'color': const Color(0xFFF9A825),
        'badge': 'Best Value',
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'Verified Provider Badge',
        'desc': 'Build trust with a verified badge on all your listings',
        'price': 199,
        'color': Colors.blue.shade600,
        'badge': null,
      },
      {
        'icon': Icons.campaign_rounded,
        'title': 'Sponsored Listing',
        'desc': 'Appear in sponsored section across the app',
        'price': 599,
        'color': Colors.purple.shade600,
        'badge': null,
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Analytics Dashboard',
        'desc': 'Detailed insights: views, inquiries, conversion rates',
        'price': 149,
        'color': Colors.teal.shade600,
        'badge': null,
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'title': 'Luxury Villa Badge',
        'desc': 'Premium badge for villa listings (Villa subcategory)',
        'price': 299,
        'color': const Color(0xFFE65100),
        'badge': null,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Boost Your Listings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add-ons to increase visibility and build trust',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ...addOns.map((a) => _buildAddOnCard(a)),
        ],
      ),
    );
  }

  Widget _buildAddOnCard(Map<String, dynamic> addOn) {
    final color = addOn['color'] as Color;
    final badge = addOn['badge'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(addOn['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        addOn['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  addOn['desc'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${addOn['price']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.upiPaymentScreen,
                  arguments: {
                    'amount': addOn['price'],
                    'description': addOn['title'],
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Buy',
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

  Widget _buildMyListingsTab() {
    final mockListings = [
      {
        'title': 'Spacious 1BHK Room',
        'subcategory': 'Room',
        'status': 'Active',
        'views': 248,
        'inquiries': 18,
        'plan': 'Standard',
        'featured': true,
        'color': const Color(0xFF26A69A),
      },
      {
        'title': 'Budget Room Near IT Park',
        'subcategory': 'Room',
        'status': 'Pending',
        'views': 0,
        'inquiries': 0,
        'plan': 'Free',
        'featured': false,
        'color': const Color(0xFF26A69A),
      },
      {
        'title': 'JCB Excavator – Daily Rental',
        'subcategory': 'Tools',
        'status': 'Active',
        'views': 124,
        'inquiries': 8,
        'plan': 'Basic',
        'featured': true,
        'color': const Color(0xFF2E7D32),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Listings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add New',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _statChip('3', 'Total', Icons.list_rounded, AppTheme.primary),
              const SizedBox(width: 8),
              _statChip(
                '2',
                'Active',
                Icons.check_circle_rounded,
                Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              _statChip(
                '1',
                'Pending',
                Icons.pending_rounded,
                Colors.orange.shade600,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mockListings.map((l) => _buildMyListingCard(l)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyListingCard(Map<String, dynamic> listing) {
    final color = listing['color'] as Color;
    final status = listing['status'] as String;
    final statusColor = status == 'Active'
        ? Colors.green.shade600
        : status == 'Pending'
        ? Colors.orange.shade600
        : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  listing['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  listing['subcategory'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${listing['plan']} Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (listing['featured'] == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9A825), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 9,
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
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniStat(
                Icons.visibility_rounded,
                '${listing['views']}',
                'Views',
                color,
              ),
              const SizedBox(width: 12),
              _miniStat(
                Icons.message_rounded,
                '${listing['inquiries']}',
                'Inquiries',
                color,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Edit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Boost',
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
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
