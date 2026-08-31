import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// A fully dynamic category loaded from Supabase — no hardcoded data.
class DynamicSubCategory {
  final String id;
  final String name;
  final String nameMarathi;
  final IconData icon;
  final String imageUrl;
  final String description;
  final bool isActive;
  final int sortOrder;

  const DynamicSubCategory({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.icon,
    required this.imageUrl,
    required this.description,
    required this.isActive,
    required this.sortOrder,
  });

  factory DynamicSubCategory.fromMap(Map<String, dynamic> map) {
    return DynamicSubCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameMarathi: map['name_marathi'] as String? ?? '',
      icon: CategoryService._iconFromName(map['icon_name'] as String? ?? ''),
      imageUrl: map['image_url'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 99,
    );
  }
}

class DynamicCategory {
  final String id;
  final String name;
  final String nameMarathi;
  final IconData icon;
  final String imageUrl;
  final Color color;
  final bool isActive;
  final int sortOrder;
  final List<DynamicSubCategory> subcategories;

  const DynamicCategory({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.icon,
    required this.imageUrl,
    required this.color,
    required this.isActive,
    required this.sortOrder,
    required this.subcategories,
  });

  factory DynamicCategory.fromMap(
    Map<String, dynamic> map,
    List<DynamicSubCategory> subs,
  ) {
    return DynamicCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameMarathi: map['name_marathi'] as String? ?? '',
      icon: CategoryService._iconFromName(map['icon_name'] as String? ?? ''),
      imageUrl: map['image_url'] as String? ?? '',
      color: CategoryService._colorFromHex(
        map['color_hex'] as String? ?? '',
        map['id'] as String? ?? '',
      ),
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 99,
      subcategories: subs,
    );
  }
}

/// Singleton service for dynamic category management.
/// All data comes from Supabase — no hardcoded lists.
class CategoryService {
  static CategoryService? _instance;
  static CategoryService get instance => _instance ??= CategoryService._();
  CategoryService._();

  // In-memory cache
  List<DynamicCategory>? _cachedActive;
  List<DynamicCategory>? _cachedAll;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid =>
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  /// Invalidate cache — call after any admin add/edit/delete/toggle.
  void invalidateCache() {
    _cachedActive = null;
    _cachedAll = null;
    _cacheTime = null;
    debugPrint('[CategoryService] Cache invalidated');
  }

