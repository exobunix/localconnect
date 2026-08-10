import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './notification_service.dart';
import './supabase_service.dart';

/// Listens to real-time changes on the [quotations] table and fires
/// push notifications + in-app toasts for both customers and providers.
class QuotationRealtimeService {
  static QuotationRealtimeService? _instance;
  static QuotationRealtimeService get instance =>
      _instance ??= QuotationRealtimeService._();

  QuotationRealtimeService._();

  RealtimeChannel? _channel;
  bool _isListening = false;

  SupabaseClient get _client => SupabaseService.instance.client;

  // ─── START ────────────────────────────────────────────────────────────────

  /// Call once after the user is authenticated.
  /// Safe to call multiple times – will not create duplicate channels.
  Future<void> startListening() async {
    if (_isListening) return;

    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    _isListening = true;

    // Subscribe to ALL updates on the quotations table.
    // We filter by the current user's role (customer or provider) in the callback.
    _channel = _client
        .channel('quotation_status_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'quotations',
          callback: (payload) => _handleQuotationChange(payload, userId),
        )
        .subscribe((status, [error]) {
          if (error != null) {
            debugPrint('[QuotationRealtime] subscription error: $error');
          }
        });
  }

  /// Stop listening and clean up the channel.
  Future<void> stopListening() async {
    await _channel?.unsubscribe();
    _channel = null;
    _isListening = false;
  }

  // ─── HANDLER ─────────────────────────────────────────────────────────────

  Future<void> _handleQuotationChange(
    PostgresChangePayload payload,
    String currentUserId,
  ) async {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final quotationId = newRecord['id'] as String? ?? '';
      final status = newRecord['status'] as String? ?? '';
      final customerId = newRecord['customer_id'] as String? ?? '';
      final providerId = newRecord['provider_id'] as String? ?? '';

      // Determine if the current user is the customer or provider
      final isCustomer = currentUserId == customerId;
      final isProvider = currentUserId == providerId;

      if (!isCustomer && !isProvider) return;

      // Fetch related names for richer notifications
      String? providerName;
      String? customerName;

      try {
        if (isCustomer && providerId.isNotEmpty) {
          final providerData = await _client
              .from('service_providers')
              .select('business_name')
              .eq('id', providerId)
              .maybeSingle();
          providerName = providerData?['business_name'] as String?;
        }

        if (isProvider && customerId.isNotEmpty) {
          final customerData = await _client
              .from('user_profiles')
              .select('full_name')
              .eq('id', customerId)
              .maybeSingle();
          customerName = customerData?['full_name'] as String?;
        }
      } catch (_) {
        // Names are optional – proceed without them
      }

      if (isCustomer) {
        await _notifyCustomer(
          quotationId: quotationId,
          status: status,
          providerName: providerName,
        );
      } else if (isProvider) {
        await _notifyProvider(
          quotationId: quotationId,
          status: status,
          customerName: customerName,
        );
      }
    } catch (e) {
      debugPrint('[QuotationRealtime] error handling change: $e');
    }
  }

  // ─── CUSTOMER NOTIFICATIONS ───────────────────────────────────────────────

  Future<void> _notifyCustomer({
    required String quotationId,
    required String status,
    String? providerName,
  }) async {
    // Only notify for statuses relevant to the customer
    if (!['sent', 'accepted', 'rejected', 'negotiating'].contains(status)) {
      return;
    }

    // In-app toast
    NotificationService.instance.showQuotationStatusToast(
      status: status,
      providerName: providerName,
      isProvider: false,
    );

    // Push notification (mobile only)
    await NotificationService.instance.showQuotationStatusNotification(
      quotationId: quotationId,
      status: status,
      providerName: providerName,
      isProvider: false,
    );
  }

  // ─── PROVIDER NOTIFICATIONS ───────────────────────────────────────────────

  Future<void> _notifyProvider({
    required String quotationId,
    required String status,
    String? customerName,
  }) async {
    // Only notify for statuses relevant to the provider
    if (!['accepted', 'rejected', 'negotiating'].contains(status)) return;

    // In-app toast
    NotificationService.instance.showQuotationStatusToast(
      status: status,
      customerName: customerName,
      isProvider: true,
    );

    // Push notification (mobile only)
    await NotificationService.instance.showQuotationStatusNotification(
      quotationId: quotationId,
      status: status,
      customerName: customerName,
      isProvider: true,
    );
  }
}
