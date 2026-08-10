import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localconnect/core/supabase_mock.dart';

/// GPS Tracking Service for transport providers.
/// Handles location permissions, real-time position streaming,
/// and broadcasting location updates to Supabase for live tracking.
class GpsTrackingService {
  static final GpsTrackingService _instance = GpsTrackingService._internal();
  factory GpsTrackingService() => _instance;
  GpsTrackingService._internal();

  static GpsTrackingService get instance => _instance;

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Position? _lastPosition;
  bool _isTracking = false;
  String? _activeBookingId;

  Stream<Position> get locationStream => _locationController.stream;
  Position? get lastPosition => _lastPosition;
  bool get isTracking => _isTracking;

  /// Request location permissions and check service availability.
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      // Web uses browser geolocation
      try {
        await Geolocator.getCurrentPosition();
        return true;
      } catch (_) {
        return false;
      }
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current position once.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _lastPosition = position;
      return position;
    } catch (_) {
      return null;
    }
  }

  /// Start continuous GPS tracking and broadcast to Supabase.
  Future<bool> startTracking({String? bookingId}) async {
    if (_isTracking) return true;

    final hasPermission = await requestPermission();
    if (!hasPermission) return false;

    _activeBookingId = bookingId;
    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _lastPosition = position;
            _locationController.add(position);
            _broadcastToSupabase(position);
          },
          onError: (error) {
            debugPrint('[GPS] Stream error: $error');
            _isTracking = false;
            _positionSubscription = null;
          },
          cancelOnError: false,
        );

    return true;
  }

  /// Stop GPS tracking.
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _activeBookingId = null;
  }

  /// Broadcast location to Supabase order_tracking table.
  Future<void> _broadcastToSupabase(Position position) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Validate coordinates are within reasonable bounds
      if (position.latitude < -90 ||
          position.latitude > 90 ||
          position.longitude < -180 ||
          position.longitude > 180) {
        debugPrint(
          '[GPS] Invalid coordinates: ${position.latitude}, ${position.longitude}',
        );
        return;
      }

      final payload = {
        'provider_lat': position.latitude,
        'provider_lng': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_activeBookingId != null) {
        // Update specific booking tracking
        await Supabase.instance.client
            .from('order_tracking')
            .upsert({
              ...payload,
              'order_id': _activeBookingId,
              'provider_id': userId,
              'status': 'in_transit',
            })
            .eq('order_id', _activeBookingId!);
      }

      // Also update provider's current location in providers table
      await Supabase.instance.client
          .from('service_providers')
          .update({'lat': position.latitude, 'lng': position.longitude})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[GPS] Supabase broadcast error: $e');
      // Silent fail — tracking continues even if Supabase update fails
    }
  }

  /// Subscribe to a provider's live location updates (for customers).
  RealtimeChannel subscribeToProviderLocation({
    required String providerId,
    required void Function(double lat, double lng) onLocationUpdate,
  }) {
    final channel = Supabase.instance.client
        .channel('provider_location_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'providers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: providerId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final lat = (newRecord['latitude'] as num?)?.toDouble();
            final lng = (newRecord['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              onLocationUpdate(lat, lng);
            }
          },
        )
        .subscribe();
    return channel;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