  /// Returns all active categories with their active subcategories.
  /// This is what customer screens, provider registration, and search use.
  Future<List<DynamicCategory>> getActiveCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _cachedActive != null) {
      return _cachedActive!;
    }
    try {
      final cats = await SupabaseService.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      // Only fetch active subcategories
      final subs = await SupabaseService.instance.client
          .from('subcategories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final subsByCategory = <String, List<DynamicSubCategory>>{};
      final seenSubNames = <String, Set<String>>{};
      for (final s in List<Map<String, dynamic>>.from(subs)) {
        final catId = s['category_id'] as String? ?? '';
        final subName = (s['name'] as String? ?? '').toLowerCase().trim();
        seenSubNames.putIfAbsent(catId, () => {});
        if (subName.isNotEmpty && seenSubNames[catId]!.contains(subName)) {
          continue; // skip duplicate subcategory
        }
        if (subName.isNotEmpty) {
          seenSubNames[catId]!.add(subName);
        }
        subsByCategory
            .putIfAbsent(catId, () => [])
            .add(DynamicSubCategory.fromMap(s));
      }

      final result = List<Map<String, dynamic>>.from(cats).map((c) {
        final catId = c['id'] as String? ?? '';
        return DynamicCategory.fromMap(c, subsByCategory[catId] ?? []);
      }).toList();

      _cachedActive = result;
      _cacheTime = DateTime.now();
      debugPrint(
        '[CategoryService] Loaded ${result.length} active categories, '
        '${subs.length} active subcategories from Supabase',
      );
      return result;
    } catch (e) {
      debugPrint('[CategoryService] ERROR loading active categories: $e');
      return _cachedActive ?? [];
    }
  }

  /// Returns ALL categories (active + inactive) with ALL subcategories.
  /// Used by admin screens.
  Future<List<DynamicCategory>> getAllCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid && _cachedAll != null) {
      return _cachedAll!;
    }
    try {
      final cats = await SupabaseService.instance.client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      final subs = await SupabaseService.instance.client
          .from('subcategories')
          .select()
          .order('sort_order', ascending: true);

      final subsByCategory = <String, List<DynamicSubCategory>>{};
      final seenSubNames = <String, Set<String>>{};
      for (final s in List<Map<String, dynamic>>.from(subs)) {
        final catId = s['category_id'] as String? ?? '';
        final subName = (s['name'] as String? ?? '').toLowerCase().trim();
        seenSubNames.putIfAbsent(catId, () => {});
        if (subName.isNotEmpty && seenSubNames[catId]!.contains(subName)) {
          continue; // skip duplicate subcategory
        }
        if (subName.isNotEmpty) {
          seenSubNames[catId]!.add(subName);
        }
        subsByCategory
            .putIfAbsent(catId, () => [])
            .add(DynamicSubCategory.fromMap(s));
      }

      final result = List<Map<String, dynamic>>.from(cats).map((c) {
        final catId = c['id'] as String? ?? '';
        return DynamicCategory.fromMap(c, subsByCategory[catId] ?? []);
      }).toList();

      _cachedAll = result;
      _cacheTime = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('[CategoryService] ERROR loading all categories: $e');
      return _cachedAll ?? [];
    }
  }

  /// Find a single active category by id.
  Future<DynamicCategory?> findById(String id) async {
    final cats = await getActiveCategories();
    try {
      return cats.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Icon mapping ─────────────────────────────────────────────────────────

  static IconData _iconFromName(String name) {
    const map = <String, IconData>{
      'storefront': Icons.storefront_rounded,
      'storefront_rounded': Icons.storefront_rounded,
      'local_taxi': Icons.local_taxi_rounded,
      'local_taxi_rounded': Icons.local_taxi_rounded,
      'home_repair_service': Icons.home_repair_service_rounded,
      'home_repair_service_rounded': Icons.home_repair_service_rounded,
      'delivery_dining': Icons.delivery_dining_rounded,
      'delivery_dining_rounded': Icons.delivery_dining_rounded,
      'home': Icons.home_rounded,
      'home_rounded': Icons.home_rounded,
      'celebration': Icons.celebration_rounded,
      'celebration_rounded': Icons.celebration_rounded,
      'shopping_basket': Icons.shopping_basket_rounded,
      'shopping_basket_rounded': Icons.shopping_basket_rounded,
      'electrical_services': Icons.electrical_services_rounded,
      'electrical_services_rounded': Icons.electrical_services_rounded,
      'set_meal': Icons.set_meal_rounded,
      'set_meal_rounded': Icons.set_meal_rounded,
      'eco': Icons.eco_rounded,
      'eco_rounded': Icons.eco_rounded,
      'wb_sunny': Icons.wb_sunny_rounded,
      'wb_sunny_rounded': Icons.wb_sunny_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'more_horiz_rounded': Icons.more_horiz_rounded,
      'electric_rickshaw': Icons.electric_rickshaw_rounded,
      'electric_rickshaw_rounded': Icons.electric_rickshaw_rounded,
      'airport_shuttle': Icons.airport_shuttle_rounded,
      'airport_shuttle_rounded': Icons.airport_shuttle_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'local_shipping_rounded': Icons.local_shipping_rounded,
      'fire_truck': Icons.fire_truck_rounded,
      'fire_truck_rounded': Icons.fire_truck_rounded,
      'directions_car': Icons.directions_car_rounded,
      'directions_car_rounded': Icons.directions_car_rounded,
      'plumbing': Icons.plumbing_rounded,
      'plumbing_rounded': Icons.plumbing_rounded,
      'format_paint': Icons.format_paint_rounded,
      'format_paint_rounded': Icons.format_paint_rounded,
      'construction': Icons.construction_rounded,
      'construction_rounded': Icons.construction_rounded,
      'carpenter': Icons.carpenter_rounded,
      'carpenter_rounded': Icons.carpenter_rounded,
      'engineering': Icons.engineering_rounded,
      'engineering_rounded': Icons.engineering_rounded,
      'cleaning_services': Icons.cleaning_services_rounded,
      'cleaning_services_rounded': Icons.cleaning_services_rounded,
      'fastfood': Icons.fastfood_rounded,
      'fastfood_rounded': Icons.fastfood_rounded,
      'medication': Icons.medication_rounded,
      'medication_rounded': Icons.medication_rounded,
      'inventory_2': Icons.inventory_2_rounded,
      'inventory_2_rounded': Icons.inventory_2_rounded,
      'swap_horiz': Icons.swap_horiz_rounded,
      'swap_horiz_rounded': Icons.swap_horiz_rounded,
      'bolt': Icons.bolt_rounded,
      'bolt_rounded': Icons.bolt_rounded,
      'schedule': Icons.schedule_rounded,
      'schedule_rounded': Icons.schedule_rounded,
      'connecting_airports': Icons.connecting_airports_rounded,
      'connecting_airports_rounded': Icons.connecting_airports_rounded,
      'bedroom_parent': Icons.bedroom_parent_rounded,
      'bedroom_parent_rounded': Icons.bedroom_parent_rounded,
      'apartment': Icons.apartment_rounded,
      'apartment_rounded': Icons.apartment_rounded,
      'hotel': Icons.hotel_rounded,
      'hotel_rounded': Icons.hotel_rounded,
      'villa': Icons.villa_rounded,
      'villa_rounded': Icons.villa_rounded,
      'build': Icons.build_rounded,
      'build_rounded': Icons.build_rounded,
      'camera_alt': Icons.camera_alt_rounded,
      'camera_alt_rounded': Icons.camera_alt_rounded,
      'videocam': Icons.videocam_rounded,
      'videocam_rounded': Icons.videocam_rounded,
      'speaker': Icons.speaker_rounded,
      'speaker_rounded': Icons.speaker_rounded,
      'music_note': Icons.music_note_rounded,
      'music_note_rounded': Icons.music_note_rounded,
      'temple_hindu': Icons.temple_hindu_rounded,
      'temple_hindu_rounded': Icons.temple_hindu_rounded,
      'cake': Icons.cake_rounded,
      'cake_rounded': Icons.cake_rounded,
      'favorite': Icons.favorite_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'local_florist': Icons.local_florist_rounded,
      'local_florist_rounded': Icons.local_florist_rounded,
      'lightbulb': Icons.lightbulb_rounded,
      'lightbulb_rounded': Icons.lightbulb_rounded,
      'restaurant': Icons.restaurant_rounded,
      'restaurant_rounded': Icons.restaurant_rounded,
      'brush': Icons.brush_rounded,
      'brush_rounded': Icons.brush_rounded,
      'face_retouching_natural': Icons.face_retouching_natural_rounded,
      'face_retouching_natural_rounded': Icons.face_retouching_natural_rounded,
      'event_note': Icons.event_note_rounded,
      'event_note_rounded': Icons.event_note_rounded,
      'mic': Icons.mic_rounded,
      'mic_rounded': Icons.mic_rounded,
      'queue_music': Icons.queue_music_rounded,
      'queue_music_rounded': Icons.queue_music_rounded,
      'piano': Icons.piano_rounded,
      'piano_rounded': Icons.piano_rounded,
      'directions_run': Icons.directions_run_rounded,
      'directions_run_rounded': Icons.directions_run_rounded,
      'power': Icons.power_rounded,
      'power_rounded': Icons.power_rounded,
      'chair': Icons.chair_rounded,
      'chair_rounded': Icons.chair_rounded,
      'holiday_village': Icons.holiday_village_rounded,
      'holiday_village_rounded': Icons.holiday_village_rounded,
      // Waterproofing and other home maintenance extras
      'water_damage': Icons.water_damage_rounded,
      'water_damage_rounded': Icons.water_damage_rounded,
      'roofing': Icons.roofing_rounded,
      'roofing_rounded': Icons.roofing_rounded,
      'handyman': Icons.handyman_rounded,
      'handyman_rounded': Icons.handyman_rounded,
      'home_work': Icons.home_work_rounded,
      'home_work_rounded': Icons.home_work_rounded,
      'category': Icons.category_rounded,
      'category_rounded': Icons.category_rounded,
    };
    return map[name] ?? Icons.miscellaneous_services_rounded;
  }

  // ─── Color mapping ────────────────────────────────────────────────────────

  static Color _colorFromHex(String hex, String categoryId) {
    // Try hex first
    if (hex.isNotEmpty) {
      try {
        final h = hex.replaceAll('#', '');
        if (h.length == 6) {
          return Color(int.parse('FF$h', radix: 16));
        }
        if (h.length == 8) {
          return Color(int.parse(h, radix: 16));
        }
      } catch (_) {}
    }
    // Fallback by category id
    const fallbacks = <String, Color>{
      'shop': AppTheme.catGrocery,
      'transport': AppTheme.catTransport,
      'home_maintenance': AppTheme.catPlumbing,
      'delivery': AppTheme.catDelivery,
      'rent': AppTheme.catRent,
      'events': AppTheme.catEvents,
    };
    return fallbacks[categoryId] ?? AppTheme.primary;
  }
}
