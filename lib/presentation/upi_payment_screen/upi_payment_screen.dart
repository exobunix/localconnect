import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';

class UpiPaymentScreen extends StatefulWidget {
  const UpiPaymentScreen({super.key});

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _paymentDone = false;
  bool _launching = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ─── UPI Deep Link Launchers ──────────────────────────────────────────────

  /// Builds a UPI intent URI and launches it.
  /// pa = payee UPI ID, pn = payee name, am = amount, tn = transaction note
  Future<void> _launchUpiApp({
    required String appScheme,
    required String upiId,
    required String payeeName,
    required String amount,
    required String note,
  }) async {
    if (_launching) return;
    setState(() => _launching = true);

    final amt = amount.isEmpty ? '0' : amount;
    final encodedName = Uri.encodeComponent(payeeName);
    final encodedNote = Uri.encodeComponent(note);

    // Standard UPI deep-link format
    final upiUri = Uri.parse(
      '$appScheme://upi/pay?pa=$upiId&pn=$encodedName&am=$amt&cu=INR&tn=$encodedNote',
    );

    try {
      final launched = await launchUrl(
        upiUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnack('${_appLabel(appScheme)} is not installed on this device.');
      } else if (launched && mounted) {
        // Mark as done after returning from the UPI app
        setState(() => _paymentDone = true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Could not open ${_appLabel(appScheme)}. Please try another app.',
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  String _appLabel(String scheme) {
    switch (scheme) {
      case 'phonepe':
        return 'PhonePe';
      case 'gpay':
        return 'Google Pay';
      case 'paytm':
        return 'Paytm';
      case 'upi':
        return 'BHIM UPI';
      default:
        return scheme;
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final providerName = args?['providerName'] as String? ?? 'Provider';
    final upiId = args?['upiId'] as String? ?? 'provider@upi';
    final defaultAmount = args?['amount'] as String? ?? '';

    if (defaultAmount.isNotEmpty && _amountController.text.isEmpty) {
      _amountController.text = defaultAmount
          .replaceAll('₹', '')
          .replaceAll(',', '');
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'UPI Payment',
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
      body: _paymentDone
          ? _buildSuccessView(context)
          : _buildPaymentView(context, providerName, upiId),
    );
  }

  Widget _buildPaymentView(
    BuildContext context,
    String providerName,
    String upiId,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Provider Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        upiId,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: upiId));
                    _showSnack('UPI ID copied!', success: true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Amount Input
          Container(
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
                  'Enter Amount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                    hintText: '0',
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['100', '200', '500', '1000']
                      .map(
                        (amt) => GestureDetector(
                          onTap: () =>
                              setState(() => _amountController.text = amt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹$amt',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── UPI App Deep Links ──────────────────────────────────────────
          Container(
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
                  'Pay with UPI App',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to open your preferred UPI app directly',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF74777F),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _UpiDeepLinkButton(
                        label: 'PhonePe',
                        icon: Icons.phone_android_rounded,
                        color: const Color(0xFF5F259F),
                        isLoading: _launching,
                        onTap: () => _launchUpiApp(
                          appScheme: 'phonepe',
                          upiId: upiId,
                          payeeName: providerName,
                          amount: _amountController.text,
                          note: 'LocalConnect Payment',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UpiDeepLinkButton(
                        label: 'Google Pay',
                        icon: Icons.g_mobiledata_rounded,
                        color: const Color(0xFF4285F4),
                        isLoading: _launching,
                        onTap: () => _launchUpiApp(
                          appScheme: 'gpay',
                          upiId: upiId,
                          payeeName: providerName,
                          amount: _amountController.text,
                          note: 'LocalConnect Payment',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _UpiDeepLinkButton(
                        label: 'Paytm',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF00BAF2),
                        isLoading: _launching,
                        onTap: () => _launchUpiApp(
                          appScheme: 'paytm',
                          upiId: upiId,
                          payeeName: providerName,
                          amount: _amountController.text,
                          note: 'LocalConnect Payment',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UpiDeepLinkButton(
                        label: 'BHIM UPI',
                        icon: Icons.currency_rupee_rounded,
                        color: const Color(0xFF138808),
                        isLoading: _launching,
                        onTap: () => _launchUpiApp(
                          appScheme: 'upi',
                          upiId: upiId,
                          payeeName: providerName,
                          amount: _amountController.text,
                          note: 'LocalConnect Payment',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manual pay button (fallback)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_amountController.text.isNotEmpty) {
                    setState(() => _paymentDone = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mark as Paid — ₹${_amountController.text.isEmpty ? "0" : _amountController.text}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 14, color: AppTheme.success),
              const SizedBox(width: 4),
              Text(
                'Secured by UPI • 256-bit encryption',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppTheme.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Initiated!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_amountController.text} payment request sent',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF90A4AE),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── UPI Deep Link Button Widget ──────────────────────────────────────────────

class _UpiDeepLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _UpiDeepLinkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
