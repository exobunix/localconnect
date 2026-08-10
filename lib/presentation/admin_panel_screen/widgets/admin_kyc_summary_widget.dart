import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class AdminKycSummaryWidget extends StatefulWidget {
  const AdminKycSummaryWidget({super.key});

  @override
  State<AdminKycSummaryWidget> createState() => _AdminKycSummaryWidgetState();
}

class _AdminKycSummaryWidgetState extends State<AdminKycSummaryWidget> {
  bool _isLoading = true;
  int _pendingDocs = 0;
  int _pendingProviders = 0;
  int _approvedProviders = 0;
  int _rejectedProviders = 0;
  List<Map<String, dynamic>> _recentPending = [];

  final Map<String, Map<String, dynamic>> _docConfig = {
    'aadhaar': {
      'label': 'Aadhaar',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF1565C0),
    },
    'pan_card': {
      'label': 'PAN Card',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF00695C),
    },
    'bank_account': {
      'label': 'Bank A/C',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF4527A0),
    },
    'gst_certificate': {
      'label': 'GST',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFBF360C),
    },
    'license': {
      'label': 'License',
      'icon': Icons.store_rounded,
      'color': const Color(0xFF2E7D32),
    },
    'business_proof': {
      'label': 'Biz Proof',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFF6A1B9A),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final docs = await SupabaseService.instance.getAdminAllKycDocuments();

      final pending = docs.where((d) => d['status'] == 'pending').toList();
      final approved = docs.where((d) => d['status'] == 'approved').toList();
      final rejected = docs.where((d) => d['status'] == 'rejected').toList();

      final pendingProviderIds = pending
          .map((d) => d['provider_id'] as String? ?? '')
          .toSet();
      final approvedProviderIds = approved
          .map((d) => d['provider_id'] as String? ?? '')
          .toSet();
      final rejectedProviderIds = rejected
          .map((d) => d['provider_id'] as String? ?? '')
          .toSet();

      // Get recent 3 pending docs grouped by provider
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final doc in pending) {
        final pid = doc['provider_id'] as String? ?? 'unknown';
        grouped.putIfAbsent(pid, () => []).add(doc);
      }
      final recentPendingGroups = grouped.entries.take(3).toList();

      if (mounted) {
        setState(() {
          _pendingDocs = pending.length;
          _pendingProviders = pendingProviderIds.length;
          _approvedProviders = approvedProviderIds.length;
          _rejectedProviders = rejectedProviderIds.length;
          _recentPending = recentPendingGroups
              .map(
                (e) => {
                  'provider_id': e.key,
                  'docs': e.value,
                  'provider_name':
                      e.value.first['service_providers']?['business_name']
                          as String? ??
                      e.value.first['service_providers']?['full_name']
                          as String? ??
                      'Provider',
                  'category':
                      e.value.first['service_providers']?['category']
                          as String? ??
                      '',
                },
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF1565C0),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYC Verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        'Provider document review panel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pendingDocs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pending_rounded,
                          size: 12,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_pendingDocs pending',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else ...[
            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _buildStatCard(
                    'Pending',
                    _pendingProviders,
                    AppTheme.warning,
                    Icons.hourglass_top_rounded,
                    '$_pendingDocs docs',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Verified',
                    _approvedProviders,
                    AppTheme.success,
                    Icons.verified_rounded,
                    'providers',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    'Rejected',
                    _rejectedProviders,
                    AppTheme.error,
                    Icons.cancel_rounded,
                    'providers',
                  ),
                ],
              ),
            ),
            // Recent pending providers
            if (_recentPending.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Awaiting Review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ),
              ..._recentPending.map((item) => _buildPendingProviderRow(item)),
            ],
            // View All button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.adminKycVerificationScreen,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    'Open KYC Review Panel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color,
    IconData icon,
    String sub,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingProviderRow(Map<String, dynamic> item) {
    final providerName = item['provider_name'] as String;
    final category = item['category'] as String;
    final docs = item['docs'] as List<Map<String, dynamic>>;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                providerName[0].toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            // Doc type mini chips
            Wrap(
              spacing: 4,
              children: docs.take(3).map((doc) {
                final docType = doc['doc_type'] as String? ?? '';
                final config = _docConfig[docType] ?? _docConfig['aadhaar']!;
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    size: 12,
                    color: config['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
