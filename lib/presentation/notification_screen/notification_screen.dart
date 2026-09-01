import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/notification_hub_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;
  late TabController _tabController;

  static const _tabs = [
    _TabDef('All', null, Icons.notifications_rounded),
    _TabDef('Announcements', 'admin_broadcast', Icons.campaign_rounded),
    _TabDef('Bookings', 'booking', Icons.event_available_rounded),
    _TabDef('Enquiries', 'enquiry', Icons.mark_email_unread_rounded),
    _TabDef('Quotations', 'quotation', Icons.request_quote_rounded),
    _TabDef('Messages', 'message', Icons.chat_bubble_rounded),
    _TabDef('Reviews', 'review', Icons.star_rounded),
  ];

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Stop continuous partner alarm when entering notifications hub
    NotificationService.instance.stopContinuousBookingAlert();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadNotifications();
    _subscribeToNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadNotifications(isSilent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _channel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool isSilent = false}) async {
    if (!isSilent && _notifications.isEmpty) {
      setState(() => _isLoading = true);
    }
    final data = await SupabaseService.instance.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  void _subscribeToNotifications() {
    _channel = SupabaseService.instance.subscribeToNotifications(
      onUpdate: () {
        if (mounted) _loadNotifications(isSilent: true);
      },
      onDelete: (payload) {
        final id = payload['id'] as String?;
        final title = payload['title'] as String?;
        final body = payload['body'] as String?;
        if (mounted) {
          setState(() {
            _notifications.removeWhere((n) {
              if (id != null && id.isNotEmpty && n['id'] == id) return true;
              if (title != null && title.isNotEmpty && n['title'] == title) {
                if (body == null || body.isEmpty || n['body'] == body) return true;
              }
              return false;
            });
          });
        }
      },
    );
  }

  Future<void> _markAllRead() async {
    await SupabaseService.instance.markAllNotificationsRead();
    NotificationHubService.instance.resetAll();
    if (mounted) {
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
    }
  }

  Future<void> _markRead(Map<String, dynamic> n, int index) async {
    final id = n['id'] as String? ?? '';
    final type = n['type'] as String?;
    await SupabaseService.instance.markNotificationRead(id);
    NotificationHubService.instance.decrementUnread(type: type);
    if (mounted) {
      setState(() => _notifications[index]['is_read'] = true);
    }
  }

  Future<void> _deleteNotification(String id, int index) async {
    final n = _notifications[index];
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? '';
    final type = n['type'] as String?;
    final wasUnread = n['is_read'] == false;
    setState(() => _notifications.removeAt(index));
    if (wasUnread) NotificationHubService.instance.decrementUnread(type: type);
    try {
      await SupabaseService.instance.deleteNotification(
        id: id.isNotEmpty ? id : null,
        title: title.isNotEmpty ? title : null,
        body: body.isNotEmpty ? body : null,
      );
    } catch (_) {}
  }

  bool _isBroadcast(Map<String, dynamic> n) {
    final t = n['type'] as String?;
    final meta = n['metadata'];
    final aud = n['target_audience'] as String?;
    return t == 'admin_broadcast' ||
        t == 'broadcast' ||
        t == 'announcement' ||
        (meta is Map && (meta['is_broadcast'] == true || meta['subtype'] == 'admin_broadcast')) ||
        (aud != null && aud.isNotEmpty && aud != 'specific');
  }

  List<Map<String, dynamic>> _filteredFor(String? typeFilter) {
    if (typeFilter == null) return _notifications;
    if (typeFilter == 'admin_broadcast') {
      return _notifications.where(_isBroadcast).toList();
    }
    return _notifications.where((n) => n['type'] == typeFilter).toList();
  }

  IconData _getIcon(String? type, [Map<String, dynamic>? item]) {
    if (item != null && _isBroadcast(item)) {
      return Icons.campaign_rounded;
    }
    switch (type) {
      case 'admin_broadcast':
      case 'broadcast':
      case 'announcement':
        return Icons.campaign_rounded;
      case 'enquiry':
        return Icons.mark_email_unread_rounded;
      case 'quotation':
        return Icons.request_quote_rounded;
      case 'booking':
      case 'booking_status':
        return Icons.event_available_rounded;
      case 'order':
        return Icons.receipt_long_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      case 'nearby':
        return Icons.location_on_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type, [Map<String, dynamic>? item]) {
    if (item != null && _isBroadcast(item)) {
      return const Color(0xFFE11D48); // Bold Crimson / Rose
    }
    switch (type) {
      case 'admin_broadcast':
      case 'broadcast':
      case 'announcement':
        return const Color(0xFFE11D48); // Bold Crimson / Rose for Admin Announcements
      case 'enquiry':
        return const Color(0xFF2563EB); // Vibrant Blue
      case 'quotation':
        return const Color(0xFF7C3AED);
      case 'booking':
      case 'booking_status':
        return AppTheme.success;
      case 'order':
        return const Color(0xFF0EA5E9);
      case 'offer':
        return AppTheme.secondary;
      case 'nearby':
        return AppTheme.primary;
      case 'payment':
        return const Color(0xFF059669);
      case 'review':
        return const Color(0xFFF59E0B);
      case 'message':
        return const Color(0xFF3B82F6);
      default:
        return AppTheme.primary;
    }
  }

  String _typeLabel(String? type, [Map<String, dynamic>? item]) {
    if (item != null && _isBroadcast(item)) {
      return 'ANNOUNCEMENT';
    }
    switch (type) {
      case 'admin_broadcast':
      case 'broadcast':
      case 'announcement':
        return 'ANNOUNCEMENT';
      case 'enquiry':
        return 'ENQUIRY';
      case 'quotation':
        return 'QUOTATION';
      case 'booking':
      case 'booking_status':
        return 'BOOKING';
      case 'order':
        return 'ORDER';
      case 'offer':
        return 'OFFER';
      case 'nearby':
        return 'NEARBY';
      case 'payment':
        return 'PAYMENT';
      case 'review':
        return 'REVIEW';
      case 'message':
        return 'MESSAGE';
      default:
        return 'GENERAL';
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final now = DateTime.now();
    for (final n in items) {
      final createdAt = n['created_at'] as String?;
      String groupKey = 'Earlier';
      if (createdAt != null) {
        try {
          final dt = DateTime.parse(createdAt).toLocal();
          final diff = now.difference(dt);
          if (diff.inDays == 0) {
            groupKey = 'Today';
          } else if (diff.inDays == 1) {
            groupKey = 'Yesterday';
          } else if (diff.inDays < 7) {
            groupKey = 'This Week';
          }
        } catch (_) {}
      }
      groups.putIfAbsent(groupKey, () => []).add(n);
    }
    return groups;
  }

  int _tabUnread(int tabIndex) {
    if (tabIndex == 0) {
      return _notifications.where((n) => n['is_read'] == false).length;
    }
    if (tabIndex < _tabs.length) {
      final tab = _tabs[tabIndex];
      final filtered = _filteredFor(tab.typeFilter);
      return filtered.where((n) => n['is_read'] == false).length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => n['is_read'] == false)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(unreadCount),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _buildTabContent(tab.typeFilter);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Hub',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  label: Text(
                    'Mark all read',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.primary,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final count = _tabUnread(i);
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 15),
                const SizedBox(width: 5),
                Text(tab.label),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(String? typeFilter) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LoadingSkeletonWidget(
            width: double.infinity,
            height: 80,
            borderRadius: 14,
          ),
        ),
      );
    }

    final items = _filteredFor(typeFilter);

    if (items.isEmpty) {
      return _buildEmptyState(typeFilter);
    }

    final groups = _groupByDate(items);
    const groupOrder = ['Today', 'Yesterday', 'This Week', 'Earlier'];

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          for (final groupKey in groupOrder)
            if (groups.containsKey(groupKey)) ...[
              _buildGroupHeader(groupKey),
              const SizedBox(height: 8),
              ...groups[groupKey]!.map((n) {
                final globalIndex = _notifications.indexOf(n);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildNotificationCard(n, globalIndex),
                );
              }),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.outline,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppTheme.outlineVariant)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, int index) {
    final isRead = n['is_read'] as bool? ?? true;
    final type = n['type'] as String?;
    final color = _getColor(type, n);
    final icon = _getIcon(type, n);

    return Dismissible(
      key: Key(n['id'] as String? ?? '$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => _deleteNotification(n['id'] as String? ?? '', index),
      child: GestureDetector(
        onTap: () {
          if (!isRead) _markRead(n, index);
          _handleNotificationTap(n);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? AppTheme.outlineVariant
                  : color.withValues(alpha: 0.3),
            ),
            boxShadow: isRead ? [] : AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (!isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n['title'] as String? ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(n['created_at'] as String?),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF90A4AE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['body'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(type, n),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isRead) ...[
                          GestureDetector(
                            onTap: () => _markRead(n, index),
                            child: Text(
                              'Mark read',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        GestureDetector(
                          onTap: () => _deleteNotification(n['id'] as String? ?? '', index),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    NotificationService.instance.stopContinuousBookingAlert();

    final type = n['type'] as String?;
    final metadata = n['metadata'] as Map<String, dynamic>?;

    switch (type) {
      case 'enquiry':
        final enquiryId = metadata?['enquiry_id']?.toString() ?? n['id']?.toString();
        // Route to received quotations or chat/enquiry view
        Navigator.pushNamed(
          context,
          AppRoutes.customerReceivedQuotationsScreen,
        );
        break;
      case 'quotation':
        Navigator.pushNamed(
          context,
          AppRoutes.customerReceivedQuotationsScreen,
        );
        break;
      case 'booking':
      case 'booking_status':
        Navigator.pushNamed(context, AppRoutes.customerBookingsScreen);
        break;
      case 'message':
        Navigator.pushNamed(context, AppRoutes.chatListScreen);
        break;
      case 'review':
        Navigator.pushNamed(context, AppRoutes.reviewSubmissionScreen);
        break;
      default:
        break;
    }
  }

  Widget _buildEmptyState(String? typeFilter) {
    final label = typeFilter == null
        ? 'notifications'
        : _typeLabel(typeFilter).toLowerCase();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 42,
              color: AppTheme.outline.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No $label yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updates will appear here\nas they come in',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.outline,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final String? typeFilter;
  final IconData icon;
  const _TabDef(this.label, this.typeFilter, this.icon);
}

