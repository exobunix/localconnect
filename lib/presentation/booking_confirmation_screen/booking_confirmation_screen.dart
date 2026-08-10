import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/share_widgets.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String? _razorpayPaymentId;
  String? _razorpayOrderId;
  bool _fetchingPayment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final paymentMethod = args['paymentMethod'] as String? ?? '';
    final orderId =
        args['orderId'] as String? ?? args['order_id'] as String? ?? '';
    if (paymentMethod == 'razorpay' &&
        orderId.isNotEmpty &&
        !_fetchingPayment) {
      _fetchRazorpayDetails(orderId);
    }
  }

  Future<void> _fetchRazorpayDetails(String orderId) async {
    setState(() => _fetchingPayment = true);
    try {
      final result = await SupabaseService.instance.client
          .from('orders')
          .select('razorpay_payment_id, razorpay_order_id')
          .eq('id', orderId)
          .maybeSingle();
      if (mounted && result != null) {
        setState(() {
          _razorpayPaymentId = result['razorpay_payment_id'] as String?;
          _razorpayOrderId = result['razorpay_order_id'] as String?;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _fetchingPayment = false);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final orderNumber = args['orderNumber'] as String? ?? '';
    final service = args['service'] as String? ?? 'Service';
    final providerName = args['providerName'] as String? ?? '';
    final amount = args['amount'] as String? ?? '';
    final scheduledDate = args['scheduledDate'] as String? ?? '';
    final scheduledTime = args['scheduledTime'] as String? ?? '';
    final paymentMethod = args['paymentMethod'] as String? ?? 'cash';
    final address = args['address'] as String? ?? '';
    final orderId =
        args['orderId'] as String? ?? args['order_id'] as String? ?? '';
    final estimatedMinutes = args['estimatedMinutes'] as int? ?? 45;
    final providerPhone = args['providerPhone'] as String? ?? '';
    final providerRating = args['providerRating'] as double? ?? 4.8;
    final providerJobsCount = args['providerJobsCount'] as int? ?? 120;

    final isRazorpay = paymentMethod == 'razorpay';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Success animation container
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isRazorpay
                          ? 'Payment & Booking Confirmed!'
                          : 'Booking Confirmed!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRazorpay
                          ? 'Payment received. Your booking is confirmed\nand the provider will be notified.'
                          : 'Your booking has been placed successfully.\nThe provider will confirm shortly.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF44474E),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (orderNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Order #$orderNumber',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // ── Razorpay Payment Receipt ──────────────────────────
                    if (isRazorpay) ...[
                      _RazorpayReceiptCard(
                        orderNumber: orderNumber,
                        orderId: orderId,
                        amount: amount,
                        service: service,
                        providerName: providerName,
                        scheduledDate: scheduledDate,
                        scheduledTime: scheduledTime,
                        razorpayPaymentId: _razorpayPaymentId,
                        razorpayOrderId: _razorpayOrderId,
                        isFetching: _fetchingPayment,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Estimated Delivery Time Card ──────────────────────
                    _EstimatedTimeCard(estimatedMinutes: estimatedMinutes),
                    const SizedBox(height: 16),

                    // ── Delivery Address Card ─────────────────────────────
                    if (address.isNotEmpty) ...[
                      _DeliveryAddressCard(address: address),
                      const SizedBox(height: 16),
                    ],

                    // ── Provider Assignment Card ──────────────────────────
                    if (providerName.isNotEmpty) ...[
                      _ProviderAssignmentCard(
                        providerName: providerName,
                        service: service,
                        providerPhone: providerPhone,
                        rating: providerRating,
                        jobsCount: providerJobsCount,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Booking details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Icons.home_repair_service_rounded,
                            label: 'Service',
                            value: service,
                            iconColor: AppTheme.primary,
                          ),
                          if (providerName.isNotEmpty) ...[
                            const _Divider(),
                            _DetailRow(
                              icon: Icons.person_rounded,
                              label: 'Provider',
                              value: providerName,
                              iconColor: AppTheme.secondary,
                            ),
                          ],
                          if (amount.isNotEmpty) ...[
                            const _Divider(),
                            _DetailRow(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Amount',
                              value: amount,
                              iconColor: AppTheme.success,
                              valueStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                          if (scheduledDate.isNotEmpty) ...[
                            const _Divider(),
                            _DetailRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Date',
                              value: scheduledDate,
                              iconColor: AppTheme.warning,
                            ),
                          ],
                          if (scheduledTime.isNotEmpty) ...[
                            const _Divider(),
                            _DetailRow(
                              icon: Icons.access_time_rounded,
                              label: 'Time',
                              value: scheduledTime,
                              iconColor: AppTheme.info,
                            ),
                          ],
                          const _Divider(),
                          _DetailRow(
                            icon: Icons.payment_rounded,
                            label: 'Payment',
                            value: _paymentLabel(paymentMethod),
                            iconColor: const Color(0xFF6A1B9A),
                          ),
                          if (address.isNotEmpty) ...[
                            const _Divider(),
                            _DetailRow(
                              icon: Icons.location_on_rounded,
                              label: 'Address',
                              value: address,
                              iconColor: AppTheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // What's next card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.infoContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.info,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "What's Next?",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _NextStep(
                            number: '1',
                            text: 'Provider reviews and accepts your booking',
                          ),
                          const SizedBox(height: 8),
                          _NextStep(
                            number: '2',
                            text: 'You receive a confirmation notification',
                          ),
                          const SizedBox(height: 8),
                          _NextStep(
                            number: '3',
                            text: 'Provider arrives at scheduled date & time',
                          ),
                          const SizedBox(height: 8),
                          _NextStep(
                            number: '4',
                            text: 'Service completed — rate your experience',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Share Prompt ──────────────────────────────────────
                    const SuccessSharePromptWidget(
                      title: 'Enjoying LocalConnect?',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Direct Order Tracking Link ────────────────────────
                  if (orderId.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orderStatusScreen,
                            arguments: {'order_id': orderId},
                          );
                        },
                        icon: const Icon(Icons.location_on_rounded, size: 18),
                        label: Text(
                          'Track Live Order Status',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.orderManagementScreen,
                          (route) =>
                              route.settings.name == AppRoutes.homeScreen,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orderId.isNotEmpty
                            ? AppTheme.primaryContainer
                            : AppTheme.primary,
                        foregroundColor: orderId.isNotEmpty
                            ? AppTheme.primaryDark
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View All Orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.homeScreen,
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

  String _paymentLabel(String method) {
    switch (method) {
      case 'razorpay':
        return 'Razorpay (Paid Online)';
      case 'upi':
        return 'UPI / QR Code';
      case 'card':
        return 'Credit / Debit Card';
      case 'netbanking':
        return 'Net Banking';
      default:
        return 'Cash on Delivery';
    }
  }
}

// ── Razorpay Payment Receipt Card ─────────────────────────────────────────────
class _RazorpayReceiptCard extends StatelessWidget {
  final String orderNumber;
  final String orderId;
  final String amount;
  final String service;
  final String providerName;
  final String scheduledDate;
  final String scheduledTime;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final bool isFetching;

  const _RazorpayReceiptCard({
    required this.orderNumber,
    required this.orderId,
    required this.amount,
    required this.service,
    required this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    required this.isFetching,
  });

  String _formattedNow() {
    final dt = DateTime.now();
    final months = [
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
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Secured by Razorpay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PAID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Amount highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Amount Paid',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF546E7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount.isNotEmpty ? amount : '—',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),

          // Receipt details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ReceiptRow(
                  label: 'Order ID',
                  value: orderNumber.isNotEmpty ? '#$orderNumber' : '—',
                  icon: Icons.tag_rounded,
                  iconColor: const Color(0xFF1565C0),
                ),
                const _ReceiptDivider(),
                _ReceiptRow(
                  label: 'Service',
                  value: service.isNotEmpty ? service : '—',
                  icon: Icons.home_repair_service_rounded,
                  iconColor: AppTheme.primary,
                ),
                if (providerName.isNotEmpty) ...[
                  const _ReceiptDivider(),
                  _ReceiptRow(
                    label: 'Provider',
                    value: providerName,
                    icon: Icons.person_rounded,
                    iconColor: AppTheme.secondary,
                  ),
                ],
                const _ReceiptDivider(),
                _ReceiptRow(
                  label: 'Date & Time',
                  value: scheduledDate.isNotEmpty
                      ? '$scheduledDate${scheduledTime.isNotEmpty ? ', $scheduledTime' : ''}'
                      : _formattedNow(),
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppTheme.warning,
                ),
                const _ReceiptDivider(),
                _ReceiptRow(
                  label: 'Payment Date',
                  value: _formattedNow(),
                  icon: Icons.access_time_rounded,
                  iconColor: AppTheme.info,
                ),
                const _ReceiptDivider(),
                _ReceiptRow(
                  label: 'Payment Gateway',
                  value: 'Razorpay',
                  icon: Icons.payment_rounded,
                  iconColor: const Color(0xFF3395FF),
                ),
                if (isFetching) ...[
                  const _ReceiptDivider(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF546E7A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          color: Color(0xFF546E7A),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment ID',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF90A4AE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Fetching...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF90A4AE),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (razorpayPaymentId != null &&
                    razorpayPaymentId!.isNotEmpty) ...[
                  const _ReceiptDivider(),
                  _ReceiptRow(
                    label: 'Payment ID',
                    value: razorpayPaymentId!,
                    icon: Icons.receipt_rounded,
                    iconColor: const Color(0xFF546E7A),
                    isSmall: true,
                  ),
                ],
                if (razorpayOrderId != null && razorpayOrderId!.isNotEmpty) ...[
                  const _ReceiptDivider(),
                  _ReceiptRow(
                    label: 'Razorpay Order ID',
                    value: razorpayOrderId!,
                    icon: Icons.confirmation_number_rounded,
                    iconColor: const Color(0xFF6A1B9A),
                    isSmall: true,
                  ),
                ],
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFE),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: Color(0xFF90A4AE),
                ),
                const SizedBox(width: 5),
                Text(
                  'Payment secured & verified by Razorpay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF90A4AE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isSmall;

  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                  letterSpacing: isSmall ? 0.3 : 0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFF0F4F8)),
    );
  }
}

// ── Estimated Delivery Time Card ─────────────────────────────────────────────
class _EstimatedTimeCard extends StatelessWidget {
  final int estimatedMinutes;

  const _EstimatedTimeCard({required this.estimatedMinutes});

  String get _etaLabel {
    if (estimatedMinutes <= 0) return 'Arriving soon';
    if (estimatedMinutes < 60) return '$estimatedMinutes min';
    final h = estimatedMinutes ~/ 60;
    final m = estimatedMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.08),
            const Color(0xFF42A5F5).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppTheme.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Arrival',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF546E7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _etaLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.info,
                  ),
                ),
                Text(
                  'Provider will arrive at your location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.info,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Live',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery Address Card ─────────────────────────────────────────────────────
class _DeliveryAddressCard extends StatelessWidget {
  final String address;

  const _DeliveryAddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppTheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF90A4AE),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Provider Assignment Card ──────────────────────────────────────────────────
class _ProviderAssignmentCard extends StatelessWidget {
  final String providerName;
  final String service;
  final String providerPhone;
  final double rating;
  final int jobsCount;

  const _ProviderAssignmentCard({
    required this.providerName,
    required this.service,
    required this.providerPhone,
    required this.rating,
    required this.jobsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    providerName.isNotEmpty
                        ? providerName[0].toUpperCase()
                        : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            providerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF9A825),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$jobsCount jobs completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (providerPhone.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEF0F3)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppTheme.success,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Verified Provider',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ContactButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: AppTheme.primary,
                        onTap: () {},
                      ),
                      const SizedBox(width: 4),
                      _ContactButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        color: AppTheme.secondary,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    valueStyle ??
                    GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFEEF0F3)),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String number;
  final String text;

  const _NextStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppTheme.info,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF0277BD),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
