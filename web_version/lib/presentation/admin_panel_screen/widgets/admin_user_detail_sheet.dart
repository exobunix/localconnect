import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class AdminUserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onStatusChanged;

  const AdminUserDetailSheet({
    super.key,
    required this.user,
    this.onStatusChanged,
  });

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> user, {
    VoidCallback? onStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminUserDetailSheet(
        user: user,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<AdminUserDetailSheet> createState() => _AdminUserDetailSheetState();
}

class _AdminUserDetailSheetState extends State<AdminUserDetailSheet> {
  late Map<String, dynamic> _user;
  bool _isLoadingExtra = true;
  bool _isTogglingStatus = false;
  Map<String, dynamic>? _providerDetails;
  int _orderCount = 0;
  double _totalSpent = 0.0;
  String _userPassword = '';
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.user);
    _fetchExtraDetails();
  }

  Future<void> _fetchExtraDetails() async {
    final userId = _user['id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoadingExtra = false);
      return;
    }

    try {
      // 1. Fetch fresh profile from user_profiles to ensure phone & location are current
      final profile = await SupabaseService.instance.getUserProfile(userId);
      if (profile != null && mounted) {
        _user.addAll(profile);
      }

      // 2. If provider, fetch service_providers details
      final role = (_user['role'] ?? 'customer').toString().toLowerCase();
      if (role == 'provider') {
        final provResp = await SupabaseService.instance.client
            .from('service_providers')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        if (provResp != null && mounted) {
          _providerDetails = Map<String, dynamic>.from(provResp);
          if ((_user['phone'] ?? '').toString().isEmpty &&
              (provResp['phone'] ?? '').toString().isNotEmpty) {
            _user['phone'] = provResp['phone'];
          }
          if ((_user['city'] ?? '').toString().isEmpty &&
              (provResp['city'] ?? '').toString().isNotEmpty) {
            _user['city'] = provResp['city'];
          }
        }
      }

      // 3. Fetch order / booking count
      final orders = await SupabaseService.instance.client
          .from('orders')
          .select('id, total_amount, status')
          .eq('customer_id', userId);
      final list = List<Map<String, dynamic>>.from(orders);
      _orderCount = list.length;
      _totalSpent = list.fold<double>(
        0.0,
        (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0),
      );

      // 4. Fetch stored password from credentials vault
      final pwd = await SupabaseService.instance.adminGetUserPassword(
        userId: userId,
        email: _user['email']?.toString(),
        phone: _user['phone']?.toString(),
      );
      if (mounted) {
        _userPassword = pwd;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingExtra = false);
    }
  }

  Future<void> _toggleStatus() async {
    final userId = _user['id']?.toString();
    if (userId == null || userId.isEmpty) return;

    final currentActive = _user['is_active'] as bool? ?? true;
    setState(() => _isTogglingStatus = true);

    try {
      await SupabaseService.instance.adminToggleUserStatus(
        userId: userId,
        isActive: !currentActive,
      );
      setState(() {
        _user['is_active'] = !currentActive;
        _isTogglingStatus = false;
      });
      widget.onStatusChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_user['full_name']} is now ${!currentActive ? "Active" : "Suspended"}',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: !currentActive ? AppTheme.success : AppTheme.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _launchUrl(String uriString) async {
    final uri = Uri.tryParse(uriString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return const Color(0xFF6A1B9A);
      case 'area_manager':
      case 'area_admin':
      case 'admin':
        return const Color(0xFF00796B);
      case 'provider':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  String _roleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return '👑 Super Administrator';
      case 'area_manager':
      case 'area_admin':
        return '📍 Area Manager';
      case 'admin':
        return '🛡️ Administrator';
      case 'provider':
        return '🛠️ Service Provider';
      default:
        return '👤 Registered Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_user['full_name'] ?? 'Unknown User').toString();
    final email = (_user['email'] ?? '').toString();
    final phone = (_user['phone'] ?? '').toString();
    final role = (_user['role'] ?? 'customer').toString();
    final city = (_user['city'] ?? _user['assigned_area'] ?? '').toString();
    final address = (_user['address'] ?? _user['full_address'] ?? '').toString();
    final isActive = _user['is_active'] as bool? ?? true;
    final createdAt = _user['created_at'] != null
        ? DateTime.tryParse(_user['created_at'].toString())
        : null;
    final formattedDate = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, "0")}/${createdAt.month.toString().padLeft(2, "0")}/${createdAt.year} at ${createdAt.hour.toString().padLeft(2, "0")}:${createdAt.minute.toString().padLeft(2, "0")}'
        : 'Not recorded';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header Bar with Title & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'User Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _openEditProfileDialog,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isLoadingExtra)
              const LinearProgressIndicator(minHeight: 2, color: AppTheme.primary),
            // Body Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  // User Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                          backgroundImage: _user['avatar_url'] != null &&
                                  _user['avatar_url'].toString().isNotEmpty
                              ? NetworkImage(_user['avatar_url'].toString())
                              : null,
                          child: _user['avatar_url'] == null ||
                                  _user['avatar_url'].toString().isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: _roleColor(role),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _roleColor(role).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _roleDisplay(role),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _roleColor(role),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isActive ? 'Account Active' : 'Account Suspended',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.green[700] : Colors.red[700],
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
                  const SizedBox(height: 18),

                  // Section: Contact & Identity Information
                  _sectionHeader('Contact & Personal Information'),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.email_rounded,
                    iconColor: const Color(0xFF1E88E5),
                    title: 'Email Address',
                    value: email.isNotEmpty ? email : 'No email provided',
                    trailingAction: email.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy Email',
                                onPressed: () => _copyToClipboard(email, 'Email'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, size: 18),
                                tooltip: 'Send Email',
                                onPressed: () => _launchUrl('mailto:$email'),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF43A047),
                    title: 'Phone Number',
                    value: phone.isNotEmpty ? phone : 'No phone number provided',
                    trailingAction: phone.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy Phone',
                                onPressed: () => _copyToClipboard(phone, 'Phone number'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                                tooltip: 'Call Phone',
                                onPressed: () => _launchUrl('tel:$phone'),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFFE65100),
                    title: 'Account Password',
                    value: _userPassword.isNotEmpty
                        ? (_showPassword ? _userPassword : '•' * _userPassword.length)
                        : '••••••••',
                    subtitle: 'Current password for this account',
                    trailingAction: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18,
                            color: const Color(0xFFE65100),
                          ),
                          tooltip: _showPassword ? 'Hide Password' : 'Show Password',
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        if (_userPassword.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFE65100)),
                            tooltip: 'Copy Password',
                            onPressed: () => _copyToClipboard(_userPassword, 'Password'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.badge_rounded,
                    iconColor: const Color(0xFF8E24AA),
                    title: 'Register As / Account Type',
                    value: _roleDisplay(role),
                    subtitle: 'Internal Role ID: ${role.toLowerCase()}',
                  ),

                  const SizedBox(height: 18),
                  // Section: Geographical & Location Details
                  _sectionHeader('Geographical & Location Information'),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFFFB8C00),
                    title: 'Primary City / Region',
                    value: city.isNotEmpty ? city : 'Not specified',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFF00ACC1),
                    title: 'Residential / Full Address',
                    value: address.isNotEmpty ? address : 'Address not registered yet',
                  ),

                  const SizedBox(height: 18),
                  // Section: Account Activity & Registration Meta
                  _sectionHeader('Registration & Platform Metadata'),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF3949AB),
                    title: 'Registration Date (Joined)',
                    value: formattedDate,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: Colors.grey[700]!,
                    title: 'User Identification (UID)',
                    value: (_user['id'] ?? 'N/A').toString(),
                    trailingAction: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy UID',
                      onPressed: () => _copyToClipboard((_user['id'] ?? '').toString(), 'User UID'),
                    ),
                  ),

                  // If registered as Service Provider, display business block
                  if (_providerDetails != null) ...[
                    const SizedBox(height: 18),
                    _sectionHeader('Service Provider Business Information'),
                    const SizedBox(height: 8),
                    _buildDetailTile(
                      icon: Icons.storefront_rounded,
                      iconColor: AppTheme.success,
                      title: 'Business / Shop Name',
                      value: _providerDetails!['business_name'] ?? 'Not set',
                      subtitle: 'Owner: ${_providerDetails!['owner_name'] ?? name}',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailTile(
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFFD81B60),
                      title: 'Service Category & Specialization',
                      value: [
                        _providerDetails!['category'] ?? '',
                        _providerDetails!['subcategory'] ?? '',
                      ].where((s) => s.toString().isNotEmpty).join(' • '),
                      subtitle: 'Status: ${_providerDetails!['registration_status'] ?? "active"}',
                    ),
                  ],

                  // Activity Summary KPI
                  const SizedBox(height: 18),
                  _sectionHeader('Platform Activity & Transactions'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_orderCount',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                'Total Orders Placed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${_totalSpent.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              Text(
                                'Total Spent',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1976D2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(
                            'Edit Profile',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          onPressed: _openEditProfileDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? AppTheme.warning : AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isTogglingStatus
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded),
                          label: Text(
                            isActive ? 'Suspend' : 'Activate',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          onPressed: _isTogglingStatus ? null : _toggleStatus,
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
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.outline,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    Widget? trailingAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }

  // ─── EDIT PROFILE & CONTACT NUMBER DIALOGS ──────────────────────────────────

  void _openEditProfileDialog() {
    final role = (_user['role'] ?? 'customer').toString().toLowerCase();
    if (role == 'provider') {
      _showEditProviderDialog();
    } else {
      _showEditCustomerDialog();
    }
  }

  void _showEditCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: (_user['full_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (_user['phone'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (_user['email'] ?? '').toString());
    final passwordCtrl = TextEditingController(text: _userPassword);
    final cityCtrl = TextEditingController(text: (_user['city'] ?? _user['assigned_area'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (_user['address'] ?? _user['full_address'] ?? '').toString());
    bool isActive = _user['is_active'] as bool? ?? true;
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Customer Profile',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'Update password, contact & address information',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Contact phone highlight box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Primary Contact Number *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'e.g. 9876543210',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF2E7D32)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Contact number is required';
                              final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 10) return 'Enter a valid 10-digit phone number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Password Box (View & Edit)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, color: Color(0xFFF57F17), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Account Password (View & Change) *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                              const Spacer(),
                              if (passwordCtrl.text.isNotEmpty)
                                InkWell(
                                  onTap: () => _copyToClipboard(passwordCtrl.text, 'Password'),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE65100)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Copy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: passwordCtrl,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter minimum 6 characters',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFFF57F17)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: obscurePassword ? 2.0 : 0.5,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: const Icon(Icons.person_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City / Region',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Residential / Full Address',
                        prefixIcon: const Icon(Icons.home_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text(
                        'Account Active',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: isActive,
                      activeColor: AppTheme.success,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.outline)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSubmitting = true);

                final userId = (_user['id'] ?? '').toString();
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final city = cityCtrl.text.trim();
                final address = addressCtrl.text.trim();
                final pwd = passwordCtrl.text.trim();

                final ok = await SupabaseService.instance.adminUpdateCustomerProfile(
                  customerId: userId,
                  fullName: name,
                  phone: phone,
                  email: email,
                  city: city,
                  address: address,
                  isActive: isActive,
                  password: pwd,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    setState(() {
                      _user['full_name'] = name;
                      _user['phone'] = phone;
                      _user['email'] = email;
                      _user['city'] = city;
                      _user['address'] = address;
                      _user['full_address'] = address;
                      _user['is_active'] = isActive;
                      _userPassword = pwd;
                    });
                    widget.onStatusChanged?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Customer profile & contact updated successfully!'),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProviderDialog() {
    final formKey = GlobalKey<FormState>();
    final bizNameCtrl = TextEditingController(
      text: (_providerDetails?['business_name'] ?? _user['business_name'] ?? _user['full_name'] ?? '').toString(),
    );
    final ownerNameCtrl = TextEditingController(
      text: (_providerDetails?['owner_name'] ?? _user['owner_name'] ?? _user['full_name'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (_providerDetails?['phone'] ?? _user['phone'] ?? '').toString(),
    );
    final waCtrl = TextEditingController(
      text: (_providerDetails?['whatsapp'] ?? _providerDetails?['whatsapp_number'] ?? _user['phone'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (_providerDetails?['email'] ?? _user['email'] ?? '').toString(),
    );
    final passwordCtrl = TextEditingController(text: _userPassword);
    final categoryCtrl = TextEditingController(
      text: (_providerDetails?['category'] ?? _user['category'] ?? 'Home Maintenance').toString(),
    );
    final subcatCtrl = TextEditingController(
      text: (_providerDetails?['subcategory'] ?? _user['subcategory'] ?? '').toString(),
    );
    final cityCtrl = TextEditingController(
      text: (_providerDetails?['city'] ?? _user['city'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: (_providerDetails?['address'] ?? _user['address'] ?? '').toString(),
    );
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Provider Profile',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      'Update contact number & business details',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Contact phone highlight box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Primary Contact Number *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'e.g. 9876543210',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF2E7D32)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Contact number is required';
                              final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 10) return 'Enter a valid 10-digit phone number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account Password Box (View & Edit)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, color: Color(0xFFF57F17), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Account Password (View & Change) *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                              const Spacer(),
                              if (passwordCtrl.text.isNotEmpty)
                                InkWell(
                                  onTap: () => _copyToClipboard(passwordCtrl.text, 'Password'),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE65100)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Copy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: passwordCtrl,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter minimum 6 characters',
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFFF57F17)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20,
                                  color: Colors.grey[700],
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: obscurePassword ? 2.0 : 0.5,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bizNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Business / Shop Name *',
                        prefixIcon: const Icon(Icons.storefront_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: ownerNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Owner Full Name *',
                        prefixIcon: const Icon(Icons.person_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Owner name is required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: waCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'WhatsApp Number',
                              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setDialogState(() => waCtrl.text = phoneCtrl.text.trim()),
                          child: Text(
                            'Same as\nPhone',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: subcatCtrl,
                      decoration: InputDecoration(
                        labelText: 'Subcategory / Specialization',
                        prefixIcon: const Icon(Icons.build_circle_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City / Service Area *',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Shop / Business Address',
                        prefixIcon: const Icon(Icons.map_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.outline)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSubmitting = true);

                final userId = (_user['id'] ?? '').toString();
                final providerId = (_providerDetails?['id'] ?? _user['provider_id'] ?? '').toString();
                final biz = bizNameCtrl.text.trim();
                final owner = ownerNameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final wa = waCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final cat = categoryCtrl.text.trim();
                final subcat = subcatCtrl.text.trim();
                final city = cityCtrl.text.trim();
                final address = addressCtrl.text.trim();
                final pwd = passwordCtrl.text.trim();

                final ok = await SupabaseService.instance.adminUpdateServiceProviderProfile(
                  providerId: providerId.isNotEmpty ? providerId : userId,
                  userId: userId,
                  businessName: biz,
                  ownerName: owner,
                  phone: phone,
                  whatsapp: wa,
                  email: email,
                  category: cat,
                  subcategory: subcat,
                  city: city,
                  address: address,
                  password: pwd,
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    setState(() {
                      _user['full_name'] = owner;
                      _user['owner_name'] = owner;
                      _user['business_name'] = biz;
                      _user['phone'] = phone;
                      _user['whatsapp'] = wa;
                      _user['city'] = city;
                      _user['address'] = address;
                      _userPassword = pwd;
                      if (_providerDetails != null) {
                        _providerDetails!['business_name'] = biz;
                        _providerDetails!['owner_name'] = owner;
                        _providerDetails!['phone'] = phone;
                        _providerDetails!['whatsapp'] = wa;
                        _providerDetails!['category'] = cat;
                        _providerDetails!['subcategory'] = subcat;
                        _providerDetails!['city'] = city;
                        _providerDetails!['address'] = address;
                      }
                    });
                    widget.onStatusChanged?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Provider profile & contact updated successfully!'),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
