import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_hub_service.dart';

/// Comprehensive Notification & Audio Engine for LocalConnect
/// Supports:
/// - Single chime sound for customer & admin notifications
/// - Continuous looping ringing sound for providers/partners until action is taken (Accept/Reject/Reply/Stop)
/// - In-app toasts & sticky floating alert banners
/// - Real-time Supabase triggers and broadcast listener
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── CONTINUOUS RINGING ENGINE (FOR PARTNERS / PROVIDERS) ─────────────────

  Timer? _continuousSoundTimer;
  OverlayEntry? _continuousAlertBannerEntry;
  String? _activeAlertId;

  /// Returns true if a continuous booking or enquiry alarm is currently ringing
  bool get isContinuousAlertPlaying => _continuousSoundTimer != null;

  /// Plays a single pleasant notification chime sound
  /// Web: Synthesized dual-tone sine chime via Web Audio API
  /// Mobile: System alert sound with haptics
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
                  
                  // Primary chime tone (880 Hz - A5)
                  var osc1 = ctx.createOscillator();
                  var gain1 = ctx.createGain();
                  osc1.type = 'sine';
                  osc1.frequency.setValueAtTime(880, ctx.currentTime);
                  gain1.gain.setValueAtTime(0.25, ctx.currentTime);
                  gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
                  osc1.connect(gain1);
                  gain1.connect(ctx.destination);
                  osc1.start(ctx.currentTime);
                  osc1.stop(ctx.currentTime + 0.35);

                  // Secondary harmonic chime (1318.5 Hz - E6)
                  var osc2 = ctx.createOscillator();
                  var gain2 = ctx.createGain();
                  osc2.type = 'sine';
                  osc2.frequency.setValueAtTime(1318.5, ctx.currentTime + 0.10);
                  gain2.gain.setValueAtTime(0.30, ctx.currentTime + 0.10);
                  gain2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.45);
                  osc2.connect(gain2);
                  gain2.connect(ctx.destination);
                  osc2.start(ctx.currentTime + 0.10);
                  osc2.stop(ctx.currentTime + 0.45);
                } catch(e) {}
              })();
            ''';
          html.document.body?.append(script);
          script.remove();
        } catch (_) {}
      } else {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Plays a distinct repeating alarm pulse (used internally by continuous ringing loop)
  void _playAlarmPulse() {
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

                  // Note 1: 587.33 Hz (D5)
                  var o1 = ctx.createOscillator();
                  var g1 = ctx.createGain();
                  o1.type = 'triangle';
                  o1.frequency.setValueAtTime(587.33, ctx.currentTime);
                  g1.gain.setValueAtTime(0.35, ctx.currentTime);
                  g1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.20);
                  o1.connect(g1);
                  g1.connect(ctx.destination);
                  o1.start(ctx.currentTime);
                  o1.stop(ctx.currentTime + 0.20);

                  // Note 2: 880 Hz (A5)
                  var o2 = ctx.createOscillator();
                  var g2 = ctx.createGain();
                  o2.type = 'triangle';
                  o2.frequency.setValueAtTime(880, ctx.currentTime + 0.15);
                  g2.gain.setValueAtTime(0.40, ctx.currentTime + 0.15);
                  g2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.38);
                  o2.connect(g2);
                  g2.connect(ctx.destination);
                  o2.start(ctx.currentTime + 0.15);
                  o2.stop(ctx.currentTime + 0.38);

                  // Note 3: 1174.66 Hz (D6)
                  var o3 = ctx.createOscillator();
                  var g3 = ctx.createGain();
                  o3.type = 'sine';
                  o3.frequency.setValueAtTime(1174.66, ctx.currentTime + 0.30);
                  g3.gain.setValueAtTime(0.45, ctx.currentTime + 0.30);
                  g3.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.65);
                  o3.connect(g3);
                  g3.connect(ctx.destination);
                  o3.start(ctx.currentTime + 0.30);
                  o3.stop(ctx.currentTime + 0.65);
                } catch(e) {}
              })();
            ''';
          html.document.body?.append(script);
          script.remove();
        } catch (_) {}
      } else {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Starts CONTINUOUS RINGING alert for provider/partner until they accept/reject/reply/dismiss
  void startContinuousBookingAlert({
    required String title,
    required String body,
    String? bookingId,
    String? enquiryId,
    String? customerName,
    String? serviceName,
    String? amount,
    bool isEnquiry = false,
    VoidCallback? onAccept,
    VoidCallback? onReject,
    VoidCallback? onReply,
    VoidCallback? onDismiss,
  }) {
    final alertId = bookingId ?? enquiryId ?? title;
    if (_activeAlertId == alertId && isContinuousAlertPlaying) {
      return; // Already playing for this specific booking/enquiry
    }

    // Stop any existing ringing first
    stopContinuousBookingAlert();

    _activeAlertId = alertId;

    // 1. Play immediate pulse
    _playAlarmPulse();

    // 2. Start repeating timer every 1.5 seconds
    _continuousSoundTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _playAlarmPulse();
    });

    // 3. Show top sticky interactive alert banner overlay
    final context = navigatorKey.currentContext;
    if (context != null) {
      _continuousAlertBannerEntry = OverlayEntry(
        builder: (_) => _ContinuousBookingAlertBanner(
          title: title,
          body: body,
          customerName: customerName,
          serviceName: serviceName,
          amount: amount,
          isEnquiry: isEnquiry,
          bookingId: bookingId,
          enquiryId: enquiryId,
          onAccept: () {
            stopContinuousBookingAlert();
            onAccept?.call();
          },
          onReject: () {
            stopContinuousBookingAlert();
            onReject?.call();
          },
          onReply: () {
            stopContinuousBookingAlert();
            onReply?.call();
          },
          onDismiss: () {
            stopContinuousBookingAlert();
            onDismiss?.call();
          },
        ),
      );

      Overlay.of(context).insert(_continuousAlertBannerEntry!);
    }
  }

  /// Stops the continuous ringing sound immediately and removes banner
  void stopContinuousBookingAlert() {
    _continuousSoundTimer?.cancel();
    _continuousSoundTimer = null;
    _activeAlertId = null;

    try {
      _continuousAlertBannerEntry?.remove();
    } catch (_) {}
    _continuousAlertBannerEntry = null;
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
    VoidCallback? onTap,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      _currentToastEntry?.remove();
    } catch (_) {}
    _toastTimer?.cancel();

    _currentToastEntry = OverlayEntry(
      builder: (_) => _RideStatusToastWidget(
        icon: icon,
        iconColor: iconColor,
        bgColor: bgColor,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        onDismiss: () {
          try {
            _currentToastEntry?.remove();
          } catch (_) {}
          _currentToastEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);

    _toastTimer = Timer(const Duration(seconds: 4), () {
      try {
        _currentToastEntry?.remove();
      } catch (_) {}
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

    showInAppToast(
      title: config['title'] as String,
      subtitle: config['subtitle'] as String,
      icon: config['icon'] as IconData,
      iconColor: config['iconColor'] as Color,
      bgColor: config['bgColor'] as Color,
    );
  }

  Future<void> showRideStatusNotification({
    required String rideId,
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) async {
    playNotificationSound();
    final config = _rideToastConfig(
      status: status,
      providerName: providerName,
      customerName: customerName,
      isProvider: isProvider,
    );
    if (config == null) return;

    await showLocalNotification(
      id: rideId.hashCode,
      title: config['title'] as String,
      body: config['subtitle'] as String,
      payload: 'ride:$rideId',
      channelId: 'ride_updates',
      channelName: 'Ride Updates',
      channelDescription: 'Ride status updates and alerts',
    );
  }

  Map<String, dynamic>? _rideToastConfig({
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    final name = isProvider
        ? (customerName ?? 'Customer')
        : (providerName ?? 'Driver');

    switch (status.toLowerCase()) {
      case 'requested':
        return {
          'icon': Icons.local_taxi_rounded,
          'iconColor': const Color(0xFF0284C7),
          'bgColor': const Color(0xFFF0F9FF),
          'title': isProvider ? '🚖 New Ride Request' : '🚖 Ride Requested',
          'subtitle': isProvider
              ? '$name is requesting a ride nearby.'
              : 'Looking for nearby drivers...',
        };
      case 'accepted':
        return {
          'icon': Icons.check_circle_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFF0FDF4),
          'title': isProvider ? '✅ Ride Accepted' : '✅ Driver Assigned!',
          'subtitle': isProvider
              ? 'You accepted $name\'s ride request.'
              : '$name accepted your request & is heading your way.',
        };
      case 'arrived':
        return {
          'icon': Icons.location_on_rounded,
          'iconColor': const Color(0xFF7C3AED),
          'bgColor': const Color(0xFFF5F3FF),
          'title': isProvider ? '📍 Arrived at Pickup' : '📍 Driver Arrived!',
          'subtitle': isProvider
              ? 'Waiting for $name at pickup point.'
              : '$name is at your pickup location.',
        };
      case 'in_progress':
        return {
          'icon': Icons.navigation_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFEFF6FF),
          'title': '🚀 Trip In Progress',
          'subtitle': isProvider
              ? 'Driving $name to destination.'
              : 'On your way with $name.',
        };
      case 'completed':
        return {
          'icon': Icons.celebration_rounded,
          'iconColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFF0FDF4),
          'title': '🎉 Trip Completed',
          'subtitle': isProvider
              ? 'Ride with $name completed. Payment received!'
              : 'You have reached your destination. Thank you!',
        };
      case 'cancelled':
        return {
          'icon': Icons.cancel_rounded,
          'iconColor': const Color(0xFFDC2626),
          'bgColor': const Color(0xFFFEF2F2),
          'title': '❌ Ride Cancelled',
          'subtitle': isProvider
              ? 'Ride with $name was cancelled.'
              : 'Your ride was cancelled.',
        };
      default:
        return null;
    }
  }

  // ─── NOTIFICATION INITIALIZATION ──────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _initialized = true;
    } catch (_) {}
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
  }

  // ─── LOCAL PUSH NOTIFICATIONS ─────────────────────────────────────────────

  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general_notifications',
    String channelName = 'General Notifications',
    String channelDescription = 'General app notifications',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    playNotificationSound();

    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (_) {}
  }

  // ─── REALTIME NOTIFICATION DISPATCH METHODS ───────────────────────────────

  /// Dispatch a new booking notification with sound
  Future<void> showNewBookingNotification({
    required String bookingId,
    String? customerName,
    String? serviceName,
    String? amount,
  }) async {
    final title = '🔔 New Booking Request';
    final body =
        '${customerName ?? "A customer"} booked ${serviceName ?? "your service"}.';

    startContinuousBookingAlert(
      title: title,
      body: body,
      bookingId: bookingId,
      customerName: customerName,
      serviceName: serviceName,
      amount: amount,
    );

    await showLocalNotification(
      id: bookingId.hashCode,
      title: title,
      body: body,
      payload: 'booking:$bookingId',
      channelId: 'booking_alerts',
      channelName: 'Booking Alerts',
      channelDescription: 'Incoming booking notifications',
    );
  }

  /// Toast when a new booking arrives
  void showNewBookingToast({
    String? customerName,
    String? serviceName,
    String? amount,
  }) {
    showInAppToast(
      title: '🔔 New Booking Request',
      subtitle:
          '${customerName ?? "Customer"} booked ${serviceName ?? "service"}${amount != null ? " for $amount" : ""}.',
      icon: Icons.event_available_rounded,
      iconColor: const Color(0xFF16A34A),
      bgColor: const Color(0xFFF0FDF4),
    );
  }

  /// Dispatch order status update notification with sound
  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    String? providerName,
  }) async {
    playNotificationSound();

    final statusText = _formatOrderStatus(status);
    final title = 'Order Update: $statusText';
    final body = providerName != null
        ? '$providerName has updated your order to $statusText.'
        : 'Your order #$orderId is now $statusText.';

    await showLocalNotification(
      id: orderId.hashCode,
      title: title,
      body: body,
      payload: 'order:$orderId',
      channelId: 'order_updates',
      channelName: 'Order Updates',
      channelDescription: 'Order status notifications',
    );
  }

  Future<void> showBookingStatusNotification({
    String? orderId,
    String? bookingId,
    required String status,
    String? providerName,
  }) async {
    final targetId = orderId ?? bookingId ?? '';
    await showOrderStatusNotification(
      orderId: targetId,
      status: status,
      providerName: providerName,
    );
  }

  void showQuotationStatusToast({
    required String status,
    String? quotationId,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) {
    playNotificationSound();
    final title = isProvider
        ? (status == 'accepted'
            ? '✅ Quotation Accepted'
            : status == 'rejected'
                ? '❌ Quotation Declined'
                : '💬 Quotation Negotiating')
        : (status == 'sent'
            ? '📋 New Quotation Received'
            : status == 'accepted'
                ? '✅ Quotation Confirmed'
                : 'Quotation Update');
    final subtitle = isProvider
        ? '${customerName ?? "Customer"} $status your quotation.'
        : '${providerName ?? "Provider"} sent a quotation update.';

    showInAppToast(
      title: title,
      subtitle: subtitle,
      icon: Icons.request_quote_rounded,
      iconColor: const Color(0xFF7C3AED),
      bgColor: const Color(0xFFF5F3FF),
    );
  }

  Future<void> showQuotationStatusNotification({
    required String quotationId,
    required String status,
    String? providerName,
    String? customerName,
    bool isProvider = false,
  }) async {
    playNotificationSound();
    final title = isProvider
        ? (status == 'accepted'
            ? '✅ Quotation Accepted'
            : status == 'rejected'
                ? '❌ Quotation Declined'
                : '💬 Quotation Negotiating')
        : (status == 'sent' ? '📋 New Quotation Received' : 'Quotation Update');
    final body = isProvider
        ? '${customerName ?? "Customer"} $status your quotation #$quotationId.'
        : '${providerName ?? "Provider"} sent you a quotation update.';

    await showLocalNotification(
      id: quotationId.hashCode,
      title: title,
      body: body,
      payload: 'quotation:$quotationId',
      channelId: 'quotation_updates',
      channelName: 'Quotation Updates',
      channelDescription: 'Quotation status notifications',
    );
  }

  void showBookingStatusToast({
    required String status,
    String? orderId,
    String? bookingId,
    String? serviceName,
    String? providerName,
  }) {
    playNotificationSound();
    final statusText = _formatOrderStatus(status);
    final idText = orderId ?? bookingId ?? '';
    final nameText = serviceName ?? providerName ?? 'service';
    showInAppToast(
      title: 'Booking $statusText',
      subtitle: 'Booking #$idText for $nameText is now $statusText.',
      icon: status == 'completed'
          ? Icons.check_circle_rounded
          : status == 'cancelled'
              ? Icons.cancel_rounded
              : Icons.event_note_rounded,
      iconColor: status == 'completed'
          ? const Color(0xFF16A34A)
          : status == 'cancelled'
              ? const Color(0xFFDC2626)
              : const Color(0xFF2563EB),
      bgColor: const Color(0xFFF8FAFC),
    );
  }

  String _formatOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
      case 'accepted':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
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

      // Lookup provider user_id if providerId is service_provider uuid
      String targetProviderUserId = providerId;
      try {
        final provRow = await SupabaseService.instance.client
            .from('service_providers')
            .select('user_id')
            .or('id.eq.$providerId,user_id.eq.$providerId')
            .maybeSingle();
        if (provRow != null && provRow['user_id'] != null) {
          targetProviderUserId = provRow['user_id'] as String;
        }
      } catch (_) {}

      // 1. Notify Provider (Continuous alert trigger)
      if (targetProviderUserId.isNotEmpty) {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': targetProviderUserId,
          'title': '📩 New Customer Enquiry (#$enquiryId)',
          'body':
              '$customerName ($customerPhone) sent an enquiry for $subcategory: "$message"',
          'type': 'enquiry',
          'metadata': {
            'enquiry_id': enquiryId,
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'subcategory': subcategory,
            'message': message,
            'is_continuous_alert': true,
          },
          'is_read': false,
          'created_at': now,
        });
      }

      // 2. Notify Customer (Single chime)
      if (customerId.isNotEmpty) {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': customerId,
          'title': 'Enquiry Submitted (#$enquiryId)',
          'body': 'Your enquiry for $subcategory has reached $providerName.',
          'type': 'enquiry',
          'metadata': {'enquiry_id': enquiryId},
          'is_read': false,
          'created_at': now,
        });
      }

      // 3. Notify Admin (Single chime)
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': null,
        'target_audience': 'admin',
        'title': '📋 New Platform Enquiry (#$enquiryId)',
        'body': '$customerName ➔ $providerName ($subcategory)',
        'type': 'admin_broadcast',
        'metadata': {'enquiry_id': enquiryId, 'audience': 'admin'},
        'is_read': false,
        'created_at': now,
      });
    } catch (e) {
      debugPrint('[NotificationService] notifyEnquirySubmitted error: $e');
    }
  }

  // ─── GLOBAL REALTIME BROADCAST & NOTIFICATION LISTENER ────────────────────

  RealtimeChannel? _broadcastChannel;

  /// Starts listening to real-time notification insertions, chat messages, and admin broadcasts
  void startListeningToBroadcastNotifications() {
    if (_broadcastChannel != null) return;
    try {
      _broadcastChannel = SupabaseService.instance.client
          .channel('public:global_notifications_and_broadcasts')
          .onBroadcast(
            event: 'admin_push_notification',
            callback: (payload) {
              final title = payload['title'] as String? ?? 'Notification';
              final body = payload['body'] as String? ?? '';
              final targetType =
                  payload['target_type'] as String? ?? 'all_users';
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
                  iconColor: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                );
                NotificationHubService.instance.initialize();
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
              final type = newRecord['type'] as String? ?? 'general';
              final title = newRecord['title'] as String? ?? 'Notification';
              final body = newRecord['body'] as String? ?? '';
              final metadata = newRecord['metadata'] as Map<String, dynamic>? ?? {};
              final targetAudience = newRecord['target_audience'] as String?;

              bool applies = false;
              if (uid == null || (currentUserId != null && uid == currentUserId)) {
                applies = true;
              }

              if (!applies) return;

              // Check if partner/provider continuous alarm applies
              final isContinuous = metadata['is_continuous_alert'] == true;

              if (isContinuous && currentUserId != null && uid == currentUserId) {
                // Partner gets continuous ringing alarm!
                final isEnquiry = type == 'enquiry';
                final bookingId = metadata['order_id']?.toString() ?? metadata['booking_id']?.toString();
                final enquiryId = metadata['enquiry_id']?.toString();

                startContinuousBookingAlert(
                  title: title,
                  body: body,
                  bookingId: bookingId,
                  enquiryId: enquiryId,
                  customerName: metadata['customer_name'] as String?,
                  serviceName: metadata['service'] as String? ?? metadata['subcategory'] as String?,
                  amount: metadata['amount']?.toString(),
                  isEnquiry: isEnquiry,
                );
              } else {
                // Customer or Admin or normal notification gets single chime sound!
                playNotificationSound();
                showInAppToast(
                  title: title,
                  subtitle: body,
                  icon: _getToastIcon(type),
                  iconColor: _getToastColor(type),
                  bgColor: const Color(0xFFF8FAFC),
                );
              }

              NotificationHubService.instance.initialize();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[NotificationService] Broadcast listener error: $e');
    }
  }

  IconData _getToastIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'enquiry':
        return Icons.mark_email_unread_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'quotation':
        return Icons.request_quote_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'admin_broadcast':
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getToastColor(String type) {
    switch (type) {
      case 'booking':
        return const Color(0xFF16A34A);
      case 'enquiry':
        return const Color(0xFF2563EB);
      case 'message':
        return const Color(0xFF0284C7);
      case 'quotation':
        return const Color(0xFF7C3AED);
      case 'review':
        return const Color(0xFFF59E0B);
      case 'admin_broadcast':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF1E3A8A);
    }
  }

  /// Admin broadcast push notification
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

      final broadcastRow = <String, dynamic>{
        'title': title,
        'body': body,
        'type': 'admin_broadcast',
        'target_audience': targetType,
        'metadata': {
          'is_broadcast': true,
          'subtype': 'admin_broadcast',
          'audience': targetType,
        },
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

      try {
        final broadcastChannel = SupabaseService.instance.client.channel('public:global_notifications_and_broadcasts');
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
      } catch (_) {}

      showInAppToast(
        title: '📢 Push Notification Dispatched',
        subtitle: 'Sent "$title" broadcast.',
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

// ─── CONTINUOUS BOOKING & ENQUIRY ALERT BANNER (STICKY OVERLAY) ───────────────

class _ContinuousBookingAlertBanner extends StatefulWidget {
  final String title;
  final String body;
  final String? customerName;
  final String? serviceName;
  final String? amount;
  final bool isEnquiry;
  final String? bookingId;
  final String? enquiryId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReply;
  final VoidCallback onDismiss;

  const _ContinuousBookingAlertBanner({
    required this.title,
    required this.body,
    this.customerName,
    this.serviceName,
    this.amount,
    this.isEnquiry = false,
    this.bookingId,
    this.enquiryId,
    required this.onAccept,
    required this.onReject,
    required this.onReply,
    required this.onDismiss,
  });

  @override
  State<_ContinuousBookingAlertBanner> createState() =>
      _ContinuousBookingAlertBannerState();
}

class _ContinuousBookingAlertBannerState
    extends State<_ContinuousBookingAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withAlpha(100),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with pulsing alarm bell
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Text(
                            '🔊 Ringing continuously until action is taken',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFDE68A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: widget.onDismiss,
                      tooltip: 'Stop Alarm',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Message body details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    if (!widget.isEnquiry) ...[
                      // Accept Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Reject Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF87171),
                            side: const BorderSide(color: Color(0xFFF87171)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_rounded, size: 16),
                          label: const Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Reply Button for Enquiry
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onReply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: const Text(
                            'Reply / Chat',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Stop Alarm Button
                    IconButton(
                      onPressed: widget.onDismiss,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.volume_off_rounded, color: Colors.white),
                      tooltip: 'Stop Ringing',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── IN-APP TOAST WIDGET ──────────────────────────────────────────────────────

class _RideStatusToastWidget extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _RideStatusToastWidget({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    this.onTap,
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
              onTap: () {
                widget.onTap?.call();
                widget.onDismiss();
              },
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
                      width: 42,
                      height: 42,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF44474E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF74777F),
                      ),
                      onPressed: widget.onDismiss,
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
