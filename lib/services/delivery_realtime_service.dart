import 'dart:async';
import 'package:localconnect/core/supabase_mock.dart';

/// Delivery Realtime Service
/// Handles GPS location broadcasting and delivery status sync
/// across Rider, Vendor, and Customer screens via Supabase Realtime.
class DeliveryRealtimeService {
  static final DeliveryRealtimeService _instance =
      DeliveryRealtimeService._internal();
  factory DeliveryRealtimeService() => _instance;
  DeliveryRealtimeService._internal();

  static DeliveryRealtimeService get instance => _instance;

  final SupabaseClient _client = Supabase.instance.client;

  // Active realtime channels
  final Map<String, RealtimeChannel> _channels = {};

  // ─── RIDER: Broadcast GPS location ──────────────────────────────────────────

  /// Upsert rider's live location into rider_locations table.
  /// Called by the Rider app on every GPS update.
  Future<void> updateRiderLocation({
    required double lat,
    required double lng,
    required bool isOnline,
    String? activeDeliveryId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('rider_locations').upsert({
        'rider_id': userId,
        'latitude': lat,
        'longitude': lng,
        'is_online': isOnline,
        'active_delivery_id': activeDeliveryId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'rider_id');
    } catch (_) {
      // Silent fail — GPS continues even if Supabase update fails
    }
  }

  // ─── RIDER: Update delivery status ──────────────────────────────────────────

  /// Update delivery status (accepted → picked_up → delivered).
  /// Called by the Rider app on each status change.
  Future<bool> updateDeliveryStatus({
    required String deliveryId,
    required String
    status, // 'accepted' | 'picked_up' | 'delivered' | 'cancelled'
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{
        'delivery_status': status,
        'updated_at': now,
      };

      switch (status) {
        case 'accepted':
          updates['accepted_at'] = now;
          break;
        case 'picked_up':
          updates['picked_up_at'] = now;
          break;
        case 'delivered':
          updates['delivered_at'] = now;
          break;
        case 'cancelled':
          updates['cancelled_at'] = now;
          break;
      }

      await _client
          .from('delivery_tracking')
          .update(updates)
          .eq('delivery_id', deliveryId);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── RIDER: Create or upsert delivery record ─────────────────────────────────

  /// Create a new delivery tracking record when rider accepts an order.
  Future<bool> createDeliveryTracking({
    required String deliveryId,
    required String deliveryType,
    required String pickupAddress,
    required String dropoffAddress,
    required double amount,
    required double riderEarning,
    String? customerId,
    String? vendorId,
  }) async {
    try {
      final riderId = _client.auth.currentUser?.id;
      if (riderId == null) return false;

      // Generate 4-digit OTPs
      final pickupOtp = (1000 + (DateTime.now().millisecond * 9) % 9000)
          .toString();
      final deliveryOtp = (1000 + (DateTime.now().microsecond * 7) % 9000)
          .toString();

      await _client.from('delivery_tracking').upsert({
        'delivery_id': deliveryId,
        'rider_id': riderId,
        'customer_id': customerId,
        'vendor_id': vendorId,
        'delivery_type': deliveryType,
        'delivery_status': 'accepted',
        'pickup_address': pickupAddress,
        'dropoff_address': dropoffAddress,
        'amount': amount,
        'rider_earning': riderEarning,
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
        'accepted_at': DateTime.now().toIso8601String(),
      }, onConflict: 'delivery_id');

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── SUBSCRIBE: Rider location updates (for Vendor & Customer) ───────────────

  /// Subscribe to a specific rider's live location.
  /// Used by Vendor Dashboard and Customer Screen.
  RealtimeChannel subscribeToRiderLocation({
    required String riderId,
    required void Function(double lat, double lng, bool isOnline) onUpdate,
  }) {
    final channelKey = 'rider_loc_$riderId';
    _channels[channelKey]?.unsubscribe();

    final channel = _client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rider_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'rider_id',
            value: riderId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            final lat = (record['latitude'] as num?)?.toDouble();
            final lng = (record['longitude'] as num?)?.toDouble();
            final isOnline = record['is_online'] as bool? ?? false;
            if (lat != null && lng != null) {
              onUpdate(lat, lng, isOnline);
            }
          },
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  // ─── SUBSCRIBE: Delivery status updates ──────────────────────────────────────

  /// Subscribe to a specific delivery's status changes.
  /// Used by Customer Screen and Vendor Dashboard.
  RealtimeChannel subscribeToDeliveryStatus({
    required String deliveryId,
    required void Function(String status, Map<String, dynamic> record) onUpdate,
  }) {
    final channelKey = 'delivery_status_$deliveryId';
    _channels[channelKey]?.unsubscribe();

    final channel = _client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'delivery_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'delivery_id',
            value: deliveryId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            final status = record['delivery_status'] as String? ?? 'pending';
            onUpdate(status, record);
          },
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  // ─── SUBSCRIBE: All active deliveries (for Vendor Dashboard) ─────────────────

  /// Subscribe to all delivery_tracking changes.
  /// Used by Vendor Dashboard to monitor all deliveries in real-time.
  RealtimeChannel subscribeToAllDeliveries({
    required void Function(String eventType, Map<String, dynamic> record)
    onUpdate,
  }) {
    const channelKey = 'all_deliveries';
    _channels[channelKey]?.unsubscribe();

    final channel = _client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_tracking',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            onUpdate(payload.eventType.name, record);
          },
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  // ─── SUBSCRIBE: All rider locations (for Vendor Dashboard map) ───────────────

  /// Subscribe to all rider location updates.
  /// Used by Vendor Dashboard live map.
  RealtimeChannel subscribeToAllRiderLocations({
    required void Function(Map<String, dynamic> record) onUpdate,
  }) {
    const channelKey = 'all_rider_locations';
    _channels[channelKey]?.unsubscribe();

    final channel = _client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rider_locations',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) onUpdate(record);
          },
        )
        .subscribe();

    _channels[channelKey] = channel;
    return channel;
  }

  // ─── FETCH: Get delivery tracking record ─────────────────────────────────────

  Future<Map<String, dynamic>?> getDeliveryTracking(String deliveryId) async {
    try {
      final result = await _client
          .from('delivery_tracking')
          .select()
          .eq('delivery_id', deliveryId)
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  }

  // ─── FETCH: Get rider's current location ─────────────────────────────────────

  Future<Map<String, dynamic>?> getRiderLocation(String riderId) async {
    try {
      final result = await _client
          .from('rider_locations')
          .select()
          .eq('rider_id', riderId)
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  }

  // ─── FETCH: Get all online riders ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOnlineRiders() async {
    try {
      final result = await _client
          .from('rider_locations')
          .select()
          .eq('is_online', true);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  // ─── FETCH: Get active deliveries for vendor ─────────────────────────────────

  Future<List<Map<String, dynamic>>> getActiveDeliveries() async {
    try {
      final result = await _client
          .from('delivery_tracking')
          .select()
          .inFilter('delivery_status', ['accepted', 'picked_up'])
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  // ─── CLEANUP ─────────────────────────────────────────────────────────────────

  /// Unsubscribe a specific channel by key.
  void unsubscribe(String channelKey) {
    _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);
  }

  /// Unsubscribe all channels. Call in dispose().
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
