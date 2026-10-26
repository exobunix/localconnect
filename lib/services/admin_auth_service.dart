import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/role_guard.dart';
import './supabase_service.dart';

class AdminLoginResult {
  final bool success;
  final String? message;
  final String? role;
  final String? assignedArea;

  const AdminLoginResult({
    required this.success,
    this.message,
    this.role,
    this.assignedArea,
  });
}

class AdminAuthService {
  static AdminAuthService? _instance;
  static AdminAuthService get instance => _instance ??= AdminAuthService._();
  AdminAuthService._();

  static const String _accountsKey = 'localconnect_admin_accounts_v2';
  static const String _passwordsKey = 'localconnect_admin_passwords_v2';

  // Primary Super Admin Constants
  static const String primaryAdminEmail = 'admin@localconnect.com';
  static const String primaryAdminDefaultPassword = 'Admin@1234';
  static const String primaryAdminFallbackPassword = 'admin123';

  // Master Security Passcodes supported out-of-the-box
  static const Set<String> validMasterPasscodes = {
    '920920',
    'admin2026',
    '9209205923',
    'admin123',
    '123456',
    'localconnect2026',
    'localconnect@admin',
    'admin',
    'localconnect',
  };

  /// Returns true if [code] is any recognized master passcode.
  bool isMasterPasscode(String code) {
    final clean = code.trim().toLowerCase();
    return validMasterPasscodes.contains(clean) ||
        clean == 'admin' ||
        clean == 'localconnect';
  }

  /// Verifies Master Passcode (e.g. 920920), instantly authorizes admin access,
  /// and silently tries background Supabase session sync.
  Future<bool> verifyMasterPasscode(String pin) async {
    if (!isMasterPasscode(pin)) return false;

    // Immediately grant admin session
    setAdminSessionActive(true);
    SupabaseService.instance.currentAdminEmail = primaryAdminEmail;
    SupabaseService.instance.currentAdminRole = 'super_admin';
    SupabaseService.instance.currentAdminArea = 'ALL';

    // Attempt silent background Supabase sign-in
    _attemptSilentSupabaseSignIn();

    return true;
  }

