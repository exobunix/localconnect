import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';

class AdminMediaModerationScreen extends StatefulWidget {
  const AdminMediaModerationScreen({super.key});

  @override
  State<AdminMediaModerationScreen> createState() =>
      _AdminMediaModerationScreenState();
}

class _AdminMediaModerationScreenState
    extends State<AdminMediaModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMedia = [];
  List<Map<String, dynamic>> _filteredMedia = [];
  String _activeFilter = 'pending';
  String _typeFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _statusFilters = ['pending', 'approved', 'rejected', 'all'];
  final List<String> _typeFilters = ['all', 'photo', 'video'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.client
          .from('provider_media_items')
          .select('''
            *,
            service_providers!provider_id (
              business_name,
              user_id,
              category,
              subcategory,
              user_profiles!user_id (full_name, phone)
            )
          ''')
          .order('uploaded_at', ascending: false);

      if (mounted) {
        setState(() {
          _allMedia = List<Map<String, dynamic>>.from(data);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load media: $e', isError: true);
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_allMedia);
    if (_activeFilter != 'all') {
      result = result
          .where((m) => m['moderation_status'] == _activeFilter)
          .toList();
    }
    if (_typeFilter != 'all') {
      result = result.where((m) => m['media_type'] == _typeFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((m) {
        final sp = m['service_providers'] as Map<String, dynamic>?;
        final name = (sp?['business_name'] ?? '').toString().toLowerCase();
        final caption = (m['caption'] ?? '').toString().toLowerCase();
        return name.contains(q) || caption.contains(q);
      }).toList();
    }
    setState(() => _filteredMedia = result);
  }

  Future<void> _updateStatus(String mediaId, String status,
      {String? note}) async {
    try {
      final adminId = SupabaseService.instance.currentUser?.id;
      await SupabaseService.instance.client
          .from('provider_media_items')
          .update({
            'moderation_status': status,
            'moderation_note': note,
            'moderated_by': adminId,
            'moderated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mediaId);

      final idx = _allMedia.indexWhere((m) => m['id'] == mediaId);
      if (idx != -1) {
        setState(() {
          _allMedia[idx] = {
            ..._allMedia[idx],
            'moderation_status': status,
            'moderation_note': note,
            'moderated_at': DateTime.now().toIso8601String(),
          };
          _applyFilters();
        });
      }
      _showSnack(
        status == 'approved'
            ? '✅ Media approved'
            : status == 'rejected'
                ? '❌ Media rejected'
                : '🗑️ Media removed',
      );
    } catch (e) {
      _showSnack('Action failed: $e', isError: true);
    }
  }

  Future<void> _deleteMedia(String mediaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Media',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Permanently remove this media item? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF90A4AE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Remove',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService.instance.client
            .from('provider_media_items')
            .delete()
            .eq('id', mediaId);
        setState(() {
          _allMedia.removeWhere((m) => m['id'] == mediaId);
          _applyFilters();
        });
        _showSnack('🗑️ Media removed permanently');
      } catch (e) {
        _showSnack('Delete failed: $e', isError: true);
      }
    }
  }

  Future<void> _showRejectDialog(String mediaId) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Media',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason for rejection (optional):',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF546E7A))),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Inappropriate content, blurry image...',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFFB0BEC5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF90A4AE))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reject',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus(mediaId, 'rejected', note: noteCtrl.text.trim());
    }
    noteCtrl.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.error : const Color(0xFF1A1C1E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int _countByStatus(String status) =>
      _allMedia.where((m) => m['moderation_status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatsRow(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredMedia.isEmpty
                    ? _buildEmptyState()
                    : _buildMediaGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F3))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.photo_library_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Media Moderation',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1E))),
                Text('Review provider photos, videos & portfolio',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: const Color(0xFF78909C))),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadMedia,
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primary, size: 22),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      ('Pending', _countByStatus('pending'), const Color(0xFFF59E0B)),
      ('Approved', _countByStatus('approved'), AppTheme.success),
      ('Rejected', _countByStatus('rejected'), AppTheme.error),
      ('Total', _allMedia.length, AppTheme.primary),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: stats.indexOf(s) < stats.length - 1 ? 8 : 0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: s.$3.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: s.$3.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${s.$2}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: s.$3),
                      ),
                      Text(s.$1,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: s.$3)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _searchQuery = v;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search by provider name or caption...',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: const Color(0xFFB0BEC5)),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFFB0BEC5), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Color(0xFFB0BEC5), size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 10),
          // Status + Type filters
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((f) {
                      final isActive = _activeFilter == f;
                      final color = f == 'pending'
                          ? const Color(0xFFF59E0B)
                          : f == 'approved'
                              ? AppTheme.success
                              : f == 'rejected'
                                  ? AppTheme.error
                                  : AppTheme.primary;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _activeFilter = f);
                          _applyFilters();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isActive
                                    ? color
                                    : color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Type filter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeFilter,
                    isDense: true,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E)),
                    items: _typeFilters
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t[0].toUpperCase() + t.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _typeFilter = v);
                        _applyFilters();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return RefreshIndicator(
      onRefresh: _loadMedia,
      color: AppTheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: _filteredMedia.length,
        itemBuilder: (_, i) => _MediaCard(
          item: _filteredMedia[i],
          onApprove: () =>
              _updateStatus(_filteredMedia[i]['id'], 'approved'),
          onReject: () => _showRejectDialog(_filteredMedia[i]['id']),
          onDelete: () => _deleteMedia(_filteredMedia[i]['id']),
          onPreview: () => _showPreview(_filteredMedia[i]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_library_outlined,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilter == 'pending'
                ? 'No pending media'
                : 'No $_activeFilter media',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E)),
          ),
          const SizedBox(height: 6),
          Text(
            'All provider media has been reviewed',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: const Color(0xFF90A4AE)),
          ),
        ],
      ),
    );
  }

  void _showPreview(Map<String, dynamic> item) {
    final isVideo = item['media_type'] == 'video';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVideo)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CustomImageWidget(
                    imageUrl: item['media_url'] ?? '',
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                    semanticLabel: item['caption'] ?? 'Provider media',
                  ),
                )
              else
                Container(
                  height: 180,
                  color: const Color(0xFF1A1C1E),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        Text('Video Link',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            item['media_url'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54, fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((item['caption'] ?? '').isNotEmpty)
                      Text(item['caption'],
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _buildProviderInfo(item),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text('Close',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic> item) {
    final sp = item['service_providers'] as Map<String, dynamic>?;
    final name = sp?['business_name'] ?? 'Unknown Provider';
    final category = sp?['category'] ?? '';
    return Row(
      children: [
        const Icon(Icons.store_rounded, size: 14, color: Color(0xFF90A4AE)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$name${category.isNotEmpty ? ' • $category' : ''}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: const Color(0xFF546E7A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Media Card Widget ────────────────────────────────────────────────────────
class _MediaCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onPreview;

  const _MediaCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onPreview,
  });

  Color get _statusColor {
    switch (item['moderation_status']) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (item['moderation_status']) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = item['media_type'] == 'video';
    final sp = item['service_providers'] as Map<String, dynamic>?;
    final providerName = sp?['business_name'] ?? 'Unknown';
    final status = item['moderation_status'] ?? 'pending';
    final isPending = status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: _statusColor.withValues(alpha: isPending ? 0.3 : 0.15),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          GestureDetector(
            onTap: onPreview,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                  child: isVideo
                      ? Container(
                          height: 120,
                          width: double.infinity,
                          color: const Color(0xFF1A1C1E),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline_rounded,
                                color: Colors.white70, size: 36),
                          ),
                        )
                      : CustomImageWidget(
                          imageUrl: item['thumbnail_url'] ??
                              item['media_url'] ??
                              '',
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          semanticLabel:
                              item['caption'] ?? 'Provider media item',
                        ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isVideo
                          ? Icons.videocam_rounded
                          : Icons.photo_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                // Preview tap overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPreview,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((item['caption'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item['caption'],
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: const Color(0xFF78909C)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if ((item['moderation_note'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['moderation_note'],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: AppTheme.error,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: isPending
                ? Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Approve',
                          icon: Icons.check_rounded,
                          color: AppTheme.success,
                          onTap: onApprove,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Reject',
                          icon: Icons.close_rounded,
                          color: AppTheme.error,
                          onTap: onReject,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (status == 'rejected')
                        Expanded(
                          child: _ActionBtn(
                            label: 'Approve',
                            icon: Icons.check_rounded,
                            color: AppTheme.success,
                            onTap: onApprove,
                          ),
                        ),
                      if (status == 'approved') ...[
                        Expanded(
                          child: _ActionBtn(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: onReject,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      _ActionBtn(
                        label: '',
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        onTap: onDelete,
                        compact: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 6, horizontal: compact ? 8 : 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}