import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/category_service.dart';

class SearchFiltersBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final void Function(Map<String, dynamic> filters) onApply;

  const SearchFiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<SearchFiltersBottomSheet> createState() =>
      _SearchFiltersBottomSheetState();
}

class _SearchFiltersBottomSheetState extends State<SearchFiltersBottomSheet> {
  late RangeValues _priceRange;
  late double _minRating;
  late double _maxDistance;
  late String? _selectedCategory;

  // Dynamic categories loaded from Supabase
  List<String> _categoryNames = ['All'];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    _priceRange = RangeValues(
      (f['minPrice'] as double?) ?? 0,
      (f['maxPrice'] as double?) ?? 5000,
    );
    _minRating = (f['minRating'] as double?) ?? 0;
    _maxDistance = (f['maxDistance'] as double?) ?? 50;
    _selectedCategory = f['category'] as String?;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.instance.getActiveCategories();
      if (mounted) {
        setState(() {
          _categoryNames = ['All', ...cats.map((c) => c.name)];
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SearchFilters] Error loading categories: $e');
      if (mounted) {
        setState(() => _categoriesLoading = false);
      }
    }
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, 5000);
      _minRating = 0;
      _maxDistance = 50;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Text(
                'Search Filters',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category — dynamic from Supabase
          Text(
            'Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 10),
          _categoriesLoading
              ? const SizedBox(
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryNames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categoryNames[index];
                      final isSelected = cat == 'All'
                          ? _selectedCategory == null
                          : _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat == 'All' ? null : cat;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF44474E),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 20),
          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              Text(
                '₹${_priceRange.start.toInt()} – ₹${_priceRange.end.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.primaryContainer,
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 8),
          // Min Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimum Rating',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFC107),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: const Color(0xFFFFC107),
            inactiveColor: const Color(0xFFFFECB3),
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 8),
          // Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Distance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              Text(
                _maxDistance >= 50 ? 'Any' : '${_maxDistance.toInt()} km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppTheme.secondary,
            inactiveColor: AppTheme.secondaryContainer,
            onChanged: (v) => setState(() => _maxDistance = v),
          ),
          const SizedBox(height: 20),
          // Apply button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply({
                  'minPrice': _priceRange.start,
                  'maxPrice': _priceRange.end,
                  'minRating': _minRating,
                  'maxDistance': _maxDistance >= 50 ? null : _maxDistance,
                  'category': _selectedCategory,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
        ],
      ),
    );
  }
}
