import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../services/razorpay_service.dart';
import '../services/supabase_service.dart';
import './razorpay_stub.dart';

// Conditional import: real SDK on mobile, stub on web

/// Razorpay payment widget — handles the full payment flow on mobile.
/// On web, shows a "download app" message.
class RazorpayPaymentWidget extends StatefulWidget {
  final double amount;
  final String description;
  final String paymentType; // 'one_time' or 'subscription'
  final String? orderId;
  final String? providerId;
  final String? planId;
  final Map<String, dynamic>? notes;
  final VoidCallback? onPaymentSuccess;
  final Function(String error)? onPaymentFailed;

  const RazorpayPaymentWidget({
    super.key,
    required this.amount,
    required this.description,
    required this.paymentType,
    this.orderId,
    this.providerId,
    this.planId,
    this.notes,
    this.onPaymentSuccess,
    this.onPaymentFailed,
  });

  @override
  State<RazorpayPaymentWidget> createState() => _RazorpayPaymentWidgetState();
}

class _RazorpayPaymentWidgetState extends State<RazorpayPaymentWidget> {
  Razorpay? _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    final paymentId = response.paymentId ?? '';
    final razorpayOrderId = response.orderId;
    final signature = response.signature;

    // 1. Record in razorpay_transactions table
    await RazorpayService.instance.recordTransaction(
      razorpayPaymentId: paymentId,
      amount: widget.amount,
      paymentType: widget.paymentType,
      description: widget.description,
      razorpayOrderId: razorpayOrderId,
      razorpaySignature: signature,
      orderId: widget.orderId,
      providerId: widget.providerId,
      planId: widget.planId,
      metadata: widget.notes,
    );

    // 2. Update the booking order's payment_status to 'paid' in orders table
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      await RazorpayService.instance.updateOrderPaymentStatus(
        orderId: widget.orderId!,
        razorpayPaymentId: paymentId,
        amountPaid: widget.amount,
        razorpayOrderId: razorpayOrderId,
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      widget.onPaymentSuccess?.call();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    final message = response.message ?? 'Payment failed';
    widget.onPaymentFailed?.call(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  void _openRazorpay() {
    final keyId = RazorpayService.instance.keyId;
    if (keyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Razorpay Key ID not configured. Please add RAZORPAY_KEY_ID.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = SupabaseService.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final phone = user?.userMetadata?['phone'] as String? ?? '';
    final name = user?.userMetadata?['full_name'] as String? ?? 'Customer';

    if (kIsWeb) {
      setState(() => _isProcessing = true);
      RazorpayService.instance.openRazorpayWeb(
        amount: widget.amount,
        description: widget.description,
        orderId: widget.orderId ?? '',
        customerName: name,
        customerEmail: email,
        customerPhone: phone,
        notes: widget.notes ?? {},
        onSuccess: (paymentId, orderId, signature) async {
          if (!mounted) return;
          
          await RazorpayService.instance.recordTransaction(
            razorpayPaymentId: paymentId,
            amount: widget.amount,
            paymentType: widget.paymentType,
            description: widget.description,
            razorpayOrderId: orderId,
            razorpaySignature: signature,
            orderId: widget.orderId,
            providerId: widget.providerId,
            planId: widget.planId,
            metadata: widget.notes,
          );

          if (widget.orderId != null && widget.orderId!.isNotEmpty) {
            await RazorpayService.instance.updateOrderPaymentStatus(
              orderId: widget.orderId!,
              razorpayPaymentId: paymentId,
              amountPaid: widget.amount,
              razorpayOrderId: orderId,
            );
          }

          if (mounted) {
            setState(() => _isProcessing = false);
            widget.onPaymentSuccess?.call();
          }
        },
        onFailure: (error) {
          if (mounted) {
            setState(() => _isProcessing = false);
            widget.onPaymentFailed?.call(error);
          }
        },
      );
      return;
    }

    final options = {
      'key': keyId,
      'amount': (widget.amount * 100).toInt(),
      'currency': 'INR',
      'name': 'LocalConnect',
      'description': widget.description,
      'prefill': {'name': name, 'email': email, 'contact': phone},
      'theme': {'color': '#1565C0'},
      'retry': {'enabled': true, 'max_count': 3},
      // Razorpay deep-link callback scheme registered in AndroidManifest
      'redirect': {'return_url': 'localconnect://razorpay'},
      if (widget.notes != null) 'notes': widget.notes,
    };

    setState(() => _isProcessing = true);
    try {
      _razorpay?.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      widget.onPaymentFailed?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _openRazorpay,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1565C0).withAlpha(153),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Processing...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${widget.amount.toStringAsFixed(widget.amount == widget.amount.truncateToDouble() ? 0 : 2)} via Razorpay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
