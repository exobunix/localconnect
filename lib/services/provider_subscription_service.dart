import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './notification_service.dart';
import './supabase_service.dart';

/// Manages the full provider subscription lifecycle:
/// - 30-day free trial assignment
/// - Grace period tracking
/// - Trial reminder notifications
/// - Subscription status checks
/// - Auto-renewal logic
class ProviderSubscriptionService {
  static ProviderSubscriptionService? _instance;
  static ProviderSubscriptionService get instance =>
      _instance ??= ProviderSubscriptionService._();
  ProviderSubscriptionService._();

  // ─── SUBSCRIPTION STATUS CONSTANTS ───────────────────────────────────────
  static const String statusActive = 'active';
  static const String statusExpired = 'expired';
  static const String statusCancelled = 'cancelled';
  static const String statusTrial = 'trial';

  // ─── GET CURRENT SUBSCRIPTION ────────────────────────────────────────────

  /// Returns the current subscription for a provider (active or expired).
  Future<Map<String, dynamic>?> getCurrentSubscription(
    String providerId,
  ) async {
    try {
      final result = await SupabaseService.instance.client
          .from('provider_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('getCurrentSubscription error: $e');
      return null;
    }
  }

  /// Returns only active subscriptions.
  Future<Map<String, dynamic>?> getActiveSubscription(String providerId) async {
    try {
      final result = await SupabaseService.instance.client
          .from('provider_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('provider_id', providerId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('getActiveSubscription error: $e');
      return null;
    }
  }

  // ─── SUBSCRIPTION STATUS ANALYSIS ────────────────────────────────────────

  /// Comprehensive subscription status for display.
  SubscriptionStatus analyzeStatus(Map<String, dynamic>? sub) {
    if (sub == null) return SubscriptionStatus.noSubscription();

    final status = sub['status'] as String? ?? 'expired';
    final isTrial = sub['is_trial'] as bool? ?? false;
    final endDateStr =
        sub['end_date'] as String? ?? sub['expires_at'] as String?;
    final trialEndStr = sub['trial_end_date'] as String?;
    final gracePeriodEndStr = sub['grace_period_end'] as String?;

    final now = DateTime.now();
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
    final trialEnd = trialEndStr != null
        ? DateTime.tryParse(trialEndStr)
        : null;
    final gracePeriodEnd = gracePeriodEndStr != null
        ? DateTime.tryParse(gracePeriodEndStr)
        : null;

    if (status == 'active') {
      final effectiveEnd = isTrial ? (trialEnd ?? endDate) : endDate;
      if (effectiveEnd != null) {
        final daysLeft = effectiveEnd.difference(now).inDays;
        if (daysLeft < 0) {
          // Should be expired but DB not updated yet
          return SubscriptionStatus(
            type: isTrial
                ? SubscriptionStatusType.trialExpired
                : SubscriptionStatusType.expired,
            daysLeft: 0,
            endDate: effectiveEnd,
            isTrial: isTrial,
            gracePeriodEnd: gracePeriodEnd,
            isInGracePeriod:
                gracePeriodEnd != null && now.isBefore(gracePeriodEnd),
          );
        }
        return SubscriptionStatus(
          type: isTrial
              ? SubscriptionStatusType.trial
              : SubscriptionStatusType.active,
          daysLeft: daysLeft,
          endDate: effectiveEnd,
          isTrial: isTrial,
          gracePeriodEnd: gracePeriodEnd,
          isInGracePeriod: false,
        );
      }
    }

    if (status == 'expired') {
      final isInGrace = gracePeriodEnd != null && now.isBefore(gracePeriodEnd);
      final graceDaysLeft = gracePeriodEnd != null
          ? gracePeriodEnd.difference(now).inDays
          : 0;
      return SubscriptionStatus(
        type: isInGrace
            ? SubscriptionStatusType.gracePeriod
            : (isTrial
                  ? SubscriptionStatusType.trialExpired
                  : SubscriptionStatusType.expired),
        daysLeft: isInGrace ? graceDaysLeft : 0,
        endDate: endDate,
        isTrial: isTrial,
        gracePeriodEnd: gracePeriodEnd,
        isInGracePeriod: isInGrace,
      );
    }

    return SubscriptionStatus(
      type: SubscriptionStatusType.cancelled,
      daysLeft: 0,
      endDate: endDate,
      isTrial: isTrial,
      gracePeriodEnd: null,
      isInGracePeriod: false,
    );
  }

  // ─── TRIAL MANAGEMENT ────────────────────────────────────────────────────

  /// Assigns a 30-day free trial to a newly approved provider.
  /// This is also handled by the DB trigger, but can be called manually.
  Future<bool> assignFreeTrial(String providerId) async {
    try {
      // Check if already has subscription
      final existing = await getCurrentSubscription(providerId);
      if (existing != null) return false;

      // Get trial config
      final config = await getConfig();
      final trialDays = int.tryParse(config['trial_days'] ?? '30') ?? 30;

      // Get free/trial plan
      final plans = await SupabaseService.instance.client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price')
          .limit(1);

      if ((plans as List).isEmpty) return false;
      final plan = plans.first;

      final now = DateTime.now();
      final endDate = now.add(Duration(days: trialDays));

      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .insert({
            'provider_id': providerId,
            'plan_id': plan['id'],
            'status': 'active',
            'is_trial': true,
            'trial_start_date': now.toIso8601String(),
            'trial_end_date': endDate.toIso8601String(),
            'start_date': now.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'started_at': now.toIso8601String(),
            'expires_at': endDate.toIso8601String(),
            'auto_renew': false,
            'payment_ref': 'FREE_TRIAL',
          });

      // Log audit
      await _logAuditEvent(
        providerId: providerId,
        planId: plan['id'] as String,
        eventType: 'trial_start',
        amount: 0,
        status: 'success',
        metadata: {'trial_days': trialDays, 'manual_assignment': true},
      );

      return true;
    } catch (e) {
      debugPrint('assignFreeTrial error: $e');
      return false;
    }
  }

  // ─── REMINDER NOTIFICATIONS ───────────────────────────────────────────────

  /// Checks and sends trial/subscription expiry reminders.
  Future<void> checkAndSendReminders(String providerId, String userId) async {
    try {
      final sub = await getActiveSubscription(providerId);
      if (sub == null) return;

      final isTrial = sub['is_trial'] as bool? ?? false;
      final endDateStr =
          sub['end_date'] as String? ?? sub['expires_at'] as String?;
      if (endDateStr == null) return;

      final endDate = DateTime.tryParse(endDateStr);
      if (endDate == null) return;

      final now = DateTime.now();
      final daysLeft = endDate.difference(now).inDays;
      final subId = sub['id'] as String;

      // Reminder thresholds
      final reminderDays = [7, 3, 1];
      for (final days in reminderDays) {
        if (daysLeft <= days && daysLeft >= days - 1) {
          final reminderType = '${days}_days';
          final alreadySent = await _wasReminderSent(
            providerId,
            subId,
            reminderType,
          );
          if (!alreadySent) {
            await _sendReminderNotification(
              userId: userId,
              providerId: providerId,
              subId: subId,
              daysLeft: daysLeft,
              isTrial: isTrial,
              reminderType: reminderType,
            );
          }
        }
      }

      // Day 0 reminder
      if (daysLeft == 0) {
        final alreadySent = await _wasReminderSent(
          providerId,
          subId,
          'expired',
        );
        if (!alreadySent) {
          await _sendReminderNotification(
            userId: userId,
            providerId: providerId,
            subId: subId,
            daysLeft: 0,
            isTrial: isTrial,
            reminderType: 'expired',
          );
        }
      }
    } catch (e) {
      debugPrint('checkAndSendReminders error: $e');
    }
  }

  Future<bool> _wasReminderSent(
    String providerId,
    String subId,
    String reminderType,
  ) async {
    try {
      final result = await SupabaseService.instance.client
          .from('subscription_reminders')
          .select('id')
          .eq('provider_id', providerId)
          .eq('subscription_id', subId)
          .eq('reminder_type', reminderType)
          .limit(1)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendReminderNotification({
    required String userId,
    required String providerId,
    required String subId,
    required int daysLeft,
    required bool isTrial,
    required String reminderType,
  }) async {
    String title;
    String body;

    if (daysLeft == 0) {
      title = isTrial ? '⏰ Free Trial Ended' : '⚠️ Subscription Expired';
      body = isTrial
          ? 'Your 30-day free trial has ended. Subscribe now to continue serving customers!'
          : 'Your subscription has expired. Renew now to restore your visibility!';
    } else {
      title = isTrial
          ? '⏰ Trial Ending in $daysLeft Day${daysLeft == 1 ? '' : 's'}'
          : '⚠️ Subscription Expiring in $daysLeft Day${daysLeft == 1 ? '' : 's'}';
      body = isTrial
          ? 'Your free trial ends in $daysLeft day${daysLeft == 1 ? '' : 's'}. Subscribe to keep your business visible!'
          : 'Your subscription expires in $daysLeft day${daysLeft == 1 ? '' : 's'}. Renew to avoid service interruption.';
    }

    // In-app notification
    try {
      await SupabaseService.instance.insertOrderNotification(
        userId: userId,
        title: title,
        body: body,
        type: 'subscription',
      );
    } catch (_) {}

    // Local push notification
    try {
      await NotificationService.instance.showLocalNotification(
        title: title,
        body: body,
      );
    } catch (_) {}

    // Log reminder sent
    try {
      await SupabaseService.instance.client
          .from('subscription_reminders')
          .insert({
            'provider_id': providerId,
            'subscription_id': subId,
            'reminder_type': reminderType,
            'channel': 'in_app',
          });
    } catch (_) {}
  }

  // ─── SUBSCRIPTION ACTIVATION ─────────────────────────────────────────────

  /// Activates a subscription after successful Razorpay payment verification.
  /// Calls the server-side Edge Function for signature verification.
  Future<SubscriptionActivationResult> activateAfterPayment({
    required String providerId,
    required String planId,
    required double amount,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    bool isRenewal = false,
    bool autoRenew = false,
  }) async {
    try {
      final session = SupabaseService.instance.client.auth.currentSession;
      final token = session?.accessToken ?? '';

      final response = await SupabaseService.instance.client.functions.invoke(
        'razorpay-verify-subscription',
        body: {
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'provider_id': providerId,
          'plan_id': planId,
          'amount': amount,
          'is_renewal': isRenewal,
          'auto_renew': autoRenew,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.data != null) {
        final data = Map<String, dynamic>.from(response.data as Map);
        if (data['success'] == true) {
          return SubscriptionActivationResult(
            success: true,
            subscriptionId: data['subscription_id'] as String?,
            planName: data['plan_name'] as String?,
            endDate: data['end_date'] != null
                ? DateTime.tryParse(data['end_date'] as String)
                : null,
          );
        }
      }
      return SubscriptionActivationResult(
        success: false,
        error: 'Verification failed',
      );
    } catch (e) {
      debugPrint('activateAfterPayment error: $e');
      return SubscriptionActivationResult(success: false, error: e.toString());
    }
  }

  // ─── TOGGLE AUTO-RENEWAL ─────────────────────────────────────────────────

  Future<bool> toggleAutoRenew(String subscriptionId, bool value) async {
    try {
      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .update({
            'auto_renew': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      debugPrint('toggleAutoRenew error: $e');
      return false;
    }
  }

  // ─── PAYMENT HISTORY ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String providerId,
  ) async {
    try {
      final result = await SupabaseService.instance.client
          .from('subscription_billing_history')
          .select('*, subscription_plans(name, price)')
          .eq('provider_id', providerId)
          .order('billed_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      debugPrint('getPaymentHistory error: $e');
      return [];
    }
  }

  // ─── AUDIT LOG ────────────────────────────────────────────────────────────

  Future<void> _logAuditEvent({
    required String providerId,
    required String planId,
    required String eventType,
    required double amount,
    required String status,
    String? subscriptionId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('subscription_payment_audit')
          .insert({
            'provider_id': providerId,
            'plan_id': planId,
            'event_type': eventType,
            'amount': amount,
            'status': status,
            if (subscriptionId != null) 'subscription_id': subscriptionId,
            if (razorpayPaymentId != null)
              'razorpay_payment_id': razorpayPaymentId,
            if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
            'metadata': metadata ?? {},
          });
    } catch (_) {}
  }

  // ─── CONFIG ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> getConfig() async {
    try {
      final result = await SupabaseService.instance.client
          .from('subscription_config')
          .select('key, value');
      final config = <String, String>{};
      for (final row in (result as List)) {
        config[row['key'] as String] = row['value'] as String;
      }
      return config;
    } catch (_) {
      return {
        'trial_days': '30',
        'grace_period_days': '7',
        'reminder_days': '7,3,1',
      };
    }
  }

  // ─── ADMIN: MANUAL ACTIVATE/DEACTIVATE ───────────────────────────────────

  Future<bool> adminActivateSubscription({
    required String providerId,
    required String planId,
    required int durationDays,
    String reason = 'admin_manual',
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .update({'status': 'expired', 'updated_at': now.toIso8601String()})
          .eq('provider_id', providerId)
          .eq('status', 'active');

      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .insert({
            'provider_id': providerId,
            'plan_id': planId,
            'status': 'active',
            'is_trial': false,
            'start_date': now.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'started_at': now.toIso8601String(),
            'expires_at': endDate.toIso8601String(),
            'auto_renew': false,
            'payment_ref': 'ADMIN_MANUAL',
          });

      return true;
    } catch (e) {
      debugPrint('adminActivateSubscription error: $e');
      return false;
    }
  }

  Future<bool> adminDeactivateSubscription(String subscriptionId) async {
    try {
      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancellation_reason': 'admin_deactivated',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
      return true;
    } catch (e) {
      debugPrint('adminDeactivateSubscription error: $e');
      return false;
    }
  }

  // ─── ANALYTICS ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final allSubs = await SupabaseService.instance.client
          .from('provider_subscriptions')
          .select(
            'status, is_trial, plan_id, created_at, subscription_plans(name, price, billing_cycle)',
          );

      final subs = List<Map<String, dynamic>>.from(allSubs as List);

      int totalProviders = subs.length;
      int trialProviders = subs.where((s) => s['is_trial'] == true).length;
      int activeProviders = subs
          .where((s) => s['status'] == 'active' && s['is_trial'] != true)
          .length;
      int expiredProviders = subs.where((s) => s['status'] == 'expired').length;

      // Revenue from billing history
      final billing = await SupabaseService.instance.client
          .from('subscription_billing_history')
          .select('amount, billed_at, status');

      double totalRevenue = 0;
      double monthlyRevenue = 0;
      final now = DateTime.now();
      for (final b in (billing as List)) {
        if (b['status'] == 'paid') {
          final amt = (b['amount'] as num?)?.toDouble() ?? 0;
          totalRevenue += amt;
          final billedAt = DateTime.tryParse(b['billed_at'] as String? ?? '');
          if (billedAt != null &&
              billedAt.year == now.year &&
              billedAt.month == now.month) {
            monthlyRevenue += amt;
          }
        }
      }

      // Plan breakdown
      final planBreakdown = <String, int>{};
      for (final s in subs) {
        if (s['status'] == 'active') {
          final plan = s['subscription_plans'] as Map<String, dynamic>?;
          final planName = plan?['name'] as String? ?? 'Unknown';
          planBreakdown[planName] = (planBreakdown[planName] ?? 0) + 1;
        }
      }

      return {
        'total_providers': totalProviders,
        'trial_providers': trialProviders,
        'active_providers': activeProviders,
        'expired_providers': expiredProviders,
        'total_revenue': totalRevenue,
        'monthly_revenue': monthlyRevenue,
        'plan_breakdown': planBreakdown,
        'renewal_rate': totalProviders > 0
            ? (activeProviders / totalProviders * 100).toStringAsFixed(1)
            : '0',
        'churn_rate': totalProviders > 0
            ? (expiredProviders / totalProviders * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      debugPrint('getAnalytics error: $e');
      return {};
    }
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum SubscriptionStatusType {
  noSubscription,
  trial,
  trialExpired,
  active,
  gracePeriod,
  expired,
  cancelled,
}

class SubscriptionStatus {
  final SubscriptionStatusType type;
  final int daysLeft;
  final DateTime? endDate;
  final bool isTrial;
  final DateTime? gracePeriodEnd;
  final bool isInGracePeriod;

  SubscriptionStatus({
    required this.type,
    required this.daysLeft,
    required this.endDate,
    required this.isTrial,
    required this.gracePeriodEnd,
    required this.isInGracePeriod,
  });

  factory SubscriptionStatus.noSubscription() => SubscriptionStatus(
    type: SubscriptionStatusType.noSubscription,
    daysLeft: 0,
    endDate: null,
    isTrial: false,
    gracePeriodEnd: null,
    isInGracePeriod: false,
  );

  bool get isActive =>
      type == SubscriptionStatusType.active ||
      type == SubscriptionStatusType.trial;

  bool get canAccessDashboard =>
      isActive || type == SubscriptionStatusType.gracePeriod;

  bool get isVisible =>
      isActive; // Provider visible to customers only when active

  String get statusLabel {
    switch (type) {
      case SubscriptionStatusType.trial:
        return 'Free Trial';
      case SubscriptionStatusType.trialExpired:
        return 'Trial Expired';
      case SubscriptionStatusType.active:
        return 'Active';
      case SubscriptionStatusType.gracePeriod:
        return 'Grace Period';
      case SubscriptionStatusType.expired:
        return 'Expired';
      case SubscriptionStatusType.cancelled:
        return 'Cancelled';
      case SubscriptionStatusType.noSubscription:
        return 'No Plan';
    }
  }

  Color get statusColor {
    switch (type) {
      case SubscriptionStatusType.trial:
        return const Color(0xFF1565C0);
      case SubscriptionStatusType.active:
        return const Color(0xFF2E7D32);
      case SubscriptionStatusType.gracePeriod:
        return const Color(0xFFE65100);
      case SubscriptionStatusType.trialExpired:
      case SubscriptionStatusType.expired:
        return const Color(0xFFC62828);
      case SubscriptionStatusType.cancelled:
        return const Color(0xFF546E7A);
      case SubscriptionStatusType.noSubscription:
        return const Color(0xFF78909C);
    }
  }
}

class SubscriptionActivationResult {
  final bool success;
  final String? subscriptionId;
  final String? planName;
  final DateTime? endDate;
  final String? error;

  SubscriptionActivationResult({
    required this.success,
    this.subscriptionId,
    this.planName,
    this.endDate,
    this.error,
  });
}
