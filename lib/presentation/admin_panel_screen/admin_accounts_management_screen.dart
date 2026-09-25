import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/admin_auth_service.dart';
import '../../theme/app_theme.dart';

class AdminAccountsManagementScreen extends StatefulWidget {
  const AdminAccountsManagementScreen({super.key});

  @override
  State<AdminAccountsManagementScreen> createState() =>
      _AdminAccountsManagementScreenState();
}

class _AdminAccountsManagementScreenState
    extends State<AdminAccountsManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _admins = [];
  String _searchQuery = '';
  String _areaFilter = 'ALL';

  static const List<String> _commonCities = [
    'ALL',
    'Pune',
    'Mumbai',
    'Nashik',
    'Aurangabad',
    'Nagpur',
    'Kolhapur',
    'Alibag',
    'Roha',
    'Pen',
    'Panvel',
    'Khopoli',
    'Karjat',
  ];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getAllAdmins();
      if (mounted) {
        setState(() {
          _admins = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAdmins {
    return _admins.where((a) {
      final name = (a['full_name'] ?? '').toString().toLowerCase();
      final email = (a['email'] ?? '').toString().toLowerCase();
      final area = (a['assigned_area'] ?? '').toString();
      final matchesQuery =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          area.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesArea = _areaFilter == 'ALL' || area == _areaFilter;
      return matchesQuery && matchesArea;
    }).toList();
  }

  void _showAddEditAdminDialog({Map<String, dynamic>? admin}) {
    final isEditing = admin != null;
    final nameCtrl = TextEditingController(text: admin?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: admin?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: admin?['phone'] ?? '');
    final passwordCtrl = TextEditingController(
      text: isEditing ? '' : 'Admin@1234',
    );
    String selectedRole = admin?['role'] ?? 'area_admin';
    String selectedArea = admin?['assigned_area'] ?? 'Pune';
    bool isActive = admin?['is_active'] ?? true;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Admin Account' : 'Create New Admin',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Initial Password',
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword,
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Admin Role',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super Admin (Full Access)'),
                    ),
                    DropdownMenuItem(
                      value: 'area_admin',
                      child: Text('Area Admin (Designated Area Only)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedRole = val;
                        if (val == 'super_admin') selectedArea = 'ALL';
                        else if (selectedArea == 'ALL') selectedArea = 'Pune';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Designated Area / City',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _commonCities.contains(selectedArea) ? selectedArea : 'Pune',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _commonCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c == 'ALL' ? 'ALL Areas (Nationwide)' : c)))
                      .toList(),
                  onChanged: selectedRole == 'super_admin'
                      ? null
                      : (val) {
                          if (val != null) setDialogState(() => selectedArea = val);
                        },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Active',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill name and email')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final success = await SupabaseService.instance.adminUpsertAdminAccount(
                  id: admin?['id'] as String?,
                  email: email,
                  password: passwordCtrl.text.trim(),
                  fullName: name,
                  phone: phoneCtrl.text.trim(),
                  role: selectedRole,
                  assignedArea: selectedArea,
                  isActive: isActive,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Admin updated successfully!'
                            : 'Admin created successfully!',
                      ),
                      backgroundColor: const Color(0xFF00C853),
                    ),
                  );
                  _loadAdmins();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save admin account'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Create Admin'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> admin) {
    final newPasswordCtrl = TextEditingController(text: 'Admin@1234');
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Reset Admin Password',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resetting password for: ${admin['full_name']} (${admin['email']})',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newPass = newPasswordCtrl.text.trim();
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final ok = await AdminAuthService.instance.resetAdminPassword(
                    admin['email'] ?? '',
                    newPass,
                  );
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password reset for ${admin['email']} successfully!'),
                        backgroundColor: const Color(0xFF00C853),
                      ),
                    );
                    _loadAdmins();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to reset password. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAdminConfirm(Map<String, dynamic> admin) {
    if (admin['email'] == 'admin@localconnect.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete main Super Administrator account.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin Account'),
        content: Text('Are you sure you want to remove ${admin['full_name']} as administrator?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await SupabaseService.instance.adminDeleteAdminAccount(admin['id'] as String);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin removed'), backgroundColor: Colors.red),
                );
                _loadAdmins();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAdmins;
    final superAdminCount = _admins.where((a) => a['role'] == 'super_admin').length;
    final areaAdminCount = _admins.where((a) => a['role'] == 'area_admin').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Admin Access & Management',
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
            onPressed: _loadAdmins,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddEditAdminDialog(),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'Add Admin',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // ── KPI Summary Card ──────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF00796B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _kpiItem('Total Admins', '${_admins.length}', Icons.security_rounded),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _kpiItem('Super Admins', '$superAdminCount', Icons.admin_panel_settings_rounded),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _kpiItem('Area Admins', '$areaAdminCount', Icons.location_city_rounded),
                    ],
                  ),
                ),

                // ── Search & Filter Bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or area...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _areaFilter,
                            items: _commonCities
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _areaFilter = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Admins List ───────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No administrators found',
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final admin = filtered[i];
                            final isSuper = admin['role'] == 'super_admin';
                            final isActive = admin['is_active'] == true;
                            final area = admin['assigned_area'] ?? 'ALL';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppTheme.cardShadow,
                                border: Border.all(
                                  color: isSuper
                                      ? const Color(0xFF6A1B9A).withValues(alpha: 0.3)
                                      : const Color(0xFF00796B).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isSuper
                                            ? const Color(0xFF6A1B9A).withValues(alpha: 0.1)
                                            : const Color(0xFF00796B).withValues(alpha: 0.1),
                                        child: Icon(
                                          isSuper
                                              ? Icons.admin_panel_settings_rounded
                                              : Icons.location_city_rounded,
                                          color: isSuper
                                              ? const Color(0xFF6A1B9A)
                                              : const Color(0xFF00796B),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              admin['full_name'] ?? 'Admin',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              admin['email'] ?? '',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: Colors.grey[600],
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
                                          color: isActive
                                              ? const Color(0xFFE8F5E9)
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.green[700] : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Role badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSuper
                                              ? const Color(0xFFEDE7F6)
                                              : const Color(0xFFE0F2F1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isSuper ? '👑 Super Admin' : '📍 Area Admin',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isSuper
                                                ? const Color(0xFF512DA8)
                                                : const Color(0xFF00796B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Designated area badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isSuper ? 'Nationwide (ALL)' : 'Area: $area',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Actions
                                      IconButton(
                                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                                        tooltip: 'Reset Password',
                                        onPressed: () => _showResetPasswordDialog(admin),
                                        color: AppTheme.primary,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 18),
                                        tooltip: 'Edit Admin',
                                        onPressed: () => _showAddEditAdminDialog(admin: admin),
                                        color: Colors.grey[700],
                                      ),
                                      if (admin['email'] != 'admin@localconnect.com')
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                          tooltip: 'Delete Admin',
                                          onPressed: () => _showDeleteAdminConfirm(admin),
                                          color: Colors.red,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _kpiItem(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
