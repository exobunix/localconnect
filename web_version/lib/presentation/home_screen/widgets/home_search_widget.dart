import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/app_categories.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './search_filters_bottom_sheet.dart';

class _SearchResult {
  final AppCategory category;
  final SubCategory? subcategory;
  final String displayName;
  final String subtitle;

  const _SearchResult({
    required this.category,
    this.subcategory,
    required this.displayName,
    required this.subtitle,
  });
}

class HomeSearchWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<Map<String, dynamic>>? onFiltersChanged;

  const HomeSearchWidget({
    super.key,
    required this.onSearch,
    this.onFiltersChanged,
  });

  @override
  State<HomeSearchWidget> createState() => _HomeSearchWidgetState();
}

class _HomeSearchWidgetState extends State<HomeSearchWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<_SearchResult> _suggestions = [];
  Map<String, dynamic> _activeFilters = {};
  bool _showSuggestions = false;

  bool get _hasActiveFilters {
    return _activeFilters.isNotEmpty &&
        (_activeFilters['category'] != null ||
            (_activeFilters['minRating'] as double? ?? 0) > 0 ||
            _activeFilters['maxDistance'] != null ||
            (_activeFilters['minPrice'] as double? ?? 0) > 0 ||
            (_activeFilters['maxPrice'] as double? ?? 5000) < 5000);
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay hiding so taps on suggestion tiles can register first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  List<_SearchResult> _buildSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final results = <_SearchResult>[];

    for (final category in AppCategories.all) {
      if (category.name.toLowerCase().contains(q) ||
          category.nameMarathi.contains(q)) {
        results.add(
          _SearchResult(
            category: category,
            displayName: category.name,
            subtitle: '${category.nameMarathi} • All services',
          ),
        );
      }
      for (final sub in category.subcategories) {
        if (sub.name.toLowerCase().contains(q) || sub.nameMarathi.contains(q)) {
          results.add(
            _SearchResult(
              category: category,
              subcategory: sub,
              displayName: sub.name,
              subtitle: '${sub.nameMarathi} • in ${category.name}',
            ),
          );
        }
      }
    }
    return results.take(8).toList();
  }

  void _onTextChanged(String value) {
    widget.onSearch(value);
    final suggestions = _buildSuggestions(value);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = value.trim().isNotEmpty && suggestions.isNotEmpty;
    });
  }

  void _onSubmit(String query) {
    if (query.trim().isNotEmpty) {
      setState(() => _showSuggestions = false);
      _focusNode.unfocus();
      widget.onSearch(query);
      Navigator.pushNamed(
        context,
        AppRoutes.allCategoriesScreen,
        arguments: {'searchQuery': query, 'filters': _activeFilters},
      );
    }
  }

  void _navigateToResult(_SearchResult result) {
    // Dismiss keyboard and suggestions BEFORE navigating
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
      _controller.text = result.displayName;
    });

    final categoryId = result.category.id;
    final subcategoryId = result.subcategory?.id;

    // Use addPostFrameCallback to ensure setState is complete before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (categoryId) {
        case 'shop':
          Navigator.pushNamed(
            context,
            AppRoutes.shopHomeScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        case 'transport':
          Navigator.pushNamed(
            context,
            AppRoutes.transportCustomerScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        case 'home_maintenance':
          Navigator.pushNamed(
            context,
            AppRoutes.homeMaintenanceCustomerScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        case 'delivery':
          Navigator.pushNamed(
            context,
            AppRoutes.deliveryCustomerScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        case 'rent':
          Navigator.pushNamed(
            context,
            AppRoutes.rentCustomerScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        case 'events':
          Navigator.pushNamed(
            context,
            AppRoutes.eventManagementCustomerScreen,
            arguments: {'subcategory': subcategoryId},
          );
          break;
        default:
          Navigator.pushNamed(
            context,
            AppRoutes.allCategoriesScreen,
            arguments: {
              'searchQuery': result.displayName,
              'filters': _activeFilters,
            },
          );
      }
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFiltersBottomSheet(
        initialFilters: _activeFilters,
        onApply: (filters) {
          setState(() => _activeFilters = filters);
          widget.onFiltersChanged?.call(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onTextChanged,
                    onSubmitted: _onSubmit,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF1A1C1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'सेवा शोधा / Search services...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF90A4AE),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      suffixIcon: _controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _onTextChanged('');
                                _focusNode.requestFocus();
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF90A4AE),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppTheme.outlineVariant),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilters,
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: AppTheme.secondary,
                            size: 18,
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
          // Inline suggestions dropdown (no Overlay — avoids tap-cancel race)
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _suggestions.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _SuggestionTile(
                        result: _suggestions[i],
                        onTap: () => _navigateToResult(_suggestions[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Active filter chips
          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_activeFilters['category'] != null)
                    _FilterChip(
                      label: _activeFilters['category'] as String,
                      onRemove: () => setState(() {
                        _activeFilters = Map.from(_activeFilters)
                          ..remove('category');
                        widget.onFiltersChanged?.call(_activeFilters);
                      }),
                    ),
                  if ((_activeFilters['minRating'] as double? ?? 0) > 0)
                    _FilterChip(
                      label:
                          '★ ${(_activeFilters['minRating'] as double).toStringAsFixed(1)}+',
                      onRemove: () => setState(() {
                        _activeFilters = Map.from(_activeFilters)
                          ..['minRating'] = 0.0;
                        widget.onFiltersChanged?.call(_activeFilters);
                      }),
                    ),
                  if (_activeFilters['maxDistance'] != null)
                    _FilterChip(
                      label:
                          '≤ ${(_activeFilters['maxDistance'] as double).toInt()} km',
                      onRemove: () => setState(() {
                        _activeFilters = Map.from(_activeFilters)
                          ..remove('maxDistance');
                        widget.onFiltersChanged?.call(_activeFilters);
                      }),
                    ),
                  if ((_activeFilters['minPrice'] as double? ?? 0) > 0 ||
                      (_activeFilters['maxPrice'] as double? ?? 5000) < 5000)
                    _FilterChip(
                      label:
                          '₹${(_activeFilters['minPrice'] as double? ?? 0).toInt()}–₹${(_activeFilters['maxPrice'] as double? ?? 5000).toInt()}',
                      onRemove: () => setState(() {
                        _activeFilters = Map.from(_activeFilters)
                          ..['minPrice'] = 0.0
                          ..['maxPrice'] = 5000.0;
                        widget.onFiltersChanged?.call(_activeFilters);
                      }),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;

  const _SuggestionTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = result.subcategory?.icon ?? result.category.icon;
    final color = result.category.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF90A4AE),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Color(0xFFBDBDBD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
