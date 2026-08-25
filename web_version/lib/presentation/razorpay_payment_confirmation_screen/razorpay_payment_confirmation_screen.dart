import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class RazorpayPaymentConfirmationScreen extends StatelessWidget {
  const RazorpayPaymentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final paymentId = args['paymentId'] as String? ?? '';
    final amount = args['amount'] as double? ?? 0.0;
    final description = args['description'] as String? ?? 'Payment';
    final paymentType = args['paymentType'] as String? ?? 'one_time';
    final isSuccess = args['isSuccess'] as bool? ?? true;
    final errorMessage = args['errorMessage'] as String? ?? '';
    final orderNumber = args['orderNumber'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Status icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppTheme.successContainer
                      : AppTheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 56,
                  color: isSuccess ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isSuccess ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Your payment has been processed successfully.'
                    : errorMessage.isNotEmpty
                    ? errorMessage
                    : 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF74777F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Payment details card
              if (isSuccess) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Amount Paid',
                        value:
                            '₹${amount.toStringAsFixed(amount == amount.truncateToDouble() ? 0 : 2)}',
                        highlight: true,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE1E8EF)),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Description', value: description),
                      if (paymentId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailRow(
                          label: 'Payment ID',
                          value: paymentId,
                          isSmall: true,
                        ),
                      ],
                      if (orderNumber.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailRow(label: 'Order Number', value: orderNumber),
                      ],
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Payment Type',
                        value: paymentType == 'subscription'
                            ? 'Subscription'
                            : 'One-time Payment',
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(label: 'Gateway', value: 'Razorpay'),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Date & Time',
                        value: _formatDateTime(DateTime.now()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Razorpay branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Color(0xFF74777F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secured by Razorpay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Action buttons
              Column(
                children: [
                  if (isSuccess) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.razorpayTransactionHistoryScreen,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Transaction History',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop back to home or previous screen
                        Navigator.popUntil(
                          context,
                          (route) =>
                              route.settings.name == AppRoutes.homeScreen ||
                              route.settings.name ==
                                  AppRoutes.providerDashboardScreen ||
                              route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Go to Home',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isSmall;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF74777F),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: highlight ? 16 : (isSmall ? 11 : 13),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppTheme.primary : const Color(0xFF1A1C1E),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