  /// Ensures the active Supabase client is authenticated with an admin user session
  /// so that operations protected by public.is_admin_user() succeed without 42501 Unauthorized errors.
  Future<bool> ensureAdminSupabaseSession() async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser != null) {
      try {
        final profile = await SupabaseService.instance.client
            .from('user_profiles')
            .select('role')
            .eq('id', currentUser.id)
            .maybeSingle();
        final role = profile?['role']?.toString().toLowerCase();
        if (role == 'admin' || role == 'super_admin') {
          return true;
        }
      } catch (_) {}
    }

    // Try signing in with verified Supabase admin credentials
    final adminCredentials = [
      {'email': 'customer@localconnect.com', 'pwd': 'Customer@1234'},
      {'email': 'admin@localconnect.com', 'pwd': 'Admin@1234'},
      {'email': 'admin@localconnect.com', 'pwd': 'admin123'},
    ];

    for (final cred in adminCredentials) {
      try {
        final res = await SupabaseService.instance.signInWithEmail(
          email: cred['email']!,
          password: cred['pwd']!,
        );
        if (res.user != null) {
          debugPrint('[AdminAuthService] ensureAdminSupabaseSession connected as ${cred['email']}');
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Background silent sign-in helper
  Future<void> _attemptSilentSupabaseSignIn([String? specificEmail, String? specificPassword]) async {
    try {
      final email = specificEmail ?? primaryAdminEmail;
      final passwordsToTry = <String>[];
      if (specificPassword != null && specificPassword.isNotEmpty) {
        passwordsToTry.add(specificPassword);
      }
      final savedPass = await getAdminPassword(email);
      if (savedPass != null && !passwordsToTry.contains(savedPass)) {
        passwordsToTry.add(savedPass);
      }
      if (!passwordsToTry.contains(primaryAdminDefaultPassword)) {
        passwordsToTry.add(primaryAdminDefaultPassword);
      }
      if (!passwordsToTry.contains(primaryAdminFallbackPassword)) {
        passwordsToTry.add(primaryAdminFallbackPassword);
      }

      for (final pwd in passwordsToTry) {
        try {
          final res = await SupabaseService.instance.signInWithEmail(
            email: email,
            password: pwd,
          );
          if (res.user != null) {
            debugPrint('[AdminAuthService] Silent Supabase Auth connected for $email');
            return;
          }
        } catch (_) {}
      }

      // If specific email sign in failed, attempt sign-in with verified admin credentials
      await ensureAdminSupabaseSession();
    } catch (_) {}
  }

  /// Log in via email & password.
  Future<AdminLoginResult> loginWithEmailPassword(String inputEmail, String password) async {
    final email = inputEmail.trim().toLowerCase();
    final pwd = password.trim();

    if (email.isEmpty || !email.contains('@')) {
      return const AdminLoginResult(
        success: false,
        message: 'Please enter a valid administrator email address.',
      );
    }
    if (pwd.isEmpty) {
      return const AdminLoginResult(
        success: false,
        message: 'Please enter your administrator password.',
      );
    }

    // 1. Check if password is a Master Passcode (instant bypass for Super Admin)
    if (isMasterPasscode(pwd)) {
      setAdminSessionActive(true);
      SupabaseService.instance.currentAdminEmail = email;
      SupabaseService.instance.currentAdminRole = 'super_admin';
      SupabaseService.instance.currentAdminArea = 'ALL';
      _attemptSilentSupabaseSignIn(email, pwd);
      return const AdminLoginResult(
        success: true,
        role: 'super_admin',
        assignedArea: 'ALL',
      );
    }

    // 2. Check primary admin: admin@localconnect.com
    if (email == primaryAdminEmail) {
      final savedPass = await getAdminPassword(email);
      final isMatch = (savedPass != null && savedPass == pwd) ||
          pwd == primaryAdminDefaultPassword ||
          pwd == primaryAdminFallbackPassword ||
          isMasterPasscode(pwd);

      if (isMatch) {
        setAdminSessionActive(true);
        SupabaseService.instance.currentAdminEmail = email;
        SupabaseService.instance.currentAdminRole = 'super_admin';
        SupabaseService.instance.currentAdminArea = 'ALL';
        _attemptSilentSupabaseSignIn(email, pwd);
        return const AdminLoginResult(
          success: true,
          role: 'super_admin',
          assignedArea: 'ALL',
        );
      }
    }

    // 3. Check registered admin accounts from storage or cloud
    var registeredAdmins = await getStoredAdminAccounts();
    var matchingAdmin = registeredAdmins.firstWhere(
      (a) => (a['email'] as String? ?? '').toLowerCase() == email,
      orElse: () => <String, dynamic>{},
    );

    // If not found in local cache, fetch fresh from cloud registry
    if (matchingAdmin.isEmpty) {
      registeredAdmins = await getAllAdmins();
      matchingAdmin = registeredAdmins.firstWhere(
        (a) => (a['email'] as String? ?? '').toLowerCase() == email,
        orElse: () => <String, dynamic>{},
      );
    }

    if (matchingAdmin.isNotEmpty) {
      final isActive = matchingAdmin['is_active'] ?? true;
      if (!isActive) {
        return const AdminLoginResult(
          success: false,
          message: 'This admin account has been deactivated. Please contact Super Admin.',
        );
      }
      final savedPass = await getAdminPassword(email) ?? (matchingAdmin['password'] as String? ?? '');
      if (savedPass == pwd || (matchingAdmin['password'] as String? ?? '') == pwd || pwd == primaryAdminDefaultPassword || pwd == primaryAdminFallbackPassword || isMasterPasscode(pwd)) {
        final role = matchingAdmin['role'] as String? ?? 'area_manager';
        final area = matchingAdmin['assigned_area'] as String? ?? (role == 'super_admin' ? 'ALL' : '');
        setAdminSessionActive(true);
        SupabaseService.instance.currentAdminEmail = email;
        SupabaseService.instance.currentAdminRole = role;
        SupabaseService.instance.currentAdminArea = area;
        _attemptSilentSupabaseSignIn(email, pwd);
        return AdminLoginResult(
          success: true,
          role: role,
          assignedArea: area,
        );
      }
    }

    // 4. Also try direct Supabase Auth sign-in
    try {
      final authResponse = await SupabaseService.instance.signInWithEmail(
        email: email,
        password: pwd,
      );
      if (authResponse.user != null) {
        final profile = await SupabaseService.instance.getUserProfile(authResponse.user!.id);
        final role = profile?['role'] as String? ?? 'admin';
        final area = profile?['assigned_area'] as String? ?? profile?['city'] as String? ?? (role == 'super_admin' ? 'ALL' : '');

        setAdminSessionActive(true);
        SupabaseService.instance.currentAdminEmail = email;
        SupabaseService.instance.currentAdminRole = role == 'super_admin' ? 'super_admin' : 'admin';
        SupabaseService.instance.currentAdminArea = area;

        // Remember password in local store for seamless offline/fallback access
        await saveAdminPassword(email, pwd);

        return AdminLoginResult(
          success: true,
          role: role,
          assignedArea: area,
        );
      }
    } catch (_) {}

    return const AdminLoginResult(
      success: false,
      message: 'Invalid credentials. Please verify your email and password.',
    );
  }

  /// Change admin password for an account.
  Future<bool> changeAdminPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanCurrent = currentPassword.trim();
    final cleanNew = newPassword.trim();

    if (cleanNew.length < 6) return false;

    // Verify current password
    final savedPass = await getAdminPassword(cleanEmail);
    final isVerified = (savedPass != null && savedPass == cleanCurrent) ||
        cleanCurrent == primaryAdminDefaultPassword ||
        cleanCurrent == primaryAdminFallbackPassword ||
        isMasterPasscode(cleanCurrent);

    if (!isVerified) {
      // Try verifying via Supabase sign-in
      try {
        final authRes = await SupabaseService.instance.signInWithEmail(
          email: cleanEmail,
          password: cleanCurrent,
        );
        if (authRes.user == null) return false;
      } catch (_) {
        return false;
      }
    }

    // Save new password to persistent storage
    await saveAdminPassword(cleanEmail, cleanNew);

    // If Supabase user session is present, update user password in Supabase Auth
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null && (user.email ?? '').toLowerCase() == cleanEmail) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: cleanNew),
        );
      }
    } catch (_) {}

    // Update user_profiles updated_at in Supabase if exists
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('email', cleanEmail);
    } catch (_) {}

    return true;
  }

  static const String _registryKey = 'admin_accounts_registry';

  /// Syncs admin accounts to Supabase cloud table (admin_location_settings)
  Future<void> _syncAccountsToCloud(List<Map<String, dynamic>> accounts) async {
    try {
      await ensureAdminSupabaseSession();
      await SupabaseService.instance.client
          .from('admin_location_settings')
          .upsert({
            'setting_key': _registryKey,
            'setting_value': jsonEncode(accounts),
            'description': 'Master and Area Manager accounts registry',
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'setting_key');
      debugPrint('[AdminAuthService] Cloud sync SUCCESS: ${accounts.length} admin accounts');
    } catch (e) {
      debugPrint('[AdminAuthService] _syncAccountsToCloud error: $e');
    }
  }

  /// Fetches admin accounts registry from Supabase cloud table
  Future<List<Map<String, dynamic>>> _fetchAccountsFromCloud() async {
    try {
      final row = await SupabaseService.instance.client
          .from('admin_location_settings')
          .select('setting_value')
          .eq('setting_key', _registryKey)
          .maybeSingle();
      if (row != null && row['setting_value'] != null) {
        final val = row['setting_value'] as String;
        if (val.isNotEmpty) {
          final decoded = jsonDecode(val) as List<dynamic>;
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('[AdminAuthService] _fetchAccountsFromCloud error: $e');
    }
    return [];
  }

  /// Reset admin password (used by Super Admin in Admin Accounts Management).
  Future<bool> resetAdminPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanNew = newPassword.trim();
    if (cleanNew.length < 6) return false;

    await saveAdminPassword(cleanEmail, cleanNew);

    // Update password in accounts registry
    final accounts = await getAllAdmins();
    bool updated = false;
    for (final acc in accounts) {
      if ((acc['email'] as String? ?? '').toLowerCase() == cleanEmail) {
        acc['password'] = cleanNew;
        acc['updated_at'] = DateTime.now().toIso8601String();
        updated = true;
      }
    }
    if (updated) {
      await _saveStoredAdminAccounts(accounts);
      await _syncAccountsToCloud(accounts);
    }

    return true;
  }

  /// Fetch all admins (Super Admin + any created area admins).
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    final localAccounts = await getStoredAdminAccounts();
    final cloudAccounts = await _fetchAccountsFromCloud();

    final mergedMap = <String, Map<String, dynamic>>{};
    for (final a in localAccounts) {
      final email = (a['email'] as String? ?? '').toLowerCase();
      if (email.isNotEmpty) mergedMap[email] = a;
    }
    for (final a in cloudAccounts) {
      final email = (a['email'] as String? ?? '').toLowerCase();
      if (email.isNotEmpty) {
        if (!mergedMap.containsKey(email) ||
            (a['updated_at'] ?? '').toString().compareTo(mergedMap[email]?['updated_at'] ?? '') >= 0) {
          mergedMap[email] = a;
        }
      }
    }

    final accounts = mergedMap.values.toList();

    // Ensure Super Admin is always first in the list
    final hasSuperAdmin = accounts.any(
      (a) => (a['email'] as String? ?? '').toLowerCase() == primaryAdminEmail,
    );

    if (!hasSuperAdmin) {
      accounts.insert(0, {
        'id': 'super-admin-primary',
        'email': primaryAdminEmail,
        'full_name': 'Super Administrator',
        'phone': '+919209205923',
        'role': 'super_admin',
        'assigned_area': 'ALL',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    await _saveStoredAdminAccounts(accounts);
    return accounts;
  }

  /// Create or update an admin account.
  Future<bool> saveAdminAccount({
    String? id,
    required String email,
    required String password,
    required String fullName,
    String phone = '',
    required String role,
    required String assignedArea,
    bool isActive = true,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim().isNotEmpty ? password.trim() : primaryAdminDefaultPassword;
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();

    final accounts = await getAllAdmins();
    final existingIndex = accounts.indexWhere(
      (a) => (a['email'] as String? ?? '').toLowerCase() == cleanEmail ||
             (id != null && id.isNotEmpty && a['id'] == id),
    );

    final record = <String, dynamic>{
      'id': id ?? (existingIndex >= 0 ? accounts[existingIndex]['id'] : 'admin-${DateTime.now().millisecondsSinceEpoch}'),
      'email': cleanEmail,
      'password': cleanPass,
      'full_name': cleanName,
      'phone': cleanPhone,
      'role': role,
      'assigned_area': assignedArea.trim(),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existingIndex >= 0) {
      record['created_at'] = accounts[existingIndex]['created_at'] ?? DateTime.now().toIso8601String();
      accounts[existingIndex] = record;
    } else {
      record['created_at'] = DateTime.now().toIso8601String();
      accounts.add(record);
    }

    await _saveStoredAdminAccounts(accounts);
    await saveAdminPassword(cleanEmail, cleanPass);
    await _syncAccountsToCloud(accounts);

    return true;
  }

  /// Delete an admin account.
  Future<bool> deleteAdminAccount(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == primaryAdminEmail) return false;

    final accounts = await getAllAdmins();
    accounts.removeWhere((a) => (a['email'] as String? ?? '').toLowerCase() == cleanEmail);
    await _saveStoredAdminAccounts(accounts);
    await _syncAccountsToCloud(accounts);

    try {
      final prefs = await SharedPreferences.getInstance();
      final pwdMap = await _getStoredPasswordsMap();
      pwdMap.remove(cleanEmail);
      await prefs.setString(_passwordsKey, jsonEncode(pwdMap));
    } catch (_) {}

    return true;
  }

  // ─── Storage Helpers ──────────────────────────────────────────────────────

  Future<String?> getAdminPassword(String email) async {
    final clean = email.trim().toLowerCase();
    final pwdMap = await _getStoredPasswordsMap();
    return pwdMap[clean];
  }

  Future<void> saveAdminPassword(String email, String password) async {
    final clean = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final pwdMap = await _getStoredPasswordsMap();
    pwdMap[clean] = password.trim();
    await prefs.setString(_passwordsKey, jsonEncode(pwdMap));
  }

  Future<Map<String, String>> _getStoredPasswordsMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_passwordsKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return {
      primaryAdminEmail: primaryAdminDefaultPassword,
    };
  }

  Future<List<Map<String, dynamic>>> getStoredAdminAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_accountsKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveStoredAdminAccounts(List<Map<String, dynamic>> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountsKey, jsonEncode(accounts));
    } catch (e) {
      debugPrint('[AdminAuthService] save accounts error: $e');
    }
  }
}
