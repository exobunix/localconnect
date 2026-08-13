import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

enum InboxRole { customer, vendor, rider, admin }

enum AlertType {
  orderUpdate,
  bookingRequest,
  deliveryAssignment,
  adminApproval,
  payment,
  message,
  system,
}

enum AlertStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
}

class InboxAlert {
  final String id;
  final AlertType type;
  final AlertStatus status;
  final InboxRole role;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isRead;
  final String? avatarUrl;
  final String? actionLabel1;
  final String? actionLabel2;
  final Map<String, dynamic> meta;

  const InboxAlert({
    required this.id,
    required this.type,
    required this.status,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isRead = false,
    this.avatarUrl,
    this.actionLabel1,
    this.actionLabel2,
    this.meta = const {},
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class UnifiedInboxScreen extends StatefulWidget {
  const UnifiedInboxScreen({super.key});

  @override
  State<UnifiedInboxScreen> createState() => _UnifiedInboxScreenState();
}

class _UnifiedInboxScreenState extends State<UnifiedInboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeRole = 'all';
  String _userRole = 'customer';
  final Set<String> _readIds = {};
  bool _isLoading = false;

  List<InboxAlert> _dynamicAlerts = [];
  List<InboxAlert> get _alerts => _dynamicAlerts;

  final List<Map<String, dynamic>> _roleTabs = [
    {'id': 'all', 'label': 'All', 'icon': Icons.inbox_rounded},
    {'id': 'customer', 'label': 'Customer', 'icon': Icons.person_rounded},
    {'id': 'vendor', 'label': 'Vendor', 'icon': Icons.storefront_rounded},
    {'id': 'rider', 'label': 'Rider', 'icon': Icons.delivery_dining_rounded},
    {
      'id': 'admin',
      'label': 'Admin',
      'icon': Icons.admin_panel_settings_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roleTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeRole = _roleTabs[_tabController.index]['id']);
      }
    });
    _loadUserRole().then((_) => _loadDynamicAlerts());
  }

  Future<void> _loadUserRole() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    final profile = await SupabaseService.instance.getUserProfile(userId);
    if (mounted && profile != null) {
      setState(() => _userRole = profile['role'] as String? ?? 'customer');
    }
  }

  Future<void> _loadDynamicAlerts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dbAlerts = await SupabaseService.instance.getNotifications();
      
      final List<InboxAlert> loaded = [];
      for (final row in dbAlerts) {
        final id = row['id']?.toString() ?? '';
        final title = row['title'] as String? ?? '';
        final body = row['body'] as String? ?? '';
        final typeStr = row['type'] as String? ?? 'system';
        final isRead = row['is_read'] as bool? ?? false;
        final createdAtStr = row['created_at'] as String? ?? '';
        
        // Determine AlertType
        AlertType type;
        switch (typeStr.toLowerCase()) {
          case 'booking':
            type = AlertType.bookingRequest;
            break;
          case 'order':
            type = AlertType.orderUpdate;
            break;
          case 'payment':
            type = AlertType.payment;
            break;
          case 'delivery':
            type = AlertType.deliveryAssignment;
            break;
          case 'admin':
            type = AlertType.adminApproval;
            break;
          default:
            type = AlertType.system;
        }
        
        // Format time ago
        String timeAgo = 'Just now';
        if (createdAtStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();
            final diff = DateTime.now().difference(dt);
            if (diff.inDays > 0) {
              timeAgo = '${diff.inDays}d ago';
            } else if (diff.inHours > 0) {
              timeAgo = '${diff.inHours}h ago';
            } else if (diff.inMinutes > 0) {
              timeAgo = '${diff.inMinutes}m ago';
            } else {
              timeAgo = 'Just now';
            }
          } catch (_) {}
        }
        
        // Determine status
        AlertStatus status = AlertStatus.pending;
        if (type == AlertType.payment) {
          status = AlertStatus.completed;
        }
        
        // Set role based on user role
        InboxRole role = InboxRole.customer;
        if (_userRole == 'provider') {
          role = InboxRole.vendor;
        } else if (_userRole == 'admin') {
          role = InboxRole.admin;
        } else if (_userRole == 'rider') {
          role = InboxRole.rider;
        }

        // Add appropriate action labels
        String? actionLabel1;
        if (type == AlertType.bookingRequest) {
          actionLabel1 = _userRole == 'provider' ? 'Accept' : 'View Booking';
        } else if (type == AlertType.payment) {
          actionLabel1 = 'View Receipt';
        } else if (type == AlertType.orderUpdate) {
          actionLabel1 = 'View Order';
        }

        loaded.add(
          InboxAlert(
            id: id,
            type: type,
            status: status,
            role: role,
            title: title,
            subtitle: body,
            timeAgo: timeAgo,
            isRead: isRead,
            actionLabel1: actionLabel1,
          ),
        );
      }
      
      if (mounted) {
        setState(() {
          _dynamicAlerts = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<InboxAlert> get _filteredAlerts {
    if (_activeRole == 'all') return _alerts;
    final roleMap = {
      'customer': InboxRole.customer,
      'vendor': InboxRole.vendor,
      'rider': InboxRole.rider,
      'admin': InboxRole.admin,
    };
    final role = roleMap[_activeRole];
    return _alerts.where((a) => a.role == role).toList();
  }

  int _unreadCount(String roleId) {
    if (roleId == 'all') {
      return _alerts.where((a) => !a.isRead && !_readIds.contains(a.id)).length;
    }
    final roleMap = {
      'customer': InboxRole.customer,
      'vendor': InboxRole.vendor,
      'rider': InboxRole.rider,
      'admin': InboxRole.admin,
    };
    final role = roleMap[roleId];
    return _alerts
        .where((a) => a.role == role && !a.isRead && !_readIds.contains(a.id))
        .length;
  }

  void _markRead(String id) async {
    setState(() => _readIds.add(id));
    try {
      await SupabaseService.instance.markNotificationRead(id);
    } catch (_) {}
  }

  void _markAllRead() async {
    setState(() {
      for (final a in _filteredAlerts) {
        _readIds.add(a.id);
      }
    });
    try {
      await SupabaseService.instance.markAllNotificationsRead();
    } catch (_) {}
  }

  // ─── Status helpers ───────────────────────────────────────────────────────

  Color _statusColor(AlertStatus s) {
    switch (s) {
      case AlertStatus.pending:
        return AppTheme.warning;
      case AlertStatus.confirmed:
        return AppTheme.primary;
      case AlertStatus.inProgress:
        return const Color(0xFF7B1FA2);
      case AlertStatus.completed:
        return AppTheme.success;
      case AlertStatus.cancelled:
        return AppTheme.error;
      case AlertStatus.rejected:
        return AppTheme.error;
    }
  }

  String _statusLabel(AlertStatus s) {
    switch (s) {
      case AlertStatus.pending:
        return 'Pending';
      case AlertStatus.confirmed:
        return 'Confirmed';
      case AlertStatus.inProgress:
        return 'In Progress';
      case AlertStatus.completed:
        return 'Completed';
      case AlertStatus.cancelled:
        return 'Cancelled';
      case AlertStatus.rejected:
        return 'Rejected';
    }
  }

  Color _typeColor(AlertType t) {
    switch (t) {
      case AlertType.orderUpdate:
        return AppTheme.catDelivery;
      case AlertType.bookingRequest:
        return AppTheme.primary;
      case AlertType.deliveryAssignment:
        return const Color(0xFF00897B);
      case AlertType.adminApproval:
        return const Color(0xFF6A1B9A);
      case AlertType.payment:
        return AppTheme.catGrocery;
      case AlertType.message:
        return AppTheme.catPlumbing;
      case AlertType.system:
        return AppTheme.catMore;
    }
  }

  IconData _typeIcon(AlertType t) {
    switch (t) {
      case AlertType.orderUpdate:
        return Icons.receipt_long_rounded;
      case AlertType.bookingRequest:
        return Icons.calendar_today_rounded;
      case AlertType.deliveryAssignment:
        return Icons.delivery_dining_rounded;
      case AlertType.adminApproval:
        return Icons.verified_rounded;
      case AlertType.payment:
        return Icons.payments_rounded;
      case AlertType.message:
        return Icons.chat_bubble_rounded;
      case AlertType.system:
        return Icons.info_rounded;
    }
  }

  String _typeLabel(AlertType t) {
    switch (t) {
      case AlertType.orderUpdate:
        return 'Order';
      case AlertType.bookingRequest:
        return 'Booking';
      case AlertType.deliveryAssignment:
        return 'Delivery';
      case AlertType.adminApproval:
        return 'Approval';
      case AlertType.payment:
        return 'Payment';
      case AlertType.message:
        return 'Message';
      case AlertType.system:
        return 'System';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalUnread = _unreadCount('all');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(totalUnread),
      body: Column(
        children: [
          _buildRoleTabBar(),
          Expanded(
            child: _filteredAlerts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _isLoading = true);
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (mounted) setState(() => _isLoading = false);
                    },
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = _filteredAlerts[index];
                        return _AlertCard(
                          alert: alert,
                          isRead: alert.isRead || _readIds.contains(alert.id),
                          statusColor: _statusColor(alert.status),
                          statusLabel: _statusLabel(alert.status),
                          typeColor: _typeColor(alert.type),
                          typeIcon: _typeIcon(alert.type),
                          typeLabel: _typeLabel(alert.type),
                          onTap: () => _markRead(alert.id),
                          onAction1: alert.actionLabel1 != null
                              ? () => _handleAction(alert, 1)
                              : null,
                          onAction2: alert.actionLabel2 != null
                              ? () => _handleAction(alert, 2)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int totalUnread) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unified Inbox',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (totalUnread > 0)
            Text(
              '$totalUnread unread alerts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: [
        if (totalUnread > 0)
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
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRoleTabBar() {
    return Container(
      color: AppTheme.primary,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: _roleTabs.map((tab) {
              final isActive = _activeRole == tab['id'];
              final count = _unreadCount(tab['id']);
              return GestureDetector(
                onTap: () {
                  final idx = _roleTabs.indexOf(tab);
                  _tabController.animateTo(idx);
                  setState(() => _activeRole = tab['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 15,
                        color: isActive ? Colors.white : AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF44474E),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white24
                                : AppTheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No alerts for this role right now.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(InboxAlert alert, int actionNum) {
    _markRead(alert.id);
    final label = actionNum == 1 ? alert.actionLabel1 : alert.actionLabel2;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label — ${alert.title}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Alert Card Widget ────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final InboxAlert alert;
  final bool isRead;
  final Color statusColor;
  final String statusLabel;
  final Color typeColor;
  final IconData typeIcon;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback? onAction1;
  final VoidCallback? onAction2;

  const _AlertCard({
    required this.alert,
    required this.isRead,
    required this.statusColor,
    required this.statusLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.typeLabel,
    required this.onTap,
    this.onAction1,
    this.onAction2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppTheme.outlineVariant : AppTheme.primaryContainer,
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar or type icon
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type chip + time
                        Row(
                          children: [
                            _TypeChip(
                              label: typeLabel,
                              icon: typeIcon,
                              color: typeColor,
                            ),
                            const Spacer(),
                            Text(
                              alert.timeAgo,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF90A4AE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Title
                        Text(
                          alert.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Subtitle
                        Text(
                          alert.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF74777F),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Status badge + actions ───────────────────────────────────
              Row(
                children: [
                  _StatusBadge(label: statusLabel, color: statusColor),
                  const Spacer(),
                  if (onAction2 != null) ...[
                    _ActionButton(
                      label: alert.actionLabel2!,
                      isPrimary: false,
                      onTap: onAction2!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onAction1 != null)
                    _ActionButton(
                      label: alert.actionLabel1!,
                      isPrimary: true,
                      onTap: onAction1!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (alert.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: alert.avatarUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 44,
            height: 44,
            color: typeColor.withAlpha(31),
            child: Icon(typeIcon, size: 22, color: typeColor),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, size: 22, color: typeColor),
          ),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: typeColor.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(typeIcon, size: 22, color: typeColor),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary ? AppTheme.primary : AppTheme.outline,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : const Color(0xFF44474E),
          ),
        ),
      ),
    );
  }
}
