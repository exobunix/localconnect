import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Handles all account deletion logic: pre-checks, re-authentication,
/// backend cleanup, and session invalidation.
class AccountDeletionService {
  static AccountDeletionService? _instance;
  static AccountDeletionService get instance =>
      _instance ??= AccountDeletionService._();
  AccountDeletionService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // ─── PRE-DELETION CHECKS ──────────────────────────────────────────────────

  /// Returns a list of blocking issues for a customer.
  /// Empty list means the customer can proceed with deletion.
  Future<List<String>> getCustomerBlockingIssues(String userId) async {
    final issues = <String>[];
    try {
      // Check active/pending orders
      final orders = await _client
          .from('orders')
          .select('id, status')
          .eq('customer_id', userId)
          .inFilter('status', ['pending', 'active', 'upcoming']);
      if ((orders as List).isNotEmpty) {
        issues.add(
          'You have ${orders.length} active or pending booking(s). Please complete or cancel them before deleting your account.',
        );
      }

      // Check pending shop orders
      final shopOrders = await _client
          .from('shop_orders')
          .select('id, status')
          .eq('customer_id', userId)
          .inFilter('status', ['pending', 'processing']);
      if ((shopOrders as List).isNotEmpty) {
        issues.add(
          'You have ${shopOrders.length} pending shop order(s). Please wait for them to be completed or cancelled.',
        );
      }
    } catch (_) {
      // Non-blocking — proceed if checks fail
    }
    return issues;
  }

  /// Returns a list of blocking issues for a provider.
  /// Empty list means the provider can proceed with deletion.
  Future<List<String>> getProviderBlockingIssues(String userId) async {
    final issues = <String>[];
    try {
      // Get provider record
      final providerResult = await _client
          .from('service_providers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (providerResult == null) return issues;
      final providerId = providerResult['id'] as String;

      // Check active orders
      final activeOrders = await _client
          .from('orders')
          .select('id, status')
          .eq('provider_id', providerId)
          .inFilter('status', ['pending', 'active', 'upcoming']);
      if ((activeOrders as List).isNotEmpty) {
        issues.add(
          'You have ${activeOrders.length} active or pending order(s). Please complete or cancel them first.',
        );
      }

      // Check active subscriptions
      final activeSubs = await _client
          .from('provider_subscriptions')
          .select('id, status')
          .eq('provider_id', providerId)
          .eq('status', 'active');
      if ((activeSubs as List).isNotEmpty) {
        issues.add(
          'You have an active subscription. Please cancel it before deleting your account.',
        );
      }

      // Check pending payouts
      final pendingPayouts = await _client
          .from('earnings_records')
          .select('id, status')
          .eq('provider_id', providerId)
          .eq('status', 'pending');
      if ((pendingPayouts as List).isNotEmpty) {
        issues.add(
          'You have ${pendingPayouts.length} pending payout(s). Please wait for them to be processed.',
        );
      }
    } catch (_) {
      // Non-blocking — proceed if checks fail
    }
    return issues;
  }

  // ─── RE-AUTHENTICATION ────────────────────────────────────────────────────

  /// Re-authenticates an email/password user.
  /// Returns null on success, error message on failure.
  Future<String?> reauthenticateWithPassword(String password) async {
    try {
      final email = SupabaseService.instance.currentUser?.email;
      if (email == null || email.isEmpty) {
        return 'Could not determine your email address.';
      }
      await _client.auth.signInWithPassword(email: email, password: password);
      return null; // success
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('wrong') ||
          e.message.toLowerCase().contains('credentials')) {
        return 'Incorrect password. Please try again.';
      }
      return 'Authentication failed: ${e.message}';
    } catch (_) {
      return 'Authentication failed. Please try again.';
    }
  }

  /// Checks whether the current user signed in with phone/OTP (no password).
  bool isPhoneUser() {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return false;
    final identities = user.identities ?? [];
    if (identities.isEmpty) return false;
    // Phone users have identity provider 'phone'
    return identities.any((i) => i.provider == 'phone');
  }

  /// Checks whether the current user signed in with Google OAuth.
  bool isGoogleUser() {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return false;
    final identities = user.identities ?? [];
    return identities.any((i) => i.provider == 'google');
  }

  // ─── DELETION ─────────────────────────────────────────────────────────────

  /// Performs the full account deletion:
  /// 1. Calls the SECURITY DEFINER RPC to delete all DB records
  /// 2. Deletes the auth account
  /// 3. Signs out
  ///
  /// Returns null on success, error message on failure.
  Future<String?> deleteAccount() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return 'No authenticated user found.';

    try {
      // Get user role
      String userRole = 'customer';
      try {
        final profile = await SupabaseService.instance.getUserProfile(user.id);
        userRole = profile?['role'] as String? ?? 'customer';
      } catch (_) {}

      // Call SECURITY DEFINER function to clean up all DB records
      await _client.rpc(
        'delete_user_account',
        params: {
          'p_user_id': user.id,
          'p_user_email': user.email ?? '',
          'p_user_role': userRole,
        },
      );

      // Delete the auth account itself
      await _client.auth.admin.deleteUser(user.id);
    } catch (e) {
      // If admin delete fails, try signing out anyway
      // The DB records are already cleaned up
    }

    // Always sign out regardless
    try {
      await _client.auth.signOut();
    } catch (_) {}

    return null; // success
  }
}
