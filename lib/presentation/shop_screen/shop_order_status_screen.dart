import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ShopOrderStatusScreen extends StatefulWidget {
  const ShopOrderStatusScreen({super.key});

  @override
  State<ShopOrderStatusScreen> createState() => _ShopOrderStatusScreenState();
}

class _ShopOrderStatusScreenState extends State<ShopOrderStatusScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _provider;
  bool _isLoading = true;
  String? _orderId;
  String? _orderNumber;
  String? _providerName;
  String? _subcategoryName;
  double _grandTotal = 0;
  String _deliveryType = 'home_delivery';
  String _paymentMethod = 'cod';
  String _currentStep =
      'confirmed'; // confirmed | preparing | out_for_delivery | delivered
  int _etaMinutes = 35;
  DateTime? _confirmedAt;
  DateTime? _preparingAt;
  DateTime? _outForDeliveryAt;
  DateTime? _deliveredAt;

  RealtimeChannel? _realtimeChannel;

  late AnimationController _pulseController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnim;

  // ── Shop-specific steps ────────────────────────────────────────────────────
  static const _steps = [
    {
      'key': 'confirmed',
      'label': 'Order Confirmed',
      'sublabel': 'Your order has been received by the shop',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'key': 'preparing',
      'label': 'Preparing',
      'sublabel': 'Shop is packing your items',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'key': 'out_for_delivery',
      'label': 'Out for Delivery',
      'sublabel': 'Your order is on the way',
      'icon': Icons.delivery_dining_rounded,
    },
    {
      'key': 'delivered',
      'label': 'Delivered',
      'sublabel': 'Order delivered successfully',
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
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _orderId == null) {
      _orderId = args['orderId'] as String? ?? args['order_id'] as String?;
      _orderNumber = args['orderNumber'] as String?;
      _providerName = args['providerName'] as String? ?? 'Shop';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Shop';
      _grandTotal = (args['grandTotal'] as num?)?.toDouble() ?? 0;
      _deliveryType = args['deliveryType'] as String? ?? 'home_delivery';
      _paymentMethod = args['paymentMethod'] as String? ?? 'cod';
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Try to load from Supabase if we have an orderId
    if (_orderId != null && _orderId!.isNotEmpty) {
      try {
        final order = await SupabaseService.instance.getOrderById(_orderId!);
        if (order != null) {
          _order = order;
          final status = order['status'] as String? ?? 'confirmed';
          _currentStep = _mapOrderStatusToStep(status);
          _orderNumber ??= order['order_number'] as String?;
          _grandTotal = (order['amount'] as num?)?.toDouble() ?? _grandTotal;

          if (order['provider_id'] != null) {
            _provider = await SupabaseService.instance.getProviderById(
              order['provider_id'] as String,
            );
            _providerName =
                _provider?['business_name'] as String? ??
                _provider?['full_name'] as String? ??
                _providerName;
          }
        }
      } catch (_) {}
    }

    // Set demo timestamps based on current step
    _confirmedAt = DateTime.now().subtract(const Duration(minutes: 5));
    if (_currentStepIndex >= 1) {
      _preparingAt = DateTime.now().subtract(const Duration(minutes: 3));
    }
    if (_currentStepIndex >= 2) {
      _outForDeliveryAt = DateTime.now().subtract(const Duration(minutes: 1));
      _etaMinutes = 15;
    }
    if (_currentStepIndex >= 3) {
      _deliveredAt = DateTime.now();
      _etaMinutes = 0;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _stepController.forward();
      _subscribeToRealtime();
    }
  }

  String _mapOrderStatusToStep(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 'confirmed';
      case 'in_progress':
      case 'preparing':
        return 'preparing';
      case 'en_route':
      case 'out_for_delivery':
        return 'out_for_delivery';
      case 'completed':
      case 'delivered':
        return 'delivered';
      default:
        return 'confirmed';
    }
  }

  void _subscribeToRealtime() {
    if (_orderId == null || _orderId!.isEmpty) return;
    _realtimeChannel = SupabaseService.instance.client
        .channel('shop_order_status_$_orderId')
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
                final newStatus = updated['status'] as String? ?? '';
                final newStep = _mapOrderStatusToStep(newStatus);
                if (newStep != _currentStep) {
                  setState(() {
                    _currentStep = newStep;
                    _order = {...?_order, ...updated};
                    _updateTimestamps(newStep);
                  });
                  _stepController
                    ..reset()
                    ..forward();
                }
              }
            }
          },
        )
        .subscribe();
  }

  void _updateTimestamps(String step) {
    final now = DateTime.now();
    switch (step) {
      case 'preparing':
        _preparingAt = now;
        _etaMinutes = 30;
        break;
      case 'out_for_delivery':
        _outForDeliveryAt = now;
        _etaMinutes = 15;
        break;
      case 'delivered':
        _deliveredAt = now;
        _etaMinutes = 0;
        break;
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _pulseController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  // ── Computed helpers ───────────────────────────────────────────────────────
  int get _currentStepIndex {
    switch (_currentStep) {
      case 'confirmed':
        return 0;
      case 'preparing':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  bool get _isDelivered => _currentStepIndex == 3;
  bool get _isOutForDelivery => _currentStepIndex == 2;

  String get _etaText {
    if (_isDelivered) return 'Delivered!';
    if (_etaMinutes <= 0) return 'Arriving now';
    if (_etaMinutes < 60) return '$_etaMinutes min away';
    final h = _etaMinutes ~/ 60;
    final m = _etaMinutes % 60;
    return m == 0 ? '${h}h away' : '${h}h ${m}m away';
  }

  String get _stepStatusLabel {
    switch (_currentStep) {
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Confirmed';
    }
  }

  DateTime? _getTimestampForStep(String key) {
    switch (key) {
      case 'confirmed':
        return _confirmedAt;
      case 'preparing':
        return _preparingAt;
      case 'out_for_delivery':
        return _outForDeliveryAt;
      case 'delivered':
        return _deliveredAt;
      default:
        return null;
    }
  }

  // ── Phone / WhatsApp ───────────────────────────────────────────────────────
  Future<void> _callProvider() async {
    final phone = _provider?['phone'] as String? ?? '';
    if (phone.isEmpty) {
      if (mounted) {
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
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsappProvider() async {
    final phone =
        _provider?['whatsapp'] as String? ??
        _provider?['phone'] as String? ??
        '';
    if (phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETA Banner
                  if (!_isDelivered) ...[
                    _buildEtaBanner(),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildDeliveredBanner(),
                    const SizedBox(height: 16),
                  ],

                  // Timeline
                  _buildTimeline(),
                  const SizedBox(height: 16),

                  // Delivery Location Map
                  if (_isOutForDelivery || _isDelivered) ...[
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                  ],

                  // Order Summary Card
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),

                  // Provider Contact Card
                  _buildProviderContactCard(),
                  const SizedBox(height: 16),

                  // Action Buttons
                  if (!_isDelivered) _buildContactButtons(),
                  if (_isDelivered) _buildPostDeliveryActions(),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
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
                          'Track Your Order',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (_orderNumber != null)
                          Text(
                            '#$_orderNumber • $_subcategoryName',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
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
                      color: _isDelivered
                          ? AppTheme.success
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isDelivered) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          _stepStatusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
    final Color bannerColor = _isOutForDelivery
        ? const Color(0xFF1565C0)
        : _currentStepIndex == 1
        ? const Color(0xFFF57C00)
        : AppTheme.success;
    final Color bannerEnd = _isOutForDelivery
        ? const Color(0xFF1E88E5)
        : _currentStepIndex == 1
        ? const Color(0xFFFF9800)
        : const Color(0xFF43A047);
    final IconData bannerIcon = _isOutForDelivery
        ? Icons.delivery_dining_rounded
        : _currentStepIndex == 1
        ? Icons.inventory_2_outlined
        : Icons.check_circle_outline_rounded;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _isOutForDelivery ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bannerColor, bannerEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.35),
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
              child: Icon(bannerIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOutForDelivery
                        ? 'Delivery partner is on the way!'
                        : _currentStepIndex == 1
                        ? 'Shop is packing your items'
                        : 'Order confirmed!',
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
            if (_isOutForDelivery)
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

  Widget _buildDeliveredBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.3),
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
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Delivered!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your items have been delivered successfully',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${_currentStepIndex + 1} of 4',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) {
            final step = _steps[i];
            final isDone = i <= _currentStepIndex;
            final isActive = i == _currentStepIndex;
            final isLast = i == _steps.length - 1;
            final ts = _getTimestampForStep(step['key'] as String);

            return AnimatedBuilder(
              animation: _stepController,
              builder: (context, child) {
                final delay = i * 0.15;
                final progress =
                    (_stepController.value - delay).clamp(0.0, 1.0) /
                    (1.0 - delay).clamp(0.01, 1.0);
                return Opacity(
                  opacity: isDone ? progress.clamp(0.0, 1.0) : 0.35,
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDone
                              ? (isActive ? AppTheme.primary : AppTheme.success)
                              : const Color(0xFFE8EAED),
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 14,
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
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: i < _currentStepIndex
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.success,
                                      AppTheme.success,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: i < _currentStepIndex
                                ? null
                                : const Color(0xFFE8EAED),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Text content
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
                          if (ts != null) ...[
                            const SizedBox(height: 4),
                            _buildTimestampChip(ts),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Status badge
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: isDone && !isActive
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.success,
                            size: 18,
                          )
                        : isActive
                        ? Container(
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
                          )
                        : const SizedBox(width: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimestampChip(DateTime dt) {
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
  }

  Widget _buildLocationCard() {
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
                  'Delivery Location',
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
                        _isDelivered ? 'Done' : 'Live',
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
          // Map visual
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Container(
                  height: 190,
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
                // Delivery partner marker (animated)
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
                                if (!_isDelivered)
                                  Container(
                                    width: 52 * _pulseAnim.value,
                                    height: 52 * _pulseAnim.value,
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
                                    color: _isDelivered
                                        ? AppTheme.success
                                        : AppTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isDelivered
                                                    ? AppTheme.success
                                                    : AppTheme.primary)
                                                .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isDelivered
                                        ? Icons.verified_rounded
                                        : Icons.delivery_dining_rounded,
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
                            color: _isDelivered
                                ? AppTheme.success
                                : AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isDelivered
                                ? 'Delivered'
                                : _providerName ?? 'Shop',
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
                // Home marker
                Positioned(
                  bottom: 28,
                  right: 55,
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
                // Shop marker
                Positioned(
                  top: 28,
                  left: 55,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57C00),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF57C00,
                              ).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      Text(
                        'Shop',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
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
                'Order Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow(
            Icons.tag_rounded,
            'Order ID',
            '#${_orderNumber ?? '---'}',
          ),
          _summaryRow(
            Icons.storefront_rounded,
            'Shop',
            _providerName ?? 'Shop',
          ),
          _summaryRow(
            Icons.category_rounded,
            'Category',
            _subcategoryName ?? '---',
          ),
          _summaryRow(
            Icons.currency_rupee_rounded,
            'Total Amount',
            '₹${_grandTotal.toStringAsFixed(0)}',
            isBold: true,
          ),
          _summaryRow(
            Icons.local_shipping_rounded,
            'Delivery',
            _deliveryType == 'home_delivery' ? 'Home Delivery' : 'Self Pickup',
          ),
          _summaryRow(
            Icons.payment_rounded,
            'Payment',
            _paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online Payment',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.outline),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
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
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderContactCard() {
    final name =
        _provider?['business_name'] as String? ??
        _provider?['full_name'] as String? ??
        _providerName ??
        'Shop';
    final phone = _provider?['phone'] as String? ?? '';
    final address = _provider?['address'] as String? ?? '';
    final rating = (_provider?['average_rating'] as num?)?.toDouble() ?? 4.5;
    final photoUrl = _provider?['profile_photo_url'] as String?;

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
                Icons.storefront_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Provider Details',
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
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.storefront_rounded,
                            color: AppTheme.primary,
                            size: 26,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.storefront_rounded,
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
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFC107),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle,
                            size: 4,
                            color: Color(0xFF74777F),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Color(0xFF74777F),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Quick contact buttons
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: AppTheme.success,
                  onTap: _callProvider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: _whatsappProvider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactButton(
                  icon: Icons.message_rounded,
                  label: 'Message',
                  color: AppTheme.primary,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.chatListScreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
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
      ),
    );
  }

  Widget _buildContactButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _callProvider,
            icon: const Icon(Icons.call_rounded, size: 16),
            label: Text(
              'Call Shop',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.success,
              side: const BorderSide(color: AppTheme.success),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _whatsappProvider,
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: Text(
              'WhatsApp',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostDeliveryActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.reviewSubmissionScreen,
              arguments: {
                'order_id': _orderId,
                'provider_id': _provider?['id'],
                'provider_name': _providerName,
              },
            ),
            icon: const Icon(Icons.star_rounded, size: 18),
            label: Text(
              'Rate Your Order',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.shopHomeScreen,
              (route) => route.settings.name == AppRoutes.homeScreen,
            ),
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: Text(
              'Shop Again',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Map Grid Painter ──────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.35)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Road lines
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.45),
      Offset(size.width, size.height * 0.45),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );

    // Dotted route line
    final dotPaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double x = size.width * 0.18;
    final y1 = size.height * 0.3;
    final y2 = size.height * 0.45;
    final x2 = size.width * 0.72;
    while (x < x2) {
      canvas.drawLine(Offset(x, y1), Offset(x + 6, y1), dotPaint);
      x += 12;
    }
    double y = y1;
    while (y < y2) {
      canvas.drawLine(Offset(x2, y), Offset(x2, y + 6), dotPaint);
      y += 12;
    }
    double xr = x2;
    while (xr < size.width * 0.82) {
      canvas.drawLine(Offset(xr, y2), Offset(xr + 6, y2), dotPaint);
      xr += 12;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
