import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/category_service.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  List<DynamicCategory> _activeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveCategories();
  }

  Future<void> _loadActiveCategories({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryService.instance.getActiveCategories(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _activeCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AllCategoriesScreen] Error: $e');
      if (mounted) {
        setState(() {
          _activeCategories = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'All Categories',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _activeCategories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: AppTheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No categories available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadActiveCategories(forceRefresh: true),
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activeCategories.length,
                itemBuilder: (context, index) {
                  final cat = _activeCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.categoryDetailScreen,
                              arguments: cat.id,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cat.color,
                                    cat.color.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(cat.icon, color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (cat.nameMarathi.isNotEmpty)
                                          Text(
                                            cat.nameMarathi,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Subcategories — fully dynamic from DB
                          if (cat.subcategories.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cat.subcategories
                                    .map(
                                      (sub) => GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.categoryDetailScreen,
                                          arguments: cat.id,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cat.color.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: cat.color.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                sub.icon,
                                                size: 13,
                                                color: cat.color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                sub.name,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: cat.color,
                                                    ),
                                              ),
                                            ],
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
                  );
                },
              ),
            ),
    );
  }
}
