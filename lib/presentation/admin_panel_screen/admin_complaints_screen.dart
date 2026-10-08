import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _complaints = [];
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAdminComplaints(
        status: _statusFilter == 'all' ? null : _statusFilter,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _complaints = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_searchQuery.isEmpty) return _complaints;
    return _complaints.where((c) {
      final num = (c['complaint_number'] ?? '').toString().toLowerCase();
      final cust = (c['customer_name'] ?? '').toString().toLowerCase();
      final prov = (c['provider_name'] ?? '').toString().toLowerCase();
      final issue = (c['issue'] ?? '').toString().toLowerCase();
      return num.contains(_searchQuery) ||
          cust.contains(_searchQuery) ||
          prov.contains(_searchQuery) ||
          issue.contains(_searchQuery);
    }).toList();
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  String? _extractEnquiryId(String issueText, String? orderId) {
    if (orderId != null && orderId.isNotEmpty) {
      return orderId;
    }
    final refMatch = RegExp(r'\[Ref:\s*#?([a-zA-Z0-9\-_]+)\]').firstMatch(issueText);
    if (refMatch != null) {
      return refMatch.group(1);
    }
    return null;
  }

  Future<void> _showReplyDialog(Map<String, dynamic> c) async {
    final complaintId = c['id']?.toString() ?? '';
    final complaintNum = c['complaint_number']?.toString() ?? '';
    final customerId = c['customer_id']?.toString();
    final providerId = c['provider_id']?.toString();
    final customerName = c['customer_name']?.toString() ?? 'Customer';
    final providerName = c['provider_name']?.toString() ?? 'Provider';

    final textController = TextEditingController();
    bool notifyCust = true;
    bool notifyProv = true;
    bool markResolved = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.reply_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reply to Complaint ($complaintNum)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complainant: $customerName vs $providerName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter Admin resolution / explanation for customer & partner...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: notifyCust,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primary,
                  title: Text(
                    'Send notification to Customer ($customerName)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (val) => setDlgState(() => notifyCust = val ?? true),
                ),
                CheckboxListTile(
                  value: notifyProv,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primary,
                  title: Text(
                    'Send notification to Partner ($providerName)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (val) => setDlgState(() => notifyProv = val ?? true),
                ),
                CheckboxListTile(
                  value: markResolved,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.success,
                  title: Text(
                    'Mark complaint as Resolved',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                  onChanged: (val) => setDlgState(() => markResolved = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reply = textController.text.trim();
                      if (reply.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a response message.')),
                        );
                        return;
                      }

                      setDlgState(() => isSubmitting = true);
                      final ok = await SupabaseService.instance.adminReplyToComplaint(
                        complaintId: complaintId,
                        complaintNumber: complaintNum,
                        replyText: reply,
                        customerId: customerId,
                        providerId: providerId,
                        notifyCustomer: notifyCust,
                        notifyProvider: notifyProv,
                        markResolved: markResolved,
                      );

                      if (mounted) {
                        Navigator.pop(ctx);
                        _loadComplaints();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Response sent & complaint updated successfully!' : 'Failed to save response.',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                            backgroundColor: ok ? AppTheme.success : AppTheme.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeProviderDialog(Map<String, dynamic> c) async {
    final complaintId = c['id']?.toString() ?? '';
    final issueText = c['issue']?.toString() ?? '';
    final currentProvId = c['provider_id']?.toString() ?? '';
    final currentProvName = c['provider_name']?.toString() ?? 'Current Provider';
    final enquiryId = _extractEnquiryId(issueText, c['order_id']?.toString());

    if (enquiryId == null || enquiryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot automatically change provider: No enquiry/booking reference found in this complaint record.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reasonController = TextEditingController(
      text: 'Reassigned due to customer complaint: $issueText',
    );
    Map<String, dynamic>? selectedProvider;
    List<Map<String, dynamic>> availableProviders = [];
    bool isLoadingProviders = true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          if (isLoadingProviders && availableProviders.isEmpty) {
            SupabaseService.instance.adminGetProvidersForDispatch().then((list) {
              setDlgState(() {
                availableProviders = list.where((p) => p['id']?.toString() != currentProvId).toList();
                isLoadingProviders = false;
              });
            }).catchError((_) {
              setDlgState(() => isLoadingProviders = false);
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reassign / Change Provider',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        'Current Assigned Provider: $currentProvName',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9F1239),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Replacement Provider:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isLoadingProviders)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (availableProviders.isEmpty)
                      Text(
                        'No alternative active providers found.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: availableProviders.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final p = availableProviders[i];
                            final isSel = selectedProvider?['id'] == p['id'];
                            final bName = p['business_name'] ?? 'Provider';
                            final phone = p['phone'] ?? '';
                            final city = p['city'] ?? '';
                            return ListTile(
                              dense: true,
                              selected: isSel,
                              selectedTileColor: const Color(0xFFEFF6FF),
                              leading: Icon(
                                isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSel ? const Color(0xFF2563EB) : Colors.grey,
                                size: 18,
                              ),
                              title: Text(
                                bName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '$city • $phone',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11),
                              ),
                              onTap: () => setDlgState(() => selectedProvider = p),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Reassignment Reason / Note for Customer & Partner:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (selectedProvider == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a replacement provider.')),
                          );
                          return;
                        }

                        setDlgState(() => isSubmitting = true);
                        final ok = await SupabaseService.instance.adminReassignProviderForComplaint(
                          complaintId: complaintId,
                          enquiryId: enquiryId,
                          newProvider: selectedProvider!,
                          reasonNote: reasonController.text.trim(),
                          previousProviderId: currentProvId,
                          previousProviderName: currentProvName,
                        );

                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadComplaints();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Provider reassigned successfully! Ringing alert sent to new partner.'
                                    : 'Failed to reassign provider.',
                                style: GoogleFonts.plusJakartaSans(),
                              ),
                              backgroundColor: ok ? AppTheme.success : AppTheme.error,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirm & Reassign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredComplaints;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Customer & Partner Complaints',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadComplaints,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by complaint #, customer, partner, or issue...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in ['all', 'open', 'resolved', 'closed'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _statusFilter = s);
                              _loadComplaints();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusFilter == s ? AppTheme.primary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusFilter == s ? AppTheme.primary : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                s == 'all'
                                    ? 'All (${_complaints.length})'
                                    : '${s[0].toUpperCase()}${s.substring(1)} (${_complaints.where((c) => (c['status'] ?? '').toLowerCase() == s).length})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _statusFilter == s ? Colors.white : const Color(0xFF475569),
                                ),
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
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Complaints list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.success),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No matching complaints found' : 'No complaints queue',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadComplaints,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _buildComplaintCard(list[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final complaintNum = c['complaint_number'] ?? 'CMP';
    final severity = (c['severity'] ?? 'medium').toString().toLowerCase();
    final status = (c['status'] ?? 'open').toString().toLowerCase();
    final issue = c['issue']?.toString() ?? '';
    final adminNote = c['admin_note']?.toString() ?? '';
    final customerName = c['customer_name']?.toString() ?? 'Customer';
    final providerName = c['provider_name']?.toString() ?? 'Provider';
    final createdAt = _timeAgo(c['created_at']?.toString());
    final isResolved = status == 'resolved' || status == 'closed';
    final hasRef = issue.contains('[Ref:');

    final severityColor = severity == 'high'
        ? const Color(0xFFE11D48)
        : severity == 'medium'
            ? const Color(0xFFD97706)
            : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: severity == 'high'
              ? const Color(0xFFFECDD3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Number, Severity, Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaintNum,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: severityColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isResolved
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isResolved
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer and Partner info
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 15, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customerName,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF7C3AED)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  providerName,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Issue description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              issue,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Admin Resolution / Reply Banner (if present)
          if (adminNote.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Resolution / Action:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adminNote,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Footer actions: Change Provider, Reply to Complainant, Quick Resolve
          Row(
            children: [
              Text(
                createdAt,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8)),
              ),
              const Spacer(),

              // Change Provider Button
              if (hasRef || c['order_id'] != null)
                OutlinedButton.icon(
                  onPressed: () => _showChangeProviderDialog(c),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                  label: Text(
                    'Change Provider',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(width: 6),

              // Reply & Resolve Button
              ElevatedButton.icon(
                onPressed: () => _showReplyDialog(c),
                icon: const Icon(Icons.reply_rounded, size: 14),
                label: Text(
                  adminNote.isNotEmpty ? 'Edit Reply' : 'Reply & Resolve',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
