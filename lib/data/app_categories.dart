import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubCategory {
  final String id;
  final String name;
  final String nameMarathi;
  final IconData icon;

  const SubCategory({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.icon,
  });
}

class AppCategory {
  final String id;
  final String name;
  final String nameMarathi;
  final IconData icon;
  final Color color;
  final List<SubCategory> subcategories;
  final bool hasProducts;
  final bool hasOffers;

  const AppCategory({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.icon,
    required this.color,
    required this.subcategories,
    this.hasProducts = false,
    this.hasOffers = false,
  });
}

class AppCategories {
  static const List<AppCategory> all = [
    AppCategory(
      id: 'shop',
      name: 'Shop',
      nameMarathi: 'दुकान',
      icon: Icons.storefront_rounded,
      color: AppTheme.catGrocery,
      hasProducts: true,
      hasOffers: true,
      subcategories: [
        SubCategory(
          id: 'grocery',
          name: 'Grocery / Kirana',
          nameMarathi: 'किराणा',
          icon: Icons.shopping_basket_rounded,
        ),
        SubCategory(
          id: 'electrical',
          name: 'Electrical & Hardware',
          nameMarathi: 'इलेक्ट्रिकल',
          icon: Icons.electrical_services_rounded,
        ),
        SubCategory(
          id: 'mutton_chicken',
          name: 'Mutton, Chicken & Fish',
          nameMarathi: 'मटण, चिकन, मासे',
          icon: Icons.set_meal_rounded,
        ),
        SubCategory(
          id: 'vegetables',
          name: 'Vegetables & Fruits',
          nameMarathi: 'भाजीपाला',
          icon: Icons.eco_rounded,
        ),
        SubCategory(
          id: 'seasonal',
          name: 'Seasonal Items',
          nameMarathi: 'हंगामी वस्तू',
          icon: Icons.wb_sunny_rounded,
        ),
        SubCategory(
          id: 'others_shop',
          name: 'Others',
          nameMarathi: 'इतर',
          icon: Icons.more_horiz_rounded,
        ),
      ],
    ),
    AppCategory(
      id: 'transport',
      name: 'Transport',
      nameMarathi: 'वाहतूक',
      icon: Icons.local_taxi_rounded,
      color: AppTheme.catTransport,
      subcategories: [
        SubCategory(
          id: 'rickshaw',
          name: 'Auto Rickshaw',
          nameMarathi: 'रिक्षा',
          icon: Icons.electric_rickshaw_rounded,
        ),
        SubCategory(
          id: 'tempo',
          name: 'Tempo',
          nameMarathi: 'टेम्पो',
          icon: Icons.airport_shuttle_rounded,
        ),
        SubCategory(
          id: 'pickup_van',
          name: 'Pickup Van',
          nameMarathi: 'पिकअप व्हॅन',
          icon: Icons.local_shipping_rounded,
        ),
        SubCategory(
          id: 'truck',
          name: 'Truck',
          nameMarathi: 'ट्रक',
          icon: Icons.fire_truck_rounded,
        ),
        SubCategory(
          id: 'car',
          name: 'Car (Taxi)',
          nameMarathi: 'कार',
          icon: Icons.directions_car_rounded,
        ),
      ],
    ),
    AppCategory(
      id: 'home_maintenance',
      name: 'Home Maintenance',
      nameMarathi: 'घर देखभाल',
      icon: Icons.home_repair_service_rounded,
      color: AppTheme.catPlumbing,
      subcategories: [
        SubCategory(
          id: 'plumber',
          name: 'Plumber',
          nameMarathi: 'प्लंबर',
          icon: Icons.plumbing_rounded,
        ),
        SubCategory(
          id: 'electrician',
          name: 'Electrician',
          nameMarathi: 'इलेक्ट्रिशन',
          icon: Icons.electrical_services_rounded,
        ),
        SubCategory(
          id: 'painter',
          name: 'Painter',
          nameMarathi: 'रंगारी',
          icon: Icons.format_paint_rounded,
        ),
        SubCategory(
          id: 'mason',
          name: 'Mason',
          nameMarathi: 'गवंडी',
          icon: Icons.construction_rounded,
        ),
        SubCategory(
          id: 'carpenter',
          name: 'Carpenter',
          nameMarathi: 'सुतार',
          icon: Icons.carpenter_rounded,
        ),
        SubCategory(
          id: 'daily_wage',
          name: 'Daily Wage Worker',
          nameMarathi: 'मजूर',
          icon: Icons.engineering_rounded,
        ),
        SubCategory(
          id: 'cleaning',
          name: 'Cleaning Services',
          nameMarathi: 'सफाई सेवा',
          icon: Icons.cleaning_services_rounded,
        ),
      ],
    ),
    AppCategory(
      id: 'delivery',
      name: 'Delivery',
      nameMarathi: 'डिलिव्हरी',
      icon: Icons.delivery_dining_rounded,
      color: AppTheme.catDelivery,
      subcategories: [
        SubCategory(
          id: 'food',
          name: 'Food Delivery',
          nameMarathi: 'फूड डिलिव्हरी',
          icon: Icons.fastfood_rounded,
        ),
        SubCategory(
          id: 'grocery',
          name: 'Grocery Delivery',
          nameMarathi: 'किराणा डिलिव्हरी',
          icon: Icons.shopping_basket_rounded,
        ),
        SubCategory(
          id: 'medicine',
          name: 'Medicine Delivery',
          nameMarathi: 'औषध डिलिव्हरी',
          icon: Icons.medication_rounded,
        ),
        SubCategory(
          id: 'parcel',
          name: 'Parcel & Document',
          nameMarathi: 'पार्सल व दस्तऐवज',
          icon: Icons.inventory_2_rounded,
        ),
        SubCategory(
          id: 'shop_purchase',
          name: 'Shop Purchase & Delivery',
          nameMarathi: 'दुकान खरेदी डिलिव्हरी',
          icon: Icons.storefront_rounded,
        ),
        SubCategory(
          id: 'pickup_drop',
          name: 'Pickup & Drop',
          nameMarathi: 'पिकअप व ड्रॉप',
          icon: Icons.swap_horiz_rounded,
        ),
        SubCategory(
          id: 'heavy',
          name: 'Heavy Item Delivery',
          nameMarathi: 'जड वस्तू डिलिव्हरी',
          icon: Icons.help_outline,
        ),
        SubCategory(
          id: 'express',
          name: 'Express Delivery',
          nameMarathi: 'एक्सप्रेस डिलिव्हरी',
          icon: Icons.bolt_rounded,
        ),
        SubCategory(
          id: 'scheduled',
          name: 'Scheduled Delivery',
          nameMarathi: 'शेड्युल्ड डिलिव्हरी',
          icon: Icons.schedule_rounded,
        ),
        SubCategory(
          id: 'intercity',
          name: 'Intercity Delivery',
          nameMarathi: 'आंतरशहर डिलिव्हरी',
          icon: Icons.connecting_airports_rounded,
        ),
      ],
    ),
    AppCategory(
      id: 'rent',
      name: 'Rent',
      nameMarathi: 'भाड्याने',
      icon: Icons.home_rounded,
      color: AppTheme.catRent,
      subcategories: [
        SubCategory(
          id: 'room',
          name: 'Room',
          nameMarathi: 'खोली',
          icon: Icons.bedroom_parent_rounded,
        ),
        SubCategory(
          id: 'pg',
          name: 'PG',
          nameMarathi: 'पीजी',
          icon: Icons.apartment_rounded,
        ),
        SubCategory(
          id: 'hostel',
          name: 'Hostel',
          nameMarathi: 'हॉस्टेल',
          icon: Icons.hotel_rounded,
        ),
        SubCategory(
          id: 'villa',
          name: 'Villa / Holiday Home',
          nameMarathi: 'व्हिला',
          icon: Icons.villa_rounded,
        ),
        SubCategory(
          id: 'tools',
          name: 'Tools & Equipment',
          nameMarathi: 'साधने',
          icon: Icons.build_rounded,
        ),
      ],
    ),
    AppCategory(
      id: 'events',
      name: 'Event Management',
      nameMarathi: 'कार्यक्रम व्यवस्थापन',
      icon: Icons.celebration_rounded,
      color: AppTheme.catEvents,
      hasProducts: true,
      hasOffers: true,
      subcategories: [
        SubCategory(
          id: 'photography',
          name: 'Photography',
          nameMarathi: 'फोटोग्राफी',
          icon: Icons.camera_alt_rounded,
        ),
        SubCategory(
          id: 'videography',
          name: 'Videography',
          nameMarathi: 'व्हिडिओग्राफी',
          icon: Icons.videocam_rounded,
        ),
        SubCategory(
          id: 'sound',
          name: 'Sound System',
          nameMarathi: 'साउंड सिस्टम',
          icon: Icons.speaker_rounded,
        ),
        SubCategory(
          id: 'dj',
          name: 'DJ Services',
          nameMarathi: 'डीजे सेवा',
          icon: Icons.music_note_rounded,
        ),
        SubCategory(
          id: 'mandap',
          name: 'Mandap Decoration',
          nameMarathi: 'मंडप सजावट',
          icon: Icons.temple_hindu_rounded,
        ),
        SubCategory(
          id: 'birthday',
          name: 'Birthday Decoration',
          nameMarathi: 'वाढदिवस सजावट',
          icon: Icons.cake_rounded,
        ),
        SubCategory(
          id: 'wedding',
          name: 'Wedding Decoration',
          nameMarathi: 'लग्न सजावट',
          icon: Icons.favorite_rounded,
        ),
        SubCategory(
          id: 'balloon',
          name: 'Balloon Decoration',
          nameMarathi: 'फुगे सजावट',
          icon: Icons.celebration_rounded,
        ),
        SubCategory(
          id: 'flower',
          name: 'Flower Decoration',
          nameMarathi: 'फुल सजावट',
          icon: Icons.local_florist_rounded,
        ),
        SubCategory(
          id: 'lighting',
          name: 'Lighting Decoration',
          nameMarathi: 'लाइटिंग सजावट',
          icon: Icons.lightbulb_rounded,
        ),
        SubCategory(
          id: 'catering',
          name: 'Catering',
          nameMarathi: 'केटरिंग',
          icon: Icons.restaurant_rounded,
        ),
        SubCategory(
          id: 'mehendi',
          name: 'Mehendi Artist',
          nameMarathi: 'मेहंदी कलाकार',
          icon: Icons.brush_rounded,
        ),
        SubCategory(
          id: 'makeup',
          name: 'Makeup Artist',
          nameMarathi: 'मेकअप कलाकार',
          icon: Icons.face_retouching_natural_rounded,
        ),
        SubCategory(
          id: 'planner',
          name: 'Event Planner',
          nameMarathi: 'इव्हेंट प्लॅनर',
          icon: Icons.event_note_rounded,
        ),
        SubCategory(
          id: 'anchor',
          name: 'Anchor / Host',
          nameMarathi: 'अँकर / होस्ट',
          icon: Icons.mic_rounded,
        ),
        SubCategory(
          id: 'band',
          name: 'Live Band',
          nameMarathi: 'लाइव बँड',
          icon: Icons.queue_music_rounded,
        ),
        SubCategory(
          id: 'orchestra',
          name: 'Orchestra',
          nameMarathi: 'ऑर्केस्ट्रा',
          icon: Icons.piano_rounded,
        ),
        SubCategory(
          id: 'dance',
          name: 'Dance Group',
          nameMarathi: 'नृत्य गट',
          icon: Icons.directions_run_rounded,
        ),
        SubCategory(
          id: 'generator',
          name: 'Generator Rental',
          nameMarathi: 'जनरेटर भाडे',
          icon: Icons.power_rounded,
        ),
        SubCategory(
          id: 'chair_table',
          name: 'Chair & Table Rental',
          nameMarathi: 'खुर्ची टेबल भाडे',
          icon: Icons.chair_rounded,
        ),
        SubCategory(
          id: 'tent',
          name: 'Tent House',
          nameMarathi: 'तंबू घर',
          icon: Icons.holiday_village_rounded,
        ),
      ],
    ),
  ];

  static AppCategory? findById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
