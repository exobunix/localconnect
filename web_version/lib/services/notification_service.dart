import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for showing local push notifications for order updates.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Plays a notification chime sound (Web Audio synthesizer on Web, system sound on mobile)
  void playNotificationSound() {
    try {
      if (kIsWeb) {
        try {
          final script = html.ScriptElement()
            ..text = '''
              (function() {
                try {
                  var AudioContext = window.AudioContext || window.webkitAudioContext;
                  if (!AudioContext) return;
                  var ctx = new AudioContext();
                  
                  var osc1 = ctx.createOscillator();
                  var gain1 = ctx.createGain();
                  osc1.type = 'sine';
                  osc1.frequency.setValueAtTime(880, ctx.currentTime);
                  gain1.gain.setValueAtTime(0.2, ctx.currentTime);
                  gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
                  osc1.connect(gain1);
                  gain1.connect(ctx.destination);
                  osc1.start(ctx.currentTime);
                  osc1.stop(ctx.currentTime + 0.35);

                  var osc2 = ctx.createOscillator();
                  var gain2 = ctx.createGain();
                  osc2.type = 'sine';
                  osc2.frequency.setValueAtTime(1318.5, ctx.currentTime + 0.12);
                  gain2.gain.setValueAtTime(0.25, ctx.currentTime + 0.12);
                  gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.45);
                  osc2.connect(gain2);
                  gain2.connect(ctx.destination);
                  osc2.start(ctx.currentTime + 0.12);
                  osc2.stop(ctx.currentTime + 0.45);
                } catch(e) {}
              })();
            ''';
          html.document.body?.append(script);
          script.remove();
        } catch (_) {}
      } else {
        SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  // ─── IN-APP TOAST OVERLAY ─────────────────────────────────────────────────

  /// Global overlay key for in-app toast notifications
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentToastEntry;
  Timer? _toastTimer;

  /// Show generic in-app toast notification with icon and message
  void showInAppToast({
    required String title,
    required String subtitle,
    IconData icon = Icons.notifications_active_rounded,
    Color iconColor = const Color(0xFF1E3A8A),
    Color bgColor = const Color(0xFFF1F5F9),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentToastEntry?.remove();
    _toastTimer?.cancel();

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: icon,
        iconColor: iconColor,
        bgColor: bgColor,
        title: title,
        subtitle: subtitle,
        onDismiss: () {
          _currentToastEntry?.remove();
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    });
  }

  /// Show an in-app toast overlay for ride status changes
  void showRideStatusToast({
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    final config = _rideToastConfig(
      status: status,
      providerName: providerName,
      customerName: customerName,
      isProvider: isProvider,
    );
    if (config == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Remove existing toast
    _currentToastEntry?.remove();
    _toastTimer?.cancel();

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: config['icon'] as IconData,
        iconColor: config['iconColor'] as Color,
        bgColor: config['bgColor'] as Color,
        title: config['title'] as String,
        subtitle: config['subtitle'] as String,
        onDismiss: () {
          _currentToastEntry?.remove();
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    });
  }

  Map<String, dynamic>? _rideToastConfig({
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    if (isProvider) {
      // Provider-side toasts
      switch (status) {
        case 'pending':
          return {
            'icon': Icons.notifications_active_rounded,
            'iconColor': const Color(0xFF1565C0),
            'bgColor': const Color(0xFFE3F2FD),
            'title': '🔔 New Ride Request',
            'subtitle': customerName != null
                ? '$customerName is requesting a ride'
                : 'A new ride request has arrived',
          };
        case 'cancelled':
          return {
            'icon': Icons.cancel_rounded,
            'iconColor': const Color(0xFFC62828),
            'bgColor': const Color(0xFFFFEBEE),
            'title': '❌ Ride Cancelled',
            'subtitle': customerName != null
                ? '$customerName cancelled the ride request'
                : 'Customer cancelled the ride request',
          };
        default:
          return null;
      }
    } else {
      // Customer-side toasts
      switch (status) {
        case 'accepted':
          return {
            'icon': Icons.check_circle_rounded,
            'iconColor': const Color(0xFF2E7D32),
            'bgColor': const Color(0xFFE8F5E9),
            'title': '✅ Ride Accepted!',
            'subtitle': providerName != null
                ? '$providerName accepted your ride request'
                : 'Your ride request has been accepted',
          };
        case 'rejected':
          return {
            'icon': Icons.cancel_rounded,
            'iconColor': const Color(0xFFC62828),
            'bgColor': const Color(0xFFFFEBEE),
            'title': '❌ Ride Rejected',
            'subtitle': providerName != null
                ? '$providerName could not accept your request'
                : 'Your ride request was rejected',
          };
        case 'in_progress':
          return {
            'icon': Icons.directions_car_rounded,
            'iconColor': const Color(0xFF1565C0),
            'bgColor': const Color(0xFFE3F2FD),
            'title': '🚗 Ride Started!',
            'subtitle': providerName != null
                ? '$providerName has started your ride'
                : 'Your ride has started',
          };
        case 'completed':
          return {
            'icon': Icons.celebration_rounded,
            'iconColor': const Color(0xFF2E7D32),
            'bgColor': const Color(0xFFE8F5E9),
            'title': '🎉 Ride Completed!',
            'subtitle': 'Your ride is complete. Please rate your experience.',
          };
        case 'cancelled':
          return {
            'icon': Icons.cancel_rounded,
            'iconColor': const Color(0xFFC62828),
            'bgColor': const Color(0xFFFFEBEE),
            'title': '❌ Ride Cancelled',
            'subtitle': providerName != null
                ? '$providerName cancelled your ride'
                : 'Your ride has been cancelled',
          };
        default:
          return null;
      }
    }
  }

  // ─── INITIALIZATION ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _pendingNavigationPayload = payload;
    }
  }

  String? _pendingNavigationPayload;
  String? get pendingNavigationPayload => _pendingNavigationPayload;
  void clearPendingPayload() => _pendingNavigationPayload = null;

  // ─── ORDER NOTIFICATIONS ──────────────────────────────────────────────────

  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    String? providerName,
  }) async {
    if (kIsWeb || !_initialized) return;

    final title = _titleForStatus(status);
    final body = _bodyForStatus(status, providerName);
    if (title == null) return;

    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: orderId.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: orderId,
    );
  }

  /// Generic local notification — used for subscription reminders etc.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (kIsWeb || !_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'subscription_updates',
      'Subscription Updates',
      channelDescription: 'Notifications for subscription status and reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      id: id ?? title.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ─── RIDE NOTIFICATIONS ───────────────────────────────────────────────────

  Future<void> showRideStatusNotification({
    required String rideId,
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) async {
    if (kIsWeb || !_initialized) return;

    String? title;
    String body = '';

    if (isProvider) {
      switch (status) {
        case 'pending':
          title = '🔔 New Ride Request';
          body = customerName != null
              ? '$customerName is requesting a ride'
              : 'A new ride request has arrived';
          break;
        case 'cancelled':
          title = '❌ Ride Cancelled';
          body = customerName != null
              ? '$customerName cancelled the ride'
              : 'Customer cancelled the ride';
          break;
      }
    } else {
      switch (status) {
        case 'accepted':
          title = '✅ Ride Accepted!';
          body = providerName != null
              ? '$providerName accepted your ride request'
              : 'Your ride request has been accepted';
          break;
        case 'rejected':
          title = '❌ Ride Rejected';
          body = providerName != null
              ? '$providerName could not accept your request'
              : 'Your ride request was rejected';
          break;
        case 'in_progress':
          title = '🚗 Ride Started!';
          body = providerName != null
              ? '$providerName has started your ride'
              : 'Your ride has started';
          break;
        case 'completed':
          title = '🎉 Ride Completed!';
          body = 'Your ride is complete. Please rate your experience.';
          break;
        case 'cancelled':
          title = '❌ Ride Cancelled';
          body = providerName != null
              ? '$providerName cancelled your ride'
              : 'Your ride has been cancelled';
          break;
      }
    }

    if (title == null) return;

    const androidDetails = AndroidNotificationDetails(
      'ride_updates',
      'Ride Updates',
      channelDescription: 'Notifications for ride status changes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: rideId.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'ride:$rideId',
    );
  }

  Future<void> showNewMessageNotification({
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: senderId.hashCode,
      title: 'New message from $senderName',
      body: message.length > 60 ? '${message.substring(0, 60)}...' : message,
      notificationDetails: details,
      payload: 'chat:$senderId',
    );
  }

  String? _titleForStatus(String status) {
    switch (status) {
      case 'confirmed':
        return '✅ Order Confirmed';
      case 'provider_accepted':
        return '🤝 Provider Accepted';
      case 'active':
      case 'accepted':
        return '✅ Order Accepted!';
      case 'en_route':
        return '🚴 Provider On the Way';
      case 'delivered':
        return '🎉 Service Completed';
      case 'cancelled':
        return '❌ Order Cancelled';
      case 'payment_received':
        return '💰 Payment Received';
      // Booking statuses
      case 'pending':
        return '⏳ Booking Placed';
      case 'in_progress':
        return '🔧 Service In Progress';
      case 'completed':
        return '🎉 Booking Completed!';
      default:
        return null;
    }
  }

  String _bodyForStatus(String status, String? providerName) {
    final name = providerName ?? 'Your provider';
    switch (status) {
      case 'confirmed':
        return 'Your order has been placed successfully.';
      case 'provider_accepted':
        return '$name has accepted your order and is preparing.';
      case 'active':
      case 'accepted':
        return '$name has accepted your order and will arrive soon.';
      case 'en_route':
        return '$name is on the way to your location.';
      case 'delivered':
        return 'Service delivered! Tap to rate your experience.';
      case 'cancelled':
        return 'Your order has been declined. Please try another provider.';
      case 'payment_received':
        return 'Payment from $name has been received for your order.';
      // Booking statuses
      case 'pending':
        return 'Your booking is placed and waiting for provider confirmation.';
      case 'in_progress':
        return '$name has started the service at your location.';
      case 'completed':
        return 'Service completed! Tap to rate your experience.';
      default:
        return 'Your order status has been updated.';
    }
  }

  // ─── BOOKING NOTIFICATIONS ────────────────────────────────────────────────

  /// Show a push notification when a booking status changes (customer-side).
  /// Handles: pending → accepted → in_progress → completed → cancelled
  Future<void> showBookingStatusNotification({
    required String bookingId,
    required String status,
    String? providerName,
  }) async {
    if (kIsWeb || !_initialized) return;

    final title = _titleForStatus(status);
    final body = _bodyForStatus(status, providerName);
    if (title == null) return;

    const androidDetails = AndroidNotificationDetails(
      'booking_updates',
      'Booking Updates',
      channelDescription: 'Notifications for booking status changes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: bookingId.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'booking:$bookingId',
    );
  }

  /// Show a push notification to a provider when a new booking arrives.
  Future<void> showNewBookingNotification({
    required String bookingId,
    String? customerName,
    String? serviceName,
  }) async {
    if (kIsWeb || !_initialized) return;

    final body = customerName != null
        ? '$customerName booked ${serviceName ?? 'a service'}'
        : 'You have a new booking request';

    const androidDetails = AndroidNotificationDetails(
      'booking_updates',
      'Booking Updates',
      channelDescription: 'Notifications for booking status changes',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: bookingId.hashCode,
      title: '🔔 New Booking Request',
      body: body,
      notificationDetails: details,
      payload: 'booking:$bookingId',
    );
  }

  /// Show an in-app toast overlay for booking status changes (customer-side).
  void showBookingStatusToast({required String status, String? providerName}) {
    final config = _bookingToastConfig(
      status: status,
      providerName: providerName,
    );
    if (config == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentToastEntry?.remove();
    _toastTimer?.cancel();

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: config['icon'] as IconData,
        iconColor: config['iconColor'] as Color,
        bgColor: config['bgColor'] as Color,
        title: config['title'] as String,
        subtitle: config['subtitle'] as String,
        onDismiss: () {
          _currentToastEntry?.remove();
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    });
  }

  /// Show an in-app toast overlay for new booking requests (provider-side).
  void showNewBookingToast({String? customerName, String? serviceName}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentToastEntry?.remove();
    _toastTimer?.cancel();

    final subtitle = customerName != null
        ? '$customerName booked ${serviceName ?? 'a service'}'
        : 'You have a new booking request';

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        title: '🔔 New Booking Request',
        subtitle: subtitle,
        onDismiss: () {
          _currentToastEntry?.remove();
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    });
  }

  Map<String, dynamic>? _bookingToastConfig({
    required String status,
    String? providerName,
  }) {
    final name = providerName ?? 'Your provider';
    switch (status) {
      case 'accepted':
        return {
          'icon': Icons.check_circle_rounded,
          'iconColor': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
          'title': '✅ Booking Accepted!',
          'subtitle': '$name accepted your booking',
        };
      case 'in_progress':
        return {
          'icon': Icons.build_rounded,
          'iconColor': const Color(0xFF6A1B9A),
          'bgColor': const Color(0xFFF3E5F5),
          'title': '🔧 Service Started',
          'subtitle': '$name has started the service',
        };
      case 'completed':
        return {
          'icon': Icons.celebration_rounded,
          'iconColor': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
          'title': '🎉 Booking Completed!',
          'subtitle': 'Service done! Please rate your experience.',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_rounded,
          'iconColor': const Color(0xFFC62828),
          'bgColor': const Color(0xFFFFEBEE),
          'title': '❌ Booking Cancelled',
          'subtitle': 'Your booking has been cancelled.',
        };
      default:
        return null;
    }
  }

  // ─── QUOTATION NOTIFICATIONS ──────────────────────────────────────────────

  /// Show a push notification when a quotation status changes.
  /// [isProvider] = true  → provider receives notification (customer accepted/rejected/negotiating)
  /// [isProvider] = false → customer receives notification (quotation sent/accepted/rejected/negotiating)
  Future<void> showQuotationStatusNotification({
    required String quotationId,
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) async {
    if (kIsWeb || !_initialized) return;

    String? title;
    String body = '';

    if (isProvider) {
      switch (status) {
        case 'accepted':
          title = '✅ Quotation Accepted!';
          body = customerName != null
              ? '$customerName accepted your quotation'
              : 'Your quotation has been accepted';
          break;
        case 'rejected':
          title = '❌ Quotation Rejected';
          body = customerName != null
              ? '$customerName rejected your quotation'
              : 'Your quotation was rejected';
          break;
        case 'negotiating':
          title = '💬 Negotiation Requested';
          body = customerName != null
              ? '$customerName wants to negotiate the quotation'
              : 'A customer wants to negotiate your quotation';
          break;
      }
    } else {
      switch (status) {
        case 'sent':
          title = '📋 New Quotation Received';
          body = providerName != null
              ? '$providerName sent you a quotation'
              : 'You have received a new quotation';
          break;
        case 'accepted':
          title = '✅ Quotation Confirmed';
          body = providerName != null
              ? '$providerName confirmed your quotation'
              : 'Your quotation has been confirmed';
          break;
        case 'rejected':
          title = '❌ Quotation Rejected';
          body = providerName != null
              ? '$providerName could not fulfil your request'
              : 'Your quotation request was rejected';
          break;
        case 'negotiating':
          title = '💬 Negotiation Update';
          body = providerName != null
              ? '$providerName is open to negotiation'
              : 'The provider wants to negotiate';
          break;
      }
    }

    if (title == null) return;

    const androidDetails = AndroidNotificationDetails(
      'quotation_updates',
      'Quotation Updates',
      channelDescription: 'Notifications for quotation status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1565C0),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: quotationId.hashCode ^ (isProvider ? 1 : 0),
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'quotation:$quotationId',
    );
  }

  /// Show an in-app toast overlay for quotation status changes.
  void showQuotationStatusToast({
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    final config = _quotationToastConfig(
      status: status,
      providerName: providerName,
      customerName: customerName,
      isProvider: isProvider,
    );
    if (config == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentToastEntry?.remove();
    _toastTimer?.cancel();

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: config['icon'] as IconData,
        iconColor: config['iconColor'] as Color,
        bgColor: config['bgColor'] as Color,
        title: config['title'] as String,
        subtitle: config['subtitle'] as String,
        onDismiss: () {
          _currentToastEntry?.remove();
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    });
  }

  Map<String, dynamic>? _quotationToastConfig({
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    if (isProvider) {
      switch (status) {
        case 'accepted':
          return {
            'icon': Icons.check_circle_rounded,
            'iconColor': const Color(0xFF2E7D32),
            'bgColor': const Color(0xFFE8F5E9),
            'title': '✅ Quotation Accepted!',
            'subtitle': customerName != null
                ? '$customerName accepted your quotation'
                : 'Your quotation has been accepted',
          };
        case 'rejected':
          return {
            'icon': Icons.cancel_rounded,
            'iconColor': const Color(0xFFC62828),
            'bgColor': const Color(0xFFFFEBEE),
            'title': '❌ Quotation Rejected',
            'subtitle': customerName != null
                ? '$customerName rejected your quotation'
                : 'Your quotation was rejected',
          };
        case 'negotiating':
          return {
            'icon': Icons.swap_horiz_rounded,
            'iconColor': const Color(0xFFE65100),
            'bgColor': const Color(0xFFFFF3E0),
            'title': '💬 Negotiation Requested',
            'subtitle': customerName != null
                ? '$customerName wants to negotiate'
                : 'A customer wants to negotiate',
          };
        default:
          return null;
      }
    } else {
      switch (status) {
        case 'sent':
          return {
            'icon': Icons.description_rounded,
            'iconColor': const Color(0xFF1565C0),
            'bgColor': const Color(0xFFE3F2FD),
            'title': '📋 New Quotation Received',
            'subtitle': providerName != null
                ? '$providerName sent you a quotation'
                : 'You have received a new quotation',
          };
        case 'accepted':
          return {
            'icon': Icons.check_circle_rounded,
            'iconColor': const Color(0xFF2E7D32),
            'bgColor': const Color(0xFFE8F5E9),
            'title': '✅ Quotation Confirmed',
            'subtitle': providerName != null
                ? '$providerName confirmed your quotation'
                : 'Your quotation has been confirmed',
          };
        case 'rejected':
          return {
            'icon': Icons.cancel_rounded,
            'iconColor': const Color(0xFFC62828),
            'bgColor': const Color(0xFFFFEBEE),
            'title': '❌ Quotation Rejected',
            'subtitle': providerName != null
                ? '$providerName could not fulfil your request'
                : 'Your quotation request was rejected',
          };
        case 'negotiating':
          return {
            'icon': Icons.swap_horiz_rounded,
            'iconColor': const Color(0xFFE65100),
            'bgColor': const Color(0xFFFFF3E0),
            'title': '💬 Negotiation Update',
            'subtitle': providerName != null
                ? '$providerName is open to negotiation'
                : 'The provider wants to negotiate',
          };
        default:
          return null;
      }
    }
  }

  // ─── UNIVERSAL BOOKING, ENQUIRY & ADMIN PUSH DISPATCHERS ─────────────────

  /// Notify when a customer creates a new booking
  Future<void> notifyBookingCreated({
    required String bookingId,
    required String service,
    required String customerId,
    required String customerName,
    required String providerId,
    required String providerName,
    required String amount,
  }) async {
    playNotificationSound();

    showInAppToast(
      title: '✅ Booking Confirmed (#$bookingId)',
      subtitle: 'Your booking for $service with $providerName ($amount) is confirmed.',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF00C853),
      bgColor: const Color(0xFFE8F5E9),
    );

    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': customerId,
        'title': 'Booking Confirmed (#$bookingId)',
        'body': 'Your booking for $service with $providerName has been placed.',
        'type': 'booking',
        'is_read': false,
        'created_at': now,
      });

      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': providerId,
        'title': '🎉 New Booking Received (#$bookingId)',
        'body': '$customerName booked $service for $amount.',
        'type': 'booking',
        'is_read': false,
        'created_at': now,
      });

      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': 'admin',
        'title': '📦 New Booking Placed (#$bookingId)',
        'body': '$customerName booked $service with $providerName ($amount).',
        'type': 'admin_broadcast',
        'is_read': false,
        'created_at': now,
      });
    } catch (_) {}
  }

  /// Notify when booking status changes (accepted, in_progress, completed, cancelled)
  Future<void> notifyBookingStatusChanged({
    required String bookingId,
    required String service,
    required String customerId,
    required String providerId,
    required String newStatus,
  }) async {
    playNotificationSound();

    final statusText = newStatus == 'accepted'
        ? 'Accepted'
        : newStatus == 'in_progress'
            ? 'In Progress'
            : newStatus == 'completed'
                ? 'Completed'
                : 'Cancelled';

    showInAppToast(
      title: 'Booking $statusText (#$bookingId)',
      subtitle: 'Your booking for $service is now $statusText.',
      icon: newStatus == 'completed'
          ? Icons.verified_rounded
          : newStatus == 'cancelled'
              ? Icons.cancel_rounded
              : Icons.update_rounded,
      iconColor: newStatus == 'completed'
          ? const Color(0xFF00C853)
          : newStatus == 'cancelled'
              ? Colors.red
              : const Color(0xFF1E3A8A),
      bgColor: const Color(0xFFF1F5F9),
    );

    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': customerId,
        'title': 'Booking Status: $statusText (#$bookingId)',
        'body': 'Your service $service is now marked as $statusText.',
        'type': 'booking_status',
        'is_read': false,
        'created_at': now,
      });
    } catch (_) {}
  }

  /// Notify when a customer submits an enquiry to a provider
  Future<void> notifyEnquirySubmitted({
    required String enquiryId,
    required String subcategory,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String providerId,
    required String providerName,
    required String message,
  }) async {
    playNotificationSound();

    showInAppToast(
      title: '📨 Enquiry Sent (#$enquiryId)',
      subtitle: 'Your enquiry for $subcategory was sent to $providerName.',
      icon: Icons.send_rounded,
      iconColor: const Color(0xFF1E3A8A),
      bgColor: const Color(0xFFE0E7FF),
    );

    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': providerId,
        'title': '📩 New Customer Enquiry (#$enquiryId)',
        'body': '$customerName ($customerPhone) sent an enquiry for $subcategory: "$message"',
        'type': 'enquiry',
        'is_read': false,
        'created_at': now,
      });

      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': customerId,
        'title': 'Enquiry Submitted (#$enquiryId)',
        'body': 'Your enquiry for $subcategory has reached $providerName.',
        'type': 'enquiry',
        'is_read': false,
        'created_at': now,
      });

      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': 'admin',
        'title': '📋 New Platform Enquiry (#$enquiryId)',
        'body': '$customerName ➔ $providerName ($subcategory)',
        'type': 'admin_broadcast',
        'is_read': false,
        'created_at': now,
      });
    } catch (_) {}
  }

  RealtimeChannel? _broadcastChannel;

  /// Starts listening to real-time admin broadcast alerts and notifications
  void startListeningToBroadcastNotifications() {
    if (_broadcastChannel != null) return;
    try {
      _broadcastChannel = SupabaseService.instance.client
          .channel('public:global_admin_broadcast')
          .onBroadcast(
            event: 'admin_push_notification',
            callback: (payload) {
              final title = payload['title'] as String? ?? 'Notification';
              final body = payload['body'] as String? ?? '';
              final targetType = payload['target_type'] as String? ?? 'all_users';
              final targetUserId = payload['target_user_id'] as String?;
              final currentUserId = SupabaseService.instance.currentUser?.id;

              bool applies = false;
              if (targetType == 'all_users' || targetType == 'all') {
                applies = true;
              } else if (targetType == 'all_customers') {
                applies = true;
              } else if (targetType == 'all_vendors') {
                applies = true;
              } else if (targetType == 'specific_user') {
                applies = currentUserId != null && currentUserId == targetUserId;
              }

              if (applies) {
                playNotificationSound();
                showInAppToast(
                  title: title,
                  subtitle: body,
                  icon: Icons.campaign_rounded,
                  iconColor: const Color(0xFF1E3A8A),
                  bgColor: const Color(0xFFF1F5F9),
                );
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final uid = newRecord['user_id'] as String?;
              final currentUserId = SupabaseService.instance.currentUser?.id;

              bool applies = false;
              if (uid == null || (currentUserId != null && uid == currentUserId)) {
                applies = true;
              }

              if (applies) {
                playNotificationSound();
                showInAppToast(
                  title: newRecord['title'] as String? ?? 'Notification',
                  subtitle: newRecord['body'] as String? ?? '',
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF1E3A8A),
                  bgColor: const Color(0xFFF1F5F9),
                );
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[NotificationService] Broadcast listener error: $e');
    }
  }

  /// Admin broadcast push notification to all customers, all vendors, or a specific user
  Future<int> broadcastAdminPushNotification({
    required String targetType,
    String? targetUserId,
    required String title,
    required String body,
  }) async {
    playNotificationSound();
    int sentCount = 0;

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Insert primary broadcast row
      final broadcastRow = <String, dynamic>{
        'title': title,
        'body': body,
        'type': 'admin_broadcast',
        'target_audience': targetType,
        'is_read': false,
        'created_at': now,
      };

      if (targetType == 'specific_user' && targetUserId != null) {
        broadcastRow['user_id'] = targetUserId;
        broadcastRow['target_audience'] = 'specific';
      } else {
        broadcastRow['user_id'] = null;
      }

      await SupabaseService.instance.client.from('notifications').insert(broadcastRow);
      sentCount = 1;

      // 2. Also insert individual rows for users if broadcasting to a group
      if (targetType != 'specific_user') {
        try {
          var query = SupabaseService.instance.client.from('user_profiles').select('id, role');
          if (targetType == 'all_customers') {
            query = query.eq('role', 'customer');
          } else if (targetType == 'all_vendors') {
            query = query.eq('role', 'provider');
          }

          final users = await query;
          final userList = List<Map<String, dynamic>>.from(users);
          final rows = <Map<String, dynamic>>[];
          for (final u in userList) {
            final uid = u['id'] as String?;
            if (uid != null && uid.isNotEmpty) {
              rows.add({
                'user_id': uid,
                'title': title,
                'body': body,
                'type': 'admin_broadcast',
                'target_audience': targetType,
                'is_read': false,
                'created_at': now,
              });
            }
          }
          if (rows.isNotEmpty) {
            await SupabaseService.instance.client.from('notifications').insert(rows);
            sentCount += rows.length;
          }
        } catch (e) {
          debugPrint('[NotificationService] Individual row insert: $e');
        }
      }

      // 3. Dispatch realtime broadcast event to all active clients
      try {
        final broadcastChannel = SupabaseService.instance.client.channel('public:global_admin_broadcast');
        await broadcastChannel.sendBroadcastMessage(
          event: 'admin_push_notification',
          payload: {
            'title': title,
            'body': body,
            'target_type': targetType,
            'target_user_id': targetUserId,
            'timestamp': now,
          },
        );
      } catch (e) {
        debugPrint('[NotificationService] Realtime channel broadcast: $e');
      }

      showInAppToast(
        title: '📢 Push Notification Dispatched',
        subtitle: 'Sent "$title" to $sentCount recipient(s).',
        icon: Icons.campaign_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      );
    } catch (e) {
      debugPrint('[NotificationService] Broadcast error: $e');
    }

    return sentCount;
  }
}

// ─── IN-APP TOAST WIDGET ──────────────────────────────────────────────────────

class _RideStatusToastWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const _RideStatusToastWidget({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
  });

  @override
  State<_RideStatusToastWidget> createState() => _RideStatusToastWidgetState();
}

class _RideStatusToastWidgetState extends State<_RideStatusToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.iconColor.withAlpha(77),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF44474E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: const Color(0xFF74777F),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
