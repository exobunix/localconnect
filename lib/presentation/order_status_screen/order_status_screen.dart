import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/service_rating_modal.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _tracking;
  Map<String, dynamic>? _provider;
  bool _isLoading = true;
  String? _orderId;
  bool _ratingShown = false;

  RealtimeChannel? _trackingChannel;
  RealtimeChannel? _orderChannel;

  late AnimationController _pulseController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnim;

  // Timeline steps
  static const _steps = [
    {
      'key': 'confirmed',
      'label': 'Order Confirmed',
      'sublabel': 'Your order has been placed',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'key': 'provider_accepted',
      'label': 'Provider Accepted',
      'sublabel': 'Provider is preparing for your service',
      'icon': Icons.handshake_outlined,
    },
    {
      'key': 'en_route',
      'label': 'En Route',
      'sublabel': 'Provider is on the way to you',
      'icon': Icons.directions_bike_rounded,
    },
    {
      'key': 'delivered',
      'label': 'Service Delivered',
      'sublabel': 'Service completed successfully',
      'icon': Icons.verified_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _orderId == null) {
      _orderId = args['order_id'] as String?;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_orderId == null) return;
    setState(() => _isLoading = true);

    final results = await Future.wait([
      SupabaseService.instance.getOrderById(_orderId!),
      SupabaseService.instance.getOrderTracking(_orderId!),
    ]);

    final order = results[0];
    final tracking = results[1];

    Map<String, dynamic>? provider;
    if (order?['provider_id'] != null) {
      provider = await SupabaseService.instance.getProviderById(
        order!['provider_id'] as String,
      );
    }

    if (mounted) {
      setState(() {
        _order = order;
        _tracking = tracking;
        _provider = provider;
        _isLoading = false;
      });
      _stepController.forward();
      _subscribeToRealtime();
    }
  }

  void _subscribeToRealtime() {
    if (_orderId == null) return;

    // Subscribe to tracking changes
    _trackingChannel = SupabaseService.instance.client
        .channel('order_tracking_$_orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: _orderId!,
          ),
          callback: (payload) {
            if (mounted) {
              final updated = payload.newRecord;
              if (updated.isNotEmpty) {
                final newStep = updated['current_step'] as String?;
                final oldStep = _tracking?['current_step'] as String?;
                setState(() => _tracking = updated);
                _stepController
                  ..reset()
                  ..forward();
                // Fire push notification when step changes
                if (newStep != null && newStep != oldStep) {
                  NotificationService.instance.showOrderStatusNotification(
                    orderId: _orderId!,
                    status: newStep,
                    providerName:
                        _provider?['business_name'] as String? ??
                        _provider?['full_name'] as String?,
                  );
                  // Show rating modal when order is delivered
                  if (newStep == 'delivered' && !_ratingShown) {
                    _ratingShown = true;
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) _showRatingModal();
                    });
                  }
                }
              }
            }
          },
        )
        .subscribe();

    // Subscribe to order status changes
    _orderChannel = SupabaseService.instance.client
        .channel('order_status_$_orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _orderId!,
          ),
          callback: (payload) {
            if (mounted) {
              final updated = payload.newRecord;
              if (updated.isNotEmpty) {
                final newStatus = updated['status'] as String?;
                final oldStatus = _order?['status'] as String?;
                setState(() => _order = {...?_order, ...updated});
                // Fire notification for order-level status changes (e.g. cancelled)
                if (newStatus != null &&
                    newStatus != oldStatus &&
                    newStatus == 'cancelled') {
                  NotificationService.instance.showOrderStatusNotification(
                    orderId: _orderId!,
                    status: newStatus,
                    providerName:
                        _provider?['business_name'] as String? ??
                        _provider?['full_name'] as String?,
                  );
                }
                // Show rating modal when order is completed
                if (newStatus != null &&
                    newStatus != oldStatus &&
                    newStatus == 'completed' &&
                    !_ratingShown) {
                  _ratingShown = true;
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) _showRatingModal();
                  });
                }
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _trackingChannel?.unsubscribe();
    _orderChannel?.unsubscribe();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  int get _currentStepIndex {
    final step = _tracking?['current_step'] as String? ?? 'confirmed';
    switch (step) {
      case 'confirmed':
        return 0;
      case 'provider_accepted':
        return 1;
      case 'en_route':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  bool get _isDelivered => _currentStepIndex == 3;
  bool get _isEnRoute => _currentStepIndex == 2;

  String get _etaText {
    final eta = _tracking?['eta_minutes'] as int?;
    if (eta == null) return 'Calculating...';
    if (eta <= 0) return 'Arriving now';
    if (eta < 60) return '$eta min away';
    final h = eta ~/ 60;
    final m = eta % 60;
    return m == 0 ? '${h}h away' : '${h}h ${m}m away';
  }

  Future<void> _callProvider() async {
    final phone = _provider?['phone'] as String? ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Provider phone number not available',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappProvider() async {
    final whatsapp =
        _provider?['whatsapp'] as String? ??
        _provider?['phone'] as String? ??
        '';
    if (whatsapp.isEmpty) return;
    final clean = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showRatingModal() async {
    if (_orderId == null) return;
    await showServiceRatingModal(
      context,
      bookingId: _orderId!,
      providerName:
          _provider?['business_name'] as String? ??
          _provider?['full_name'] as String?,
      serviceName: _order?['service'] as String?,
      isOrder: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoading()
          : _order == null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Order not found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ETA Banner (only when en route or accepted)
                if (!_isDelivered) ...[
                  _buildEtaBanner(),
                  const SizedBox(height: 16),
                ],

                // Timeline
                _buildTimeline(),
                const SizedBox(height: 16),

                // Live Location Map Card
                if (_isEnRoute || _currentStepIndex == 1) ...[
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                ],

                // Order Details Card
                _buildOrderDetailsCard(),
                const SizedBox(height: 16),

                // Provider Card
                if (_provider != null) ...[
                  _buildProviderCard(),
                  const SizedBox(height: 16),
                ],

                // Contact Buttons
                if (!_isDelivered) _buildContactButtons(),

                // Review button when delivered
                if (_isDelivered) ...[
                  _buildReviewButton(),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showRatingModal,
        icon: const Icon(Icons.star_rounded, size: 18),
        label: Text(
          'Leave a Review',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final orderNumber = _order?['order_number'] as String? ?? '';
    final status = _order?['status'] as String? ?? '';
    final isCompleted = status == 'completed' || _isDelivered;

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Track Order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (orderNumber.isNotEmpty)
                          Text(
                            '#$orderNumber',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.success
                          : AppTheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted
                          ? 'Completed'
                          : _steps[_currentStepIndex]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          'Track Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildEtaBanner() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _isEnRoute ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isEnRoute
                ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)]
                : [AppTheme.success, const Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isEnRoute ? AppTheme.primary : AppTheme.success)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isEnRoute
                    ? Icons.directions_bike_rounded
                    : Icons.schedule_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEnRoute ? 'Provider is on the way!' : 'Estimated Time',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _etaText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_isEnRoute)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
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

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) {
            final step = _steps[i];
            final isDone = i <= _currentStepIndex;
            final isActive = i == _currentStepIndex;
            final isLast = i == _steps.length - 1;

            return AnimatedBuilder(
              animation: _stepController,
              builder: (context, child) {
                final delay = i * 0.15;
                final progress =
                    (_stepController.value - delay).clamp(0.0, 1.0) /
                    (1.0 - delay).clamp(0.01, 1.0);
                return Opacity(
                  opacity: isDone ? progress.clamp(0.0, 1.0) : 0.4,
                  child: child,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + connector
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDone
                              ? (isActive ? AppTheme.primary : AppTheme.success)
                              : AppTheme.outlineVariant,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: isDone ? Colors.white : AppTheme.outline,
                          size: 20,
                        ),
                      ),
                      if (!isLast)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 2,
                          height: 36,
                          color: i < _currentStepIndex
                              ? AppTheme.success
                              : AppTheme.outlineVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Text
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isDone
                                  ? const Color(0xFF1A1C1E)
                                  : AppTheme.outline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step['sublabel'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDone
                                  ? const Color(0xFF74777F)
                                  : AppTheme.outline,
                            ),
                          ),
                          if (isActive && _tracking != null) ...[
                            const SizedBox(height: 4),
                            _buildStepTimestamp(step['key'] as String),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isDone && !isActive)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 18,
                      ),
                    ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepTimestamp(String stepKey) {
    String? ts;
    switch (stepKey) {
      case 'confirmed':
        ts = _tracking?['confirmed_at'] as String?;
        break;
      case 'provider_accepted':
        ts = _tracking?['accepted_at'] as String?;
        break;
      case 'en_route':
        ts = _tracking?['en_route_at'] as String?;
        break;
      case 'delivered':
        ts = _tracking?['delivered_at'] as String?;
        break;
    }
    if (ts == null) return const SizedBox.shrink();
    try {
      final dt = DateTime.parse(ts).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return Text(
        'Updated at $h:$m $period',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLocationCard() {
    final lat = (_tracking?['provider_lat'] as num?)?.toDouble();
    final lng = (_tracking?['provider_lng'] as num?)?.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Provider Location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map placeholder with provider pin
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                // Provider marker
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50 * _pulseAnim.value,
                                  height: 50 * _pulseAnim.value,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_bike_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _provider?['business_name'] as String? ??
                                'Provider',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Destination marker
                Positioned(
                  bottom: 30,
                  right: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      Text(
                        'You',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Coordinates overlay
                if (lat != null && lng != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    final order = _order!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            Icons.tag_rounded,
            'Order ID',
            '#${order['order_number'] ?? ''}',
          ),
          _detailRow(
            Icons.miscellaneous_services_rounded,
            'Service',
            order['service'] as String? ?? '',
          ),
          _detailRow(
            Icons.calendar_today_rounded,
            'Scheduled',
            '${order['scheduled_date'] ?? ''} at ${order['scheduled_time'] ?? ''}',
          ),
          _detailRow(
            Icons.currency_rupee_rounded,
            'Amount',
            order['amount'] as String? ?? '',
          ),
          if ((order['notes'] as String? ?? '').isNotEmpty)
            _detailRow(
              Icons.notes_rounded,
              'Notes',
              order['notes'] as String? ?? '',
            ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.outline),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF74777F),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    final provider = _provider!;
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final completedOrders = provider['completed_orders'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Provider',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: AppTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['business_name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider['owner_name'] as String? ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completedOrders jobs done',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callProvider,
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: Text(
              'Call Provider',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _whatsappProvider,
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text(
              'WhatsApp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MAP GRID PAINTER ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Major roads
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );

    // Minor roads
    for (double y = 0; y < size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 0; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Blocks
    final blockPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.05,
        size.width * 0.22,
        size.height * 0.27,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.05,
        size.width * 0.3,
        size.height * 0.27,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.38,
        size.width * 0.22,
        size.height * 0.24,
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

