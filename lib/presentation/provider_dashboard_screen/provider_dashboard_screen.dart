import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/role_guard.dart';
import '../../services/account_deletion_service.dart';
import '../../services/notification_service.dart';
import '../../services/provider_subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/inline_error_widget.dart';
import '../../widgets/share_widgets.dart';
import '../provider_kyc_screen/provider_kyc_upload_screen.dart';
import '../provider_profile_screen/widgets/provider_offers_management_widget.dart';
import '../provider_profile_screen/widgets/provider_photos_management_widget.dart';
import '../provider_service_area_screen/provider_service_area_screen.dart';
import '../quotation_screen/provider_enquiries_screen.dart';
import '../virtual_shop_setup_screen/virtual_shop_setup_screen.dart';
import './widgets/provider_availability_screen.dart';
import './widgets/provider_bottom_nav_widget.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex =
      0; // 0=Dashboard, 1=Orders, 2=Calendar, 3=Earnings, 4=Profile

  bool _isLoading = true;
  String? _error;

  // Provider data
  Map<String, dynamic>? _providerProfile;

  // Orders
  List<Map<String, dynamic>> _incomingOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];

  // Stats
  double _totalEarnings = 0;
  double _todayEarnings = 0;
  int _completedCount = 0;
  int _acceptedCount = 0;
  int _rejectedCount = 0;
  double _completionRate = 0;

  // Quotation metrics
  int _quotationPending = 0;
  int _quotationAccepted = 0;
  int _quotationRejected = 0;
  int _quotationExpired = 0;
  String _quotationFilter = 'all'; // all, pending, accepted, rejected, expired

  // Subscription status
  SubscriptionStatus? _subscriptionStatus;

  // Realtime
  RealtimeChannel? _ordersChannel;

  // Action loading states
  final Set<String> _processingOrderIds = {};

  // Unread request counter
  int _unreadRequestCount = 0;
  int _lastKnownIncomingCount = 0;

  // Account deletion
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = await SupabaseService.instance.getMyProviderProfile();
      if (provider == null) {
        setState(() {
          _error = 'Provider profile not found. Please complete onboarding.';
          _isLoading = false;
        });
        return;
      }
      _providerProfile = provider;
      await _loadOrders(provider['id'] as String);
      await _loadQuotationCounts();
      _subscribeToOrders(provider['id'] as String);
      // Load subscription status for dashboard card
      _loadSubscriptionStatus(provider['id'] as String);
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders(String providerId) async {
    final orders = await SupabaseService.instance.getProviderOrders(providerId);

    final incoming = <Map<String, dynamic>>[];
    final active = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    double totalEarnings = 0;
    double todayEarnings = 0;
    int completedCount = 0;
    int acceptedCount = 0;
    int rejectedCount = 0;

    final today = DateTime.now();

    for (final order in orders) {
      final status = order['status'] as String? ?? '';
      final amountStr = order['amount'] as String? ?? '0';
      final amount =
          double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final createdAt = order['created_at'] != null
          ? DateTime.tryParse(order['created_at'] as String)
          : null;

      switch (status) {
        case 'pending':
          incoming.add(order);
          break;
        case 'active':
        case 'upcoming':
          active.add(order);
          acceptedCount++;
          break;
        case 'completed':
          completed.add(order);
          completedCount++;
          acceptedCount++;
          totalEarnings += amount;
          if (createdAt != null &&
              createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day) {
            todayEarnings += amount;
          }
          break;
        case 'cancelled':
          rejectedCount++;
          break;
      }
    }

    final totalHandled = acceptedCount + rejectedCount;
    final completionRate = totalHandled > 0
        ? (completedCount / totalHandled) * 100
        : 0.0;

    if (mounted) {
      setState(() {
        // Increment unread count if new incoming orders arrived
        if (incoming.length > _lastKnownIncomingCount && _bottomNavIndex != 1) {
          _unreadRequestCount += incoming.length - _lastKnownIncomingCount;
        }
        _lastKnownIncomingCount = incoming.length;
        _incomingOrders = incoming;
        _activeOrders = active;
        _completedOrders = completed;
        _totalEarnings = totalEarnings;
        _todayEarnings = todayEarnings;
        _completedCount = completedCount;
        _acceptedCount = acceptedCount;
        _rejectedCount = rejectedCount;
        _completionRate = completionRate;
        _isLoading = false;
      });
    }
  }

  void _subscribeToOrders(String providerId) {
    _ordersChannel?.unsubscribe();
    _ordersChannel = SupabaseService.instance.client
        .channel('provider_orders_dash_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newRow = payload.newRecord;
            final status = newRow['status'] as String? ?? '';
            final customerName = newRow['customer_name'] as String?;
            final service = newRow['service'] as String?;
            final orderId = newRow['id'] as String? ?? '';
            final paymentStatus = newRow['payment_status'] as String? ?? '';

            if (status == 'pending') {
              // New order request — notify provider
              NotificationService.instance.showNewBookingNotification(
                bookingId: orderId,
                customerName: customerName,
                serviceName: service,
              );
              NotificationService.instance.showNewBookingToast(
                customerName: customerName,
                serviceName: service,
              );
            }

            if (paymentStatus == 'paid') {
              // Payment received — notify provider
              NotificationService.instance.showOrderStatusNotification(
                orderId: orderId,
                status: 'payment_received',
                providerName: customerName,
              );
            }

            _loadOrders(providerId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newRow = payload.newRecord;
            final oldRow = payload.oldRecord;
            final orderId = newRow['id'] as String? ?? '';
            final customerName = newRow['customer_name'] as String?;

            // Detect payment_status change to 'paid'
            final oldPayment = oldRow['payment_status'] as String? ?? '';
            final newPayment = newRow['payment_status'] as String? ?? '';
            if (oldPayment != 'paid' && newPayment == 'paid') {
              NotificationService.instance.showOrderStatusNotification(
                orderId: orderId,
                status: 'payment_received',
                providerName: customerName,
              );
            }

            _loadOrders(providerId);
          },
        )
        .subscribe((status, [error]) {
          if (error != null) {
            debugPrint(
              '[ProviderDashboard] Realtime subscription error: $error',
            );
          } else {
            debugPrint('[ProviderDashboard] Realtime channel status: $status');
          }
        });
  }

  Future<void> _loadQuotationCounts() async {
    try {
      final counts = await SupabaseService.instance
          .getProviderQuotationCounts();
      if (mounted) {
        setState(() {
          _quotationPending = counts['pending'] ?? 0;
          _quotationAccepted = counts['accepted'] ?? 0;
          _quotationRejected = counts['rejected'] ?? 0;
          _quotationExpired = counts['expired'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSubscriptionStatus(String providerId) async {
    try {
      final sub = await ProviderSubscriptionService.instance
          .getCurrentSubscription(providerId);
      final status = ProviderSubscriptionService.instance.analyzeStatus(sub);
      if (mounted) {
        setState(() => _subscriptionStatus = status);
      }
      // Check and send reminders
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        ProviderSubscriptionService.instance.checkAndSendReminders(
          providerId,
          userId,
        );
      }
    } catch (_) {}
  }

  Future<void> _acceptOrder(String orderId) async {
    setState(() => _processingOrderIds.add(orderId));
    // Fetch order details for notification
    final orderData = await SupabaseService.instance.getOrderById(orderId);
    await SupabaseService.instance.updateOrderStatus(
      orderId: orderId,
      status: 'active',
    );
    // Notify customer via DB notification + local push (if customer is on this device)
    if (orderData != null) {
      final customerId = orderData['customer_id'] as String?;
      final orderNumber = orderData['order_number'] as String? ?? orderId;
      final providerName =
          _providerProfile?['business_name'] as String? ??
          _providerProfile?['full_name'] as String? ??
          'Provider';
      if (customerId != null) {
        await SupabaseService.instance.insertOrderNotification(
          userId: customerId,
          title: '✅ Order Accepted!',
          body: '$providerName accepted your order $orderNumber.',
          type: 'booking',
        );
      }
      // Show local push for current user if they are the customer
      final currentId = SupabaseService.instance.currentUser?.id;
      if (currentId == customerId) {
        await NotificationService.instance.showOrderStatusNotification(
          orderId: orderId,
          status: 'accepted',
          providerName: providerName,
        );
        NotificationService.instance.showBookingStatusToast(
          status: 'accepted',
          providerName: providerName,
        );
      }
    }
    if (mounted) {
      setState(() => _processingOrderIds.remove(orderId));
      _showSnack('Order accepted!', isSuccess: true);
      if (_providerProfile != null) {
        await _loadOrders(_providerProfile!['id'] as String);
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final confirm = await _showConfirmDialog(
      'Reject Order',
      'Are you sure you want to reject this order?',
    );
    if (!confirm) return;

    setState(() => _processingOrderIds.add(orderId));
    // Fetch order details for notification
    final orderData = await SupabaseService.instance.getOrderById(orderId);
    await SupabaseService.instance.updateOrderStatus(
      orderId: orderId,
      status: 'cancelled',
    );
    // Notify customer via DB notification
    if (orderData != null) {
      final customerId = orderData['customer_id'] as String?;
      final orderNumber = orderData['order_number'] as String? ?? orderId;
      final providerName =
          _providerProfile?['business_name'] as String? ??
          _providerProfile?['full_name'] as String? ??
          'Provider';
      if (customerId != null) {
        await SupabaseService.instance.insertOrderNotification(
          userId: customerId,
          title: '❌ Order Declined',
          body: '$providerName could not accept your order $orderNumber.',
          type: 'booking',
        );
      }
      final currentId = SupabaseService.instance.currentUser?.id;
      if (currentId == customerId) {
        await NotificationService.instance.showOrderStatusNotification(
          orderId: orderId,
          status: 'cancelled',
          providerName: providerName,
        );
        NotificationService.instance.showBookingStatusToast(
          status: 'cancelled',
          providerName: providerName,
        );
      }
    }
    if (mounted) {
      setState(() => _processingOrderIds.remove(orderId));
      _showSnack('Order rejected.');
      if (_providerProfile != null) {
        await _loadOrders(_providerProfile!['id'] as String);
      }
    }
  }

  Future<void> _completeOrder(String orderId) async {
    final confirm = await _showConfirmDialog(
      'Complete Order',
      'Mark this order as completed?',
    );
    if (!confirm) return;

    setState(() => _processingOrderIds.add(orderId));
    await SupabaseService.instance.updateOrderStatus(
      orderId: orderId,
      status: 'completed',
    );
    if (mounted) {
      setState(() => _processingOrderIds.remove(orderId));
      _showSnack('Order marked as completed!', isSuccess: true);
      if (_providerProfile != null) {
        await _loadOrders(_providerProfile!['id'] as String);
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── DELETE ACCOUNT FLOW ─────────────────────────────────────────────────

  Future<void> _showDeleteAccountFlow() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    setState(() => _isDeletingAccount = true);
    final issues = await AccountDeletionService.instance
        .getProviderBlockingIssues(userId);
    setState(() => _isDeletingAccount = false);

    if (!mounted) return;

    // Show blocking issues if any
    if (issues.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cannot Delete Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please resolve the following before deleting your account:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: AppTheme.error,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'All your personal data, profile information, listings, orders, chats, and account history will be permanently removed.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF74777F),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Re-authentication for email/password users
    final isPhone = AccountDeletionService.instance.isPhoneUser();
    final isGoogle = AccountDeletionService.instance.isGoogleUser();

    if (!isPhone && !isGoogle) {
      final verified = await _showPasswordVerificationDialog();
      if (!verified) return;
    }

    if (!mounted) return;
    setState(() => _isDeletingAccount = true);

    final error = await AccountDeletionService.instance.deleteAccount();

    if (!mounted) return;
    setState(() => _isDeletingAccount = false);

    if (error != null) {
      _showSnack('Deletion failed: $error', isSuccess: false);
      return;
    }

    // Success — navigate to login
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Account Deleted',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been permanently deleted. We\'re sorry to see you go.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  clearCachedRole();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.loginScreen,
                    (r) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _showPasswordVerificationDialog() async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Verify Your Identity',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your password to confirm account deletion.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  errorText: errorMsg,
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF74777F),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = passwordCtrl.text.trim();
                if (pwd.isEmpty) {
                  setDialogState(() => errorMsg = 'Password is required');
                  return;
                }
                final err = await AccountDeletionService.instance
                    .reauthenticateWithPassword(pwd);
                if (err != null) {
                  setDialogState(() => errorMsg = err);
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Verify',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    passwordCtrl.dispose();
    return result == true;
  }

  /// Centralized logout — signs out first, then navigates to login.
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Sign out FIRST, then clear cache, then navigate
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    clearCachedRole();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: Stack(
        children: [
          _isLoading
              ? const ScreenLoadingWidget(message: 'Loading dashboard...')
              : _error != null
              ? _buildErrorState()
              : _buildCurrentTab(),
          // Persistent logout button — always visible in top-right corner
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          (!_isLoading && _error == null && _bottomNavIndex == 0)
          ? _buildRequestFAB()
          : null,
      bottomNavigationBar: ProviderBottomNavWidget(
        selectedIndex: _bottomNavIndex,
        onTap: _onBottomNavTap,
        unreadCount: _unreadRequestCount,
      ),
    );
  }

  Widget _buildRequestFAB() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _unreadRequestCount = 0;
          _lastKnownIncomingCount = _incomingOrders.length;
          _bottomNavIndex = 1;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          if (_unreadRequestCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _unreadRequestCount > 99 ? '99+' : '$_unreadRequestCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.providerEarningsDashboardScreen);
      return;
    }
    if (index == 4) {
      // Show provider profile / settings
      final providerId = _providerProfile?['id'] as String?;
      if (providerId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.providerProfileScreen,
          arguments: {'providerId': providerId},
        );
      }
      return;
    }
    // Reset unread badge when opening Orders tab
    if (index == 1) {
      setState(() {
        _unreadRequestCount = 0;
        _lastKnownIncomingCount = _incomingOrders.length;
      });
    }
    setState(() => _bottomNavIndex = index);
  }

  Widget _buildCurrentTab() {
    switch (_bottomNavIndex) {
      case 1:
        return _buildOrdersOnlyView();
      case 2:
        return _buildCalendarView();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildOrdersOnlyView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'My Orders',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Incoming'),

                  if (_incomingOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_incomingOrders.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_activeOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeOrders.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncomingTab(), _buildActiveTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildCalendarView() {
    final providerId = _providerProfile?['id'] as String?;
    if (providerId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ProviderAvailabilityScreen(providerId: providerId);
  }

  Widget _buildErrorState() {
    return InlineErrorWidget(
      message: _error ?? 'Failed to load dashboard.',
      onRetry: _loadDashboard,
    );
  }

  Widget _buildDashboard() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          snap: true,
          pinned: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provider Dashboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (_providerProfile != null)
                Text(
                  _providerProfile!['business_name'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          actions: [
            // Inbox bell with unread badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  onPressed: () {
                    setState(() {
                      _unreadRequestCount = 0;
                      _lastKnownIncomingCount = _incomingOrders.length;
                      _bottomNavIndex = 1;
                    });
                  },
                  tooltip: 'Request Inbox',
                ),
                if (_unreadRequestCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary, width: 1.5),
                      ),
                      child: Text(
                        _unreadRequestCount > 99
                            ? '99+'
                            : '$_unreadRequestCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.local_offer_rounded),
              onPressed: () {
                final providerId = _providerProfile?['id'] as String?;
                if (providerId != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.75,
                      maxChildSize: 0.95,
                      minChildSize: 0.4,
                      builder: (_, ctrl) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.outline,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: ctrl,
                                child: ProviderOffersManagementWidget(
                                  providerId: providerId,
                                  isOwner: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Manage Offers',
            ),
            IconButton(
              icon: const Icon(Icons.schedule_rounded),
              onPressed: () {
                final providerId = _providerProfile?['id'] as String?;
                if (providerId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProviderAvailabilityScreen(providerId: providerId),
                    ),
                  );
                }
              },
              tooltip: 'Availability Settings',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboard,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _handleLogout,
              tooltip: 'Sign Out',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Incoming'),
                    if (_incomingOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_incomingOrders.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Active'),
                    if (_activeOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_activeOrders.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'History'),
            ],
          ),
        ),
      ],
      body: Column(
        children: [
          _buildStatsBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIncomingTab(),
                _buildActiveTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                icon: Icons.currency_rupee,
                label: 'Total Earned',
                value: '₹${_totalEarnings.toStringAsFixed(0)}',
                color: AppTheme.success,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.today,
                label: 'Today',
                value: '₹${_todayEarnings.toStringAsFixed(0)}',
                color: AppTheme.primary,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                label: 'Completion',
                value: '${_completionRate.toStringAsFixed(0)}%',
                color: _completionRate >= 80
                    ? AppTheme.success
                    : _completionRate >= 50
                    ? AppTheme.warning
                    : AppTheme.error,
              ),
              _buildStatDivider(),
              _buildStatItem(
                icon: Icons.done_all,
                label: 'Completed',
                value: '$_completedCount',
                color: AppTheme.info,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ─── Service Area Management Button ────────────────────────────
          GestureDetector(
            onTap: () {
              final providerId = _providerProfile?['id'] as String?;
              if (providerId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProviderServiceAreaScreen(providerId: providerId),
                  ),
                ).then((_) => _loadDashboard());
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Area Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _providerProfile?['service_radius_km'] != null
                              ? 'Radius: ${(_providerProfile!['service_radius_km'] as num).toStringAsFixed(0)} km  •  ${(_providerProfile!['service_mode'] as String? ?? 'radius').toUpperCase()}'
                              : 'Set your business location & service area',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/provider-bookings-screen'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'My Bookings & Orders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_activeOrders.length + _completedOrders.length} orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Incoming Bookings (from Quotations) ───────────────────────────
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.providerIncomingBookingsScreen,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Incoming Bookings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_incomingOrders.length} new',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Virtual Shop Edit Button ──────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VirtualShopSetupScreen(isEditing: true),
              ),
            ).then((_) => _loadDashboard()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF26C6A6), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Virtual Shop',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Customer Enquiries Button ─────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProviderEnquiriesScreen(),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.request_quote_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Customer Enquiries & Quotations',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProviderKycUploadScreen(),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'KYC Verification',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _providerProfile?['kyc_status'] == 'approved'
                          ? 'Verified ✓'
                          : _providerProfile?['kyc_status'] == 'pending'
                          ? 'Under Review'
                          : 'Upload Docs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuotationMetricsCard(),
          const SizedBox(height: 12),
          // ─── PROMOTE MY BUSINESS ─────────────────────────────────────────
          if (_providerProfile != null)
            ProviderShareWidget(
              providerId: _providerProfile!['id'] as String? ?? '',
              providerName:
                  _providerProfile!['full_name'] as String? ?? 'Provider',
              businessName:
                  _providerProfile!['business_name'] as String? ??
                  'My Business',
              category: _providerProfile!['category'] as String? ?? 'Services',
            ),
          const SizedBox(height: 12),
          // ─── REFERRAL HUB ────────────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.referralHubScreen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Referral Hub',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── INVITE FRIENDS ──────────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.inviteFriendsScreen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Invite Friends & Earn Rewards',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── CHANGE PASSWORD ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.changePasswordScreen),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(
                'Change Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ─── DELETE ACCOUNT ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDeletingAccount ? null : _showDeleteAccountFlow,
              icon: _isDeletingAccount
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.error,
                      ),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 18),
              label: Text(
                'Delete My Account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deleting your account is permanent and cannot be undone.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.error.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuotationMetricsCard() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'rejected', 'label': 'Rejected'},
      {'key': 'expired', 'label': 'Expired'},
    ];

    final int totalQuotations =
        _quotationPending +
        _quotationAccepted +
        _quotationRejected +
        _quotationExpired;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    size: 16,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quotation Metrics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C1B1F),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderEnquiriesScreen(),
                    ),
                  ).then((_) => _loadQuotationCounts()),
                  child: Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B1FA2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metric tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildQuotationTile(
                  label: 'Pending',
                  count: _quotationPending,
                  color: const Color(0xFFF57C00),
                  bgColor: const Color(0xFFFFF3E0),
                  icon: Icons.hourglass_empty_rounded,
                  filterKey: 'pending',
                ),
                const SizedBox(width: 6),
                _buildQuotationTile(
                  label: 'Accepted',
                  count: _quotationAccepted,
                  color: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                  icon: Icons.check_circle_outline_rounded,
                  filterKey: 'accepted',
                ),
                const SizedBox(width: 6),
                _buildQuotationTile(
                  label: 'Rejected',
                  count: _quotationRejected,
                  color: const Color(0xFFC62828),
                  bgColor: const Color(0xFFFFEBEE),
                  icon: Icons.cancel_outlined,
                  filterKey: 'rejected',
                ),
                const SizedBox(width: 6),
                _buildQuotationTile(
                  label: 'Expired',
                  count: _quotationExpired,
                  color: const Color(0xFF546E7A),
                  bgColor: const Color(0xFFECEFF1),
                  icon: Icons.timer_off_outlined,
                  filterKey: 'expired',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF74777F),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = _quotationFilter == f['key'];
                      int count = 0;
                      switch (f['key']) {
                        case 'pending':
                          count = _quotationPending;
                          break;
                        case 'accepted':
                          count = _quotationAccepted;
                          break;
                        case 'rejected':
                          count = _quotationRejected;
                          break;
                        case 'expired':
                          count = _quotationExpired;
                          break;
                        default:
                          count = totalQuotations;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _quotationFilter = f['key']!);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderEnquiriesScreen(
                                  initialStatusFilter: f['key'] == 'all'
                                      ? null
                                      : f['key'],
                                ),
                              ),
                            ).then((_) => _loadQuotationCounts());
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7B1FA2)
                                  : const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7B1FA2)
                                    : const Color(0xFFCE93D8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  f['label']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF7B1FA2),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.3)
                                          : const Color(
                                              0xFF7B1FA2,
                                            ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF7B1FA2),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationTile({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String filterKey,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _quotationFilter = filterKey);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProviderEnquiriesScreen(initialStatusFilter: filterKey),
            ),
          ).then((_) => _loadQuotationCounts());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: const Color(0xFF74777F),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.outlineVariant,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ─── INCOMING ORDERS TAB ──────────────────────────────────────────────────

  Widget _buildIncomingTab() {
    if (_incomingOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Pending Orders',
        subtitle: 'New customer orders will appear here in real-time.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (_providerProfile != null) {
          await _loadOrders(_providerProfile!['id'] as String);
        }
      },
      child: Column(
        children: [
          // Swipe hint banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBCCFF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swipe_rounded,
                  size: 16,
                  color: Color(0xFF3F51B5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swipe right to Accept · Swipe left to Decline',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3F51B5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _incomingOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _incomingOrders[index];
                return _buildIncomingOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final isProcessing = _processingOrderIds.contains(orderId);
    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'] as String)
        : null;

    // Extract customer details from joined data
    final customerMap = order['customer'] as Map<String, dynamic>?;
    final customerName =
        customerMap?['full_name'] as String? ??
        order['customer_name'] as String? ??
        'Customer';
    final customerPhone = customerMap?['phone'] as String? ?? '';

    // Time slot
    final scheduledDate = order['scheduled_date'] as String? ?? '';
    final scheduledTime = order['scheduled_time'] as String? ?? '';
    final hasTimeSlot = scheduledDate.isNotEmpty || scheduledTime.isNotEmpty;

    return Dismissible(
      key: Key('pending_order_$orderId'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (isProcessing) return false;
        if (direction == DismissDirection.startToEnd) {
          // Accept
          setState(() => _processingOrderIds.add(orderId));
          final orderData = await SupabaseService.instance.getOrderById(
            orderId,
          );
          await SupabaseService.instance.updateOrderStatus(
            orderId: orderId,
            status: 'active',
          );
          if (orderData != null) {
            final customerId = orderData['customer_id'] as String?;
            final orderNumber = orderData['order_number'] as String? ?? orderId;
            final providerName =
                _providerProfile?['business_name'] as String? ??
                _providerProfile?['full_name'] as String? ??
                'Provider';
            if (customerId != null) {
              await SupabaseService.instance.insertOrderNotification(
                userId: customerId,
                title: '✅ Order Accepted!',
                body: '$providerName accepted your order $orderNumber.',
                type: 'booking',
              );
            }
            final currentId = SupabaseService.instance.currentUser?.id;
            if (currentId == customerId) {
              await NotificationService.instance.showOrderStatusNotification(
                orderId: orderId,
                status: 'accepted',
                providerName: providerName,
              );
              NotificationService.instance.showBookingStatusToast(
                status: 'accepted',
                providerName: providerName,
              );
            }
          }
          if (mounted) {
            setState(() => _processingOrderIds.remove(orderId));
            _showSnack('Order accepted!', isSuccess: true);
            if (_providerProfile != null) {
              await _loadOrders(_providerProfile!['id'] as String);
            }
          }
          return false; // list already refreshed
        } else {
          // Decline — confirm first
          final confirm = await _showConfirmDialog(
            'Decline Order',
            'Are you sure you want to decline this order from $customerName?',
          );
          if (!confirm) return false;
          setState(() => _processingOrderIds.add(orderId));
          final orderData = await SupabaseService.instance.getOrderById(
            orderId,
          );
          await SupabaseService.instance.updateOrderStatus(
            orderId: orderId,
            status: 'cancelled',
          );
          if (orderData != null) {
            final customerId = orderData['customer_id'] as String?;
            final orderNumber = orderData['order_number'] as String? ?? orderId;
            final providerName =
                _providerProfile?['business_name'] as String? ??
                _providerProfile?['full_name'] as String? ??
                'Provider';
            if (customerId != null) {
              await SupabaseService.instance.insertOrderNotification(
                userId: customerId,
                title: '❌ Order Declined',
                body: '$providerName could not accept your order $orderNumber.',
                type: 'booking',
              );
            }
            final currentId = SupabaseService.instance.currentUser?.id;
            if (currentId == customerId) {
              await NotificationService.instance.showOrderStatusNotification(
                orderId: orderId,
                status: 'cancelled',
                providerName: providerName,
              );
              NotificationService.instance.showBookingStatusToast(
                status: 'cancelled',
                providerName: providerName,
              );
            }
          }
          if (mounted) {
            setState(() => _processingOrderIds.remove(orderId));
            _showSnack('Order declined.');
            if (_providerProfile != null) {
              await _loadOrders(_providerProfile!['id'] as String);
            }
          }
          return false;
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'Accept',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Decline',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.primaryLight.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] as String? ?? 'Order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDateTime(createdAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PENDING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Customer details row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customerPhone.isNotEmpty)
                          Text(
                            customerPhone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Customer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderDetailRow(
                    Icons.miscellaneous_services_outlined,
                    'Service',
                    order['service'] as String? ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _buildOrderDetailRow(
                    Icons.category_outlined,
                    'Category',
                    order['category'] as String? ?? '-',
                  ),
                  if (hasTimeSlot) ...[
                    const SizedBox(height: 8),
                    _buildOrderDetailRow(
                      Icons.access_time_rounded,
                      'Time Slot',
                      [
                        scheduledDate,
                        scheduledTime,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                  ],
                  if ((order['notes'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildOrderDetailRow(
                      Icons.notes_outlined,
                      'Notes',
                      order['notes'] as String,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                            ),
                            Text(
                              '₹${order['amount'] ?? '0'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _rejectOrder(orderId),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _acceptOrder(orderId),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE ORDERS TAB ────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    if (_activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_outline,
        title: 'No Active Orders',
        subtitle: 'Accepted orders will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (_providerProfile != null) {
          await _loadOrders(_providerProfile!['id'] as String);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          return _buildActiveOrderCard(order);
        },
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final isProcessing = _processingOrderIds.contains(orderId);
    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'] as String)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.successContainer.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.handyman_outlined,
                    size: 18,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['order_number'] as String? ?? 'Order',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDateTime(createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'IN PROGRESS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderDetailRow(
                  Icons.miscellaneous_services_outlined,
                  'Service',
                  order['service'] as String? ?? '-',
                ),
                const SizedBox(height: 8),
                if ((order['scheduled_date'] as String? ?? '').isNotEmpty) ...[
                  _buildOrderDetailRow(
                    Icons.calendar_today_outlined,
                    'Scheduled',
                    '${order['scheduled_date']} ${order['scheduled_time'] ?? ''}'
                        .trim(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                        Text(
                          '₹${order['amount'] ?? '0'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _completeOrder(orderId),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HISTORY TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_providerProfile != null) {
          await _loadOrders(_providerProfile!['id'] as String);
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildEarningsSummaryCard()),
          SliverToBoxAdapter(child: _buildCompletionRateCard()),
          // ── Shop & Service Photos ──────────────────────────────────────
          if (_providerProfile != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: ProviderPhotosManagementWidget(
                  providerId: _providerProfile!['id'] as String,
                  isOwner: true,
                ),
              ),
            ),
          if (_completedOrders.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(
                icon: Icons.history,
                title: 'No Completed Orders',
                subtitle: 'Your completed orders will appear here.',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Completed Orders (${_completedOrders.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final order = _completedOrders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildHistoryOrderCard(order),
                  );
                }, childCount: _completedOrders.length),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Earnings Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_totalEarnings.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Total Lifetime Earnings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarningsSubStat(
                  'Today',
                  '₹${_todayEarnings.toStringAsFixed(0)}',
                  Icons.today,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildEarningsSubStat(
                  'Orders Done',
                  '$_completedCount',
                  Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildEarningsSubStat(
                  'Rejected',
                  '$_rejectedCount',
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSubStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRateCard() {
    final rate = _completionRate.clamp(0.0, 100.0);
    final Color rateColor = rate >= 80
        ? AppTheme.success
        : rate >= 50
        ? AppTheme.warning
        : AppTheme.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: rateColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Completion Rate',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: rateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 10,
              backgroundColor: AppTheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(rateColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRateStat('Accepted', _acceptedCount, AppTheme.success),
              _buildRateStat('Completed', _completedCount, AppTheme.primary),
              _buildRateStat('Rejected', _rejectedCount, AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF74777F),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryOrderCard(Map<String, dynamic> order) {
    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'] as String)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_circle, size: 20, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['service'] as String? ?? 'Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  order['order_number'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF74777F),
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatDateTime(createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₹${order['amount'] ?? '0'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildOrderDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF74777F)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF74777F),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return EmptyStateWidget(icon: icon, title: title, subtitle: subtitle);
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

