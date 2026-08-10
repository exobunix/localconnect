import 'dart:async';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/service_rating_modal.dart';

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _provider;
  bool _isLoading = true;
  String? _bookingId;
  bool _ratingShown = false;

  RealtimeChannel? _bookingChannel;

  late AnimationController _pulseController;
  late AnimationController _stepController;
  late AnimationController _markerController;
  late Animation<double> _pulseAnim;

  int _etaMinutes = 18;
  Timer? _etaTimer;

  static const _stages = [
    {
      'key': 'pending',
      'label': 'Booking Placed',
      'sublabel': 'Waiting for provider to accept',
      'icon': Icons.pending_actions_rounded,
      'color': Color(0xFFF57C00),
    },
    {
      'key': 'accepted',
      'label': 'Accepted',
      'sublabel': 'Provider has accepted your booking',
      'icon': Icons.handshake_rounded,
      'color': Color(0xFF1565C0),
    },
    {
      'key': 'in_progress',
      'label': 'In Progress',
      'sublabel': 'Provider is on the way to you',
      'icon': Icons.directions_walk_rounded,
      'color': Color(0xFF6A1B9A),
    },
    {
      'key': 'completed',
      'label': 'Completed',
      'sublabel': 'Service completed successfully',
      'icon': Icons.verified_rounded,
      'color': Color(0xFF2E7D32),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _markerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _bookingId == null) {
      _bookingId = args['booking_id'] as String?;
      if (args['booking'] != null) {
        _booking = args['booking'] as Map<String, dynamic>;
        _isLoading = false;
        _loadProvider();
        _subscribeToRealtime();
        _startEtaCountdown();
        _stepController.forward();
      } else {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (_bookingId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.client
          .from('orders')
          .select(
            'id, created_at, scheduled_date, scheduled_time, status, amount, service, notes, provider_id, customer_id, order_number, payment_method, payment_status, service_providers(business_name, category, subcategory, phone, whatsapp, rating, completed_orders, owner_name)',
          )
          .eq('id', _bookingId!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _booking = data;
          _isLoading = false;
        });
        if (data != null) {
          _loadProvider();
          _subscribeToRealtime();
          _startEtaCountdown();
          _stepController.forward();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProvider() async {
    final providerId = _booking?['provider_id'] as String?;
    if (providerId == null) return;
    try {
      final p = await SupabaseService.instance.getProviderById(providerId);
      if (mounted) setState(() => _provider = p);
    } catch (_) {}
  }

  void _subscribeToRealtime() {
    if (_bookingId == null) return;
    _bookingChannel = SupabaseService.instance.client
        .channel('booking_status_$_bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _bookingId!,
          ),
          callback: (payload) {
            if (mounted) {
              final updated = payload.newRecord;
              if (updated.isNotEmpty) {
                final newStatus = updated['status'] as String?;
                final oldStatus = _booking?['status'] as String?;
                setState(() {
                  _booking = {...?_booking, ...updated};
                });
                _stepController
                  ..reset()
                  ..forward();
                // Fire push notification + in-app toast when status changes
                if (newStatus != null && newStatus != oldStatus) {
                  final providerName = _providerName.isNotEmpty
                      ? _providerName
                      : null;
                  NotificationService.instance.showBookingStatusNotification(
                    bookingId: _bookingId!,
                    status: newStatus,
                    providerName: providerName,
                  );
                  NotificationService.instance.showBookingStatusToast(
                    status: newStatus,
                    providerName: providerName,
                  );
                  // Show rating modal when order is completed
                  if (newStatus == 'completed' && !_ratingShown) {
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
  }

  Future<void> _showRatingModal() async {
    if (_bookingId == null) return;
    await showServiceRatingModal(
      context,
      bookingId: _bookingId!,
      providerName: _providerName.isNotEmpty ? _providerName : null,
      serviceName: _booking?['service'] as String?,
    );
  }

  void _startEtaCountdown() {
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _etaMinutes > 0 && _currentStageIndex < 3) {
        setState(() {
          _etaMinutes = math.max(0, _etaMinutes - 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _bookingChannel?.unsubscribe();
    _pulseController.dispose();
    _stepController.dispose();
    _markerController.dispose();
    _etaTimer?.cancel();
    super.dispose();
  }

  int get _currentStageIndex {
    final status = _booking?['status'] as String? ?? 'pending';
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'active': // DB enum value for accepted
        return 1;
      case 'in_progress':
      case 'upcoming': // DB enum value for in_progress/en_route
      case 'en_route':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  bool get _isCompleted => _currentStageIndex == 3;
  bool get _isActive => _currentStageIndex >= 1 && _currentStageIndex < 3;
  bool get _isCancelled => _currentStageIndex == -1;

  String get _etaText {
    if (_isCompleted) return 'Service Done';
    if (_isCancelled) return 'Cancelled';
    if (_etaMinutes <= 0) return 'Arriving now';
    if (_etaMinutes < 60) return '$_etaMinutes min away';
    final h = _etaMinutes ~/ 60;
    final m = _etaMinutes % 60;
    return m == 0 ? '${h}h away' : '${h}h ${m}m away';
  }

  String get _providerName {
    final sp = _booking?['service_providers'];
    if (sp is Map) return sp['business_name'] as String? ?? '';
    return _provider?['business_name'] as String? ?? 'Provider';
  }

  String get _providerPhone {
    final sp = _booking?['service_providers'];
    if (sp is Map) return sp['phone'] as String? ?? '';
    return _provider?['phone'] as String? ?? '';
  }

  double get _providerRating {
    final sp = _booking?['service_providers'];
    if (sp is Map) return (sp['rating'] as num?)?.toDouble() ?? 0.0;
    return (_provider?['rating'] as num?)?.toDouble() ?? 0.0;
  }

  int get _completedOrders {
    final sp = _booking?['service_providers'];
    if (sp is Map) return sp['completed_orders'] as int? ?? 0;
    return _provider?['completed_orders'] as int? ?? 0;
  }

  Future<void> _callProvider() async {
    final phone = _providerPhone;
    if (phone.isEmpty) {
      _showSnack('Provider phone number not available', AppTheme.warning);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _chatProvider() async {
    final phone = _providerPhone;
    if (phone.isEmpty) {
      _showSnack('Provider contact not available', AppTheme.warning);
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? _buildLoading()
          : _booking == null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _simpleAppBar('Track Booking'),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _simpleAppBar('Track Booking'),
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
              'Booking not found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadData,
              child: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _simpleAppBar(String title) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      title: Text(
        title,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCancelled) ...[
                  _buildCancelledBanner(),
                  const SizedBox(height: 16),
                ] else if (_isCompleted) ...[
                  _buildCompletedBanner(),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildEtaBanner(),
                  const SizedBox(height: 16),
                ],
                if (_isActive) ...[_buildMapCard(), const SizedBox(height: 16)],
                _buildProgressStages(),
                const SizedBox(height: 16),
                _buildBookingDetailsCard(),
                const SizedBox(height: 16),
                _buildProviderCard(),
                const SizedBox(height: 16),
                if (!_isCompleted && !_isCancelled) ...[
                  _buildContactButtons(),
                  const SizedBox(height: 16),
                ],
                if (_isCompleted) _buildReviewButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    final orderNumber =
        _booking?['order_number'] as String? ?? _bookingId ?? '';
    final stageIdx = _currentStageIndex;
    final stageLabel = stageIdx >= 0 && stageIdx < _stages.length
        ? _stages[stageIdx]['label'] as String
        : 'Cancelled';
    final stageColor = stageIdx >= 0 && stageIdx < _stages.length
        ? _stages[stageIdx]['color'] as Color
        : AppTheme.error;

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
                          'Track Booking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderNumber.isNotEmpty
                              ? '#${orderNumber.toString().toUpperCase()}'
                              : _booking?['service'] as String? ??
                                    'Service Booking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      color: stageColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stageLabel,
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
          'Track Booking',
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
    final isInProgress = _currentStageIndex == 2;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: isInProgress ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isInProgress
                ? [const Color(0xFF6A1B9A), const Color(0xFF9C27B0)]
                : [const Color(0xFF1565C0), const Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isInProgress ? const Color(0xFF6A1B9A) : AppTheme.primary)
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
                isInProgress
                    ? Icons.directions_walk_rounded
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
                    isInProgress
                        ? 'Provider is on the way!'
                        : 'Booking Accepted',
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
            if (isInProgress)
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

  Widget _buildCancelledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: AppTheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Cancelled',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This booking has been cancelled.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
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
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Completed!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thank you for using LocalConnect.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 28),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
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
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFF2E7D32),
                                const Color(0xFF69F0AE),
                                _pulseAnim.value,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEDE7F6), Color(0xFFE3F2FD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _BookingMapPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _markerController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RouteLinePainter(_markerController.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                  // Provider marker
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 50,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 52 * _pulseAnim.value,
                                height: 52 * _pulseAnim.value,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6A1B9A,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1B9A),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6A1B9A,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.engineering_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  // Provider name label
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 98,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _providerName.isNotEmpty
                              ? _providerName.split(' ').first
                              : 'Provider',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Destination marker
                  Positioned(
                    right: 50,
                    bottom: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.4,
                                ),
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
                        const SizedBox(height: 2),
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
                  // ETA chip
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _etaText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStages() {
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
                'Service Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              if (_currentStageIndex >= 0)
                Text(
                  '${math.min(_currentStageIndex + 1, _stages.length)} / ${_stages.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(_stages.length, (i) {
            final stage = _stages[i];
            final isDone = _currentStageIndex >= 0 && i <= _currentStageIndex;
            final isActive = _currentStageIndex >= 0 && i == _currentStageIndex;
            final isLast = i == _stages.length - 1;
            final stageColor = stage['color'] as Color;

            return AnimatedBuilder(
              animation: _stepController,
              builder: (context, child) {
                final delay = i * 0.12;
                final progress =
                    (_stepController.value - delay).clamp(0.0, 1.0) /
                    (1.0 - delay).clamp(0.01, 1.0);
                return Opacity(
                  opacity: isDone ? progress.clamp(0.0, 1.0) : 0.38,
                  child: child,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDone
                              ? (isActive ? stageColor : AppTheme.success)
                              : AppTheme.outlineVariant,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: stageColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          stage['icon'] as IconData,
                          color: isDone ? Colors.white : AppTheme.outline,
                          size: 20,
                        ),
                      ),
                      if (!isLast)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 2,
                          height: 38,
                          decoration: BoxDecoration(
                            color: i < _currentStageIndex
                                ? AppTheme.success
                                : AppTheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stage['label'] as String,
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
                              ),
                              if (isDone && !isActive)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                  size: 18,
                                ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stageColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Now',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: stageColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stage['sublabel'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDone
                                  ? const Color(0xFF74777F)
                                  : AppTheme.outline,
                            ),
                          ),
                        ],
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

  Widget _buildBookingDetailsCard() {
    final booking = _booking!;
    final sp = booking['service_providers'];
    final service =
        booking['service'] as String? ??
        (sp is Map ? sp['subcategory'] as String? ?? '' : '');
    final date = booking['scheduled_date'] as String? ?? '';
    final time = booking['scheduled_time'] as String? ?? '';
    final amount = booking['amount'];
    final amountStr = amount != null ? '₹${amount.toString()}' : '';
    final address = booking['address'] as String? ?? '';
    final notes = booking['notes'] as String? ?? '';
    final paymentMethod = booking['payment_method'] as String? ?? '';

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
                'Booking Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (service.isNotEmpty)
            _detailRow(
              Icons.miscellaneous_services_rounded,
              'Service',
              service,
            ),
          if (date.isNotEmpty)
            _detailRow(
              Icons.calendar_today_rounded,
              'Scheduled',
              time.isNotEmpty ? '$date at $time' : date,
            ),
          if (amountStr.isNotEmpty)
            _detailRow(Icons.currency_rupee_rounded, 'Amount', amountStr),
          if (paymentMethod.isNotEmpty)
            _detailRow(
              Icons.payment_rounded,
              'Payment',
              _capitalize(paymentMethod),
            ),
          if (address.isNotEmpty)
            _detailRow(Icons.location_on_rounded, 'Address', address),
          if (notes.isNotEmpty) _detailRow(Icons.notes_rounded, 'Notes', notes),
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
            width: 80,
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
    final sp = _booking?['service_providers'];
    final name = _providerName;
    final ownerName = sp is Map
        ? sp['owner_name'] as String? ?? ''
        : _provider?['owner_name'] as String? ?? '';
    final category = sp is Map
        ? sp['category'] as String? ?? ''
        : _provider?['category'] as String? ?? '';
    final rating = _providerRating;
    final jobs = _completedOrders;

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
                Icons.engineering_rounded,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Provider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ownerName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        ownerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _capitalize(category),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                          rating > 0 ? rating.toStringAsFixed(1) : '—',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF44474E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          jobs > 0 ? '$jobs jobs done' : 'New provider',
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
            onPressed: _chatProvider,
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─── MAP BACKGROUND PAINTER ───────────────────────────────────────────────────

class _BookingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.04,
        size.width * 0.24,
        size.height * 0.3,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.04,
        size.width * 0.28,
        size.height * 0.3,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.4,
        size.width * 0.24,
        size.height * 0.28,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.68,
        size.height * 0.4,
        size.width * 0.28,
        size.height * 0.28,
      ),
      blockPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.36),
      Offset(size.width, size.height * 0.36),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, 0),
      Offset(size.width * 0.66, size.height),
      roadPaint,
    );

    for (double y = 0; y < size.height; y += size.height / 7) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
    for (double x = 0; x < size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── ANIMATED ROUTE LINE PAINTER ─────────────────────────────────────────────

class _RouteLinePainter extends CustomPainter {
  final double progress;
  _RouteLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFF6A1B9A).withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.42);
    path.cubicTo(
      size.width * 0.6,
      size.height * 0.36,
      size.width * 0.68,
      size.height * 0.55,
      size.width * 0.82,
      size.height * 0.72,
    );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final len = metric.length;
      const dashLen = 12.0;
      const gapLen = 8.0;
      double dist = (progress * (dashLen + gapLen)) % (dashLen + gapLen);
      while (dist < len) {
        final end = math.min(dist + dashLen, len);
        canvas.drawPath(metric.extractPath(dist, end), dashPaint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter old) =>
      old.progress != progress;
}
