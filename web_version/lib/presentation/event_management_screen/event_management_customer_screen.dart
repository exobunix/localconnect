import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/universal_enquiry_dialog.dart';
import './event_provider_detail_screen.dart';
import './event_subscription_screen.dart';

class EventManagementCustomerScreen extends StatefulWidget {
  const EventManagementCustomerScreen({super.key});

  @override
  State<EventManagementCustomerScreen> createState() =>
      _EventManagementCustomerScreenState();
}

class _EventManagementCustomerScreenState
    extends State<EventManagementCustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeSubcategory = 'photography';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _sortBy = 'rating';
  double _maxBudget = 100000;
  bool _verifiedOnly = false;
  bool _availableOnly = false;
  final Set<String> _favourites = {};
  bool _showSearch = false;

  static const _subcategories = [
    {
      'id': 'photography',
      'label': 'Photography',
      'icon': Icons.camera_alt_rounded,
      'color': Color(0xFFAD1457),
    },
    {
      'id': 'videography',
      'label': 'Videography',
      'icon': Icons.videocam_rounded,
      'color': Color(0xFF6A1B9A),
    },
    {
      'id': 'sound',
      'label': 'Sound & DJ',
      'icon': Icons.speaker_rounded,
      'color': Color(0xFF0277BD),
    },
    {
      'id': 'mandap',
      'label': 'Mandap Decor',
      'icon': Icons.temple_hindu_rounded,
      'color': Color(0xFFE65100),
    },
    {
      'id': 'birthday',
      'label': 'Birthday Decor',
      'icon': Icons.cake_rounded,
      'color': Color(0xFFC62828),
    },
    {
      'id': 'catering',
      'label': 'Catering',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFF00695C),
    },
    {
      'id': 'makeup',
      'label': 'Makeup Artist',
      'icon': Icons.face_retouching_natural_rounded,
      'color': Color(0xFF880E4F),
    },
    {
      'id': 'mehendi',
      'label': 'Mehendi Artist',
      'icon': Icons.brush_rounded,
      'color': Color(0xFF4E342E),
    },
    {
      'id': 'lighting',
      'label': 'Lighting Decor',
      'icon': Icons.lightbulb_rounded,
      'color': Color(0xFFF9A825),
    },
    {
      'id': 'planner',
      'label': 'Event Planner',
      'icon': Icons.event_note_rounded,
      'color': Color(0xFF1A237E),
    },
    {
      'id': 'anchor',
      'label': 'Anchor / Host',
      'icon': Icons.mic_rounded,
      'color': Color(0xFF37474F),
    },
    {
      'id': 'band',
      'label': 'Live Band',
      'icon': Icons.music_note_rounded,
      'color': Color(0xFF4A148C),
    },
    {
      'id': 'orchestra',
      'label': 'Orchestra',
      'icon': Icons.queue_music_rounded,
      'color': Color(0xFF1B5E20),
    },
    {
      'id': 'dance',
      'label': 'Dance Group',
      'icon': Icons.directions_run_rounded,
      'color': Color(0xFFBF360C),
    },
    {
      'id': 'generator',
      'label': 'Generator Rental',
      'icon': Icons.power_rounded,
      'color': Color(0xFF263238),
    },
    {
      'id': 'chair_table',
      'label': 'Chair & Table',
      'icon': Icons.chair_rounded,
      'color': Color(0xFF4E342E),
    },
    {
      'id': 'tent',
      'label': 'Tent House',
      'icon': Icons.holiday_village_rounded,
      'color': Color(0xFF37474F),
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> _mockProviders = {
    'photography': [
      {
        'id': 'ph1',
        'name': 'Kapil Photography Studio',
        'phone': '+919876543210',
        'rating': 4.9,
        'reviews': 312,
        'distance': 2.1,
        'startingPrice': 15000,
        'experience': '8 years',
        'verified': true,
        'available': true,
        'speciality': 'Wedding & Pre-Wedding',
        'isFeatured': true,
        'image':
            'https://images.unsplash.com/photo-1666594113600-5388bbe4f745?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
          'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=300',
        ],
        'tags': ['Wedding', 'Pre-Wedding', 'Drone', 'Candid'],
        'badge': 'Top Rated',
        'subcategoryDetails': {
          'specializations': [
            'Wedding',
            'Pre-Wedding',
            'Birthday',
            'Corporate',
            'Drone',
          ],
          'equipment': 'Canon EOS R5, Sony A7IV, DJI Drone',
          'albumPackages': true,
          'cinematicVideo': false,
        },
      },
      {
        'id': 'ph2',
        'name': 'Moments by Priya',
        'phone': '+919823456789',
        'rating': 4.7,
        'reviews': 198,
        'distance': 3.5,
        'startingPrice': 10000,
        'experience': '5 years',
        'verified': true,
        'available': true,
        'speciality': 'Candid & Portraits',
        'isFeatured': false,
        'image':
            'https://images.unsplash.com/photo-1687846492894-9e5d97bfd299?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
        ],
        'tags': ['Candid', 'Portraits', 'Birthday'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'specializations': ['Wedding', 'Birthday', 'Baby Shoot'],
          'equipment': 'Nikon Z6, 50mm f/1.4',
          'albumPackages': true,
          'cinematicVideo': false,
        },
      },
      {
        'id': 'ph3',
        'name': 'Lens & Light Studio',
        'phone': '+919812345678',
        'rating': 4.6,
        'reviews': 145,
        'distance': 4.8,
        'startingPrice': 8000,
        'experience': '4 years',
        'verified': false,
        'available': true,
        'speciality': 'Corporate & Events',
        'isFeatured': false,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1b616240d-1782963988964.png',
        'portfolio': [
          'https://images.pexels.com/photos/3379934/pexels-photo-3379934.jpeg?w=300',
        ],
        'tags': ['Corporate', 'Events', 'Product'],
        'badge': '',
        'subcategoryDetails': {
          'specializations': ['Corporate', 'Events', 'Product'],
          'equipment': 'Sony A7III',
          'albumPackages': false,
          'cinematicVideo': false,
        },
      },
    ],
    'videography': [
      {
        'id': 'v1',
        'name': 'CineFrame Productions',
        'phone': '+919867890123',
        'rating': 4.8,
        'reviews': 245,
        'distance': 1.8,
        'startingPrice': 20000,
        'experience': '10 years',
        'verified': true,
        'available': true,
        'speciality': 'Cinematic Wedding Films',
        'isFeatured': true,
        'image':
            'https://images.unsplash.com/photo-1724597971403-238014e88ef1?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?w=300',
        ],
        'tags': ['Cinematic', 'Wedding', 'Drone', 'Corporate'],
        'badge': 'Premium',
        'subcategoryDetails': {
          'specializations': ['Wedding', 'Pre-Wedding', 'Corporate', 'Drone'],
          'equipment': 'Sony FX3, DJI Ronin, Drone',
          'albumPackages': false,
          'cinematicVideo': true,
        },
      },
      {
        'id': 'v2',
        'name': 'Reel Stories Films',
        'phone': '+919845678901',
        'rating': 4.6,
        'reviews': 178,
        'distance': 3.2,
        'startingPrice': 15000,
        'experience': '7 years',
        'verified': true,
        'available': true,
        'speciality': 'Wedding & Pre-Wedding',
        'isFeatured': false,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1a135a7f5-1783271524761.png',
        'portfolio': [
          'https://images.pexels.com/photos/3379934/pexels-photo-3379934.jpeg?w=300',
        ],
        'tags': ['Wedding', 'Pre-Wedding', 'Cinematic'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'specializations': ['Wedding', 'Pre-Wedding'],
          'equipment': 'Canon C70, Gimbal',
          'albumPackages': false,
          'cinematicVideo': true,
        },
      },
    ],
    'sound': [
      {
        'id': 's1',
        'name': 'Raj Sound Systems',
        'phone': '+919834567890',
        'rating': 4.6,
        'reviews': 189,
        'distance': 4.2,
        'startingPrice': 8000,
        'experience': '12 years',
        'verified': true,
        'available': true,
        'speciality': 'Outdoor Events & Weddings',
        'isFeatured': true,
        'image': 'https://images.unsplash.com/photo-1675808414079-9bca1b396a1b',
        'portfolio': [
          'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?w=300',
        ],
        'tags': ['DJ', 'Sound System', 'Outdoor', 'Wedding'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'djPackages': [
            'Basic Sound ₹8,000',
            'DJ Setup ₹15,000',
            'Full Stage ₹25,000',
          ],
          'capacity': '5000 people',
          'indoorOutdoor': 'Both',
          'genres': ['Bollywood', 'EDM', 'Classical', 'Punjabi'],
        },
      },
      {
        'id': 's2',
        'name': 'Bass Drop DJ Services',
        'phone': '+919856789012',
        'rating': 4.5,
        'reviews': 134,
        'distance': 2.9,
        'startingPrice': 6000,
        'experience': '7 years',
        'verified': false,
        'available': true,
        'speciality': 'Birthday & Corporate Events',
        'isFeatured': false,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1fe19ede6-1772998415883.png',
        'portfolio': [
          'https://images.pexels.com/photos/2747449/pexels-photo-2747449.jpeg?w=300',
        ],
        'tags': ['DJ', 'Birthday', 'Corporate'],
        'badge': 'New',
        'subcategoryDetails': {
          'djPackages': ['Basic ₹6,000', 'Premium ₹12,000'],
          'capacity': '1000 people',
          'indoorOutdoor': 'Indoor',
          'genres': ['Bollywood', 'EDM'],
        },
      },
    ],
    'mandap': [
      {
        'id': 'm1',
        'name': 'Royal Mandap Decorators',
        'phone': '+919878901234',
        'rating': 4.9,
        'reviews': 156,
        'distance': 3.1,
        'startingPrice': 25000,
        'experience': '9 years',
        'verified': true,
        'available': true,
        'speciality': 'Traditional & Floral Mandap',
        'isFeatured': true,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_149491a26-1772090161435.png',
        'portfolio': [
          'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=300',
        ],
        'tags': ['Traditional', 'Floral', 'Stage', 'Wedding'],
        'badge': 'Premium',
        'subcategoryDetails': {
          'themes': ['Traditional', 'Modern', 'Floral', 'Royal'],
          'floralDecoration': true,
          'stageDecoration': true,
        },
      },
      {
        'id': 'm2',
        'name': 'Shubh Vivah Decorators',
        'phone': '+919890123456',
        'rating': 4.7,
        'reviews': 98,
        'distance': 5.2,
        'startingPrice': 18000,
        'experience': '6 years',
        'verified': true,
        'available': true,
        'speciality': 'Modern & Fusion Mandap',
        'isFeatured': false,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1fe19ede6-1772998415883.png',
        'portfolio': [
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
        ],
        'tags': ['Modern', 'Fusion', 'Floral'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'themes': ['Modern', 'Fusion', 'Minimalist'],
          'floralDecoration': true,
          'stageDecoration': true,
        },
      },
    ],
    'birthday': [
      {
        'id': 'bd1',
        'name': 'Happy Moments Decor',
        'phone': '+919801234567',
        'rating': 4.8,
        'reviews': 214,
        'distance': 2.4,
        'startingPrice': 3500,
        'experience': '6 years',
        'verified': true,
        'available': true,
        'speciality': 'Kids & Theme Birthday Parties',
        'isFeatured': true,
        'image': 'https://images.unsplash.com/photo-1717205963725-e2a7ac8f23ea',
        'portfolio': [
          'https://images.pexels.com/photos/1543762/pexels-photo-1543762.jpeg?w=300',
          'https://images.pexels.com/photos/796606/pexels-photo-796606.jpeg?w=300',
        ],
        'tags': ['Kids Party', 'Theme', 'Balloon', 'Custom'],
        'badge': 'Top Rated',
        'subcategoryDetails': {
          'themeDecorations': ['Unicorn', 'Superhero', 'Princess', 'Cars'],
          'balloonDecoration': true,
          'kidsPartySetup': true,
          'customPackages': true,
        },
      },
      {
        'id': 'bd2',
        'name': 'Party Splash Decorators',
        'phone': '+919812345670',
        'rating': 4.6,
        'reviews': 178,
        'distance': 3.8,
        'startingPrice': 2500,
        'experience': '4 years',
        'verified': true,
        'available': true,
        'speciality': 'Balloon & Stage Decoration',
        'isFeatured': false,
        'image': 'https://images.unsplash.com/photo-1502440332504-ca20c90cab5d',
        'portfolio': [
          'https://images.pexels.com/photos/796606/pexels-photo-796606.jpeg?w=300',
        ],
        'tags': ['Balloon', 'Stage', 'Birthday'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'themeDecorations': ['Balloon', 'Floral', 'LED'],
          'balloonDecoration': true,
          'kidsPartySetup': false,
          'customPackages': true,
        },
      },
    ],
    'catering': [
      {
        'id': 'c1',
        'name': 'Shree Caterers',
        'phone': '+919823456780',
        'rating': 4.8,
        'reviews': 421,
        'distance': 2.8,
        'startingPrice': 350,
        'experience': '15 years',
        'verified': true,
        'available': true,
        'speciality': 'Veg & Non-Veg Thali',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?w=300',
          'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?w=300',
        ],
        'tags': ['Veg', 'Non-Veg', 'Wedding', 'Corporate'],
        'badge': 'Top Rated',
        'subcategoryDetails': {
          'vegNonVeg': 'Both',
          'cuisines': [
            'North Indian',
            'South Indian',
            'Chinese',
            'Continental',
          ],
          'minGuests': 50,
          'maxCapacity': 2000,
          'pricePerPlate': '₹350 onwards',
          'hygieneCertified': true,
        },
      },
      {
        'id': 'c2',
        'name': 'Maharaja Catering Services',
        'phone': '+919834567891',
        'rating': 4.7,
        'reviews': 312,
        'distance': 4.1,
        'startingPrice': 450,
        'experience': '12 years',
        'verified': true,
        'available': true,
        'speciality': 'Royal Wedding Catering',
        'isFeatured': false,
        'image': 'https://images.unsplash.com/photo-1726595453343-63c019136a57',
        'portfolio': [
          'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg?w=300',
        ],
        'tags': ['Veg', 'Wedding', 'Royal'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'vegNonVeg': 'Veg',
          'cuisines': ['North Indian', 'Rajasthani', 'Gujarati'],
          'minGuests': 100,
          'maxCapacity': 5000,
          'pricePerPlate': '₹450 onwards',
          'hygieneCertified': true,
        },
      },
    ],
    'makeup': [
      {
        'id': 'mu1',
        'name': 'Glamour by Sneha',
        'phone': '+919845678902',
        'rating': 4.9,
        'reviews': 287,
        'distance': 1.5,
        'startingPrice': 5000,
        'experience': '7 years',
        'verified': true,
        'available': true,
        'speciality': 'Bridal & Party Makeup',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?w=300',
        ],
        'tags': ['Bridal', 'HD Makeup', 'Airbrush', 'Party'],
        'badge': 'Top Rated',
        'subcategoryDetails': {
          'makeupTypes': ['Bridal', 'Party', 'Groom', 'HD Makeup', 'Airbrush'],
          'brands': 'MAC, Huda Beauty, Airbrush',
        },
      },
      {
        'id': 'mu2',
        'name': 'Blush & Glow Studio',
        'phone': '+919856789013',
        'rating': 4.7,
        'reviews': 198,
        'distance': 2.9,
        'startingPrice': 3500,
        'experience': '5 years',
        'verified': true,
        'available': true,
        'speciality': 'HD & Airbrush Makeup',
        'isFeatured': false,
        'image':
            'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?w=300',
        ],
        'tags': ['HD Makeup', 'Airbrush', 'Bridal'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'makeupTypes': ['HD Makeup', 'Airbrush', 'Bridal', 'Party'],
          'brands': 'Kryolan, Inglot',
        },
      },
    ],
    'mehendi': [
      {
        'id': 'me1',
        'name': 'Fatima Mehendi Art',
        'phone': '+919867890124',
        'rating': 4.8,
        'reviews': 342,
        'distance': 2.3,
        'startingPrice': 2000,
        'experience': '11 years',
        'verified': true,
        'available': true,
        'speciality': 'Bridal & Arabic Mehendi',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=300',
        ],
        'tags': ['Bridal', 'Arabic', 'Traditional', 'Modern'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'mehendiStyles': [
            'Bridal Mehendi',
            'Arabic',
            'Traditional',
            'Modern',
          ],
          'pricePerHand': '₹500 onwards',
          'organicHenna': true,
        },
      },
      {
        'id': 'me2',
        'name': 'Henna Craft by Riya',
        'phone': '+919878901235',
        'rating': 4.6,
        'reviews': 215,
        'distance': 3.7,
        'startingPrice': 1500,
        'experience': '6 years',
        'verified': false,
        'available': true,
        'speciality': 'Arabic & Modern Mehendi',
        'isFeatured': false,
        'image':
            'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=300',
        ],
        'tags': ['Arabic', 'Modern', 'Bridal'],
        'badge': '',
        'subcategoryDetails': {
          'mehendiStyles': ['Arabic', 'Modern', 'Indo-Arabic'],
          'pricePerHand': '₹400 onwards',
          'organicHenna': true,
        },
      },
    ],
    'lighting': [
      {
        'id': 'li1',
        'name': 'Bright Events Lighting',
        'phone': '+919890123457',
        'rating': 4.7,
        'reviews': 167,
        'distance': 3.2,
        'startingPrice': 10000,
        'experience': '8 years',
        'verified': true,
        'available': true,
        'speciality': 'LED & Fairy Light Setups',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/1190298/pexels-photo-1190298.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1190298/pexels-photo-1190298.jpeg?w=300',
        ],
        'tags': ['LED', 'Fairy Lights', 'Stage', 'Outdoor'],
        'badge': 'Top Rated',
        'subcategoryDetails': {
          'lightingTypes': ['Decorative', 'Wedding', 'Stage', 'Outdoor'],
          'equipment': 'LED Strips, Fairy Lights, Spotlights, Laser',
        },
      },
    ],
    'planner': [
      {
        'id': 'pl1',
        'name': 'Dream Events Co.',
        'phone': '+919801234568',
        'rating': 4.9,
        'reviews': 98,
        'distance': 5.0,
        'startingPrice': 50000,
        'experience': '14 years',
        'verified': true,
        'available': true,
        'speciality': 'Complete Wedding Planning',
        'isFeatured': true,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_15273b021-1771901884827.png',
        'portfolio': [
          'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=300',
        ],
        'tags': ['Wedding', 'Corporate', 'Birthday', 'End-to-End'],
        'badge': 'Premium',
        'subcategoryDetails': {
          'eventTypes': [
            'Wedding Planning',
            'Birthday Planning',
            'Corporate Events',
            'Religious Events',
            'End-to-End Management',
          ],
          'teamSize': 10,
        },
      },
      {
        'id': 'pl2',
        'name': 'Celebrations Unlimited',
        'phone': '+919812345671',
        'rating': 4.7,
        'reviews': 76,
        'distance': 6.5,
        'startingPrice': 35000,
        'experience': '9 years',
        'verified': true,
        'available': true,
        'speciality': 'Birthday & Corporate Events',
        'isFeatured': false,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1fe19ede6-1772998415883.png',
        'portfolio': [
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
        ],
        'tags': ['Birthday', 'Corporate', 'Religious'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'eventTypes': [
            'Birthday Planning',
            'Corporate Events',
            'Religious Events',
          ],
          'teamSize': 6,
        },
      },
    ],
    'anchor': [
      {
        'id': 'an1',
        'name': 'Vivek Sharma - Anchor',
        'phone': '+919823456781',
        'rating': 4.8,
        'reviews': 203,
        'distance': 2.7,
        'startingPrice': 8000,
        'experience': '9 years',
        'verified': true,
        'available': true,
        'speciality': 'Wedding & Corporate Host',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/2608517/pexels-photo-2608517.jpeg?w=300',
        ],
        'tags': ['Wedding', 'Corporate', 'Birthday', 'Bilingual'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'hostTypes': ['Wedding Host', 'Corporate Host', 'Birthday Host'],
          'languages': ['Hindi', 'English', 'Marathi'],
          'experience': '9 years',
        },
      },
    ],
    'band': [
      {
        'id': 'lb1',
        'name': 'The Harmony Band',
        'phone': '+919834567892',
        'rating': 4.7,
        'reviews': 145,
        'distance': 4.5,
        'startingPrice': 15000,
        'experience': '10 years',
        'verified': true,
        'available': true,
        'speciality': 'Bollywood & Fusion Live Music',
        'isFeatured': true,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_13369b6e6-1766437337876.png',
        'portfolio': [
          'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?w=300',
        ],
        'tags': ['Bollywood', 'Fusion', 'Wedding', 'Corporate'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'performanceType': 'Live Band',
          'teamSize': 8,
          'duration': '2-4 hours',
          'genres': ['Bollywood', 'Fusion', 'Classical', 'Pop'],
        },
      },
    ],
    'orchestra': [
      {
        'id': 'or1',
        'name': 'Swar Sangam Orchestra',
        'phone': '+919845678903',
        'rating': 4.9,
        'reviews': 87,
        'distance': 6.2,
        'startingPrice': 25000,
        'experience': '20 years',
        'verified': true,
        'available': true,
        'speciality': 'Classical & Bollywood Orchestra',
        'isFeatured': true,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1d41b268c-1766902995548.png',
        'portfolio': [
          'https://images.pexels.com/photos/2747449/pexels-photo-2747449.jpeg?w=300',
        ],
        'tags': ['Classical', 'Bollywood', 'Wedding', 'Cultural'],
        'badge': 'Premium',
        'subcategoryDetails': {
          'performanceType': 'Orchestra',
          'teamSize': 20,
          'duration': '3-5 hours',
          'genres': ['Classical', 'Bollywood', 'Devotional'],
        },
      },
    ],
    'dance': [
      {
        'id': 'dg1',
        'name': 'Rhythm Dance Academy',
        'phone': '+919856789014',
        'rating': 4.8,
        'reviews': 167,
        'distance': 3.4,
        'startingPrice': 12000,
        'experience': '8 years',
        'verified': true,
        'available': true,
        'speciality': 'Bollywood & Folk Dance',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/1190298/pexels-photo-1190298.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1190298/pexels-photo-1190298.jpeg?w=300',
        ],
        'tags': ['Bollywood', 'Folk', 'Wedding', 'Corporate'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'performanceType': 'Dance Group',
          'teamSize': 12,
          'duration': '30-60 min',
          'genres': ['Bollywood', 'Folk', 'Classical', 'Western'],
        },
      },
    ],
    'generator': [
      {
        'id': 'gen1',
        'name': 'PowerGen Rentals',
        'phone': '+919867890125',
        'rating': 4.6,
        'reviews': 134,
        'distance': 5.1,
        'startingPrice': 3000,
        'experience': '10 years',
        'verified': true,
        'available': true,
        'speciality': 'Event & Industrial Generators',
        'isFeatured': true,
        'image':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1470ae6d4-1783272779737.png',
        'portfolio': [
          'https://images.pexels.com/photos/3379934/pexels-photo-3379934.jpeg?w=300',
        ],
        'tags': ['Event', 'Industrial', 'Delivery', 'Silent'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'capacity': '5KVA - 125KVA',
          'fuelType': 'Diesel',
          'rentalDuration': 'Daily/Weekly',
          'deliveryAvailable': true,
        },
      },
    ],
    'chair_table': [
      {
        'id': 'ct1',
        'name': 'Event Furniture Hub',
        'phone': '+919878901236',
        'rating': 4.5,
        'reviews': 198,
        'distance': 3.8,
        'startingPrice': 1500,
        'experience': '7 years',
        'verified': true,
        'available': true,
        'speciality': 'Wedding & Event Furniture',
        'isFeatured': true,
        'image': 'https://images.unsplash.com/photo-1660511057210-f7fba78d2741',
        'portfolio': [
          'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
        ],
        'tags': ['Chairs', 'Tables', 'Wedding', 'Corporate'],
        'badge': 'Verified',
        'subcategoryDetails': {
          'chairTypes': ['Banquet', 'Chiavari', 'Folding', 'Sofa'],
          'tableTypes': ['Round', 'Rectangular', 'Cocktail'],
          'quantityAvailable': '500+ chairs, 100+ tables',
          'deliveryCharges': '₹500 onwards',
        },
      },
    ],
    'tent': [
      {
        'id': 'th1',
        'name': 'Grand Tent House',
        'phone': '+919890123458',
        'rating': 4.7,
        'reviews': 156,
        'distance': 4.2,
        'startingPrice': 15000,
        'experience': '12 years',
        'verified': true,
        'available': true,
        'speciality': 'Wedding & Event Tents',
        'isFeatured': true,
        'image':
            'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=400',
        'portfolio': [
          'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=300',
        ],
        'tags': ['Wedding', 'Outdoor', 'Stage', 'Lighting'],
        'badge': 'Premium',
        'subcategoryDetails': {
          'tentTypes': ['Shamiyana', 'Pagoda', 'Stretch Tent', 'Dome'],
'stageSetup': true,
          'decoration': true,
          'seatingArrangements': true,
          'lightingPackages': true,
        },
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
          .or('category.ilike.%events%,category.ilike.%Event Management%')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in response) {
        final sub = (row['subcategory'] as String? ?? '').toLowerCase().trim();
        String subKey = 'photography';
        if (sub.contains('photo')) subKey = 'photography';
        else if (sub.contains('video')) subKey = 'videography';
        else if (sub.contains('sound') || sub.contains('dj')) subKey = 'sound';
        else if (sub.contains('mandap')) subKey = 'mandap';
        else if (sub.contains('birth')) subKey = 'birthday';
        else if (sub.contains('cater')) subKey = 'catering';
        else if (sub.contains('makeup')) subKey = 'makeup';
        else if (sub.contains('mehendi') || sub.contains('mehndi')) subKey = 'mehendi';
        else if (sub.contains('light')) subKey = 'lighting';
        else if (sub.contains('plan')) subKey = 'planner';
        else if (sub.contains('anchor') || sub.contains('host')) subKey = 'anchor';
        else if (sub.contains('band')) subKey = 'band';
        else if (sub.contains('orchestra')) subKey = 'orchestra';
        else if (sub.contains('dance')) subKey = 'dance';
        else if (sub.contains('gen')) subKey = 'generator';
        else if (sub.contains('chair') || sub.contains('table')) subKey = 'chair_table';
        else if (sub.contains('tent')) subKey = 'tent';

        final charges = (row['charges'] as List?) ?? [];
        final firstCharge = charges.isNotEmpty ? charges.first : null;
        final chargeVal = firstCharge != null ? (firstCharge['base_price'] as num?)?.toDouble() ?? 5000.0 : 5000.0;

        final mapped = {
          'id': row['id'],
          'name': row['business_name'] ?? row['owner_name'] ?? 'Provider',
          'phone': row['phone'] ?? '+919876543210',
          'rating': (row['rating'] as num?)?.toDouble() ?? 4.8,
          'reviews': (row['review_count'] as num?)?.toInt() ?? 100,
          'distance': 2.0,
          'startingPrice': chargeVal.toInt(),
          'experience': '${row['years_experience'] ?? 6} years',
          'verified': row['is_verified'] == true || row['registration_status'] == 'approved',
          'available': row['is_open'] != false,
          'speciality': row['description'] ?? '${row['subcategory']} Services',
          'isFeatured': true,
          'image': row['image_url'] ?? '',
          'portfolio': (row['gallery_photos'] as List?)?.isNotEmpty == true
              ? row['gallery_photos']
              : (row['image_url'] != null ? [row['image_url']] : []),
          'tags': [row['subcategory'] ?? 'Events', 'Professional'],
          'badge': 'Verified',
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

  Map<String, dynamic> get _activeSubcategoryData =>
      _subcategories.firstWhere((s) => s['id'] == _activeSubcategory);

  Color get _activeColor => _activeSubcategoryData['color'] as Color;

  List<Map<String, dynamic>> get _filteredProviders {
    final liveList = _liveProviders[_activeSubcategory];
    final all = (liveList != null && liveList.isNotEmpty)
        ? liveList
        : (_mockProviders[_activeSubcategory] ?? []);
    var filtered = all.where((p) {
      if (_verifiedOnly && p['verified'] != true) return false;
      if (_availableOnly && p['available'] != true) return false;
      if ((p['startingPrice'] as num) > _maxBudget) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p['name'] as String).toLowerCase();
        final speciality = (p['speciality'] as String).toLowerCase();
        final tags = (p['tags'] as List).join(' ').toLowerCase();
        if (!name.contains(q) && !speciality.contains(q) && !tags.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        filtered.sort(
          (a, b) => (b['rating'] as num).compareTo(a['rating'] as num),
        );
        break;
      case 'distance':
        filtered.sort(
          (a, b) => (a['distance'] as num).compareTo(b['distance'] as num),
        );
        break;
      case 'price_low':
        filtered.sort(
          (a, b) =>
              (a['startingPrice'] as num).compareTo(b['startingPrice'] as num),
        );
        break;
      case 'price_high':
        filtered.sort(
          (a, b) =>
              (b['startingPrice'] as num).compareTo(a['startingPrice'] as num),
        );
        break;
      case 'popular':
        filtered.sort(
          (a, b) => (b['reviews'] as num).compareTo(a['reviews'] as num),
        );
        break;
    }
    return filtered;
  }

  List<Map<String, dynamic>> get _featuredProviders {
    final all = <Map<String, dynamic>>[];
    for (final sub in _subcategories) {
      final liveList = _liveProviders[sub['id']];
      final providers = (liveList != null && liveList.isNotEmpty)
          ? liveList
          : (_mockProviders[sub['id']] ?? []);
      for (final p in providers) {
        if (p['isFeatured'] == true) {
          all.add({...p, 'subcategory': sub});
        }
      }
    }
    return all;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subcategories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(
          () => _activeSubcategory =
              _subcategories[_tabController.index]['id'] as String,
        );
      }
    });
    _fetchProvidersFromDb();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        sortBy: _sortBy,
        maxBudget: _maxBudget,
        verifiedOnly: _verifiedOnly,
        availableOnly: _availableOnly,
        activeColor: _activeColor,
        onApply: (sort, budget, verified, available) {
          setState(() {
            _sortBy = sort;
            _maxBudget = budget;
            _verifiedOnly = verified;
            _availableOnly = available;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: _activeColor,
            foregroundColor: Colors.white,
            title: _showSearch
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search ${_activeSubcategoryData['label']}...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : Text(
                    'Event Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                ),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _showFilterSheet,
              ),
              IconButton(
                icon: const Icon(Icons.add_business_rounded),
                tooltip: 'List Your Service',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventSubscriptionScreen(),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_activeColor, _activeColor.withAlpha(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double appBarHeight = constraints.maxHeight;
                    final double opacity = ((appBarHeight - 110) / (180 - 110)).clamp(0.0, 1.0);
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 56),
                        child: AnimatedOpacity(
                          opacity: opacity,
                          duration: Duration.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Find the Best',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _activeSubcategoryData['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredProviders.length} providers near you',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: _activeColor,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                  ),
                  tabs: _subcategories
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
        body: TabBarView(
          controller: _tabController,
          children: _subcategories
              .map(
                (sub) => _SubcategoryTab(
                  subcategory: sub,
                  providers: _filteredProviders,
                  featuredProviders: _featuredProviders,
                  favourites: _favourites,
                  isDark: isDark,
                  sortBy: _sortBy,
                  onFavouriteToggle: (id) => setState(() {
                    if (_favourites.contains(id)) {
                      _favourites.remove(id);
                    } else {
                      _favourites.add(id);
                    }
                  }),
                  onProviderTap: (provider) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventProviderDetailScreen(
                        provider: provider,
                        subcategory: sub,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Subcategory Tab ───────────────────────────────────────────────────────────
class _SubcategoryTab extends StatelessWidget {
  final Map<String, dynamic> subcategory;
  final List<Map<String, dynamic>> providers;
  final List<Map<String, dynamic>> featuredProviders;
  final Set<String> favourites;
  final bool isDark;
  final String sortBy;
  final ValueChanged<String> onFavouriteToggle;
  final ValueChanged<Map<String, dynamic>> onProviderTap;

  const _SubcategoryTab({
    required this.subcategory,
    required this.providers,
    required this.featuredProviders,
    required this.favourites,
    required this.isDark,
    required this.sortBy,
    required this.onFavouriteToggle,
    required this.onProviderTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = subcategory['color'] as Color;
    final subFeatured = featuredProviders
        .where((p) => (p['subcategory'] as Map)['id'] == subcategory['id'])
        .toList();

    return CustomScrollView(
      slivers: [
        // Featured Providers Carousel
        if (subFeatured.isNotEmpty) ...[
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
                          const Color(0xFFFFB300),
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
                        const SizedBox(width: 4),
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
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: subFeatured.length,
                itemBuilder: (_, i) => _FeaturedCard(
                  provider: subFeatured[i],
                  color: color,
                  isFavourite: favourites.contains(subFeatured[i]['id']),
                  onFavourite: () =>
                      onFavouriteToggle(subFeatured[i]['id'] as String),
                  onTap: () => onProviderTap(subFeatured[i]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'All Providers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${providers.length} found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'All Providers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${providers.length} found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Provider List
        providers.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        subcategory['icon'] as IconData,
                        size: 56,
                        color: color.withAlpha(80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No providers found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try adjusting your filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProviderCard(
                    provider: providers[i],
                    color: color,
                    isDark: isDark,
                    isFavourite: favourites.contains(providers[i]['id']),
                    onFavourite: () =>
                        onFavouriteToggle(providers[i]['id'] as String),
                    onTap: () => onProviderTap(providers[i]),
                  ),
                  childCount: providers.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Featured Card ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color color;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.provider,
    required this.color,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                provider['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: color.withAlpha(40)),
                semanticLabel:
                    '${provider['name']} featured event service provider cover photo',
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(200)],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Featured',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onFavourite,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavourite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavourite ? Colors.red : Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${provider['rating']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${_formatPrice(provider['startingPrice'] as num)}+',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white70,
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
      ),
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toString();
  }
}

// ── Provider Card ─────────────────────────────────────────────────────────────
class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final Color color;
  final bool isDark;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.color,
    required this.isDark,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
  });

  String _formatPrice(num price) {
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '₹${(price / 1000).toStringAsFixed(0)}K';
    return '₹$price';
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = (provider['portfolio'] as List?)?.cast<String>() ?? [];
    final tags = (provider['tags'] as List?)?.cast<String>() ?? [];
    final badge = provider['badge'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2023) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Image.network(
                      provider['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(height: 160, color: color.withAlpha(30)),
                      semanticLabel:
                          '${provider['name']} event service provider cover image',
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(120),
                          ],
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
                        if (provider['isFeatured'] == true)
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
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
                                const SizedBox(width: 3),
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
                        if (provider['verified'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success,
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
                                const SizedBox(width: 3),
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
                  // Favourite
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavourite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavourite ? Colors.red : Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Portfolio strip
                  if (portfolio.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Row(
                        children: portfolio
                            .take(3)
                            .map(
                              (url) => Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(left: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: color.withAlpha(60)),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badge.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      badge,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              provider['speciality'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${provider['rating']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8B6914),
                              ),
                            ),
                            Text(
                              ' (${provider['reviews']})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Distance
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${provider['distance']} km',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Experience
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline_rounded,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            provider['experience'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tags
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: tags
                        .take(4)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // Price + CTA
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _formatPrice(provider['startingPrice'] as num),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          UniversalEnquiryDialog.show(
                            context,
                            providerId: provider['id'] as String? ?? 'event_p',
                            providerName: provider['name'] as String? ?? 'Event Partner',
                            providerImage: provider['image'] as String?,
                            providerRating: (provider['rating'] as num?)?.toDouble() ?? 4.8,
                            category: 'Event Management',
                            subcategory: provider['speciality'] as String? ?? 'Events',
                            serviceTitle: provider['speciality'] as String? ?? 'Event Service',
                            basePrice: 'From ${_formatPrice(provider['startingPrice'] as num)}',
                            themeColor: color,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Enquiry',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.bookingCheckoutScreen,
                            arguments: {
                              'providerId': provider['id'] as String?,
                              'providerName': provider['name'] as String? ?? 'Event Partner',
                              'providerImage': provider['image'] as String? ?? '',
                              'providerRating': (provider['rating'] as num?)?.toDouble() ?? 4.8,
                              'service': provider['speciality'] as String? ?? 'Event Management',
                              'category': 'event_management',
                              'amount': _formatPrice(provider['startingPrice'] as num),
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                            fontSize: 11.5,
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
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _QuickActionBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(60)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String sortBy;
  final double maxBudget;
  final bool verifiedOnly;
  final bool availableOnly;
  final Color activeColor;
  final Function(String, double, bool, bool) onApply;

  const _FilterSheet({
    required this.sortBy,
    required this.maxBudget,
    required this.verifiedOnly,
    required this.availableOnly,
    required this.activeColor,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sortBy;
  late double _maxBudget;
  late bool _verifiedOnly;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _maxBudget = widget.maxBudget;
    _verifiedOnly = widget.verifiedOnly;
    _availableOnly = widget.availableOnly;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.activeColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2023) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            children: [
              Text(
                'Filter & Sort',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortBy = 'rating';
                    _maxBudget = 100000;
                    _verifiedOnly = false;
                    _availableOnly = false;
                  });
                },
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sort By',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                [
                      {'id': 'rating', 'label': 'Top Rated'},
                      {'id': 'distance', 'label': 'Nearest'},
                      {'id': 'price_low', 'label': 'Price: Low to High'},
                      {'id': 'price_high', 'label': 'Price: High to Low'},
                      {'id': 'popular', 'label': 'Most Popular'},
                    ]
                    .map(
                      (s) => GestureDetector(
                        onTap: () => setState(() => _sortBy = s['id']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _sortBy == s['id']
                                ? color
                                : color.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s['label']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _sortBy == s['id'] ? Colors.white : color,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Max Budget',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '₹${(_maxBudget / 1000).toStringAsFixed(0)}K',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxBudget,
            min: 1000,
            max: 100000,
            divisions: 99,
            activeColor: color,
            onChanged: (v) => setState(() => _maxBudget = v),
          ),
          Row(
            children: [
              Expanded(
                child: _FilterToggle(
                  label: 'Verified Only',
                  icon: Icons.verified_rounded,
                  value: _verifiedOnly,
                  color: color,
                  onChanged: (v) => setState(() => _verifiedOnly = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterToggle(
                  label: 'Available Now',
                  icon: Icons.event_available_rounded,
                  value: _availableOnly,
                  color: color,
                  onChanged: (v) => setState(() => _availableOnly = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _sortBy,
                  _maxBudget,
                  _verifiedOnly,
                  _availableOnly,
                );
                Navigator.pop(context);
              },
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
                'Apply Filters',
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

class _FilterToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _FilterToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? color.withAlpha(20) : Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? color : Colors.grey.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: value ? color : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: value ? color : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value ? color : Colors.grey),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
