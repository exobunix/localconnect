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
  int _enquiryUnread = 0;
  int _responseUnread = 0;
  int _reviewUnread = 0;

  int get quotationUnread => _quotationUnread;
  int get bookingUnread => _bookingUnread;
  int get enquiryUnread => _enquiryUnread;
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
    _enquiryUnread = 0;
    _responseUnread = 0;
    _reviewUnread = 0;
    notifyListeners();
    await initialize();
  }

  Future<void> _fetchCounts() async {
    try {
      final notifs = await SupabaseService.instance.getNotifications();
      final unreadList = notifs.where((n) => n['is_read'] == false).toList();
      _unreadCount = unreadList.length;
      _quotationUnread = unreadList.where((n) => n['type'] == 'quotation').length;
      _bookingUnread = unreadList.where((n) => n['type'] == 'booking' || n['type'] == 'booking_status').length;
      _enquiryUnread = unreadList.where((n) => n['type'] == 'enquiry').length;
      _responseUnread = unreadList.where((n) => n['type'] == 'message').length;
      _reviewUnread = unreadList.where((n) => n['type'] == 'review').length;
      notifyListeners();
    } catch (_) {}
  }

  void _subscribeRealtime() {
    _channel = SupabaseService.instance.client
        .channel('notifications_global_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            _fetchCounts();
          },
        )
        .onBroadcast(
          event: 'notification_deleted',
          callback: (payload) {
            _fetchCounts();
          },
        )
        .onBroadcast(
          event: 'notification_created',
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
    if ((type == 'booking' || type == 'booking_status') && _bookingUnread > 0) _bookingUnread--;
    if (type == 'enquiry' && _enquiryUnread > 0) _enquiryUnread--;
    if (type == 'message' && _responseUnread > 0) _responseUnread--;
    if (type == 'review' && _reviewUnread > 0) _reviewUnread--;
    notifyListeners();
  }

  void resetAll() {
    _unreadCount = 0;
    _quotationUnread = 0;
    _bookingUnread = 0;
    _enquiryUnread = 0;
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
