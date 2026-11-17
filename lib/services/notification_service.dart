import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/role_guard.dart';
import 'supabase_service.dart';
import 'admin_auth_service.dart';
import 'notification_hub_service.dart';
import '../routes/app_routes.dart';

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
  /// Web: Synthesized  /// Unlocks Web Audio Context on user interaction to comply with autoplay policy
  void unlockWebAudioContext() {
    if (!kIsWeb) return;
    try {
      final script = html.ScriptElement()
        ..text = '''
          (function() {
            var unlock = function() {
              try {
                var AudioContext = window.AudioContext || window.webkitAudioContext;
                if (!window._lcAudioCtx && AudioContext) {
                  window._lcAudioCtx = new AudioContext();
                }
                if (window._lcAudioCtx && window._lcAudioCtx.state === 'suspended') {
                  window._lcAudioCtx.resume();
                }
              } catch(e) {}
            };
            document.addEventListener('click', unlock, { once: false, passive: true });
            document.addEventListener('touchstart', unlock, { once: false, passive: true });
            document.addEventListener('keydown', unlock, { once: false, passive: true });
          })();
        ''';
      html.document.body?.append(script);
      script.remove();
    } catch (_) {}
  }

  /// Plays a clear bell chime notification sound
  /// Web: Synthesized multi-harmonic bell chime (880 Hz, 1108.7 Hz, 1318.5 Hz, 1760 Hz)
  /// Mobile: System alert sound with medium haptic pulse
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
                  var ctx = window._lcAudioCtx || new AudioContext();
                  if (ctx.state === 'suspended') ctx.resume();
                  
                  // Authentic Bell Chime - 4 harmonic frequencies (A5=880, C#6=1108.7, E6=1318.5, A6=1760)
                  var now = ctx.currentTime;
                  var freqs = [880, 1108.73, 1318.51, 1760];
                  var gains = [0.45, 0.28, 0.35, 0.20];
                  var decays = [0.55, 0.45, 0.60, 0.40];

                  freqs.forEach(function(f, idx) {
                    var osc = ctx.createOscillator();
                    var gain = ctx.createGain();
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(f, now);
                    gain.gain.setValueAtTime(gains[idx], now);
                    gain.gain.exponentialRampToValueAtTime(0.0001, now + decays[idx]);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(now);
                    osc.stop(now + decays[idx]);
                  });
                } catch(e) {}
              })();
            ''';
          html.document.body?.append(script);
          script.remove();
        } catch (_) {}
      } else {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Explicit alias for playing the bell chime sound
  void playBellChimeSound() => playNotificationSound();

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
                  var ctx = window._lcAudioCtx || new AudioContext();
                  if (ctx.state === 'suspended') ctx.resume();

                  // Note 1: 587.33 Hz (D5)
                  var o1 = ctx.createOscillator();
                  var g1 = ctx.createGain();
                  o1.type = 'triangle';
                  o1.frequency.setValueAtTime(587.33, ctx.currentTime);
                  g1.gain.setValueAtTime(0.60, ctx.currentTime);
                  g1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.22);
                  o1.connect(g1);
                  g1.connect(ctx.destination);
                  o1.start(ctx.currentTime);
                  o1.stop(ctx.currentTime + 0.22);

                  // Note 2: 880 Hz (A5)
                  var o2 = ctx.createOscillator();
                  var g2 = ctx.createGain();
                  o2.type = 'triangle';
                  o2.frequency.setValueAtTime(880, ctx.currentTime + 0.14);
                  g2.gain.setValueAtTime(0.65, ctx.currentTime + 0.14);
                  g2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.40);
                  o2.connect(g2);
                  g2.connect(ctx.destination);
                  o2.start(ctx.currentTime + 0.14);
                  o2.stop(ctx.currentTime + 0.40);

                  // Note 3: 1174.66 Hz (D6)
                  var o3 = ctx.createOscillator();
                  var g3 = ctx.createGain();
                  o3.type = 'sine';
                  o3.frequency.setValueAtTime(1174.66, ctx.currentTime + 0.28);
                  g3.gain.setValueAtTime(0.70, ctx.currentTime + 0.28);
                  g3.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.65);
                  o3.connect(g3);
                  g3.connect(ctx.destination);
                  o3.start(ctx.currentTime + 0.28);
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

    unlockWebAudioContext();

    if (kIsWeb) {
      try {
        if (html.Notification.supported && html.Notification.permission == 'default') {
          html.Notification.requestPermission();
        }
      } catch (_) {}
      _initialized = true;
      return;
    }

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

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request runtime permission on Android 13+ (API 33+)
        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}

        // Pre-create all notification channels with high priority, sound, and vibration
        final channels = [
          const AndroidNotificationChannel(
            'booking_notifications',
            'Service Bookings & Updates',
            description: 'Notifications when bookings are placed, confirmed, updated, or completed',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
          const AndroidNotificationChannel(
            'booking_alerts',
            'Incoming Booking Alerts',
            description: 'Loud ringing and alerts for providers when a customer books a service',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
          const AndroidNotificationChannel(
            'inquiry_notifications',
            'Customer Enquiries & Ringing Alerts',
            description: 'Continuous ring and notifications for customer enquiries and service requests',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
          const AndroidNotificationChannel(
            'order_updates',
            'Order & Status Updates',
            description: 'Status updates and progress alerts for bookings and orders',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
          const AndroidNotificationChannel(
            'admin_notifications',
            'Admin & Area Manager Alerts',
            description: 'Real-time booking and service request alerts for Admin and Area Managers',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
          const AndroidNotificationChannel(
            'general_notifications',
            'General App Notifications',
            description: 'Standard notifications and announcements',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        ];

        for (final chan in channels) {
          try {
            await androidPlugin.createNotificationChannel(chan);
          } catch (_) {}
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Local notifications init note: $e');
      _initialized = true;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  void _handleNotificationPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return;
    try {
      final navState = navigatorKey.currentState;
      if (navState == null) return;

      String? enquiryId;
      String? orderId;
      String? bookingId;
      String? route;

      if (rawPayload.startsWith('{') && rawPayload.endsWith('}')) {
        try {
          final Map<String, dynamic> data = jsonDecode(rawPayload);
          enquiryId = data['enquiry_id']?.toString();
          orderId = data['order_id']?.toString();
          bookingId = data['booking_id']?.toString() ?? orderId;
          route = data['route']?.toString();
        } catch (_) {}
      } else if (rawPayload.startsWith('ENQ-') || rawPayload.startsWith('enquiry:')) {
        enquiryId = rawPayload.replaceAll('enquiry:', '').trim();
      } else if (rawPayload.startsWith('ORD-') || rawPayload.startsWith('order:')) {
        orderId = rawPayload.replaceAll('order:', '').trim();
      }

      if (route != null && route.isNotEmpty) {
        navState.pushNamed(route);
        return;
      }

      if (bookingId != null || orderId != null) {
        final id = bookingId ?? orderId!;
        navState.pushNamed(
          AppRoutes.bookingStatusScreen,
          arguments: {'orderId': id},
        );
        return;
      }

      if (enquiryId != null) {
        navState.pushNamed(AppRoutes.customerQuotationBookingsScreen);
        return;
      }
    } catch (e) {
      debugPrint('[NotificationService] _handleNotificationPayload error: $e');
    }
  }

  // ─── LOCAL PUSH & WEB BROWSER NOTIFICATIONS ───────────────────────────────

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
    // 1. Play audible bell beep sound
    playNotificationSound();

    if (!_initialized) await initialize();

    // 2. Web browser desktop notification
    if (kIsWeb) {
      try {
        if (html.Notification.supported) {
          void dispatchWebNotif() {
            try {
              final notif = html.Notification(
                title,
                body: body,
                icon: 'favicon.png',
                tag: '${channelId}_$id',
              );
              notif.onClick.listen((_) {
                _handleNotificationPayload(payload);
              });
            } catch (err) {
              debugPrint('[NotificationService] Web notification trigger error: $err');
            }
          }

          if (html.Notification.permission == 'granted') {
            dispatchWebNotif();
          } else if (html.Notification.permission == 'default') {
            html.Notification.requestPermission().then((perm) {
              if (perm == 'granted') {
                dispatchWebNotif();
              }
            });
          }
        }
      } catch (e) {
        debugPrint('[NotificationService] Web notification note: $e');
      }
      return;
    }

    // 3. Android notification drawer & shade
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
      ticker: title,
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
    } catch (e) {
      debugPrint('[NotificationService] showLocalNotification note: $e');
    }
  }

  /// Checks if an admin notification for a specific area applies to the current user (Super Admin or matching Area Manager)
  bool doesAdminNotificationApply({String? area}) {
    if (SupabaseService.instance.isSuperAdmin) return true;

    if (SupabaseService.instance.isAreaManager) {
      final assignedArea = SupabaseService.instance.currentAdminArea.trim();
      if (assignedArea.isEmpty || assignedArea.toUpperCase() == 'ALL') return true;
      if (area == null || area.trim().isEmpty) return true;
      final target = area.trim().toLowerCase();
      final mine = assignedArea.toLowerCase();
      return target == mine || target.contains(mine) || mine.contains(target);
    }

    return false;
  }

  /// Dispatches complete booking creation notifications to Customer, Provider, Super Admin, and Area Managers
  Future<void> notifyBookingCreated({
    required String orderId,
    required String orderNumber,
    required String customerId,
    required String customerName,
    String? customerPhone,
    required String service,
    required String category,
    required String amount,
    String? providerId,
    String? providerUserId,
    String? providerName,
    String? area,
    String? scheduledDate,
    String? scheduledTime,
  }) async {
    final now = DateTime.now().toIso8601String();
    final cleanArea = (area != null && area.trim().isNotEmpty) ? area.trim() : 'Local Area';
    final cleanProvName = (providerName != null && providerName.trim().isNotEmpty) ? providerName.trim() : 'LocalConnect Partner';

    // 1. Play audible bell chime sound on this device
    playNotificationSound();

    // 2. Notify Customer (Drawer notification + Toast + DB record)
    final custTitle = '🔔 Booking Confirmed (#$orderNumber)';
    final custBody = 'Your booking for $service has been placed. Provider has been alerted!';

    showInAppToast(
      title: custTitle,
      subtitle: custBody,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF16A34A),
      bgColor: const Color(0xFFF0FDF4),
    );

    // Show App Drawer / Web Notification on customer device
    showLocalNotification(
      id: orderNumber.hashCode,
      title: custTitle,
      body: custBody,
      payload: jsonEncode({'order_id': orderId, 'order_number': orderNumber, 'route': AppRoutes.customerBookingsScreen}),
      channelId: 'booking_notifications',
      channelName: 'Service Bookings & Updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Insert customer DB notification
    try {
      await SupabaseService.instance.client.from('notifications').insert({
        'user_id': customerId,
        'title': custTitle,
        'body': custBody,
        'type': 'booking',
        'metadata': {
          'order_id': orderId,
          'order_number': orderNumber,
          'service': service,
          'category': category,
          'amount': amount,
          'provider_name': cleanProvName,
          'area': cleanArea,
        },
        'is_read': false,
        'created_at': now,
      });
    } catch (_) {}

    // 3. Notify Relevant Provider / Partner
    String? targetProvUserId = providerUserId;
    if ((targetProvUserId == null || targetProvUserId.isEmpty) && providerId != null && providerId.isNotEmpty) {
      try {
        final provRow = await SupabaseService.instance.client
            .from('service_providers')
            .select('user_id, business_name')
            .or('id.eq.$providerId,user_id.eq.$providerId')
            .maybeSingle();
        targetProvUserId = provRow?['user_id'] as String? ?? providerId;
      } catch (_) {
        targetProvUserId = providerId;
      }
    }

    final provTitle = '🔔 New Booking Request (#$orderNumber)';
    final provBody = '$customerName booked $service in $cleanArea (₹$amount). Tap to respond!';

    final Set<String> targetProviderIds = {};
    if (targetProvUserId != null && targetProvUserId.isNotEmpty) {
      targetProviderIds.add(targetProvUserId);
    }
    if (providerId != null && providerId.isNotEmpty && providerId != targetProvUserId) {
      targetProviderIds.add(providerId);
    }

    // If no specific provider assigned, query matching active providers in area/category
    if (targetProviderIds.isEmpty) {
      try {
        var query = SupabaseService.instance.client
            .from('service_providers')
            .select('id, user_id')
            .eq('is_active', true);
        if (cleanArea != 'Local Area' && cleanArea != 'ALL') {
          query = query.ilike('city', '%$cleanArea%');
        }
        if (category.isNotEmpty) {
          query = query.or('category.ilike.%$category%,subcategory.ilike.%$service%');
        }
        final list = await query.limit(15);
        for (final row in list) {
          final pid = row['id']?.toString();
          final puid = row['user_id']?.toString();
          if (puid != null && puid.isNotEmpty) targetProviderIds.add(puid);
          if (pid != null && pid.isNotEmpty) targetProviderIds.add(pid);
        }
      } catch (_) {}
    }

    // Insert DB notification for all target providers
    for (final tid in targetProviderIds) {
      try {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': tid,
          'title': provTitle,
          'body': provBody,
          'type': 'booking',
          'metadata': {
            'order_id': orderId,
            'booking_id': orderId,
            'order_number': orderNumber,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'service': service,
            'category': category,
            'amount': amount,
            'area': cleanArea,
            'scheduled_date': scheduledDate,
            'scheduled_time': scheduledTime,
            'is_continuous_alert': true,
          },
          'is_read': false,
          'created_at': now,
        });
      } catch (_) {}
    }

    // Broadcast instant continuous ringing alert to provider device
    try {
      await sendProviderContinuousAlert(
        targetUserId: targetProvUserId ?? (targetProviderIds.isNotEmpty ? targetProviderIds.first : ''),
        targetProviderId: providerId,
        title: provTitle,
        body: provBody,
        bookingId: orderId,
        customerName: customerName,
        customerPhone: customerPhone,
        serviceName: service,
        amount: amount,
      );
    } catch (_) {}

    // 4. Notify Super Admin & Relevant Area Managers
    final adminTitle = '📋 New Booking in $cleanArea (#$orderNumber)';
    final adminBody = '$customerName ($cleanArea) booked $service with $cleanProvName (₹$amount).';

    try {
      await SupabaseService.instance.client.from('notifications').insert({
        'target_audience': 'admin',
        'title': adminTitle,
        'body': adminBody,
        'type': 'admin_broadcast',
        'metadata': {
          'order_id': orderId,
          'order_number': orderNumber,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'service': service,
          'category': category,
          'amount': amount,
          'provider_name': cleanProvName,
          'area': cleanArea,
          'audience': 'admin',
        },
        'is_read': false,
        'created_at': now,
      });

      // Target area managers specifically
      try {
        final allAdmins = await AdminAuthService.instance.getAllAdmins();
        for (final adm in allAdmins) {
          final role = (adm['role'] ?? '').toString();
          final assignedArea = (adm['assigned_area'] ?? '').toString();
          final admId = adm['id']?.toString() ?? '';
          final admEmail = adm['email']?.toString() ?? '';

          bool isRelevant = false;
          if (role == 'super_admin') {
            isRelevant = true;
          } else if (role == 'area_manager' || role == 'area_admin') {
            if (assignedArea == 'ALL' ||
                assignedArea.toLowerCase() == cleanArea.toLowerCase() ||
                cleanArea.toLowerCase().contains(assignedArea.toLowerCase())) {
              isRelevant = true;
            }
          }

          if (isRelevant && admId.isNotEmpty) {
            try {
              await SupabaseService.instance.client.from('notifications').insert({
                'user_id': admId,
                'title': adminTitle,
                'body': adminBody,
                'type': 'admin_broadcast',
                'metadata': {
                  'order_id': orderId,
                  'order_number': orderNumber,
                  'area': cleanArea,
                  'admin_email': admEmail,
                  'target_audience': 'admin',
                },
                'is_read': false,
                'created_at': now,
              });
            } catch (_) {}
          }
        }
      } catch (_) {}

      // Broadcast to admin channel
      final adminChan = SupabaseService.instance.client
          .channel('public:global_notifications_and_broadcasts');
      await adminChan.sendBroadcastMessage(
        event: 'admin_booking_notification',
        payload: {
          'title': adminTitle,
          'body': adminBody,
          'order_id': orderId,
          'order_number': orderNumber,
          'area': cleanArea,
          'service': service,
          'customer_name': customerName,
          'provider_name': cleanProvName,
          'amount': amount,
          'target_type': 'admin',
          'timestamp': now,
        },
      );
    } catch (_) {}
  }

  /// Dispatches booking update notifications to Customer, Provider, Super Admin, and Area Managers
  Future<void> notifyBookingUpdated({
    required String orderId,
    required String orderNumber,
    required String status,
    required String updatedBy, // 'customer', 'provider', or 'admin'
    String? customerId,
    String? customerName,
    String? providerId,
    String? providerUserId,
    String? providerName,
    String? service,
    String? area,
    String? note,
    String? newProviderName,
    String? newProviderId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final statusLabel = _formatOrderStatus(status);
    final sName = service ?? 'Service';
    final pName = providerName ?? 'Provider';
    final cName = customerName ?? 'Customer';
    final cleanArea = (area != null && area.trim().isNotEmpty) ? area.trim() : 'Local Area';

    // 1. Play audible bell sound on current device
    playNotificationSound();

    // 2. Notify Customer
    if (customerId != null && customerId.isNotEmpty) {
      String custTitle;
      String custBody;
      if (updatedBy == 'admin' && newProviderName != null) {
        custTitle = '🔄 Booking Reassigned (#$orderNumber)';
        custBody = 'Your $sName booking has been reassigned to $newProviderName. ${note ?? ""}';
      } else if (status == 'active' || status == 'confirmed') {
        custTitle = '✅ Booking Confirmed (#$orderNumber)';
        custBody = '$pName accepted your booking for $sName.';
      } else if (status == 'in_progress') {
        custTitle = '🚀 Service In Progress (#$orderNumber)';
        custBody = '$pName has started working on your $sName request.';
      } else if (status == 'completed') {
        custTitle = '🎉 Service Completed (#$orderNumber)';
        custBody = 'Your $sName service with $pName is completed. Thank you!';
      } else if (status == 'cancelled') {
        custTitle = '❌ Booking Cancelled (#$orderNumber)';
        custBody = 'Booking #$orderNumber was cancelled by ${updatedBy.toUpperCase()}. ${note ?? ""}';
      } else {
        custTitle = '📋 Booking Status: $statusLabel (#$orderNumber)';
        custBody = 'Your $sName booking is now $statusLabel. ${note ?? ""}';
      }

      // If current device is the customer, display toast & local drawer notification
      final currentUserId = SupabaseService.instance.currentUser?.id;
      if (currentUserId == customerId) {
        showInAppToast(
          title: custTitle,
          subtitle: custBody,
          icon: status == 'completed'
              ? Icons.celebration_rounded
              : status == 'cancelled'
                  ? Icons.cancel_rounded
                  : Icons.notifications_active_rounded,
          iconColor: status == 'completed'
              ? const Color(0xFF16A34A)
              : status == 'cancelled'
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF2563EB),
        );
        showLocalNotification(
          id: orderNumber.hashCode ^ 1,
          title: custTitle,
          body: custBody,
          payload: jsonEncode({'order_id': orderId, 'order_number': orderNumber, 'route': AppRoutes.customerBookingsScreen}),
          channelId: 'order_updates',
          channelName: 'Order & Status Updates',
        );
      }

      // Insert customer DB notification
      try {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': customerId,
          'title': custTitle,
          'body': custBody,
          'type': 'booking_status',
          'metadata': {
            'order_id': orderId,
            'order_number': orderNumber,
            'status': status,
            'service': sName,
            'provider_name': pName,
            'updated_by': updatedBy,
            'note': note,
          },
          'is_read': false,
          'created_at': now,
        });
      } catch (_) {}
    }

    // 3. Notify Provider(s)
    final targetPid = providerUserId ?? providerId;
    if (targetPid != null && targetPid.isNotEmpty) {
      final provTitle = 'Booking Update: $statusLabel (#$orderNumber)';
      final provBody = 'Booking for $sName ($cName) updated to $statusLabel by ${updatedBy.toUpperCase()}.';

      final currentUserId = SupabaseService.instance.currentUser?.id;
      if (currentUserId == targetPid || _cachedProviderId == targetPid) {
        showInAppToast(
          title: provTitle,
          subtitle: provBody,
          icon: Icons.event_note_rounded,
          iconColor: const Color(0xFF1E3A8A),
        );
        showLocalNotification(
          id: orderNumber.hashCode ^ 2,
          title: provTitle,
          body: provBody,
          payload: jsonEncode({'order_id': orderId, 'order_number': orderNumber}),
          channelId: 'order_updates',
          channelName: 'Order & Status Updates',
        );
      }

      try {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': targetPid,
          'title': provTitle,
          'body': provBody,
          'type': 'booking_status',
          'metadata': {
            'order_id': orderId,
            'order_number': orderNumber,
            'status': status,
            'service': sName,
            'customer_name': cName,
            'updated_by': updatedBy,
            'note': note,
          },
          'is_read': false,
          'created_at': now,
        });
      } catch (_) {}
    }

    // 4. Notify Super Admin & Relevant Area Managers
    final adminTitle = '📊 Booking #$orderNumber: $statusLabel';
    final adminBody = 'Updated by ${updatedBy.toUpperCase()}: $sName ($cName ➔ $pName) is now $statusLabel. ${note ?? ""}';

    try {
      await SupabaseService.instance.client.from('notifications').insert({
        'target_audience': 'admin',
        'title': adminTitle,
        'body': adminBody.trim(),
        'type': 'admin_broadcast',
        'metadata': {
          'order_id': orderId,
          'order_number': orderNumber,
          'status': status,
          'service': sName,
          'customer_name': cName,
          'provider_name': pName,
          'updated_by': updatedBy,
          'area': cleanArea,
          'audience': 'admin',
        },
        'is_read': false,
        'created_at': now,
      });

      // Broadcast to global realtime channel
      final chan = SupabaseService.instance.client
          .channel('public:global_notifications_and_broadcasts');
      await chan.sendBroadcastMessage(
        event: 'booking_status_update',
        payload: {
          'order_id': orderId,
          'order_number': orderNumber,
          'status': status,
          'updated_by': updatedBy,
          'customer_id': customerId,
          'provider_id': providerId,
          'provider_user_id': providerUserId,
          'area': cleanArea,
          'title': adminTitle,
          'body': adminBody,
        },
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
  /// Notify when a customer submits an enquiry to a provider
  Future<void> notifyEnquirySubmitted({
    required String enquiryId,
    required String subcategory,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String providerId,
    String? providerUserId,
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

      // Lookup provider user_id
      String? targetProviderUserId = providerUserId;
      final isUuid = RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(providerId.trim());

      if ((targetProviderUserId == null || targetProviderUserId.isEmpty) && isUuid) {
        try {
          final provRow = await SupabaseService.instance.client
              .from('service_providers')
              .select('user_id')
              .or('id.eq.$providerId,user_id.eq.$providerId')
              .maybeSingle();
          if (provRow != null && provRow['user_id'] != null) {
            targetProviderUserId = provRow['user_id'] as String;
          } else {
            targetProviderUserId = providerId;
          }
        } catch (_) {
          targetProviderUserId = providerId;
        }
      }

      // If still not resolved by UUID, search by business_name or owner_name
      if ((targetProviderUserId == null || targetProviderUserId.isEmpty) && providerName.trim().isNotEmpty) {
        try {
          final provRow = await SupabaseService.instance.client
              .from('service_providers')
              .select('user_id')
              .ilike('business_name', '%${providerName.trim()}%')
              .limit(1)
              .maybeSingle();
          if (provRow != null && provRow['user_id'] != null) {
            targetProviderUserId = provRow['user_id'] as String;
          }
        } catch (_) {}
      }

      // 1. Notify Provider via Database Notification
      final Set<String> targetIds = {};
      if (targetProviderUserId != null && targetProviderUserId.isNotEmpty) {
        targetIds.add(targetProviderUserId);
      }
      if (isUuid && providerId.isNotEmpty && providerId != targetProviderUserId) {
        targetIds.add(providerId);
      }

      // If no specific provider specified or found, broadcast to all matching area providers
      if (targetIds.isEmpty) {
        try {
          var provQuery = SupabaseService.instance.client
              .from('service_providers')
              .select('id, user_id, business_name, city, category, subcategory')
              .eq('is_active', true);
          if (subcategory.isNotEmpty) {
            provQuery = provQuery.or('subcategory.ilike.%$subcategory%,category.ilike.%$subcategory%');
          }
          final rows = await provQuery.limit(20);
          for (final row in rows) {
            final pid = row['id']?.toString();
            final puid = row['user_id']?.toString();
            if (puid != null && puid.isNotEmpty) targetIds.add(puid);
            if (pid != null && pid.isNotEmpty) targetIds.add(pid);

            // Also trigger continuous alert for each matching provider
            try {
              await sendProviderContinuousAlert(
                targetUserId: puid ?? pid ?? '',
                targetProviderId: pid,
                title: '📩 New Customer Enquiry (#$enquiryId)',
                body: '$customerName sent a service request for $subcategory in your area.',
                enquiryId: enquiryId,
                customerName: customerName,
                customerPhone: customerPhone,
                serviceName: subcategory,
                subcategory: subcategory,
                message: message,
                isEnquiry: true,
              );
            } catch (_) {}
          }
        } catch (_) {}
      }

      for (final tid in targetIds) {
        try {
          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': tid,
            'title': '📩 New Customer Enquiry (#$enquiryId)',
            'body':
                '$customerName ($customerPhone) sent an enquiry for $subcategory: "$message"',
            'type': 'enquiry',
            'metadata': {
              'enquiry_id': enquiryId,
              'customer_id': customerId,
              'customer_name': customerName,
              'customer_phone': customerPhone,
              'provider_id': providerId,
              'provider_user_id': targetProviderUserId,
              'provider_name': providerName,
              'subcategory': subcategory,
              'service': subcategory,
              'message': message,
              'is_continuous_alert': true,
            },
            'is_read': false,
            'created_at': now,
          });
        } catch (provDbErr) {
          debugPrint('[NotificationService] Provider db notification note: $provDbErr');
        }
      }

      // Trigger instant continuous ringing broadcast to provider device
      try {
        await sendProviderContinuousAlert(
          targetUserId: targetProviderUserId ?? providerId,
          targetProviderId: providerId,
          title: '📩 New Customer Enquiry (#$enquiryId)',
          body: '$customerName sent an enquiry for $subcategory.',
          enquiryId: enquiryId,
          customerName: customerName,
          customerPhone: customerPhone,
          serviceName: subcategory,
          subcategory: subcategory,
          message: message,
          isEnquiry: true,
        );
      } catch (bcastErr) {
        debugPrint('[NotificationService] Provider broadcast note: $bcastErr');
      }

      // 2. Notify Customer (Single chime & in-app local notification)
      if (customerId.isNotEmpty) {
        try {
          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': customerId,
            'title': '✅ Service Request Submitted (#$enquiryId)',
            'body': 'Your request for $subcategory has been submitted. Provider $providerName has been notified and will contact you.',
            'type': 'enquiry',
            'metadata': {
              'enquiry_id': enquiryId,
              'provider_name': providerName,
              'service': subcategory,
            },
            'is_read': false,
            'created_at': now,
          });

          // Show local confirmation notification on user device
          showLocalNotification(
            id: enquiryId.hashCode,
            title: '✅ Request Sent: $subcategory',
            body: 'Provider $providerName has been notified.',
            channelId: 'booking_notifications',
            channelName: 'Service Bookings & Updates',
          );
        } catch (_) {}
      }

      // 3. Notify Admin (Realtime broadcast & DB record)
      try {
        await SupabaseService.instance.client.from('notifications').insert({
          'target_audience': 'admin',
          'title': '📋 New Service Request (#$enquiryId)',
          'body': 'Customer: $customerName ($customerPhone) ➔ Partner: $providerName ($subcategory)',
          'type': 'admin_broadcast',
          'metadata': {
            'enquiry_id': enquiryId,
            'audience': 'admin',
            'customer_name': customerName,
            'provider_name': providerName,
            'service': subcategory,
          },
          'is_read': false,
          'created_at': now,
        });

        // Broadcast to admin channel
        try {
          final adminChan = SupabaseService.instance.client.channel('public:global_notifications_and_broadcasts');
          await adminChan.sendBroadcastMessage(
            event: 'admin_push_notification',
            payload: {
              'title': '📋 New Service Request (#$enquiryId)',
              'body': '$customerName in your area requested $subcategory ($providerName)',
              'target_type': 'admin',
              'enquiry_id': enquiryId,
            },
          );
        } catch (_) {}
      } catch (_) {}
    } catch (e) {
      debugPrint('[NotificationService] notifyEnquirySubmitted error: $e');
    }
  }

  /// Notify all relevant parties (Customer, Partner, Admin) whenever any update is made
  Future<void> notifyServiceRequestUpdated({
    required String enquiryId,
    required String updatedBy, // 'partner' or 'admin'
    required String status,
    String? customerId,
    String? customerName,
    String? providerId,
    String? providerUserId,
    String? providerName,
    String? serviceTitle,
    String? replyText,
    String? newProviderName,
    String? adminNote,
  }) async {
    final now = DateTime.now().toIso8601String();
    final sTitle = serviceTitle ?? 'Service Request';

    try {
      if (updatedBy == 'partner') {
        // 1. Notify Customer about partner update
        if (customerId != null && customerId.isNotEmpty) {
          final bodyText = (replyText != null && replyText.trim().isNotEmpty)
              ? '$providerName replied: "$replyText"'
              : '$providerName updated request status to ${status.toUpperCase()}.';

          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': customerId,
            'title': '💬 Partner Update: $providerName',
            'body': bodyText,
            'type': 'enquiry',
            'metadata': {
              'enquiry_id': enquiryId,
              'status': status,
              'provider_name': providerName,
            },
            'is_read': false,
            'created_at': now,
          });

          showLocalNotification(
            id: enquiryId.hashCode ^ 1,
            title: '💬 Update from $providerName',
            body: bodyText,
            channelId: 'booking_notifications',
            channelName: 'Service Updates',
          );
        }

        // 2. Notify Admin about partner update
        await SupabaseService.instance.client.from('notifications').insert({
          'target_audience': 'admin',
          'title': '📊 Partner Update (#$enquiryId)',
          'body': '$providerName updated status to ${status.toUpperCase()} for $customerName ($sTitle).',
          'type': 'admin_broadcast',
          'metadata': {
            'enquiry_id': enquiryId,
            'status': status,
            'audience': 'admin',
          },
          'is_read': false,
          'created_at': now,
        });
      } else {
        // Updated by Admin
        // 1. Notify Customer about admin action
        if (customerId != null && customerId.isNotEmpty) {
          final bodyText = newProviderName != null
              ? 'Your request has been reassigned to $newProviderName. ${adminNote ?? ""}'
              : 'Admin updated request status to ${status.toUpperCase()}. ${adminNote ?? ""}';

          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': customerId,
            'title': '🚀 Admin Action on Request (#$enquiryId)',
            'body': bodyText.trim(),
            'type': 'enquiry',
            'metadata': {
              'enquiry_id': enquiryId,
              'status': status,
              'new_provider': newProviderName,
            },
            'is_read': false,
            'created_at': now,
          });

          showLocalNotification(
            id: enquiryId.hashCode ^ 2,
            title: '🚀 Service Request Updated',
            body: bodyText.trim(),
            channelId: 'booking_notifications',
            channelName: 'Service Updates',
          );
        }

        // 2. Notify Partner(s)
        final targetPid = providerUserId ?? providerId;
        if (targetPid != null && targetPid.isNotEmpty) {
          final pBody = (adminNote != null && adminNote.trim().isNotEmpty)
              ? 'Admin note: "$adminNote"'
              : 'Status changed to ${status.toUpperCase()} by Admin.';

          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': targetPid,
            'title': 'ℹ️ Admin Update on Request (#$enquiryId)',
            'body': pBody,
            'type': 'enquiry',
            'metadata': {
              'enquiry_id': enquiryId,
              'status': status,
            },
            'is_read': false,
            'created_at': now,
          });
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] notifyServiceRequestUpdated error: $e');
    }
  }

  /// Notify Admin and Complainant when a complaint is raised
  Future<void> notifyComplaintRaised({
    required String complaintNumber,
    required String customerName,
    required String providerName,
    required String issue,
    required String severity,
    required String raisedBy,
    String? customerId,
    String? providerId,
    String? providerUserId,
    String? enquiryId,
  }) async {
    final now = DateTime.now().toIso8601String();

    try {
      // 1. Notify Admin (Immediate high-priority alert)
      await SupabaseService.instance.client.from('notifications').insert({
        'target_audience': 'admin',
        'title': '⚠️ Complaint Raised ($complaintNumber)',
        'body': '[$raisedBy.toUpperCase()] $customerName vs $providerName: "$issue" (Severity: ${severity.toUpperCase()})',
        'type': 'admin_broadcast',
        'metadata': {
          'complaint_number': complaintNumber,
          'enquiry_id': enquiryId,
          'severity': severity,
          'audience': 'admin',
        },
        'is_read': false,
        'created_at': now,
      });

      // 2. Notify Complainant with confirmation
      final complainantId = raisedBy == 'customer' ? customerId : (providerUserId ?? providerId);
      if (complainantId != null && complainantId.isNotEmpty) {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': complainantId,
          'title': 'Complaint Registered ($complaintNumber)',
          'body': 'Your complaint regarding $providerName has been registered. Our admin team will investigate and take action.',
          'type': 'general',
          'metadata': {
            'complaint_number': complaintNumber,
            'enquiry_id': enquiryId,
          },
          'is_read': false,
          'created_at': now,
        });

        showLocalNotification(
          id: complaintNumber.hashCode,
          title: 'Complaint Registered ($complaintNumber)',
          body: 'Admin team is investigating your report.',
          channelId: 'booking_notifications',
          channelName: 'Service Complaints',
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] notifyComplaintRaised error: $e');
    }
  }

  /// Notify Customer and/or Partner when Admin resolves / replies to a complaint
  Future<void> notifyComplaintResolved({
    required String complaintNumber,
    required String adminReply,
    String? customerId,
    String? providerId,
    String? providerUserId,
    bool notifyCustomer = true,
    bool notifyProvider = true,
  }) async {
    final now = DateTime.now().toIso8601String();

    try {
      if (notifyCustomer && customerId != null && customerId.isNotEmpty) {
        await SupabaseService.instance.client.from('notifications').insert({
          'user_id': customerId,
          'title': '📢 Admin Resolution for Complaint ($complaintNumber)',
          'body': adminReply,
          'type': 'general',
          'metadata': {
            'complaint_number': complaintNumber,
            'is_resolution': true,
          },
          'is_read': false,
          'created_at': now,
        });

        showLocalNotification(
          id: complaintNumber.hashCode ^ 3,
          title: 'Admin Resolution ($complaintNumber)',
          body: adminReply,
          channelId: 'booking_notifications',
          channelName: 'Service Complaints',
        );
      }

      if (notifyProvider) {
        final pId = providerUserId ?? providerId;
        if (pId != null && pId.isNotEmpty) {
          await SupabaseService.instance.client.from('notifications').insert({
            'user_id': pId,
            'title': '📢 Admin Resolution for Complaint ($complaintNumber)',
            'body': adminReply,
            'type': 'general',
            'metadata': {
              'complaint_number': complaintNumber,
              'is_resolution': true,
            },
            'is_read': false,
            'created_at': now,
          });
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] notifyComplaintResolved error: $e');
    }
  }

  // ─── GLOBAL REALTIME BROADCAST & NOTIFICATION LISTENER ────────────────────

  RealtimeChannel? _broadcastChannel;
  String? _cachedProviderId;

  /// Cache current provider ID on this device so incoming alerts match instantly
  void setProviderId(String id) {
    _cachedProviderId = id;
  }

  /// Send continuous alert broadcast to a provider
  Future<void> sendProviderContinuousAlert({
    required String targetUserId,
    String? targetProviderId,
    required String title,
    required String body,
    String? bookingId,
    String? enquiryId,
    String? customerName,
    String? customerPhone,
    String? serviceName,
    String? subcategory,
    String? message,
    String? amount,
    bool isEnquiry = false,
  }) async {
    try {
      if (_broadcastChannel == null) {
        startListeningToBroadcastNotifications();
      }
      final channel = _broadcastChannel ??
          SupabaseService.instance.client
              .channel('public:global_notifications_and_broadcasts');

      await channel.sendBroadcastMessage(
        event: 'provider_continuous_alert',
        payload: {
          'target_user_id': targetUserId,
          'target_provider_id': targetProviderId,
          'title': title,
          'body': body,
          'booking_id': bookingId,
          'enquiry_id': enquiryId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'service': serviceName ?? subcategory,
          'subcategory': subcategory,
          'message': message,
          'amount': amount,
          'is_enquiry': isEnquiry,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] sendProviderContinuousAlert broadcast error: $e');
    }
  }

  /// Starts listening to real-time notification insertions, chat messages, and admin broadcasts
  void startListeningToBroadcastNotifications() {
    if (_broadcastChannel != null) return;
    try {
      _broadcastChannel = SupabaseService.instance.client
          .channel('public:global_notifications_and_broadcasts')
          .onBroadcast(
            event: 'provider_continuous_alert',
            callback: (payload) async {
              final targetUserId = payload['target_user_id'] as String?;
              final targetProviderId = payload['target_provider_id'] as String?;
              final currentUserId = SupabaseService.instance.currentUser?.id;

              // Ensure cached provider ID is available
              if (_cachedProviderId == null && currentUserId != null) {
                try {
                  final sp = await SupabaseService.instance.getMyProviderProfile();
                  if (sp != null && sp['id'] != null) {
                    _cachedProviderId = sp['id'] as String;
                  }
                } catch (_) {}
              }

              bool applies = false;
              if (currentUserId != null) {
                if (targetUserId != null && targetUserId == currentUserId) {
                  applies = true;
                } else if (targetProviderId != null &&
                    (targetProviderId == currentUserId || targetProviderId == _cachedProviderId)) {
                  applies = true;
                }
              }

              if (applies) {
                final isEnquiry = payload['is_enquiry'] == true;
                final title = payload['title'] as String? ?? (isEnquiry ? '📩 New Customer Enquiry' : '🔔 New Booking Request');
                final body = payload['body'] as String? ?? 'A customer submitted a request.';
                final enquiryId = payload['enquiry_id']?.toString();
                final bookingId = payload['booking_id']?.toString();
                final customerName = payload['customer_name'] as String?;
                final serviceName = payload['service'] as String? ?? payload['subcategory'] as String?;
                final amount = payload['amount']?.toString();

                // 1. Play continuous audio loop & show top sticky banner
                startContinuousBookingAlert(
                  title: title,
                  body: body,
                  bookingId: bookingId,
                  enquiryId: enquiryId,
                  customerName: customerName,
                  serviceName: serviceName,
                  amount: amount,
                  isEnquiry: isEnquiry,
                );

                // 2. High priority Android local notification in notification shade / Web notification
                showLocalNotification(
                  id: (bookingId ?? enquiryId ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode,
                  title: title,
                  body: body,
                  payload: jsonEncode({'order_id': bookingId, 'enquiry_id': enquiryId}),
                  channelId: 'inquiry_notifications',
                  channelName: 'Customer Enquiries & Ringing Alerts',
                  importance: Importance.max,
                  priority: Priority.high,
                );
              }
            },
          )
          .onBroadcast(
            event: 'booking_status_update',
            callback: (payload) {
              final currentUserId = SupabaseService.instance.currentUser?.id;
              final custId = payload['customer_id'] as String?;
              final provId = payload['provider_id'] as String?;
              final provUid = payload['provider_user_id'] as String?;
              final area = payload['area'] as String? ?? '';
              final title = payload['title'] as String? ?? '📋 Booking Status Update';
              final body = payload['body'] as String? ?? 'Your booking has been updated.';
              final orderId = payload['order_id']?.toString() ?? '';
              final orderNumber = payload['order_number']?.toString() ?? '';

              bool applies = false;
              if (currentUserId != null && custId == currentUserId) {
                applies = true;
              } else if (currentUserId != null &&
                  (provUid == currentUserId || provId == currentUserId || _cachedProviderId == provId)) {
                applies = true;
              } else if (doesAdminNotificationApply(area: area)) {
                applies = true;
              }

              if (applies) {
                playNotificationSound();
                showInAppToast(
                  title: title,
                  subtitle: body,
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF1E3A8A),
                );
                showLocalNotification(
                  id: (orderId.isNotEmpty ? orderId : orderNumber).hashCode ^ 3,
                  title: title,
                  body: body,
                  payload: jsonEncode({'order_id': orderId, 'order_number': orderNumber}),
                  channelId: 'order_updates',
                  channelName: 'Order & Status Updates',
                  importance: Importance.high,
                  priority: Priority.high,
                );
              }
            },
          )
          .onBroadcast(
            event: 'admin_booking_notification',
            callback: (payload) {
              final area = payload['area'] as String? ?? '';
              if (!doesAdminNotificationApply(area: area)) return;

              final title = payload['title'] as String? ?? '📋 New Booking';
              final body = payload['body'] as String? ?? '';
              final orderId = payload['order_id']?.toString() ?? '';
              final orderNumber = payload['order_number']?.toString() ?? '';

              playNotificationSound();
              showInAppToast(
                title: title,
                subtitle: body,
                icon: Icons.assignment_turned_in_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
              );
              showLocalNotification(
                id: (orderId.isNotEmpty ? orderId : orderNumber).hashCode ^ 4,
                title: title,
                body: body,
                payload: jsonEncode({'order_id': orderId, 'order_number': orderNumber, 'route': AppRoutes.adminOrderManagementScreen}),
                channelId: 'admin_notifications',
                channelName: 'Admin & Area Manager Alerts',
                importance: Importance.max,
                priority: Priority.high,
              );
            },
          )
          .onBroadcast(
            event: 'admin_push_notification',
            callback: (payload) {
              final title = payload['title'] as String? ?? 'Notification';
              final body = payload['body'] as String? ?? '';
              final targetType =
                  payload['target_type'] as String? ?? 'all_users';
              final targetUserId = payload['target_user_id'] as String?;
              final currentUserId = SupabaseService.instance.currentUser?.id;
              final area = payload['area'] as String? ?? '';

              bool applies = false;
              if (targetType == 'all_users' || targetType == 'all') {
                applies = true;
              } else if (targetType == 'admin') {
                applies = doesAdminNotificationApply(area: area);
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
                showLocalNotification(
                  id: title.hashCode,
                  title: title,
                  body: body,
                  payload: jsonEncode(payload),
                  channelId: 'general_notifications',
                  channelName: 'General App Notifications',
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
              final notifArea = metadata['area']?.toString() ?? metadata['city']?.toString() ?? '';

              bool applies = false;
              if (uid != null && currentUserId != null && uid == currentUserId) {
                applies = true;
              } else if (uid != null && _cachedProviderId != null && uid == _cachedProviderId) {
                applies = true;
              } else if (targetAudience == 'all') {
                applies = true;
              } else if (targetAudience == 'providers' && _cachedProviderId != null) {
                applies = true;
              } else if (targetAudience == 'admin' || targetAudience == 'area_manager') {
                applies = doesAdminNotificationApply(area: notifArea);
              }

              if (!applies) return;

              // Check if partner/provider continuous alarm applies
              final isContinuous = metadata['is_continuous_alert'] == true;

              if (isContinuous &&
                  ((currentUserId != null && uid == currentUserId) ||
                   (_cachedProviderId != null && uid == _cachedProviderId))) {
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

                // Show system notification with sound & vibration in notification shade / Web notification
                showLocalNotification(
                  id: (bookingId ?? enquiryId ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode,
                  title: title,
                  body: body,
                  payload: jsonEncode(metadata),
                  channelId: 'inquiry_notifications',
                  channelName: 'Customer Enquiries & Ringing Alerts',
                  importance: Importance.max,
                  priority: Priority.high,
                );
              } else {
                // Customer or Admin or normal notification gets single chime sound + in-app toast + app drawer notification!
                playNotificationSound();
                showInAppToast(
                  title: title,
                  subtitle: body,
                  icon: _getToastIcon(type),
                  iconColor: _getToastColor(type),
                  bgColor: const Color(0xFFF8FAFC),
                );

                final isAdm = targetAudience == 'admin' ||
                    SupabaseService.instance.isSuperAdmin ||
                    SupabaseService.instance.isAreaManager;

                final channelId = isAdm
                    ? 'admin_notifications'
                    : (type == 'booking' || type == 'booking_status')
                        ? 'booking_notifications'
                        : 'general_notifications';

                final channelName = isAdm
                    ? 'Admin & Area Manager Alerts'
                    : 'Service Bookings & Updates';

                showLocalNotification(
                  id: (metadata['order_id'] ?? metadata['booking_id'] ?? metadata['enquiry_id'] ?? newRecord['id'] ?? DateTime.now().millisecondsSinceEpoch).hashCode,
                  title: title,
                  body: body,
                  payload: jsonEncode(metadata),
                  channelId: channelId,
                  channelName: channelName,
                  importance: Importance.max,
                  priority: Priority.high,
                );
              }

              NotificationHubService.instance.initialize();
            },
          )
          .subscribe();
      _startPeriodicAlertPoll();
    } catch (e) {
      debugPrint('[NotificationService] Broadcast listener error: $e');
    }
  }

  Timer? _alertPollTimer;
  final Set<String> _handledAlertNotificationIds = {};

  void _startPeriodicAlertPoll() {
    _alertPollTimer?.cancel();
    _alertPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final user = SupabaseService.instance.currentUser;
      final isAdm = isAdminSessionActive || SupabaseService.instance.isSuperAdmin || SupabaseService.instance.isAreaManager;
      if (user == null && !isAdm) return;
      try {
        var query = SupabaseService.instance.client.from('notifications').select();

        if (isAdm) {
          if (user != null) {
            query = query.or('user_id.eq.${user.id},target_audience.eq.admin');
          } else {
            query = query.eq('target_audience', 'admin');
          }
        } else if (user != null && _cachedProviderId != null && _cachedProviderId != user.id) {
          query = query.or('user_id.eq.${user.id},user_id.eq.$_cachedProviderId');
        } else if (user != null) {
          query = query.eq('user_id', user.id);
        }

        final res = await query
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .limit(10);
        final list = List<Map<String, dynamic>>.from(res);
        for (final item in list) {
          final id = item['id']?.toString() ?? '';
          if (_handledAlertNotificationIds.contains(id)) continue;
          _handledAlertNotificationIds.add(id);

          final meta = item['metadata'] as Map<String, dynamic>? ?? {};
          final isContinuous = meta['is_continuous_alert'] == true;
          final title = item['title'] as String? ?? '🔔 LocalConnect Notification';
          final body = item['body'] as String? ?? '';
          final type = item['type'] as String? ?? 'general';

          if (isContinuous) {
            final isEnquiry = type == 'enquiry';
            final bookingId = meta['order_id']?.toString() ?? meta['booking_id']?.toString();
            final enquiryId = meta['enquiry_id']?.toString();

            startContinuousBookingAlert(
              title: title,
              body: body,
              bookingId: bookingId,
              enquiryId: enquiryId,
              customerName: meta['customer_name'] as String?,
              serviceName: meta['service'] as String? ?? meta['subcategory'] as String?,
              amount: meta['amount']?.toString(),
              isEnquiry: isEnquiry,
            );

            showLocalNotification(
              id: (bookingId ?? enquiryId ?? id).hashCode,
              title: title,
              body: body,
              payload: jsonEncode(meta),
              channelId: 'inquiry_notifications',
              channelName: 'Customer Enquiries & Ringing Alerts',
              importance: Importance.max,
              priority: Priority.high,
            );
          } else {
            // Trigger bell chime sound, toast, and drawer notification for customer/admin
            playNotificationSound();
            showInAppToast(
              title: title,
              subtitle: body,
              icon: _getToastIcon(type),
              iconColor: _getToastColor(type),
              bgColor: const Color(0xFFF8FAFC),
            );

            showLocalNotification(
              id: id.hashCode,
              title: title,
              body: body,
              payload: jsonEncode(meta),
              channelId: 'booking_notifications',
              channelName: 'Service Bookings & Updates',
              importance: Importance.high,
              priority: Priority.high,
            );
          }
        }
      } catch (_) {}
    });
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
