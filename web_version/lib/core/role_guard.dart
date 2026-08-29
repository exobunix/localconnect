import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/supabase_service.dart';

/// Roles allowed to access each route group
const _customerOnlyRoutes = {
  AppRoutes.homeScreen,
  AppRoutes.allCategoriesScreen,
  AppRoutes.categoryDetailScreen,
  AppRoutes.checkoutScreen,
  AppRoutes.upiPaymentScreen,
  AppRoutes.bookingConfirmationScreen,
  AppRoutes.customerProfileScreen,
  AppRoutes.reviewSubmissionScreen,
  AppRoutes.mapDiscoveryScreen,
};

const _providerOnlyRoutes = {
  AppRoutes.providerDashboardScreen,
  AppRoutes.providerEarningsDashboardScreen,
  AppRoutes.providerSubscriptionScreen,
};

const _adminOnlyRoutes = {
  AppRoutes.adminPanelScreen,
  AppRoutes.adminCategoryManagementScreen,
  AppRoutes.adminUserManagementScreen,
  AppRoutes.adminBannerAdsScreen,
  AppRoutes.adminReportsScreen,
  AppRoutes.adminComplaintsScreen,
  AppRoutes.adminRentAnalyticsScreen,
  AppRoutes.adminProviderManagementScreen,
  AppRoutes.adminShopManagementScreen,
  AppRoutes.adminSubscriptionManagementScreen,
  AppRoutes.adminDeliveryManagementScreen,
  AppRoutes.adminAdvancedReportsScreen,
  AppRoutes.adminCustomerManagementScreen,
  AppRoutes.adminTransportScreen,
  AppRoutes.adminEventManagementScreen,
  AppRoutes.adminDeliveryScreen,
};

/// Returns true if the current user is allowed to access [routeName].
bool canAccess(String routeName) {
  // Use cached role — actual DB role is loaded asynchronously in RoleGuard
  final role = _getCachedRole();
  if (_customerOnlyRoutes.contains(routeName)) return role == 'customer';
  if (_providerOnlyRoutes.contains(routeName)) return role == 'provider';
  if (_adminOnlyRoutes.contains(routeName)) return role == 'admin';
  return true; // shared routes (chat, orders, notifications, etc.)
}

/// Cached role to avoid repeated DB calls for canAccess()
String? _cachedRole;
bool _isAdminSessionActive = false;

/// Returns whether an active admin session is unlocked
bool get isAdminSessionActive => _isAdminSessionActive;

/// Sets the admin session active state
void setAdminSessionActive(bool active) {
  _isAdminSessionActive = active;
  if (active) {
    _cachedRole = 'admin';
  } else {
    _cachedRole = null;
  }
}

String _getCachedRole() {
  if (_isAdminSessionActive) return 'admin';
  // SECURITY: Never fall back to user-supplied metadata for role resolution.
  // If cache is empty, default to 'customer' (least privileged).
  // The actual DB role is always verified server-side in _fetchRoleFromDb().
  return _cachedRole ?? 'customer';
}

/// Fetch role from user_profiles table (server-side, cannot be spoofed).
/// This is the authoritative role source — user_profiles.role is only
/// writable by service_role (admin API), not by the authenticated user.
Future<String> _fetchRoleFromDb() async {
  if (_isAdminSessionActive || _cachedRole == 'admin') {
    return 'admin';
  }
  try {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return 'customer';

    final result = await SupabaseService.instance.client
        .from('user_profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = result?['role'] as String? ?? 'customer';

    // SECURITY: Validate role is one of the known values before caching.
    // This prevents unexpected values from being used for access control.
    const validRoles = {'customer', 'provider', 'admin'};
    final safeRole = validRoles.contains(role) ? role : 'customer';
    _cachedRole = safeRole;
    return safeRole;
  } catch (e) {
    debugPrint('RoleGuard: DB role fetch error: $e');
    // SECURITY: On DB error, do NOT fall back to user metadata.
    // Default to 'customer' (least privileged) to prevent privilege escalation.
    _cachedRole = 'customer';
    return 'customer';
  }
}

/// Clear cached role on logout
void clearCachedRole() {
  _cachedRole = null;
  _isAdminSessionActive = false;
}

/// Wraps a screen and redirects unauthorized users to the correct home.
class RoleGuard extends StatefulWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({super.key, required this.requiredRole, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final isLoggedIn = SupabaseService.instance.isLoggedIn;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Define public routes that guests can access
    const publicRoutes = {
      AppRoutes.initial,
      AppRoutes.splashScreen,
      AppRoutes.onboardingScreen,
      AppRoutes.loginScreen,
      AppRoutes.signupScreen,
      AppRoutes.adminLoginScreen,
      AppRoutes.homeScreen,
      AppRoutes.allCategoriesScreen,
      AppRoutes.categoryDetailScreen,
      AppRoutes.rentCustomerScreen,
      AppRoutes.rentListingDetailScreen,
      AppRoutes.eventManagementCustomerScreen,
      AppRoutes.eventProviderDetailScreen,
      AppRoutes.legalScreen,
    };

    if (_isAdminSessionActive || _cachedRole == 'admin') {
      if (!mounted) return;
      setState(() {
        _role = 'admin';
        _loading = false;
      });
      return;
    }

    if (!isLoggedIn && !publicRoutes.contains(currentRoute)) {
      // User is not logged in and attempting to access a private route — redirect to login!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginScreen, (r) => false);
      });
      return;
    }

    final role = await _fetchRoleFromDb();
    if (!mounted) return;
    setState(() {
      _role = role;
      _loading = false;
    });

    if (role != widget.requiredRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = role == 'admin'
            ? AppRoutes.adminPanelScreen
            : role == 'provider'
            ? AppRoutes.providerDashboardScreen
            : AppRoutes.homeScreen;
        Navigator.pushNamedAndRemoveUntil(context, target, (r) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_role == widget.requiredRole) return widget.child;
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
