import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/razorpay_service.dart';
import '../../widgets/razorpay_payment_widget.dart';

class CustomerPaymentScreen extends StatefulWidget {
  const CustomerPaymentScreen({super.key});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMethod = 'razorpay';
  bool _isProcessing = false;
  bool _agreedToTerms = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Card form controllers
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _onMethodChanged(String method) {
    setState(() => _selectedMethod = method);
    _animController.reset();
    _animController.forward();
  }

  /// Called when Razorpay payment succeeds — transaction already recorded
  /// by RazorpayPaymentWidget; just navigate to summary.
  void _onRazorpaySuccess(Map<String, dynamic> args, double totalAmount) {
    if (!mounted) return;
    final amount =
        args['amount'] as String? ?? '₹${totalAmount.toStringAsFixed(0)}';
    final service = args['service'] as String? ?? 'Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final orderNumber =
        args['orderNumber'] as String? ??
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    _showSnack('Payment of $amount confirmed via Razorpay!', isError: false);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingSummaryScreen,
        arguments: {
          ...args,
          'orderNumber': orderNumber,
          'paymentStatus': 'Paid',
          'paymentMethod': 'Razorpay',
          'service': service,
          'providerName': providerName,
          'amount': amount,
        },
      );
    });
  }

  void _onRazorpayFailed(String error) {
    if (!mounted) return;
    _showSnack('Payment failed: $error', isError: true);
  }

  /// Confirm payment for UPI / Card / Wallet methods (non-Razorpay)
  void _confirmPayment(Map<String, dynamic> args, double totalAmount) async {
    if (!_agreedToTerms) {
      _showSnack('Please agree to the terms before proceeding.', isError: true);
      return;
    }
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final amountStr =
        args['amount'] as String? ?? '₹${totalAmount.toStringAsFixed(0)}';
    final service = args['service'] as String? ?? 'Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final orderNumber =
        args['orderNumber'] as String? ??
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Record transaction in Supabase for non-Razorpay methods
    await RazorpayService.instance.recordTransaction(
      razorpayPaymentId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      amount: totalAmount,
      paymentType: 'one_time',
      description: 'Payment for $service by $providerName',
      metadata: {
        'method': _selectedMethod,
        'service': service,
        'provider': providerName,
        'order_number': orderNumber,
      },
    );

    _showSnack('Payment of $amountStr confirmed!', isError: false);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.bookingSummaryScreen,
      arguments: {
        ...args,
        'orderNumber': orderNumber,
        'paymentStatus': 'Paid',
        'paymentMethod': _selectedMethod,
        'service': service,
        'providerName': providerName,
        'amount': amountStr,
      },
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final service = args['service'] as String? ?? 'Home Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final amount = args['amount'] as String? ?? '₹500';
    final scheduledDate = args['scheduledDate'] as String? ?? '';
    final scheduledTime = args['scheduledTime'] as String? ?? '';
    final address = args['address'] as String? ?? '';
    final category = args['category'] as String? ?? '';

    // Parse numeric amount for display
    final numericAmount =
        double.tryParse(amount.replaceAll('₹', '').replaceAll(',', '')) ?? 0.0;
    final platformFee = (numericAmount * 0.02).clamp(5.0, 50.0);
    final totalAmount = numericAmount + platformFee;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Payment',
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
      body: Column(
        children: [
          // Progress indicator strip
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _StepDot(label: 'Book', done: true),
                _StepLine(done: true),
                _StepDot(label: 'Pay', active: true),
                _StepLine(done: false),
                _StepDot(label: 'Confirm', done: false),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Booking Summary Card ──────────────────────────────
                  _BookingSummaryCard(
                    service: service,
                    providerName: providerName,
                    scheduledDate: scheduledDate,
                    scheduledTime: scheduledTime,
                    address: address,
                    category: category,
                  ),
                  const SizedBox(height: 16),

                  // ── Amount Breakdown Card ─────────────────────────────
                  _AmountBreakdownCard(
                    serviceAmount: numericAmount,
                    platformFee: platformFee,
                    totalAmount: totalAmount,
                  ),
                  const SizedBox(height: 16),

                  // ── Payment Method Selection ──────────────────────────
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PaymentMethodSelector(
                    selected: _selectedMethod,
                    onChanged: _onMethodChanged,
                  ),
                  const SizedBox(height: 14),

                  // ── Payment Method Detail Panel ───────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildMethodPanel(totalAmount, args),
                  ),
                  const SizedBox(height: 16),

                  // ── Terms Checkbox (hidden for Razorpay — SDK handles consent) ──
                  if (_selectedMethod != 'razorpay') ...[
                    _TermsRow(
                      agreed: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                    const SizedBox(height: 20),

                    // ── Confirm Button (non-Razorpay) ─────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _confirmPayment(args, totalAmount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primary.withAlpha(
                            153,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay ₹${totalAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '256-bit SSL encrypted & secure',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodPanel(double totalAmount, Map<String, dynamic> args) {
    switch (_selectedMethod) {
      case 'razorpay':
        return _RazorpayPanel(
          amount: totalAmount,
          args: args,
          onSuccess: () => _onRazorpaySuccess(args, totalAmount),
          onFailed: _onRazorpayFailed,
        );
      case 'upi':
        return _UpiPanel(amount: totalAmount);
      case 'card':
        return _CardPanel(
          cardNumberCtrl: _cardNumberCtrl,
          cardNameCtrl: _cardNameCtrl,
          expiryCtrl: _expiryCtrl,
          cvvCtrl: _cvvCtrl,
        );
      case 'wallet':
        return _WalletPanel(amount: totalAmount);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Razorpay Panel ────────────────────────────────────────────────────────────

class _RazorpayPanel extends StatelessWidget {
  final double amount;
  final Map<String, dynamic> args;
  final VoidCallback onSuccess;
  final Function(String) onFailed;

  const _RazorpayPanel({
    required this.amount,
    required this.args,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  Widget build(BuildContext context) {
    final service = args['service'] as String? ?? 'Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final orderId = args['orderId'] as String?;
    final providerId = args['providerId'] as String?;

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
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Color(0xFF1565C0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay via Razorpay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    'UPI • Cards • Net Banking • Wallets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          const SizedBox(height: 14),

          // Amount summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Web notice
          if (kIsWeb) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    color: Color(0xFFF57C00),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Razorpay checkout is available on the mobile app. Download the app to pay.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFFF57C00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Razorpay pay button
          RazorpayPaymentWidget(
            amount: amount,
            description: 'Payment for $service by $providerName',
            paymentType: 'one_time',
            orderId: orderId,
            providerId: providerId,
            notes: {'service': service, 'provider': providerName},
            onPaymentSuccess: onSuccess,
            onPaymentFailed: onFailed,
          ),

          const SizedBox(height: 12),
          // Accepted payment icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PayBadge(label: 'UPI', color: const Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              _PayBadge(label: 'VISA', color: const Color(0xFF1A1F71)),
              const SizedBox(width: 6),
              _PayBadge(label: 'MC', color: const Color(0xFFEB001B)),
              const SizedBox(width: 6),
              _PayBadge(label: 'RuPay', color: const Color(0xFF006A4E)),
              const SizedBox(width: 6),
              _PayBadge(label: 'NetBanking', color: const Color(0xFF0F4C81)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Step Progress Dot ─────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;

  const _StepDot({required this.label, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? Colors.white : Colors.white.withAlpha(77),
          ),
          child: Center(
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  )
                : Text(
                    active ? '●' : '○',
                    style: TextStyle(
                      fontSize: active ? 10 : 12,
                      color: active
                          ? AppTheme.primary
                          : Colors.white.withAlpha(153),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: done || active ? Colors.white : Colors.white.withAlpha(128),
            fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done ? Colors.white : Colors.white.withAlpha(77),
      ),
    );
  }
}

// ── Booking Summary Card ──────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final String service;
  final String providerName;
  final String scheduledDate;
  final String scheduledTime;
  final String address;
  final String category;

  const _BookingSummaryCard({
    required this.service,
    required this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.address,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.home_repair_service_rounded,
                  label: 'Service',
                  value: service,
                  iconColor: AppTheme.primary,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon: Icons.person_rounded,
                  label: 'Provider',
                  value: providerName,
                  iconColor: AppTheme.secondary,
                ),
                if (scheduledDate.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value:
                        scheduledDate +
                        (scheduledTime.isNotEmpty ? '  •  $scheduledTime' : ''),
                    iconColor: AppTheme.catEvents,
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: address,
                    iconColor: AppTheme.error,
                  ),
                ],
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: category,
                    iconColor: AppTheme.catRepair,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF74777F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
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

// ── Amount Breakdown Card ─────────────────────────────────────────────────────

class _AmountBreakdownCard extends StatelessWidget {
  final double serviceAmount;
  final double platformFee;
  final double totalAmount;

  const _AmountBreakdownCard({
    required this.serviceAmount,
    required this.platformFee,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Amount Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          _AmountRow(
            label: 'Service Charge',
            amount: '₹${serviceAmount.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Platform Fee',
            amount: '₹${platformFee.toStringAsFixed(0)}',
            sublabel: '(2% convenience fee)',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.outlineVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final String? sublabel;

  const _AmountRow({required this.label, required this.amount, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF44474E),
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFF74777F),
                ),
              ),
          ],
        ),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}

// ── Payment Method Selector ───────────────────────────────────────────────────

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      {
        'id': 'razorpay',
        'label': 'Razorpay',
        'icon': Icons.payment_rounded,
        'color': const Color(0xFF1565C0),
      },
      {
        'id': 'upi',
        'label': 'UPI / QR',
        'icon': Icons.qr_code_rounded,
        'color': AppTheme.catGrocery,
      },
      {
        'id': 'card',
        'label': 'Card',
        'icon': Icons.credit_card_rounded,
        'color': AppTheme.primary,
      },
      {
        'id': 'wallet',
        'label': 'Wallet',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppTheme.secondary,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final isSelected = selected == m['id'];
        final color = m['color'] as Color;
        return GestureDetector(
          onTap: () => onChanged(m['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 56) / 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(26) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppTheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? AppTheme.cardShadow : null,
            ),
            child: Column(
              children: [
                Icon(
                  m['icon'] as IconData,
                  color: isSelected ? color : const Color(0xFF74777F),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  m['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : const Color(0xFF74777F),
                  ),
                ),
                if (m['id'] == 'razorpay' && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Recommended',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── UPI Panel ─────────────────────────────────────────────────────────────────

class _UpiPanel extends StatelessWidget {
  final double amount;
  const _UpiPanel({required this.amount});

  @override
  Widget build(BuildContext context) {
    const upiId = 'localconnect@upi';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Scan QR to Pay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          // QR placeholder
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'UPI ID: $upiId',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF44474E),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: upiId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'UPI ID copied!',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Copy UPI ID',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Or pay via UPI app',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _UpiAppChip(label: 'PhonePe', color: const Color(0xFF5F259F)),
              const SizedBox(width: 8),
              _UpiAppChip(label: 'GPay', color: const Color(0xFF1A73E8)),
              const SizedBox(width: 8),
              _UpiAppChip(label: 'Paytm', color: const Color(0xFF00BAF2)),
              const SizedBox(width: 8),
              _UpiAppChip(label: 'BHIM', color: const Color(0xFF0F4C81)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpiAppChip extends StatelessWidget {
  final String label;
  final Color color;
  const _UpiAppChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Card Panel ────────────────────────────────────────────────────────────────

class _CardPanel extends StatelessWidget {
  final TextEditingController cardNumberCtrl;
  final TextEditingController cardNameCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;

  const _CardPanel({
    required this.cardNumberCtrl,
    required this.cardNameCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
  });

  @override
  Widget build(BuildContext context) {
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
                Icons.credit_card_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Card Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Card type icons
              Row(
                children: [
                  _CardBadge(label: 'VISA', color: const Color(0xFF1A1F71)),
                  const SizedBox(width: 6),
                  _CardBadge(label: 'MC', color: const Color(0xFFEB001B)),
                  const SizedBox(width: 6),
                  _CardBadge(label: 'RuPay', color: const Color(0xFF006A4E)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CardField(
            controller: cardNumberCtrl,
            label: 'Card Number',
            hint: '1234  5678  9012  3456',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            prefixIcon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 12),
          _CardField(
            controller: cardNameCtrl,
            label: 'Cardholder Name',
            hint: 'As printed on card',
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardField(
                  controller: expiryCtrl,
                  label: 'Expiry',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  prefixIcon: Icons.date_range_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardField(
                  controller: cvvCtrl,
                  label: 'CVV',
                  hint: '•••',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  prefixIcon: Icons.lock_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CardBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final IconData prefixIcon;

  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.prefixIcon,
    this.obscureText = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF44474E),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, size: 18, color: AppTheme.primary),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Wallet Panel ──────────────────────────────────────────────────────────────

class _WalletPanel extends StatefulWidget {
  final double amount;
  const _WalletPanel({required this.amount});

  @override
  State<_WalletPanel> createState() => _WalletPanelState();
}

class _WalletPanelState extends State<_WalletPanel> {
  String _selectedWallet = 'paytm';

  final _wallets = [
    {
      'id': 'paytm',
      'label': 'Paytm Wallet',
      'balance': '₹1,240',
      'color': const Color(0xFF00BAF2),
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'id': 'amazonpay',
      'label': 'Amazon Pay',
      'balance': '₹350',
      'color': const Color(0xFFFF9900),
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'id': 'mobikwik',
      'label': 'MobiKwik',
      'balance': '₹0',
      'color': const Color(0xFF1B3A6B),
      'icon': Icons.wallet_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                Icons.account_balance_wallet_rounded,
                color: AppTheme.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Choose Wallet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._wallets.map((w) {
            final isSelected = _selectedWallet == w['id'];
            final color = w['color'] as Color;
            final balance = w['balance'] as String;
            final balanceNum =
                double.tryParse(
                  balance.replaceAll('₹', '').replaceAll(',', ''),
                ) ??
                0;
            final hasSufficientBalance = balanceNum >= widget.amount;

            return GestureDetector(
              onTap: () => setState(() => _selectedWallet = w['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(18) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        w['icon'] as IconData,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Balance: $balance',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: hasSufficientBalance
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!hasSufficientBalance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Low balance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Terms Row ─────────────────────────────────────────────────────────────────

class _TermsRow extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool?> onChanged;

  const _TermsRow({required this.agreed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: agreed,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF44474E),
              ),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' and authorize this payment.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Text Input Formatters ─────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
