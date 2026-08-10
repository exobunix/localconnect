import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ProviderKycUploadScreen extends StatefulWidget {
  const ProviderKycUploadScreen({super.key});

  @override
  State<ProviderKycUploadScreen> createState() =>
      _ProviderKycUploadScreenState();
}

class _ProviderKycUploadScreenState extends State<ProviderKycUploadScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _uploadingDocType;
  Map<String, dynamic>? _providerProfile;
  List<Map<String, dynamic>> _kycDocs = [];

  // Text controllers for structured data fields
  final Map<String, TextEditingController> _docNumberControllers = {
    'aadhaar': TextEditingController(),
    'pan_card': TextEditingController(),
    'bank_account': TextEditingController(),
    'gst_certificate': TextEditingController(),
  };

  final Map<String, Map<String, dynamic>> _docConfig = {
    'aadhaar': {
      'label': 'Aadhaar Card',
      'icon': Icons.credit_card_rounded,
      'color': const Color(0xFF1565C0),
      'description': 'Upload front & back of your Aadhaar card',
      'numberLabel': 'Aadhaar Number (12 digits)',
      'numberHint': 'XXXX XXXX XXXX',
      'requiresFile': true,
    },
    'pan_card': {
      'label': 'PAN Card',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF00695C),
      'description': 'Upload a clear photo of your PAN card',
      'numberLabel': 'PAN Number',
      'numberHint': 'ABCDE1234F',
      'requiresFile': true,
    },
    'bank_account': {
      'label': 'Bank Account',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF4527A0),
      'description': 'Upload cancelled cheque or bank passbook first page',
      'numberLabel': 'Account Number',
      'numberHint': 'Enter bank account number',
      'requiresFile': true,
    },
    'gst_certificate': {
      'label': 'GST Certificate',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFFBF360C),
      'description': 'Upload your GST registration certificate',
      'numberLabel': 'GSTIN',
      'numberHint': '22AAAAA0000A1Z5',
      'requiresFile': true,
    },
    'license': {
      'label': 'Business License',
      'icon': Icons.store_rounded,
      'color': const Color(0xFF2E7D32),
      'description': 'Upload your trade/business license or registration',
      'numberLabel': 'License Number (optional)',
      'numberHint': 'Enter license number',
      'requiresFile': true,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _docNumberControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = await SupabaseService.instance.getMyProviderProfile();
      if (provider == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final docs = await SupabaseService.instance.getMyKycDocuments(
        provider['id'] as String,
      );
      if (mounted) {
        setState(() {
          _providerProfile = provider;
          _kycDocs = docs;
          _isLoading = false;
        });
        // Pre-fill doc numbers from existing docs
        for (final doc in docs) {
          final docType = doc['doc_type'] as String? ?? '';
          final docNumber = doc['doc_number'] as String? ?? '';
          if (_docNumberControllers.containsKey(docType) &&
              docNumber.isNotEmpty) {
            _docNumberControllers[docType]!.text = docNumber;
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getDocByType(String docType) {
    try {
      return _kycDocs.firstWhere((d) => d['doc_type'] == docType);
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadDocument(String docType) async {
    final config = _docConfig[docType]!;
    final numberController = _docNumberControllers[docType];
    final docNumber = numberController?.text.trim() ?? '';

    final picker = ImagePicker();
    XFile? file;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Upload ${config['label']}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              ),
              title: Text(
                'Take Photo',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                file = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.success,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (file == null) return;

    setState(() {
      _isUploading = true;
      _uploadingDocType = docType;
    });

    try {
      final bytes = await file!.readAsBytes();
      final ext = file!.name.split('.').last.toLowerCase();
      final providerId = _providerProfile!['id'] as String;

      await SupabaseService.instance.uploadKycDocument(
        providerId: providerId,
        docType: docType,
        imageBytes: bytes,
        fileName: '${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext',
        mimeType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
        docNumber: docNumber.isNotEmpty ? docNumber : null,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document uploaded successfully!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingDocType = null;
        });
      }
    }
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Under Review';
    }
  }

  int get _approvedCount =>
      _kycDocs.where((d) => d['status'] == 'approved').length;
  int get _totalRequired =>
      5; // aadhaar/pan, bank, gst, license, business_proof

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
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Identity Documents',
                      Icons.person_rounded,
                      const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard('aadhaar', _docConfig['aadhaar']!),
                    _buildDocumentCard('pan_card', _docConfig['pan_card']!),
                    const SizedBox(height: 8),
                    _buildSectionHeader(
                      'Financial Documents',
                      Icons.account_balance_rounded,
                      const Color(0xFF4527A0),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                      'bank_account',
                      _docConfig['bank_account']!,
                    ),
                    _buildDocumentCard(
                      'gst_certificate',
                      _docConfig['gst_certificate']!,
                    ),
                    const SizedBox(height: 8),
                    _buildSectionHeader(
                      'Business Documents',
                      Icons.store_rounded,
                      const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard('license', _docConfig['license']!),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final kycStatus =
        _providerProfile?['kyc_status'] as String? ?? 'not_submitted';
    Color bannerColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerSubtitle;

    if (kycStatus == 'approved') {
      bannerColor = AppTheme.success;
      bannerIcon = Icons.verified_rounded;
      bannerTitle = 'KYC Verified ✓';
      bannerSubtitle = 'All documents approved. You can now accept bookings.';
    } else if (kycStatus == 'rejected') {
      bannerColor = AppTheme.error;
      bannerIcon = Icons.error_rounded;
      bannerTitle = 'KYC Rejected';
      bannerSubtitle =
          'Some documents were rejected. Please re-upload the rejected ones.';
    } else if (_kycDocs.isNotEmpty) {
      bannerColor = AppTheme.warning;
      bannerIcon = Icons.pending_rounded;
      bannerTitle = 'Under Review';
      bannerSubtitle =
          '$_approvedCount of ${_kycDocs.length} documents approved. Admin is reviewing your documents.';
    } else {
      bannerColor = AppTheme.info;
      bannerIcon = Icons.info_rounded;
      bannerTitle = 'KYC Required';
      bannerSubtitle =
          'Upload your documents to get approved and start accepting bookings.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(bannerIcon, color: bannerColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bannerSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: bannerColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String docType, Map<String, dynamic> config) {
    final existingDoc = _getDocByType(docType);
    final status = existingDoc?['status'] as String? ?? 'not_uploaded';
    final isUploading = _isUploading && _uploadingDocType == docType;
    final color = config['color'] as Color;
    final isRejected = status == 'rejected';
    final hasDoc = existingDoc != null;
    final numberController = _docNumberControllers[docType];
    final numberLabel = config['numberLabel'] as String? ?? '';
    final numberHint = config['numberHint'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: isRejected
            ? Border.all(color: AppTheme.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config['description'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDoc)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 12,
                          color: _statusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(status),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Document number input field
          if (numberController != null && status != 'approved')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: numberLabel,
                  hintText: numberHint,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outlineVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: color, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
            ),
          // Show doc number if approved
          if (hasDoc &&
              status == 'approved' &&
              (existingDoc['doc_number'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded, size: 14, color: AppTheme.success),
                  const SizedBox(width: 6),
                  Text(
                    existingDoc['doc_number'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (isRejected && existingDoc?['rejection_reason'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${existingDoc!['rejection_reason']}',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUploading || status == 'approved'
                    ? null
                    : () => _uploadDocument(docType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'approved'
                      ? AppTheme.success
                      : isRejected
                      ? AppTheme.error
                      : color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: status == 'approved'
                      ? AppTheme.success.withValues(alpha: 0.5)
                      : null,
                ),
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        status == 'approved'
                            ? Icons.check_rounded
                            : hasDoc
                            ? Icons.upload_rounded
                            : Icons.upload_file_rounded,
                        size: 16,
                      ),
                label: Text(
                  isUploading
                      ? 'Uploading...'
                      : status == 'approved'
                      ? 'Verified ✓'
                      : hasDoc
                      ? 'Re-upload'
                      : 'Upload Document',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Document Guidelines',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            '• Documents must be clear and readable',
            '• Accepted formats: JPG, PNG, WEBP',
            '• Maximum file size: 5 MB per document',
            '• Aadhaar: Upload both front and back',
            '• Bank Account: Upload cancelled cheque or passbook',
            '• GST: Upload GST registration certificate',
            '• All documents must be valid and not expired',
            '• Verification typically takes 1–2 business days',
            '• You can accept bookings only after KYC is approved',
          ].map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                t,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
