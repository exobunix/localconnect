import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminBannerAdsScreen extends StatefulWidget {
  const AdminBannerAdsScreen({super.key});

  @override
  State<AdminBannerAdsScreen> createState() => _AdminBannerAdsScreenState();
}

class _AdminBannerAdsScreenState extends State<AdminBannerAdsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _adRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadBanners(),
      _loadAdRequests(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await SupabaseService.instance.getAdminBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAdRequests() async {
    try {
      final city = SupabaseService.instance.isSuperAdmin
          ? null
          : SupabaseService.instance.currentAdminArea;
      final requests = await SupabaseService.instance.getProviderAdRequests(city: city);
      if (mounted) {
        setState(() {
          _adRequests = requests;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBanner(String id, bool current) async {
    try {
      await SupabaseService.instance.adminToggleBanner(
        id: id,
        isActive: !current,
      );
      await _loadBanners();
    } catch (_) {}
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

  Future<void> _approveAdRequest(Map<String, dynamic> req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Approve & Publish Banner',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will approve the advertising request from "${req['business_name'] ?? req['provider_name']}" and immediately publish it to the live home screen carousel for ${req['duration_days'] ?? 15} days.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: Text(
              'Approve & Publish',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SupabaseService.instance.adminApproveAdRequest(
        requestId: req['id'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Ad approved and published live!' : 'Failed to approve ad.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red,
          ),
        );
      }
      await _loadAll();
    }
  }

  Future<void> _rejectAdRequest(Map<String, dynamic> req) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Ad Request',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter reason for rejection (optional):',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Inappropriate image or duplicate promotion',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
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
              'Reject',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.adminRejectAdRequest(
        req['id'] as String,
        note: noteCtrl.text.trim(),
      );
      await _loadAll();
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? banner}) {
    final titleCtrl = TextEditingController(text: banner?['title'] ?? '');
    final subtitleCtrl = TextEditingController(text: banner?['subtitle'] ?? '');
    final imageCtrl = TextEditingController(text: banner?['image_url'] ?? '');
    final actionCtrl = TextEditingController(text: banner?['action_url'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          banner == null ? 'Add Promotional Banner' : 'Edit Banner',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(titleCtrl, 'Headline / Title *'),
              const SizedBox(height: 10),
              _buildField(subtitleCtrl, 'Subtitle / Offer Details'),
              const SizedBox(height: 10),
              _buildField(imageCtrl, 'Banner Image URL (optional)'),
              const SizedBox(height: 10),
              _buildField(actionCtrl, 'Action / Deep Link URL (optional)'),
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
                  actionUrl: actionCtrl.text,
                );
              } else {
                await SupabaseService.instance.adminUpdateBanner(
                  id: banner['id'] as String,
                  title: titleCtrl.text,
                  subtitle: subtitleCtrl.text,
                  imageUrl: imageCtrl.text,
                  actionUrl: actionCtrl.text,
                );
              }
              await _loadBanners();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(
              banner == null ? 'Publish' : 'Save',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
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
    final pendingCount = _adRequests.where((r) => r['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Advertising & Banners',
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
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.view_carousel_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Active Banners (${_banners.length})',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Provider Ads',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
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
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveBannersTab(),
                _buildProviderRequestsTab(),
              ],
            ),
    );
  }

  Widget _buildActiveBannersTab() {
    if (_banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_outlined, size: 48, color: AppTheme.outline),
            const SizedBox(height: 12),
            Text(
              'No active banners yet',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first promotional banner',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
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
                color: isActive ? AppTheme.outlineVariant : AppTheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successContainer : AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppTheme.success : AppTheme.error,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        onChanged: (_) => _toggleBanner(b['id'] as String, isActive),
                        activeThumbColor: AppTheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                        onPressed: () => _showAddEditDialog(banner: b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.error),
                        onPressed: () => _deleteBanner(b['id'] as String),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderRequestsTab() {
    if (_adRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 48, color: AppTheme.outline),
            const SizedBox(height: 12),
            Text(
              'No provider ad requests yet',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Service providers can submit banner requests from their dashboard',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _adRequests.length,
        itemBuilder: (_, i) {
          final req = _adRequests[i];
          final status = (req['status'] as String? ?? 'pending').toLowerCase();
          final isPending = status == 'pending';
          final isApproved = status == 'approved';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: isPending
                    ? Colors.amber.shade300
                    : isApproved
                        ? const Color(0xFFC8E6C9)
                        : Colors.red.shade100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFF6A1B9A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req['title'] ?? 'Advertisement Request',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Provider: ${req['business_name'] ?? req['provider_name'] ?? 'Local Provider'}  •  ${req['city'] ?? 'All Areas'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF42A5F5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.amber.shade100
                            : isApproved
                                ? const Color(0xFFE8F5E9)
                                : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isPending
                              ? Colors.amber.shade900
                              : isApproved
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((req['subtitle'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Offer / Subtitle: "${req['subtitle']}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.category_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      req['category'] ?? 'General Service',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${req['duration_days'] ?? 15} Days Duration',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectAdRequest(req),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _approveAdRequest(req),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve & Publish Live'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
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
