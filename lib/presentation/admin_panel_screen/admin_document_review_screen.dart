import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminDocumentReviewScreen extends StatefulWidget {
  const AdminDocumentReviewScreen({super.key});

  @override
  State<AdminDocumentReviewScreen> createState() =>
      _AdminDocumentReviewScreenState();
}

class _AdminDocumentReviewScreenState extends State<AdminDocumentReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _pendingProviders = [];
  List<Map<String, dynamic>> _approvedProviders = [];
  List<Map<String, dynamic>> _rejectedProviders = [];

  // Map of providerId -> list of their docs
  Map<String, List<Map<String, dynamic>>> _providerDocsMap = {};

  static const _identityTypes = {
    'aadhaar': 'Aadhaar Card',
    'pan_card': 'PAN Card',
    'passport': 'Passport',
    'voter_id': 'Voter ID',
    'driving_license': 'Driving License',
  };

  static const _businessTypes = {
    'gst_certificate': 'GST Certificate',
    'license': 'Business License',
    'shop_act': 'Shop Act License',
    'trade_license': 'Trade License',
    'business_proof': 'Business Proof',
    'msme': 'MSME Certificate',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load providers with pending_approval or docs-related statuses
      final allProviders = await SupabaseService.instance
          .getAdminAllProviders();
      final allDocs = await SupabaseService.instance.getAdminAllKycDocuments();

      // Build docs map by provider id
      final docsMap = <String, List<Map<String, dynamic>>>{};
      for (final doc in allDocs) {
        final pid = doc['provider_id'] as String? ?? '';
        if (pid.isEmpty) continue;
        docsMap.putIfAbsent(pid, () => []).add(doc);
      }

      // Filter providers who have submitted documents (identity + business)
      final withDocs = allProviders.where((p) {
        final pid = p['id'] as String? ?? '';
        final docs = docsMap[pid] ?? [];
        return docs.isNotEmpty;
      }).toList();

      final pending = withDocs.where((p) {
        final status = p['registration_status'] as String? ?? '';
        return status == 'pending_approval' || status == 'documents_submitted';
      }).toList();

      final approved = withDocs.where((p) {
        final status = p['registration_status'] as String? ?? '';
        return status == 'approved';
      }).toList();

      final rejected = withDocs.where((p) {
        final status = p['registration_status'] as String? ?? '';
        return status == 'rejected';
      }).toList();

      if (mounted) {
        setState(() {
          _providerDocsMap = docsMap;
          _pendingProviders = pending;
          _approvedProviders = approved;
          _rejectedProviders = rejected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterProviders(
    List<Map<String, dynamic>> providers,
  ) {
    if (_searchQuery.isEmpty) return providers;
    final q = _searchQuery.toLowerCase();
    return providers.where((p) {
      final name =
          (p['business_name'] as String? ?? p['full_name'] as String? ?? '')
              .toLowerCase();
      final city = (p['city'] as String? ?? '').toLowerCase();
      final category = (p['category'] as String? ?? '').toLowerCase();
      return name.contains(q) || city.contains(q) || category.contains(q);
    }).toList();
  }

  Future<void> _approveProvider(Map<String, dynamic> provider) async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Provider',
      message:
          'Approve all documents and activate this provider? They will be able to receive bookings immediately.',
      confirmLabel: 'Approve & Activate',
      confirmColor: AppTheme.success,
    );
    if (confirmed != true) return;

    try {
      final providerId = provider['id'] as String;
      // Approve all pending docs
      final docs = _providerDocsMap[providerId] ?? [];
      for (final doc in docs.where((d) => d['status'] == 'pending')) {
        await SupabaseService.instance.reviewKycDocument(
          docId: doc['id'] as String,
          status: 'approved',
          providerId: providerId,
          allDocs: docs,
        );
      }
      // Activate provider
      await SupabaseService.instance.approveProvider(providerId);
      _showSnack('Provider approved and activated!', AppTheme.success);
      await _loadData();
    } catch (e) {
      _showSnack('Failed to approve provider.', AppTheme.error);
    }
  }

  Future<void> _rejectProvider(Map<String, dynamic> provider) async {
    String feedbackNote = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Registration',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide feedback for the provider so they can resubmit:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => feedbackNote = v,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Identity document is blurry. Please resubmit a clearer photo.',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(
              'Reject',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final providerId = provider['id'] as String;
      final docs = _providerDocsMap[providerId] ?? [];
      for (final doc in docs.where((d) => d['status'] == 'pending')) {
        await SupabaseService.instance.reviewKycDocument(
          docId: doc['id'] as String,
          status: 'rejected',
          rejectionReason: feedbackNote.isNotEmpty
              ? feedbackNote
              : 'Documents not acceptable',
          providerId: providerId,
          allDocs: docs,
        );
      }
      // Update provider registration_status to rejected
      await SupabaseService.instance.client
          .from('service_providers')
          .update({
            'registration_status': 'rejected',
            'admin_note': feedbackNote.isNotEmpty
                ? feedbackNote
                : 'Documents not acceptable',
          })
          .eq('id', providerId);

      _showSnack('Provider registration rejected.', AppTheme.warning);
      await _loadData();
    } catch (e) {
      _showSnack('Failed to reject provider.', AppTheme.error);
    }
  }

  Future<void> _reviewSingleDoc(
    Map<String, dynamic> doc,
    String providerId,
  ) async {
    final docs = _providerDocsMap[providerId] ?? [];
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => _DocReviewDialog(doc: doc),
    );

    if (action == null) return;

    if (action == 'approve') {
      try {
        await SupabaseService.instance.reviewKycDocument(
          docId: doc['id'] as String,
          status: 'approved',
          providerId: providerId,
          allDocs: docs,
        );
        _showSnack('Document approved!', AppTheme.success);
        await _loadData();
      } catch (e) {
        _showSnack('Failed to approve document.', AppTheme.error);
      }
    } else if (action.startsWith('reject:')) {
      final reason = action.substring(7);
      try {
        await SupabaseService.instance.reviewKycDocument(
          docId: doc['id'] as String,
          status: 'rejected',
          rejectionReason: reason,
          providerId: providerId,
          allDocs: docs,
        );
        _showSnack('Document rejected.', AppTheme.warning);
        await _loadData();
      } catch (e) {
        _showSnack('Failed to reject document.', AppTheme.error);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(
              confirmLabel,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openProviderDetail(Map<String, dynamic> provider) {
    final providerId = provider['id'] as String? ?? '';
    final docs = _providerDocsMap[providerId] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProviderDocDetailSheet(
        provider: provider,
        docs: docs,
        identityTypes: _identityTypes,
        businessTypes: _businessTypes,
        onReviewDoc: (doc) async {
          Navigator.pop(ctx);
          await _reviewSingleDoc(doc, providerId);
        },
        onApproveAll: () async {
          Navigator.pop(ctx);
          await _approveProvider(provider);
        },
        onRejectAll: () async {
          Navigator.pop(ctx);
          await _rejectProvider(provider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Document Review',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, city, category…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.outline,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.outline,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.outline,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        const SizedBox(width: 4),
                        if (_pendingProviders.isNotEmpty)
                          _buildCountBadge(
                            _pendingProviders.length,
                            AppTheme.warning,
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Approved'),
                        const SizedBox(width: 4),
                        if (_approvedProviders.isNotEmpty)
                          _buildCountBadge(
                            _approvedProviders.length,
                            AppTheme.success,
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Rejected'),
                        const SizedBox(width: 4),
                        if (_rejectedProviders.isNotEmpty)
                          _buildCountBadge(
                            _rejectedProviders.length,
                            AppTheme.error,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProviderList(
                  _filterProviders(_pendingProviders),
                  emptyMessage: 'No pending document reviews',
                  emptyIcon: Icons.check_circle_outline_rounded,
                  isPending: true,
                ),
                _buildProviderList(
                  _filterProviders(_approvedProviders),
                  emptyMessage: 'No approved providers yet',
                  emptyIcon: Icons.verified_rounded,
                ),
                _buildProviderList(
                  _filterProviders(_rejectedProviders),
                  emptyMessage: 'No rejected providers',
                  emptyIcon: Icons.cancel_outlined,
                ),
              ],
            ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProviderList(
    List<Map<String, dynamic>> providers, {
    required String emptyMessage,
    required IconData emptyIcon,
    bool isPending = false,
  }) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        itemBuilder: (_, i) =>
            _buildProviderCard(providers[i], isPending: isPending),
      ),
    );
  }

  Widget _buildProviderCard(
    Map<String, dynamic> provider, {
    bool isPending = false,
  }) {
    final providerId = provider['id'] as String? ?? '';
    final name =
        provider['business_name'] as String? ??
        provider['full_name'] as String? ??
        'Unknown Provider';
    final category = provider['category'] as String? ?? '';
    final city = provider['city'] as String? ?? '';
    final registrationStatus = provider['registration_status'] as String? ?? '';
    final docs = _providerDocsMap[providerId] ?? [];

    final identityDocs = docs
        .where(
          (d) => _identityTypes.containsKey(d['doc_type'] as String? ?? ''),
        )
        .toList();
    final businessDocs = docs
        .where(
          (d) => _businessTypes.containsKey(d['doc_type'] as String? ?? ''),
        )
        .toList();

    final pendingCount = docs.where((d) => d['status'] == 'pending').length;
    final approvedCount = docs.where((d) => d['status'] == 'approved').length;
    final rejectedCount = docs.where((d) => d['status'] == 'rejected').length;

    return GestureDetector(
      onTap: () => _openProviderDetail(provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? AppTheme.warning.withValues(alpha: 0.3)
                : AppTheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            category,
                            city,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(registrationStatus),
                ],
              ),
            ),
            // Doc summary row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _buildDocTypeTag(
                    Icons.credit_card_rounded,
                    'Identity',
                    identityDocs.isEmpty
                        ? 'none'
                        : identityDocs.first['status'] as String? ?? 'pending',
                  ),
                  const SizedBox(width: 8),
                  _buildDocTypeTag(
                    Icons.store_rounded,
                    'Business',
                    businessDocs.isEmpty
                        ? 'none'
                        : businessDocs.first['status'] as String? ?? 'pending',
                  ),
                  const Spacer(),
                  if (pendingCount > 0)
                    _buildMiniCount(pendingCount, AppTheme.warning, 'pending'),
                  if (approvedCount > 0) ...[
                    const SizedBox(width: 4),
                    _buildMiniCount(
                      approvedCount,
                      AppTheme.success,
                      'approved',
                    ),
                  ],
                  if (rejectedCount > 0) ...[
                    const SizedBox(width: 4),
                    _buildMiniCount(rejectedCount, AppTheme.error, 'rejected'),
                  ],
                ],
              ),
            ),
            // Action buttons for pending
            if (isPending) ...[
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectProvider(provider),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        label: Text(
                          'Reject',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveProvider(provider),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Approve',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _openProviderDetail(provider),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocTypeTag(IconData icon, String label, String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.success;
        break;
      case 'rejected':
        color = AppTheme.error;
        break;
      case 'none':
        color = AppTheme.outline;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCount(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'approved':
        color = AppTheme.success;
        label = 'Approved';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        color = AppTheme.error;
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      case 'documents_submitted':
        color = AppTheme.info;
        label = 'Docs Submitted';
        icon = Icons.upload_file_rounded;
        break;
      default:
        color = AppTheme.warning;
        label = 'Pending';
        icon = Icons.pending_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Provider Document Detail Bottom Sheet ────────────────────────────────────

class _ProviderDocDetailSheet extends StatelessWidget {
  final Map<String, dynamic> provider;
  final List<Map<String, dynamic>> docs;
  final Map<String, String> identityTypes;
  final Map<String, String> businessTypes;
  final Future<void> Function(Map<String, dynamic> doc) onReviewDoc;
  final VoidCallback onApproveAll;
  final VoidCallback onRejectAll;

  const _ProviderDocDetailSheet({
    required this.provider,
    required this.docs,
    required this.identityTypes,
    required this.businessTypes,
    required this.onReviewDoc,
    required this.onApproveAll,
    required this.onRejectAll,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        provider['business_name'] as String? ??
        provider['full_name'] as String? ??
        'Provider';
    final category = provider['category'] as String? ?? '';
    final city = provider['city'] as String? ?? '';
    final phone = provider['phone'] as String? ?? '';
    final registrationStatus = provider['registration_status'] as String? ?? '';
    final adminNote = provider['admin_note'] as String? ?? '';

    final identityDocs = docs
        .where((d) => identityTypes.containsKey(d['doc_type'] as String? ?? ''))
        .toList();
    final businessDocs = docs
        .where((d) => businessTypes.containsKey(d['doc_type'] as String? ?? ''))
        .toList();
    final hasPending = docs.any((d) => d['status'] == 'pending');

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Provider header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            category,
                            city,
                            phone,
                          ].where((s) => s.isNotEmpty).join(' • '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _statusChip(registrationStatus),
                ],
              ),
            ),
            // Admin note if rejected
            if (adminNote.isNotEmpty && registrationStatus == 'rejected')
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.feedback_rounded,
                      size: 16,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection Feedback',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            adminNote,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Identity Documents Section
                  _sectionHeader(
                    Icons.credit_card_rounded,
                    'Identity Documents',
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 8),
                  if (identityDocs.isEmpty)
                    _emptyDocNote('No identity document submitted')
                  else
                    ...identityDocs.map(
                      (doc) => _buildDocCard(
                        context,
                        doc,
                        identityTypes[doc['doc_type'] as String? ?? ''] ??
                            (doc['doc_type'] as String? ?? 'Document'),
                        onReview: () => onReviewDoc(doc),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Business License Section
                  _sectionHeader(
                    Icons.store_rounded,
                    'Business License Documents',
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 8),
                  if (businessDocs.isEmpty)
                    _emptyDocNote('No business license document submitted')
                  else
                    ...businessDocs.map(
                      (doc) => _buildDocCard(
                        context,
                        doc,
                        businessTypes[doc['doc_type'] as String? ?? ''] ??
                            (doc['doc_type'] as String? ?? 'Document'),
                        onReview: () => onReviewDoc(doc),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            // Bottom action bar for pending
            if (hasPending)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRejectAll,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        label: Text(
                          'Reject All',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onApproveAll,
                        icon: const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Approve & Activate',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _emptyDocNote(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        msg,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppTheme.outline,
        ),
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context,
    Map<String, dynamic> doc,
    String docLabel, {
    required VoidCallback onReview,
  }) {
    final status = doc['status'] as String? ?? 'pending';
    final docNumber = doc['doc_number'] as String? ?? '';
    final docUrl = doc['doc_url'] as String? ?? '';
    final rejectionReason = doc['rejection_reason'] as String? ?? '';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppTheme.warning;
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (docNumber.isNotEmpty)
                        Text(
                          docNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Document image preview
          if (docUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _viewFullImage(context, docUrl, docLabel),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        docUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 40,
                            color: AppTheme.outline,
                          ),
                        ),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.zoom_in_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Rejection reason
          if (status == 'rejected' && rejectionReason.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rejectionReason,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Review button for pending docs
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(
                    Icons.rate_review_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  label: Text(
                    'Review This Document',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = AppTheme.success;
        label = 'Approved';
        break;
      case 'rejected':
        color = AppTheme.error;
        label = 'Rejected';
        break;
      case 'documents_submitted':
        color = AppTheme.info;
        label = 'Docs Submitted';
        break;
      default:
        color = AppTheme.warning;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Single Document Review Dialog ───────────────────────────────────────────

class _DocReviewDialog extends StatefulWidget {
  final Map<String, dynamic> doc;

  const _DocReviewDialog({required this.doc});

  @override
  State<_DocReviewDialog> createState() => _DocReviewDialogState();
}

class _DocReviewDialogState extends State<_DocReviewDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docType = widget.doc['doc_type'] as String? ?? '';
    final docNumber = widget.doc['doc_number'] as String? ?? '';
    final docUrl = widget.doc['doc_url'] as String? ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.rate_review_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Review Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doc info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                docType
                                    .replaceAll('_', ' ')
                                    .split(' ')
                                    .map(
                                      (w) => w.isEmpty
                                          ? w
                                          : w[0].toUpperCase() + w.substring(1),
                                    )
                                    .join(' '),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (docNumber.isNotEmpty)
                                Text(
                                  docNumber,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.outline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Image preview
                  if (docUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        docUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: AppTheme.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: AppTheme.outline,
                            ),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                height: 100,
                                color: AppTheme.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                  // Feedback note (shown when rejecting)
                  if (_isRejecting) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Feedback note for provider:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Document is blurry, expired, or incorrect type',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.error),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: _isRejecting
          ? [
              TextButton(
                onPressed: () => setState(() => _isRejecting = false),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = _feedbackController.text.trim();
                  Navigator.pop(
                    context,
                    'reject:${reason.isNotEmpty ? reason : 'Document not acceptable'}',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: Text(
                  'Confirm Reject',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
              ),
            ]
          : [
              OutlinedButton.icon(
                onPressed: () => setState(() => _isRejecting = true),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppTheme.error,
                ),
                label: Text(
                  'Reject',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'approve'),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  'Approve',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
    );
  }
}
