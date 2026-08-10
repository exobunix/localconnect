import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminBannerAdsScreen extends StatefulWidget {
  const AdminBannerAdsScreen({super.key});

  @override
  State<AdminBannerAdsScreen> createState() => _AdminBannerAdsScreenState();
}

class _AdminBannerAdsScreenState extends State<AdminBannerAdsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final banners = await SupabaseService.instance.getAdminBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBanner(String id, bool current) async {
    try {
      await SupabaseService.instance.adminToggleBanner(
        id: id,
        isActive: !current,
      );
      await _loadBanners();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _deleteBanner(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Banner',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this banner?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.adminDeleteBanner(id);
      await _loadBanners();
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? banner}) {
    final titleCtrl = TextEditingController(text: banner?['title'] ?? '');
    final subtitleCtrl = TextEditingController(text: banner?['subtitle'] ?? '');
    final imageCtrl = TextEditingController(text: banner?['image_url'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          banner == null ? 'Add Banner' : 'Edit Banner',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(titleCtrl, 'Title'),
              const SizedBox(height: 10),
              _buildField(subtitleCtrl, 'Subtitle'),
              const SizedBox(height: 10),
              _buildField(imageCtrl, 'Image URL (optional)'),
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
              if (titleCtrl.text.isEmpty) return;
              Navigator.pop(context);
              if (banner == null) {
                await SupabaseService.instance.adminCreateBanner(
                  title: titleCtrl.text,
                  subtitle: subtitleCtrl.text,
                  imageUrl: imageCtrl.text,
                );
              } else {
                await SupabaseService.instance.adminUpdateBanner(
                  id: banner['id'] as String,
                  title: titleCtrl.text,
                  subtitle: subtitleCtrl.text,
                  imageUrl: imageCtrl.text,
                );
              }
              await _loadBanners();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              banner == null ? 'Add' : 'Save',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Banner Ads',
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
            onPressed: _loadBanners,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Banner',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _banners.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: AppTheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No banners yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first banner ad',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBanners,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _banners.length,
                itemBuilder: (_, i) {
                  final b = _banners[i];
                  final isActive = b['is_active'] as bool? ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(
                        color: isActive
                            ? AppTheme.outlineVariant
                            : AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Preview
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _hexColor(b['gradient_start'] ?? '#1565C0'),
                                _hexColor(b['gradient_end'] ?? '#1E88E5'),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  b['title'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                if ((b['subtitle'] ?? '').isNotEmpty)
                                  Text(
                                    b['subtitle'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.successContainer
                                      : AppTheme.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isActive,
                                onChanged: (_) =>
                                    _toggleBanner(b['id'] as String, isActive),
                                activeThumbColor: AppTheme.primary,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                onPressed: () => _showAddEditDialog(banner: b),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_rounded,
                                  size: 18,
                                  color: AppTheme.error,
                                ),
                                onPressed: () =>
                                    _deleteBanner(b['id'] as String),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _hexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}
