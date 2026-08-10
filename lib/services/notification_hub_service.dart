import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Singleton service that maintains a real-time unread notification count
/// and broadcasts changes to listeners.
class NotificationHubService extends ChangeNotifier {
  static NotificationHubService? _instance;
  static NotificationHubService get instance =>
      _instance ??= NotificationHubService._();

  NotificationHubService._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Per-category unread counts
  int _quotationUnread = 0;
  int _bookingUnread = 0;
  int _responseUnread = 0;
  int _reviewUnread = 0;

  int get quotationUnread => _quotationUnread;
  int get bookingUnread => _bookingUnread;
  int get responseUnread => _responseUnread;
  int get reviewUnread => _reviewUnread;

  RealtimeChannel? _channel;
  bool _initialized = false;

  /// Call once after auth is confirmed.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _fetchCounts();
    _subscribeRealtime();
  }

  /// Re-initialize (e.g. after login/logout).
  Future<void> reinitialize() async {
    _initialized = false;
    _channel?.unsubscribe();
    _channel = null;
    _unreadCount = 0;
    _quotationUnread = 0;
    _bookingUnread = 0;
    _responseUnread = 0;
    _reviewUnread = 0;
    notifyListeners();
    await initialize();
  }

  Future<void> _fetchCounts() async {
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return;

      final rows = await SupabaseService.instance.client
          .from('notifications')
          .select('type')
          .eq('user_id', userId)
          .eq('is_read', false);

      final list = List<Map<String, dynamic>>.from(rows);
      _unreadCount = list.length;
      _quotationUnread = list.where((n) => n['type'] == 'quotation').length;
      _bookingUnread = list.where((n) => n['type'] == 'booking').length;
      _responseUnread = list.where((n) => n['type'] == 'message').length;
      _reviewUnread = list.where((n) => n['type'] == 'review').length;
      notifyListeners();
    } catch (_) {}
  }

  void _subscribeRealtime() {
    final userId = SupabaseService.instance.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    _channel = SupabaseService.instance.client
        .channel('notif_hub_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _fetchCounts();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _fetchCounts();
          },
        )
        .subscribe();
  }

  /// Decrement count locally after marking read (optimistic update).
  void decrementUnread({String? type}) {
    if (_unreadCount > 0) _unreadCount--;
    if (type == 'quotation' && _quotationUnread > 0) _quotationUnread--;
    if (type == 'booking' && _bookingUnread > 0) _bookingUnread--;
    if (type == 'message' && _responseUnread > 0) _responseUnread--;
    if (type == 'review' && _reviewUnread > 0) _reviewUnread--;
    notifyListeners();
  }

  void resetAll() {
    _unreadCount = 0;
    _quotationUnread = 0;
    _bookingUnread = 0;
    _responseUnread = 0;
    _reviewUnread = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
