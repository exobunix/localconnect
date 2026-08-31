import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/category_service.dart';

class HomeCategoryGridWidget extends StatefulWidget {
  final bool isTablet;
  final ValueChanged<String> onCategoryTap;

  const HomeCategoryGridWidget({
    super.key,
    required this.isTablet,
    required this.onCategoryTap,
  });

  @override
  State<HomeCategoryGridWidget> createState() => _HomeCategoryGridWidgetState();
}

class _HomeCategoryGridWidgetState extends State<HomeCategoryGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Animation<double>> _itemAnimations = [];
  List<DynamicCategory> _activeCategories = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadActiveCategories();
  }

  Future<void> _loadActiveCategories({bool forceRefresh = false}) async {
    try {
      final categories = await CategoryService.instance.getActiveCategories(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _activeCategories = categories;
          _loaded = true;
        });
        _rebuildAnimations();
        _animController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('[HomeCategoryGrid] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _activeCategories = [];
          _loaded = true;
        });
      }
    }
  }

  void _rebuildAnimations() {
    _itemAnimations.clear();
    for (int i = 0; i < _activeCategories.length; i++) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end = (start + 0.3).clamp(0.0, 1.0);
      _itemAnimations.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_activeCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;
    final crossAxisCount = isDesktop ? 6 : (widget.isTablet ? 6 : 3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'सेवा / Services',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              TextButton(
                onPressed: () => widget.onCategoryTap('all'),
                child: Text(
                  'सर्व पहा',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: isDesktop ? 1.05 : 1.05,
              crossAxisSpacing: isDesktop ? 16 : 8,
              mainAxisSpacing: isDesktop ? 16 : 8,
            ),
            itemCount: _activeCategories.length,
            itemBuilder: (context, index) {
              final cat = _activeCategories[index];
              final anim = index < _itemAnimations.length
                  ? _itemAnimations[index]
                  : const AlwaysStoppedAnimation(1.0);
              return AnimatedBuilder(
                animation: anim,
                builder: (context, child) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _CategoryItem(
                  category: cat,
                  onTap: () => widget.onCategoryTap(cat.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final DynamicCategory category;
  final VoidCallback onTap;

  const _CategoryItem({required this.category, required this.onTap});

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: isDesktop
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.category.color.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.category.color.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.category.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: widget.category.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.category.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.category.icon,
                                  color: widget.category.color,
                                  size: 32,
                                ),
                              )
                            : Icon(
                                widget.category.icon,
                                color: widget.category.color,
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.category.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1B1F),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore services',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.category.color.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.category.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.category.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                widget.category.icon,
                                color: widget.category.color,
                                size: 28,
                              ),
                            )
                          : Icon(
                              widget.category.icon,
                              color: widget.category.color,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.category.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
