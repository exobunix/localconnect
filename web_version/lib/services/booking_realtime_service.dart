import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './notification_service.dart';
import './supabase_service.dart';

/// Global real-time listener for booking status changes.
///
/// Subscribes to the [bookings] table for the current customer and fires
/// push notifications + in-app toasts when a provider:
///   • accepts  → status: 'accepted'
///   • starts   → status: 'in_progress'
///   • completes → status: 'completed'
///   • cancels  → status: 'cancelled'
///
/// Also subscribes to the [orders] table (quotation-based bookings) for the
/// same statuses so both booking flows are covered.
class BookingRealtimeService {
  static BookingRealtimeService? _instance;
  static BookingRealtimeService get instance =>
      _instance ??= BookingRealtimeService._();

  BookingRealtimeService._();

  RealtimeChannel? _bookingsChannel;
  RealtimeChannel? _ordersChannel;
  bool _isListening = false;

  // Track last known statuses to avoid duplicate notifications
  final Map<String, String> _lastKnownStatus = {};

  SupabaseClient get _client => SupabaseService.instance.client;

  // ─── START ────────────────────────────────────────────────────────────────

  /// Call once after the user is authenticated.
  /// Safe to call multiple times – will not create duplicate channels.
  Future<void> startListening() async {
    if (_isListening) return;

    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    _isListening = true;
    _lastKnownStatus.clear();

    // ── Subscribe to direct bookings (bookings table) ──────────────────────
    _bookingsChannel = _client
        .channel('booking_status_updates_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) => _handleBookingChange(payload, userId),
        )
        .subscribe((status, [error]) {
          if (error != null) {
            debugPrint('[BookingRealtime] bookings subscription error: $error');
          }
        });

    // ── Subscribe to quotation-based orders (orders table) ────────────────
    _ordersChannel = _client
        .channel('order_status_updates_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) => _handleOrderChange(payload, userId),
        )
        .subscribe((status, [error]) {
          if (error != null) {
            debugPrint('[BookingRealtime] orders subscription error: $error');
          }
        });
  }

  /// Stop listening and clean up channels.
  Future<void> stopListening() async {
    await _bookingsChannel?.unsubscribe();
    await _ordersChannel?.unsubscribe();
    _bookingsChannel = null;
    _ordersChannel = null;
    _isListening = false;
    _lastKnownStatus.clear();
  }

  // ─── BOOKINGS TABLE HANDLER ───────────────────────────────────────────────

  Future<void> _handleBookingChange(
    PostgresChangePayload payload,
    String currentUserId,
  ) async {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final bookingId = newRecord['id'] as String? ?? '';
      final newStatus = newRecord['status'] as String? ?? '';
      final providerId = newRecord['provider_id'] as String? ?? '';

      if (bookingId.isEmpty || newStatus.isEmpty) return;

      // Deduplicate: skip if status hasn't changed
      final cacheKey = 'booking_$bookingId';
      if (_lastKnownStatus[cacheKey] == newStatus) return;
      _lastKnownStatus[cacheKey] = newStatus;

      // Only notify for provider-driven status changes
      if (!_isNotifiableStatus(newStatus)) return;

      // Fetch provider name for richer notification
      String? providerName;
      if (providerId.isNotEmpty) {
        try {
          final providerData = await _client
              .from('service_providers')
              .select('business_name')
              .eq('id', providerId)
              .maybeSingle();
          providerName = providerData?['business_name'] as String?;
        } catch (_) {}
      }

      // In-app toast overlay
      NotificationService.instance.showBookingStatusToast(
        status: newStatus,
        providerName: providerName,
      );

      // Push notification (mobile only)
      await NotificationService.instance.showBookingStatusNotification(
        bookingId: bookingId,
        status: newStatus,
        providerName: providerName,
      );
    } catch (e) {
      debugPrint('[BookingRealtime] error handling booking change: $e');
    }
  }

  // ─── ORDERS TABLE HANDLER ─────────────────────────────────────────────────

  Future<void> _handleOrderChange(
    PostgresChangePayload payload,
    String currentUserId,
  ) async {
    try {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final orderId = newRecord['id'] as String? ?? '';
      final newStatus = newRecord['status'] as String? ?? '';
      final providerId = newRecord['provider_id'] as String? ?? '';

      if (orderId.isEmpty || newStatus.isEmpty) return;

      // Deduplicate: skip if status hasn't changed
      final cacheKey = 'order_$orderId';
      if (_lastKnownStatus[cacheKey] == newStatus) return;
      _lastKnownStatus[cacheKey] = newStatus;

      // Map order statuses to booking notification statuses
      final mappedStatus = _mapOrderStatus(newStatus);
      if (mappedStatus == null) return;

      // Fetch provider name for richer notification
      String? providerName;
      if (providerId.isNotEmpty) {
        try {
          final providerData = await _client
              .from('service_providers')
              .select('business_name')
              .eq('id', providerId)
              .maybeSingle();
          providerName = providerData?['business_name'] as String?;
        } catch (_) {}
      }

      // In-app toast overlay
      NotificationService.instance.showBookingStatusToast(
        status: mappedStatus,
        providerName: providerName,
      );

      // Push notification (mobile only)
      await NotificationService.instance.showBookingStatusNotification(
        bookingId: orderId,
        status: mappedStatus,
        providerName: providerName,
      );
    } catch (e) {
      debugPrint('[BookingRealtime] error handling order change: $e');
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  /// Returns true for statuses that are driven by the provider and
  /// should trigger a customer notification.
  bool _isNotifiableStatus(String status) {
    return const {
      'accepted',
      'in_progress',
      'completed',
      'cancelled',
    }.contains(status);
  }

  /// Maps order-table statuses to the booking notification status strings.
  /// Returns null if the status should not trigger a notification.
  String? _mapOrderStatus(String orderStatus) {
    switch (orderStatus) {
      case 'active':
      case 'confirmed':
        return 'accepted';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return null;
    }
  }
}

