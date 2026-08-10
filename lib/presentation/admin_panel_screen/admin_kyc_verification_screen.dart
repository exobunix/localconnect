import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminKycVerificationScreen extends StatefulWidget {
  const AdminKycVerificationScreen({super.key});

  @override
  State<AdminKycVerificationScreen> createState() =>
      _AdminKycVerificationScreenState();
}

class _AdminKycVerificationScreenState extends State<AdminKycVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allDocs = [];
  List<Map<String, dynamic>> _pendingDocs = [];
  List<Map<String, dynamic>> _approvedDocs = [];
  List<Map<String, dynamic>> _rejectedDocs = [];

  final Map<String, Map<String, dynamic>> _docConfig = {
    'aadhaar': {
      'label': 'Aadhaar Card',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF1565C0),
    },
    'pan_card': {
      'label': 'PAN Card',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF00695C),
    },
    'bank_account': {
      'label': 'Bank Account',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF4527A0),
    },
    'gst_certificate': {
      'label': 'GST Certificate',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFBF360C),
    },
    'license': {
      'label': 'Business License',
      'icon': Icons.store_rounded,
      'color': const Color(0xFF2E7D32),
    },
    'business_proof': {
      'label': 'Business Proof',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFF6A1B9A),
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    setState(() => _isLoading = true);
    try {
      final docs = await SupabaseService.instance.getAdminAllKycDocuments();
      if (mounted) {
        setState(() {
          _allDocs = docs;
          _pendingDocs = docs.where((d) => d['status'] == 'pending').toList();
          _approvedDocs = docs.where((d) => d['status'] == 'approved').toList();
          _rejectedDocs = docs.where((d) => d['status'] == 'rejected').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDocument(Map<String, dynamic> doc) async {
    try {
      await SupabaseService.instance.reviewKycDocument(
        docId: doc['id'] as String,
        status: 'approved',
        providerId: doc['provider_id'] as String,
        allDocs: _allDocs,
      );
      _showSnack('Document approved!', AppTheme.success);
      await _loadDocs();
    } catch (e) {
      _showSnack('Failed to approve document.', AppTheme.error);
    }
  }

  Future<void> _rejectDocument(Map<String, dynamic> doc) async {
    String reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Document',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide a reason for rejection:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => reason = v,
              decoration: InputDecoration(
                hintText: 'e.g. Document is blurry or expired',
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
              maxLines: 2,
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
      await SupabaseService.instance.reviewKycDocument(
        docId: doc['id'] as String,
        status: 'rejected',
        rejectionReason: reason.isNotEmpty ? reason : 'Document not acceptable',
        providerId: doc['provider_id'] as String,
        allDocs: _allDocs,
      );
      _showSnack('Document rejected.', AppTheme.warning);
      await _loadDocs();
    } catch (e) {
      _showSnack('Failed to reject document.', AppTheme.error);
    }
  }

  void _viewDocument(Map<String, dynamic> doc) {
    final docUrl = doc['doc_url'] as String? ?? '';
    final docType = doc['doc_type'] as String? ?? '';
    final config = _docConfig[docType] ?? _docConfig['aadhaar']!;
    final docNumber = doc['doc_number'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (config['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      config['icon'] as IconData,
                      color: config['color'] as Color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (docNumber.isNotEmpty)
                          Text(
                            docNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            if (docUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Image.network(
                  docUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, size: 48),
                    ),
                  ),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 200,
                          color: AppTheme.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
              )
            else
              Container(
                height: 200,
                color: AppTheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.image_not_supported_rounded, size: 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProviderKycDetail(List<Map<String, dynamic>> docs) {
    final firstDoc = docs.first;
    final providerName =
        firstDoc['service_providers']?['business_name'] as String? ??
        firstDoc['service_providers']?['full_name'] as String? ??
        'Provider';
    final providerCategory =
        firstDoc['service_providers']?['category'] as String? ?? '';
    final providerCity =
        firstDoc['service_providers']?['city'] as String? ?? '';
    final providerId = firstDoc['service_providers']?['id'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        providerName[0].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
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
                            providerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (providerCategory.isNotEmpty ||
                              providerCity.isNotEmpty)
                            Text(
                              [
                                providerCategory,
                                providerCity,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildKycStatusChip(docs),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildDetailDocCard(
                    docs[i],
                    showActions: docs[i]['status'] == 'pending',
                    onApprove: () {
                      Navigator.pop(ctx);
                      _approveDocument(docs[i]);
                    },
                    onReject: () {
                      Navigator.pop(ctx);
                      _rejectDocument(docs[i]);
                    },
                  ),
                ),
              ),
              // Approve All / Reject All buttons for pending
              if (docs.any((d) => d['status'] == 'pending'))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            for (final doc in docs.where(
                              (d) => d['status'] == 'pending',
                            )) {
                              await _rejectDocument(doc);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(
                            'Reject All Pending',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            for (final doc in docs.where(
                              (d) => d['status'] == 'pending',
                            )) {
                              await _approveDocument(doc);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            'Approve All Pending',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildKycStatusChip(List<Map<String, dynamic>> docs) {
    final allApproved =
        docs.isNotEmpty && docs.every((d) => d['status'] == 'approved');
    final anyRejected = docs.any((d) => d['status'] == 'rejected');
    final anyPending = docs.any((d) => d['status'] == 'pending');

    Color color;
    String label;
    IconData icon;

    if (allApproved) {
      color = AppTheme.success;
      label = 'Verified';
      icon = Icons.verified_rounded;
    } else if (anyRejected) {
      color = AppTheme.error;
      label = 'Rejected';
      icon = Icons.cancel_rounded;
    } else if (anyPending) {
      color = AppTheme.warning;
      label = 'Pending';
      icon = Icons.pending_rounded;
    } else {
      color = AppTheme.outline;
      label = 'No Docs';
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildDetailDocCard(
    Map<String, dynamic> doc, {
    required bool showActions,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    final docType = doc['doc_type'] as String? ?? '';
    final status = doc['status'] as String? ?? 'pending';
    final config = _docConfig[docType] ?? _docConfig['aadhaar']!;
    final color = config['color'] as Color;
    final docNumber = doc['doc_number'] as String? ?? '';
    final uploadedAt = doc['uploaded_at'] != null
        ? DateTime.tryParse(doc['uploaded_at'] as String)
        : null;
    final reviewedAt = doc['reviewed_at'] != null
        ? DateTime.tryParse(doc['reviewed_at'] as String)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (docNumber.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              size: 12,
                              color: AppTheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              docNumber,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (uploadedAt != null)
                        Text(
                          'Uploaded ${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (doc['rejection_reason'] != null && status == 'rejected')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${doc['rejection_reason']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (reviewedAt != null && status != 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text(
                'Reviewed on ${reviewedAt.day}/${reviewedAt.month}/${reviewedAt.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDocument(doc),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: Text(
                      'View Doc',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: Text(
                        'Approve',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'KYC Verification',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDocs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingDocs.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingDocs.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProviderList(_pendingDocs, showActions: true),
                      _buildProviderList(_approvedDocs, showActions: false),
                      _buildProviderList(_rejectedDocs, showActions: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBar() {
    // Count unique providers
    final pendingProviders = _pendingDocs
        .map((d) => d['provider_id'] as String? ?? '')
        .toSet()
        .length;
    final approvedProviders = _approvedDocs
        .map((d) => d['provider_id'] as String? ?? '')
        .toSet()
        .length;
    final rejectedProviders = _rejectedDocs
        .map((d) => d['provider_id'] as String? ?? '')
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildStat('Total Docs', _allDocs.length, AppTheme.primary),
          const SizedBox(width: 12),
          _buildStat(
            'Pending',
            _pendingDocs.length,
            AppTheme.warning,
            sub: '$pendingProviders providers',
          ),
          const SizedBox(width: 12),
          _buildStat(
            'Approved',
            _approvedDocs.length,
            AppTheme.success,
            sub: '$approvedProviders providers',
          ),
          const SizedBox(width: 12),
          _buildStat(
            'Rejected',
            _rejectedDocs.length,
            AppTheme.error,
            sub: '$rejectedProviders providers',
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color, {String? sub}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (sub != null)
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppTheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderList(
    List<Map<String, dynamic>> docs, {
    required bool showActions,
  }) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: AppTheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No documents here',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Group by provider
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in docs) {
      final pid = doc['provider_id'] as String? ?? 'unknown';
      grouped.putIfAbsent(pid, () => []).add(doc);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final entry = grouped.entries.elementAt(i);
        return _buildProviderKycCard(entry.value, showActions: showActions);
      },
    );
  }

  Widget _buildProviderKycCard(
    List<Map<String, dynamic>> docs, {
    required bool showActions,
  }) {
    final firstDoc = docs.first;
    final providerName =
        firstDoc['service_providers']?['business_name'] as String? ??
        firstDoc['service_providers']?['full_name'] as String? ??
        'Provider';
    final providerCategory =
        firstDoc['service_providers']?['category'] as String? ?? '';
    final providerCity =
        firstDoc['service_providers']?['city'] as String? ?? '';

    final approvedCount = docs.where((d) => d['status'] == 'approved').length;
    final pendingCount = docs.where((d) => d['status'] == 'pending').length;
    final rejectedCount = docs.where((d) => d['status'] == 'rejected').length;

    return GestureDetector(
      onTap: () => _showProviderKycDetail(docs),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      providerName[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (providerCategory.isNotEmpty ||
                            providerCity.isNotEmpty)
                          Text(
                            [
                              providerCategory,
                              providerCity,
                            ].where((s) => s.isNotEmpty).join(' • '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildKycStatusChip(docs),
                ],
              ),
            ),
            // Document type chips
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: docs.map((doc) {
                  final docType = doc['doc_type'] as String? ?? '';
                  final status = doc['status'] as String? ?? 'pending';
                  final config = _docConfig[docType] ?? _docConfig['aadhaar']!;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor(status).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config['icon'] as IconData,
                          size: 11,
                          color: _statusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          config['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(status),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$approvedCount/${docs.length} approved',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                      Row(
                        children: [
                          if (pendingCount > 0)
                            Text(
                              '$pendingCount pending',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (rejectedCount > 0) ...[
                            if (pendingCount > 0) const Text('  '),
                            Text(
                              '$rejectedCount rejected',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: docs.isEmpty ? 0 : approvedCount / docs.length,
                      backgroundColor: AppTheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        approvedCount == docs.length
                            ? AppTheme.success
                            : AppTheme.primary,
                      ),
                      minHeight: 6,
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
