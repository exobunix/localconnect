import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../services/category_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/image_upload_helper.dart';

class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  State<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  String? _expandedCategoryId;

  Future<void> _pickAndUploadImage(
    TextEditingController controller,
    String pathPrefix,
    String id,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final validation = await ImageUploadHelper.validateAndCompress(picked);
      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.errorMessage ?? 'Invalid image file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loader
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Uploading image...'),
              ],
            ),
            duration: Duration(days: 1), // indefinite until dismissed
            dismissDirection: DismissDirection.none,
          ),
        );
      }

      final fileName = picked.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final storagePath = '$pathPrefix/${id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final publicUrl = await SupabaseService.instance.uploadImageToBucket(
        bucketName: 'user-avatars',
        storagePath: storagePath,
        imageBytes: validation.bytes!,
        contentType: validation.mimeType ?? 'image/jpeg',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (publicUrl != null) {
        controller.text = publicUrl;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Color(0xFF00C853),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image to storage.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await SupabaseService.instance.getAdminCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCategory(String id, bool current) async {
    // Optimistic update
    setState(() {
      final idx = _categories.indexWhere((c) => c['id'] == id);
      if (idx != -1) {
        _categories[idx] = {..._categories[idx], 'is_active': !current};
      }
    });
    try {
      await SupabaseService.instance.adminToggleCategory(
        id: id,
        isActive: !current,
      );
      // Invalidate cache so customer screens reflect the change immediately
      CategoryService.instance.invalidateCache();
    } catch (e) {
      // Revert on failure
      setState(() {
        final idx = _categories.indexWhere((c) => c['id'] == id);
        if (idx != -1) {
          _categories[idx] = {..._categories[idx], 'is_active': current};
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update category visibility'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSortOrder(String id, int newOrder) async {
    try {
      await SupabaseService.instance.client
          .from('categories')
          .update({
            'sort_order': newOrder,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      CategoryService.instance.invalidateCache();
      await _loadCategories();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _deleteSubcategory(String subId) async {
    try {
      await SupabaseService.instance.adminDeleteSubcategory(subId);
      CategoryService.instance.invalidateCache();
      await _loadCategories();
    } catch (e) {
      // ignore
    }
  }

  int get _activeCount =>
      _categories.where((c) => c['is_active'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Category Management',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCategories,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                // ── Stats Banner ──────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          label: 'Total',
                          value: '${_categories.length}',
                          icon: Icons.category_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _StatChip(
                          label: 'Visible',
                          value: '$_activeCount',
                          icon: Icons.visibility_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _StatChip(
                          label: 'Hidden',
                          value: '${_categories.length - _activeCount}',
                          icon: Icons.visibility_off_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Info Banner ───────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFFF57F17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toggle visibility to show/hide categories instantly — no app update needed.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Category List ─────────────────────────────────────────
                Expanded(
                  child: _categories.isEmpty
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
                                'No categories yet',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppTheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showAddCategoryDialog(context),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Category'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isExpanded =
                                  _expandedCategoryId == cat['id'];
                              final isActive =
                                  cat['is_active'] as bool? ?? false;
                              final subcategories =
                                  cat['subcategories'] as List<dynamic>? ?? [];
                              final sortOrder =
                                  cat['sort_order'] as int? ?? index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppTheme.cardShadow,
                                    border: Border.all(
                                      color: isActive
                                          ? AppTheme.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.transparent,
                                      width: isActive ? 1.5 : 0,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // ── Category Row ─────────────────
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _expandedCategoryId = isExpanded
                                              ? null
                                              : cat['id'] as String;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppTheme.primary.withValues(
                                                    alpha: 0.04,
                                                  )
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Visibility indicator dot
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isActive
                                                      ? Colors.green
                                                      : Colors.grey.shade400,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.category_rounded,
                                                  color: AppTheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      cat['name'] as String? ??
                                                          '',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    Wrap(
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment.center,
                                                      spacing: 6,
                                                      runSpacing: 2,
                                                      children: [
                                                        Text(
                                                          '${subcategories.length} subcategories',
                                                          style:
                                                              GoogleFonts.plusJakartaSans(
                                                                fontSize: 11,
                                                                color:
                                                                    const Color(
                                                                  0xFF74777F,
                                                                ),
                                                              ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isActive
                                                                ? Colors.green
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )
                                                                : Colors
                                                                    .grey
                                                                    .shade100,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                              20,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            isActive
                                                                ? 'Visible'
                                                                : 'Hidden',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: isActive
                                                                  ? Colors
                                                                      .green
                                                                      .shade700
                                                                  : Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Sort order badge
                                              GestureDetector(
                                                onTap: () =>
                                                    _showSortOrderDialog(
                                                      context,
                                                      cat,
                                                      sortOrder,
                                                    ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.surfaceVariant,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.swap_vert_rounded,
                                                        size: 14,
                                                        color: AppTheme.outline,
                                                      ),
                                                      Text(
                                                        '#$sortOrder',
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 10,
                                                              color: AppTheme
                                                                  .outline,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              // Visibility toggle
                                              Switch(
                                                value: isActive,
                                                onChanged: (_) =>
                                                    _toggleCategory(
                                                      cat['id'] as String,
                                                      isActive,
                                                    ),
                                                activeColor: AppTheme.primary,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              // Edit button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 18,
                                                  color: AppTheme.primary,
                                                ),
                                                onPressed: () =>
                                                    _showEditCategoryDialog(
                                                      context,
                                                      cat,
                                                    ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                              ),
                                              Icon(
                                                isExpanded
                                                    ? Icons.expand_less_rounded
                                                    : Icons.expand_more_rounded,
                                                color: AppTheme.outline,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // ── Subcategories ─────────────────
                                      if (isExpanded) ...[
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Subcategories',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                            0xFF74777F,
                                                          ),
                                                        ),
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        _showAddSubcategoryDialog(
                                                          context,
                                                          cat,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.add_rounded,
                                                      size: 14,
                                                    ),
                                                    label: Text(
                                                      'Add',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppTheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (!isActive)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .visibility_off_rounded,
                                                        size: 14,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'All subcategories are hidden because this category is hidden.',
                                                          style:
                                                              GoogleFonts.plusJakartaSans(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .orange
                                                                    .shade800,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: subcategories.map((
                                                  sub,
                                                ) {
                                                  final s =
                                                      sub
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final subActive =
                                                      s['is_active'] as bool? ??
                                                      true;
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: subActive
                                                          ? AppTheme
                                                                .surfaceVariant
                                                          : Colors
                                                                .grey
                                                                .shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: subActive
                                                            ? AppTheme
                                                                  .outlineVariant
                                                            : Colors
                                                                  .grey
                                                                  .shade400,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.label_rounded,
                                                          size: 14,
                                                          color: subActive
                                                              ? AppTheme.primary
                                                              : Colors.grey,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        GestureDetector(
                                                          onTap: () => _showEditSubcategoryDialog(context, s),
                                                          child: MouseRegion(
                                                            cursor: SystemMouseCursors.click,
                                                            child: Text(
                                                              s['name'] as String? ?? '',
                                                              style: GoogleFonts.plusJakartaSans(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                                color: subActive ? null : Colors.grey,
                                                                decoration: subActive
                                                                    ? null
                                                                    : TextDecoration.lineThrough,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        // Toggle hide/unhide
                                                        GestureDetector(
                                                          onTap: () async {
                                                            await SupabaseService
                                                                .instance
                                                                .adminToggleSubcategory(
                                                                  id:
                                                                      s['id']
                                                                          as String,
                                                                  isActive:
                                                                      !subActive,
                                                                );
                                                            CategoryService
                                                                .instance
                                                                .invalidateCache();
                                                            await _loadCategories();
                                                          },
                                                          child: Icon(
                                                            subActive
                                                                ? Icons
                                                                      .visibility_rounded
                                                                : Icons
                                                                      .visibility_off_rounded,
                                                            size: 14,
                                                            color: subActive
                                                                ? AppTheme
                                                                      .primary
                                                                : Colors.grey,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        GestureDetector(
                                                          onTap: () =>
                                                              _deleteSubcategory(
                                                                s['id']
                                                                    as String,
                                                              ),
                                                          child: const Icon(
                                                            Icons.close_rounded,
                                                            size: 14,
                                                            color: AppTheme
                                                                .outline,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showSortOrderDialog(
    BuildContext context,
    Map<String, dynamic> cat,
    int currentOrder,
  ) {
    final ctrl = TextEditingController(text: '$currentOrder');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Display Order',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the display position for "${cat['name']}".\nLower number = appears first.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Order Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.swap_vert_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text);
              if (val != null) {
                Navigator.pop(context);
                await _updateSortOrder(cat['id'] as String, val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final marathiCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Category',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name (English)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marathiCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name (Marathi)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                decoration: InputDecoration(
                  labelText: 'Photo/Image URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final folderId = name.isNotEmpty
                          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')
                          : 'temp';
                      _pickAndUploadImage(imageCtrl, 'categories', folderId);
                    },
                    tooltip: 'Upload Photo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final name = nameCtrl.text.trim();
                final marathi = marathiCtrl.text.trim();
                final imageUrl = imageCtrl.text.trim();
                final description = descCtrl.text.trim();
                Navigator.pop(context);
                try {
                  final id = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  await SupabaseService.instance.adminUpsertCategory(
                    id: id.isNotEmpty ? id : 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    nameMarathi: marathi,
                    isActive: true, // Make immediately active and visible
                    imageUrl: imageUrl,
                    description: description,
                  );
                  CategoryService.instance.invalidateCache();
                  await _loadCategories();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Category "$name" added successfully!'),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding category: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Add',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] as String? ?? '');
    final marathiCtrl = TextEditingController(
      text: cat['name_marathi'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: cat['description'] as String? ?? '',
    );
    final imageCtrl = TextEditingController(
      text: cat['image_url'] as String? ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Category',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name (English)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marathiCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name (Marathi)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                decoration: InputDecoration(
                  labelText: 'Photo/Image URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final folderId = name.isNotEmpty
                          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')
                          : 'temp';
                      _pickAndUploadImage(imageCtrl, 'categories', folderId);
                    },
                    tooltip: 'Upload Photo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.instance.adminUpsertCategory(
                id: cat['id'] as String,
                name: nameCtrl.text,
                nameMarathi: marathiCtrl.text,
                isActive: cat['is_active'] as bool? ?? true,
                description: descCtrl.text,
                imageUrl: imageCtrl.text,
              );
              CategoryService.instance.invalidateCache();
              await _loadCategories();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    Map<String, dynamic> cat,
  ) {
    final nameCtrl = TextEditingController();
    final marathiCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Subcategory to ${cat['name']}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Subcategory Name (English)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marathiCtrl,
                decoration: InputDecoration(
                  labelText: 'Subcategory Name (Marathi)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                decoration: InputDecoration(
                  labelText: 'Photo/Image URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final folderId = name.isNotEmpty
                          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')
                          : 'temp';
                      _pickAndUploadImage(imageCtrl, 'subcategories', folderId);
                    },
                    tooltip: 'Upload Photo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final name = nameCtrl.text.trim();
                final marathi = marathiCtrl.text.trim();
                final imageUrl = imageCtrl.text.trim();
                final description = descCtrl.text.trim();
                Navigator.pop(context);
                try {
                  final catId = cat['id'] as String;
                  final rawSlug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  final subId = '${catId}_${rawSlug.isNotEmpty ? rawSlug : DateTime.now().millisecondsSinceEpoch}';
                  await SupabaseService.instance.adminAddSubcategory(
                    categoryId: catId,
                    id: subId,
                    name: name,
                    nameMarathi: marathi,
                    imageUrl: imageUrl,
                    description: description,
                  );
                  CategoryService.instance.invalidateCache();
                  await _loadCategories();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Subcategory "$name" added to ${cat['name']}!'),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding subcategory: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Add',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSubcategoryDialog(
    BuildContext context,
    Map<String, dynamic> sub,
  ) {
    final nameCtrl = TextEditingController(text: sub['name'] as String? ?? '');
    final marathiCtrl = TextEditingController(text: sub['name_marathi'] as String? ?? '');
    final imageCtrl = TextEditingController(text: sub['image_url'] as String? ?? '');
    final descCtrl = TextEditingController(text: sub['description'] as String? ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Subcategory',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Subcategory Name (English)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marathiCtrl,
                decoration: InputDecoration(
                  labelText: 'Subcategory Name (Marathi)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                decoration: InputDecoration(
                  labelText: 'Photo/Image URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final folderId = name.isNotEmpty
                          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')
                          : 'temp';
                      _pickAndUploadImage(imageCtrl, 'subcategories', folderId);
                    },
                    tooltip: 'Upload Photo',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Content',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final name = nameCtrl.text.trim();
                final marathi = marathiCtrl.text.trim();
                final imageUrl = imageCtrl.text.trim();
                final description = descCtrl.text.trim();
                Navigator.pop(context);
                try {
                  await SupabaseService.instance.adminUpdateSubcategory(
                    id: sub['id'] as String,
                    name: name,
                    nameMarathi: marathi,
                    imageUrl: imageUrl,
                    description: description,
                  );
                  CategoryService.instance.invalidateCache();
                  await _loadCategories();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Subcategory "$name" updated successfully!'),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating subcategory: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
