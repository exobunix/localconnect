import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import './provider_photos_management_widget.dart';
import './provider_offers_management_widget.dart';

class ProviderTabsWidget extends StatelessWidget {
  final TabController tabController;
  final String? providerId;
  final bool isOwner;
  final String category;

  const ProviderTabsWidget({
    super.key,
    required this.tabController,
    this.providerId,
    this.isOwner = false,
    this.category = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: const Color(0xFF74777F),
            indicatorColor: AppTheme.primary,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Services'),
              Tab(text: 'Products'),
              Tab(text: 'Offers'),
              Tab(text: 'Photos'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
        SizedBox(
          height: 520,
          child: TabBarView(
            controller: tabController,
            children: [
              _ServicesTab(category: category),
              _ProductsTab(category: category),
              providerId != null
                  ? SingleChildScrollView(
                      child: ProviderOffersManagementWidget(
                        providerId: providerId!,
                        isOwner: isOwner,
                      ),
                    )
                  : const _OffersPlaceholderTab(),
              providerId != null
                  ? SingleChildScrollView(
                      child: ProviderPhotosManagementWidget(
                        providerId: providerId!,
                        isOwner: isOwner,
                      ),
                    )
                  : const _PhotosTab(),
              const _ReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Services Tab ──────────────────────────────────────────
class _ServicesTab extends StatelessWidget {
  final String category;

  const _ServicesTab({required this.category});

  static const Map<String, List<Map<String, dynamic>>> _servicesByCategory = {
    'electrician': [
      {
        'name': 'Wiring & Rewiring',
        'nameMarathi': 'वायरिंग',
        'price': '₹350–600',
        'duration': '2–4 hrs',
        'icon': Icons.electrical_services_rounded,
        'popular': true,
      },
      {
        'name': 'Fan Installation',
        'nameMarathi': 'पंखा बसवणे',
        'price': '₹200',
        'duration': '30 min',
        'icon': Icons.air_rounded,
        'popular': false,
      },
      {
        'name': 'MCB / Switchboard Repair',
        'nameMarathi': 'MCB दुरुस्ती',
        'price': '₹250–500',
        'duration': '1–2 hrs',
        'icon': Icons.settings_input_component_rounded,
        'popular': true,
      },
      {
        'name': 'AC Wiring',
        'nameMarathi': 'AC वायरिंग',
        'price': '₹400–800',
        'duration': '2–3 hrs',
        'icon': Icons.ac_unit_rounded,
        'popular': false,
      },
      {
        'name': 'Inverter / UPS Setup',
        'nameMarathi': 'इन्व्हर्टर सेटअप',
        'price': '₹500–1000',
        'duration': '2–4 hrs',
        'icon': Icons.battery_charging_full_rounded,
        'popular': false,
      },
    ],
    'rickshaw': [
      {
        'name': 'Local Trip',
        'nameMarathi': 'स्थानिक प्रवास',
        'price': '₹30–80',
        'duration': '10–30 min',
        'icon': Icons.electric_rickshaw_rounded,
        'popular': true,
      },
      {
        'name': 'Station / Airport Drop',
        'nameMarathi': 'स्टेशन ड्रॉप',
        'price': '₹100–200',
        'duration': '30–60 min',
        'icon': Icons.train_rounded,
        'popular': true,
      },
      {
        'name': 'School / Office Pickup',
        'nameMarathi': 'शाळा / ऑफिस पिकअप',
        'price': '₹50–120',
        'duration': '15–40 min',
        'icon': Icons.directions_walk_rounded,
        'popular': false,
      },
      {
        'name': 'Monthly Contract',
        'nameMarathi': 'मासिक करार',
        'price': '₹1500–3000/mo',
        'duration': 'Daily',
        'icon': Icons.calendar_month_rounded,
        'popular': false,
      },
      {
        'name': 'Outstation Trip',
        'nameMarathi': 'बाहेरगाव प्रवास',
        'price': '₹300–600',
        'duration': '1–3 hrs',
        'icon': Icons.route_rounded,
        'popular': false,
      },
    ],
    'transport': [
      {
        'name': 'Local Trip',
        'nameMarathi': 'स्थानिक प्रवास',
        'price': '₹50–150',
        'duration': '15–45 min',
        'icon': Icons.local_taxi_rounded,
        'popular': true,
      },
      {
        'name': 'Goods Transport',
        'nameMarathi': 'माल वाहतूक',
        'price': '₹200–500',
        'duration': '1–3 hrs',
        'icon': Icons.local_shipping_rounded,
        'popular': true,
      },
      {
        'name': 'Outstation Trip',
        'nameMarathi': 'बाहेरगाव प्रवास',
        'price': '₹500–1500',
        'duration': '2–6 hrs',
        'icon': Icons.route_rounded,
        'popular': false,
      },
      {
        'name': 'Monthly Contract',
        'nameMarathi': 'मासिक करार',
        'price': '₹3000–8000/mo',
        'duration': 'Daily',
        'icon': Icons.calendar_month_rounded,
        'popular': false,
      },
    ],
    'tempo': [
      {
        'name': 'Goods Transport',
        'nameMarathi': 'माल वाहतूक',
        'price': '₹300–800',
        'duration': '1–4 hrs',
        'icon': Icons.airport_shuttle_rounded,
        'popular': true,
      },
      {
        'name': 'House Shifting',
        'nameMarathi': 'घर शिफ्टिंग',
        'price': '₹800–2000',
        'duration': '3–6 hrs',
        'icon': Icons.moving_rounded,
        'popular': true,
      },
      {
        'name': 'Market Pickup',
        'nameMarathi': 'मार्केट पिकअप',
        'price': '₹200–500',
        'duration': '1–2 hrs',
        'icon': Icons.shopping_cart_rounded,
        'popular': false,
      },
      {
        'name': 'Outstation Delivery',
        'nameMarathi': 'बाहेरगाव डिलिव्हरी',
        'price': '₹1000–3000',
        'duration': '4–8 hrs',
        'icon': Icons.route_rounded,
        'popular': false,
      },
    ],
    'car': [
      {
        'name': 'Local Ride',
        'nameMarathi': 'स्थानिक राईड',
        'price': '₹80–200',
        'duration': '15–45 min',
        'icon': Icons.directions_car_rounded,
        'popular': true,
      },
      {
        'name': 'Airport Transfer',
        'nameMarathi': 'एअरपोर्ट ट्रान्सफर',
        'price': '₹300–600',
        'duration': '30–90 min',
        'icon': Icons.flight_rounded,
        'popular': true,
      },
      {
        'name': 'Outstation Trip',
        'nameMarathi': 'बाहेरगाव प्रवास',
        'price': '₹800–2000',
        'duration': '3–8 hrs',
        'icon': Icons.route_rounded,
        'popular': false,
      },
      {
        'name': 'Full Day Hire',
        'nameMarathi': 'पूर्ण दिवस भाडे',
        'price': '₹1500–3000',
        'duration': '8–12 hrs',
        'icon': Icons.calendar_today_rounded,
        'popular': false,
      },
    ],
    'bike': [
      {
        'name': 'Quick Delivery',
        'nameMarathi': 'जलद डिलिव्हरी',
        'price': '₹30–80',
        'duration': '15–30 min',
        'icon': Icons.two_wheeler_rounded,
        'popular': true,
      },
      {
        'name': 'Local Ride',
        'nameMarathi': 'स्थानिक राईड',
        'price': '₹20–60',
        'duration': '10–25 min',
        'icon': Icons.directions_bike_rounded,
        'popular': true,
      },
      {
        'name': 'Document Pickup',
        'nameMarathi': 'दस्तऐवज पिकअप',
        'price': '₹40–100',
        'duration': '20–45 min',
        'icon': Icons.description_rounded,
        'popular': false,
      },
    ],
    'truck': [
      {
        'name': 'Goods Transport',
        'nameMarathi': 'माल वाहतूक',
        'price': '₹1000–3000',
        'duration': '2–8 hrs',
        'icon': Icons.local_shipping_rounded,
        'popular': true,
      },
      {
        'name': 'Construction Material',
        'nameMarathi': 'बांधकाम साहित्य',
        'price': '₹1500–4000',
        'duration': '3–6 hrs',
        'icon': Icons.construction_rounded,
        'popular': true,
      },
      {
        'name': 'Long Distance Freight',
        'nameMarathi': 'लांब पल्ल्याची वाहतूक',
        'price': '₹3000–10000',
        'duration': '1–3 days',
        'icon': Icons.route_rounded,
        'popular': false,
      },
    ],
    'plumber': [
      {
        'name': 'Pipe Repair / Leakage Fix',
        'nameMarathi': 'पाईप दुरुस्ती',
        'price': '₹200–500',
        'duration': '1–2 hrs',
        'icon': Icons.plumbing_rounded,
        'popular': true,
      },
      {
        'name': 'Tap / Faucet Installation',
        'nameMarathi': 'नळ बसवणे',
        'price': '₹150–300',
        'duration': '30–60 min',
        'icon': Icons.water_rounded,
        'popular': false,
      },
      {
        'name': 'Bathroom Fitting',
        'nameMarathi': 'बाथरूम फिटिंग',
        'price': '₹500–1500',
        'duration': '2–4 hrs',
        'icon': Icons.bathroom_rounded,
        'popular': true,
      },
      {
        'name': 'Water Tank Cleaning',
        'nameMarathi': 'टाकी साफसफाई',
        'price': '₹300–700',
        'duration': '1–3 hrs',
        'icon': Icons.water_damage_rounded,
        'popular': false,
      },
    ],
    'painter': [
      {
        'name': 'Interior Wall Painting',
        'nameMarathi': 'आतील भिंत रंगकाम',
        'price': '₹8–15/sqft',
        'duration': '1–3 days',
        'icon': Icons.format_paint_rounded,
        'popular': true,
      },
      {
        'name': 'Exterior Painting',
        'nameMarathi': 'बाहेरील रंगकाम',
        'price': '₹10–20/sqft',
        'duration': '2–5 days',
        'icon': Icons.house_rounded,
        'popular': false,
      },
      {
        'name': 'Door / Window Painting',
        'nameMarathi': 'दरवाजा रंगकाम',
        'price': '₹200–500',
        'duration': '2–4 hrs',
        'icon': Icons.door_front_door_rounded,
        'popular': true,
      },
      {
        'name': 'Waterproofing',
        'nameMarathi': 'वॉटरप्रूफिंग',
        'price': '₹15–30/sqft',
        'duration': '1–2 days',
        'icon': Icons.water_drop_rounded,
        'popular': false,
      },
    ],
    'mason': [
      {
        'name': 'Brick / Block Work',
        'nameMarathi': 'विटकाम',
        'price': '₹500–1500/day',
        'duration': '1+ days',
        'icon': Icons.construction_rounded,
        'popular': true,
      },
      {
        'name': 'Plastering',
        'nameMarathi': 'प्लास्टर काम',
        'price': '₹10–20/sqft',
        'duration': '1–3 days',
        'icon': Icons.layers_rounded,
        'popular': true,
      },
      {
        'name': 'Floor Tiling',
        'nameMarathi': 'फरशी काम',
        'price': '₹20–40/sqft',
        'duration': '1–4 days',
        'icon': Icons.grid_on_rounded,
        'popular': false,
      },
      {
        'name': 'Repair & Renovation',
        'nameMarathi': 'दुरुस्ती व नूतनीकरण',
        'price': '₹400–1200/day',
        'duration': '1+ days',
        'icon': Icons.home_repair_service_rounded,
        'popular': false,
      },
    ],
    'delivery': [
      {
        'name': 'Parcel Delivery',
        'nameMarathi': 'पार्सल डिलिव्हरी',
        'price': '₹50–150',
        'duration': '1–3 hrs',
        'icon': Icons.inventory_2_rounded,
        'popular': true,
      },
      {
        'name': 'Document Delivery',
        'nameMarathi': 'दस्तऐवज डिलिव्हरी',
        'price': '₹30–80',
        'duration': '30–90 min',
        'icon': Icons.description_rounded,
        'popular': false,
      },
      {
        'name': 'Same-Day Delivery',
        'nameMarathi': 'त्याच दिवशी डिलिव्हरी',
        'price': '₹100–250',
        'duration': '2–6 hrs',
        'icon': Icons.delivery_dining_rounded,
        'popular': true,
      },
      {
        'name': 'Bulk Material Transport',
        'nameMarathi': 'मोठ्या प्रमाणात वाहतूक',
        'price': '₹300–800',
        'duration': '2–5 hrs',
        'icon': Icons.category_rounded,
        'popular': false,
      },
    ],
    'photography': [
      {
        'name': 'Wedding Photography',
        'nameMarathi': 'लग्न फोटोग्राफी',
        'price': '₹5000–15000',
        'duration': '6–10 hrs',
        'icon': Icons.camera_alt_rounded,
        'popular': true,
      },
      {
        'name': 'Event Photography',
        'nameMarathi': 'कार्यक्रम फोटोग्राफी',
        'price': '₹2000–6000',
        'duration': '3–6 hrs',
        'icon': Icons.celebration_rounded,
        'popular': true,
      },
      {
        'name': 'Portrait Session',
        'nameMarathi': 'पोर्ट्रेट सेशन',
        'price': '₹1000–3000',
        'duration': '1–2 hrs',
        'icon': Icons.portrait_rounded,
        'popular': false,
      },
      {
        'name': 'Video Shoot',
        'nameMarathi': 'व्हिडिओ शूट',
        'price': '₹3000–10000',
        'duration': '4–8 hrs',
        'icon': Icons.videocam_rounded,
        'popular': false,
      },
    ],
  };

  List<Map<String, dynamic>> get _services {
    final cat = category.toLowerCase().trim();
    if (_servicesByCategory.containsKey(cat)) return _servicesByCategory[cat]!;
    for (final key in _servicesByCategory.keys) {
      if (cat.contains(key) || key.contains(cat)) {
        return _servicesByCategory[key]!;
      }
    }
    return [
      {
        'name': 'Basic Service',
        'nameMarathi': 'मूलभूत सेवा',
        'price': '₹200–500',
        'duration': '1–2 hrs',
        'icon': Icons.miscellaneous_services_rounded,
        'popular': true,
      },
      {
        'name': 'Standard Package',
        'nameMarathi': 'मानक पॅकेज',
        'price': '₹500–1000',
        'duration': '2–4 hrs',
        'icon': Icons.star_rounded,
        'popular': false,
      },
      {
        'name': 'Premium Service',
        'nameMarathi': 'प्रीमियम सेवा',
        'price': '₹1000–2000',
        'duration': '4–6 hrs',
        'icon': Icons.workspace_premium_rounded,
        'popular': false,
      },
    ];
  }

  Color get _categoryColor {
    final cat = category.toLowerCase();
    if (cat.contains('rickshaw') ||
        cat.contains('transport') ||
        cat.contains('car') ||
        cat.contains('bike') ||
        cat.contains('tempo') ||
        cat.contains('bus') ||
        cat.contains('truck')) {
      return AppTheme.catTransport;
    }
    if (cat.contains('electrician') || cat.contains('electrical')) {
      return AppTheme.catElectrician;
    }
    if (cat.contains('plumber')) return AppTheme.catPlumbing;
    if (cat.contains('painter')) return AppTheme.catRepair;
    if (cat.contains('delivery')) return AppTheme.catDelivery;
    if (cat.contains('mason') || cat.contains('daily_wage')) {
      return AppTheme.catRepair;
    }
    if (cat.contains('photography') || cat.contains('event')) {
      return AppTheme.catEvents;
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s['icon'] as IconData,
                  color: _categoryColor,
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
                          s['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        if (s['popular'] as bool) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              borderRadius: BorderRadius.circular(4),
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
                      s['nameMarathi'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Color(0xFF74777F),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          s['duration'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
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
                    s['price'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Book',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Products Tab ──────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  final String category;
  const _ProductsTab({this.category = ''});

  static const List<String> _transportCategories = [
    'rickshaw',
    'taxi',
    'car',
    'pickup',
    'truck',
    'mini van',
    'minivan',
    'tempo',
    'bike',
    'bus',
    'transport',
    'vehicle',
  ];

  static const List<String> _shopCategories = [
    'electrical',
    'hardware',
    'shop',
    'plumbing hardware',
    'plumbing_hardware',
  ];

  bool get _isTransport {
    final cat = category.toLowerCase().trim();
    return _transportCategories.any((t) => cat.contains(t));
  }

  bool get _isShop {
    final cat = category.toLowerCase().trim();
    return _shopCategories.any((s) => cat.contains(s));
  }

  // Fare data per transport subcategory
  static const Map<String, List<Map<String, dynamic>>> _fareByCategory = {
    'rickshaw': [
      {'label': 'Base Fare', 'value': '₹15', 'note': 'First 1 km'},
      {'label': 'Per Km Charge', 'value': '₹10/km', 'note': 'After 1 km'},
      {
        'label': 'Waiting Charge',
        'value': '₹2/min',
        'note': 'After 5 min free',
      },
      {'label': 'Night Charge', 'value': '₹20 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹30', 'note': 'Any trip'},
      {'label': 'Monthly Contract', 'value': '₹1500–3000', 'note': 'Per month'},
    ],
    'taxi': [
      {'label': 'Base Fare', 'value': '₹50', 'note': 'First 2 km'},
      {'label': 'Per Km Charge', 'value': '₹15/km', 'note': 'After 2 km'},
      {
        'label': 'Waiting Charge',
        'value': '₹3/min',
        'note': 'After 5 min free',
      },
      {'label': 'Night Charge', 'value': '₹50 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹80', 'note': 'Any trip'},
      {'label': 'Outstation', 'value': '₹12/km', 'note': 'Both ways'},
    ],
    'car': [
      {'label': 'Base Fare', 'value': '₹60', 'note': 'First 2 km'},
      {'label': 'Per Km Charge', 'value': '₹18/km', 'note': 'After 2 km'},
      {
        'label': 'Waiting Charge',
        'value': '₹3/min',
        'note': 'After 5 min free',
      },
      {'label': 'Night Charge', 'value': '₹60 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Full Day Hire', 'value': '₹1500–3000', 'note': '8–12 hrs'},
      {'label': 'Outstation', 'value': '₹14/km', 'note': 'Both ways'},
    ],
    'truck': [
      {'label': 'Base Fare', 'value': '₹300', 'note': 'First 5 km'},
      {'label': 'Per Km Charge', 'value': '₹25/km', 'note': 'After 5 km'},
      {'label': 'Loading Charge', 'value': '₹200', 'note': 'Per load'},
      {'label': 'Night Charge', 'value': '₹200 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹500', 'note': 'Any trip'},
      {'label': 'Outstation', 'value': '₹20/km', 'note': 'Both ways'},
    ],
    'tempo': [
      {'label': 'Base Fare', 'value': '₹150', 'note': 'First 3 km'},
      {'label': 'Per Km Charge', 'value': '₹20/km', 'note': 'After 3 km'},
      {'label': 'Loading Charge', 'value': '₹100', 'note': 'Per load'},
      {'label': 'Night Charge', 'value': '₹100 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹200', 'note': 'Any trip'},
      {'label': 'House Shifting', 'value': '₹800–2000', 'note': 'Full service'},
    ],
    'bike': [
      {'label': 'Base Fare', 'value': '₹20', 'note': 'First 2 km'},
      {'label': 'Per Km Charge', 'value': '₹8/km', 'note': 'After 2 km'},
      {
        'label': 'Waiting Charge',
        'value': '₹1/min',
        'note': 'After 5 min free',
      },
      {'label': 'Night Charge', 'value': '₹15 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹30', 'note': 'Any trip'},
      {'label': 'Express Delivery', 'value': '₹30–80', 'note': 'Per parcel'},
    ],
  };

  List<Map<String, dynamic>> get _fareData {
    final cat = category.toLowerCase().trim();
    for (final key in _fareByCategory.keys) {
      if (cat.contains(key)) return _fareByCategory[key]!;
    }
    // Default transport fare
    return [
      {'label': 'Base Fare', 'value': '₹50', 'note': 'Starting fare'},
      {'label': 'Per Km Charge', 'value': '₹12/km', 'note': 'After base km'},
      {
        'label': 'Waiting Charge',
        'value': '₹2/min',
        'note': 'After 5 min free',
      },
      {'label': 'Night Charge', 'value': '₹30 extra', 'note': '10 PM – 6 AM'},
      {'label': 'Minimum Fare', 'value': '₹50', 'note': 'Any trip'},
      {'label': 'Outstation', 'value': '₹12/km', 'note': 'Both ways'},
    ];
  }

  static final List<Map<String, dynamic>> _electricalProducts = [
    {
      'name': 'Havells Switch (6A)',
      'price': '₹85',
      'quantity': '50 pcs',
      'stock': 'In Stock',
      'imageUrl':
          'https://images.unsplash.com/photo-1683085484928-14fa93e80ac1',
      'semanticLabel': 'White electrical switch plate with rocker switches',
    },
    {
      'name': 'Copper Wire (1.5mm)',
      'price': '₹320/roll',
      'quantity': '20 rolls',
      'stock': 'In Stock',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1708c1972-1770056200541.png',
      'semanticLabel': 'Roll of copper electrical wire with yellow insulation',
    },
    {
      'name': 'LED Bulb 9W (Pack of 4)',
      'price': '₹199',
      'quantity': '30 packs',
      'stock': 'Low Stock',
      'imageUrl':
          'https://images.unsplash.com/photo-1678480045293-6bbc7a458390',
      'semanticLabel':
          'Four LED bulbs arranged on white background showing warm light glow',
    },
    {
      'name': 'MCB 32A Single Pole',
      'price': '₹145',
      'quantity': '15 pcs',
      'stock': 'In Stock',
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_140a726ce-1780330699196.png',
      'semanticLabel': 'Miniature circuit breaker mounted on DIN rail',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isTransport) {
      return _buildFareChart(context);
    }
    if (_isShop) {
      return _buildProductsGrid(context);
    }
    // For home maintenance, event management, and other service categories
    return _buildNoProductsView(context);
  }

  Widget _buildFareChart(BuildContext context) {
    final fares = _fareData;
    final cat = category.toLowerCase().trim();
    String vehicleLabel = 'Vehicle';
    IconData vehicleIcon = Icons.directions_car_rounded;
    if (cat.contains('rickshaw')) {
      vehicleLabel = 'Rickshaw';
      vehicleIcon = Icons.electric_rickshaw_rounded;
    } else if (cat.contains('taxi') || cat.contains('car')) {
      vehicleLabel = 'Car / Taxi';
      vehicleIcon = Icons.local_taxi_rounded;
    } else if (cat.contains('truck')) {
      vehicleLabel = 'Truck';
      vehicleIcon = Icons.local_shipping_rounded;
    } else if (cat.contains('tempo')) {
      vehicleLabel = 'Tempo';
      vehicleIcon = Icons.airport_shuttle_rounded;
    } else if (cat.contains('bike')) {
      vehicleLabel = 'Bike';
      vehicleIcon = Icons.two_wheeler_rounded;
    } else if (cat.contains('bus')) {
      vehicleLabel = 'Bus / Mini Van';
      vehicleIcon = Icons.directions_bus_rounded;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.catTransport,
                  AppTheme.catTransport.withValues(alpha: 0.7),
                ],
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(vehicleIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$vehicleLabel Fare Chart',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Transparent pricing for all trips',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Fare rows
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              children: fares.asMap().entries.map((entry) {
                final i = entry.key;
                final fare = entry.value;
                final isLast = i == fares.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fare['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                Text(
                                  fare['note'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF74777F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.catTransport.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              fare['value'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.catTransport,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: AppTheme.outlineVariant,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fares may vary based on traffic, distance, and time. Contact provider to negotiate.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _electricalProducts.length,
      itemBuilder: (_, i) {
        final p = _electricalProducts[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: CustomImageWidget(
                  imageUrl: p['imageUrl'] as String,
                  height: 100,
                  fit: BoxFit.cover,
                  semanticLabel: p['semanticLabel'] as String,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${p['quantity']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p['price'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (p['stock'] as String) == 'In Stock'
                                ? AppTheme.successContainer
                                : AppTheme.warningContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p['stock'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: (p['stock'] as String) == 'In Stock'
                                  ? AppTheme.success
                                  : AppTheme.warning,
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
      },
    );
  }

  Widget _buildNoProductsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(
            'No products listed.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This provider offers services, not products.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offers Placeholder Tab ────────────────────────────────
class _OffersPlaceholderTab extends StatelessWidget {
  const _OffersPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 48, color: AppTheme.outline),
          const SizedBox(height: 12),
          Text(
            'No active offers at the moment.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photos Tab ────────────────────────────────────────────
class _PhotosTab extends StatelessWidget {
  const _PhotosTab();

  static final List<Map<String, dynamic>> _media = [
    {
      'url':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c7e7c675-1772662996686.png',
      'label': 'Electrical panel installation work',
      'isVideo': false,
    },
    {
      'url':
          'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg',
      'label': 'Wiring work in progress',
      'isVideo': false,
    },
    {
      'url':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a5f1bd52-1773339653462.png',
      'label': 'Completed switchboard installation',
      'isVideo': false,
    },
    {
      'url': 'https://images.unsplash.com/photo-1614138865520-a2d570017fd6',
      'label': 'Previous work - fan installation',
      'isVideo': false,
    },
    {
      'url': 'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
      'label': 'AC wiring completed',
      'isVideo': true,
    },
    {
      'url':
          'https://images.pexels.com/photos/1108101/pexels-photo-1108101.jpeg',
      'label': 'Inverter setup video',
      'isVideo': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Photos & Videos (${_media.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _media.length,
            itemBuilder: (context, i) {
              final m = _media[i];
              return GestureDetector(
                onTap: () => _showMediaViewer(context, m),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        m['url'] as String,
                        fit: BoxFit.cover,
                        semanticLabel: m['label'] as String,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surfaceVariant,
                          child: const Icon(
                            Icons.image_rounded,
                            color: AppTheme.outline,
                          ),
                        ),
                      ),
                    ),
                    if (m['isVideo'] as bool)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.play_circle_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMediaViewer(BuildContext context, Map<String, dynamic> media) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                media['url'] as String,
                fit: BoxFit.contain,
                semanticLabel: media['label'] as String,
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reviews Tab ───────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  static final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Priya Kulkarni',
      'rating': 5,
      'date': '08 Apr 2024',
      'text':
          'Suresh bhai came within 20 minutes! Fixed the wiring issue perfectly. Very professional and honest pricing.',
      'service': 'Wiring Repair',
      'avatar': 'PK',
    },
    {
      'name': 'Rahul Deshmukh',
      'rating': 4,
      'date': '05 Apr 2024',
      'text':
          'Good work. Fan installation done quickly. Slight delay but overall satisfied.',
      'service': 'Fan Installation',
      'avatar': 'RD',
    },
    {
      'name': 'Anjali Patil',
      'rating': 5,
      'date': '01 Apr 2024',
      'text': 'खूपचांगले काम! MCB बदलली आणि सर्व ठीक झाले. Highly recommend!',
      'service': 'MCB Repair',
      'avatar': 'AP',
    },
    {
      'name': 'Vikram Shinde',
      'rating': 4,
      'date': '28 Mar 2024',
      'text':
          'AC wiring done properly. Price was fair. Will call again for future work.',
      'service': 'AC Wiring',
      'avatar': 'VS',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    '4.7',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                        color: const Color(0xFFFFA000),
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '132 Reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final pct = star == 5
                        ? 0.72
                        : star == 4
                        ? 0.18
                        : star == 3
                        ? 0.06
                        : star == 2
                        ? 0.02
                        : 0.02;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFA000),
                            size: 10,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFA000),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(pct * 100).round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review['avatar'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      review['date'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(
                      review['rating'] as int,
                      (_) => const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFA000),
                        size: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      review['service'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['text'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF44474E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
