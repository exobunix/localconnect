import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import './supabase_service.dart';

// ── Razorpay is NOT supported on web — all SDK calls are guarded by kIsWeb ──
// The razorpay_flutter package is imported only on mobile via conditional logic

class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  RazorpayService._();

  static const String _keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  bool get isKeyConfigured => _keyId.isNotEmpty;
  String get keyId => _keyId;

  /// Create a Razorpay order server-side via the Edge Function.
  /// Returns {razorpay_order_id, amount, currency, transaction_id} or null on failure.
  Future<Map<String, dynamic>?> createOrder({
    required double amount,
    required String description,
    String paymentType = 'one_time',
    String? orderId,
    String? providerId,
    String? planId,
    Map<String, String>? notes,
  }) async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return null;

      final session = SupabaseService.instance.client.auth.currentSession;
      final token = session?.accessToken ?? '';

      final response = await SupabaseService.instance.client.functions.invoke(
        'razorpay-create-order',
        body: {
          'amount': amount,
          'description': description,
          'payment_type': paymentType,
          if (orderId != null) 'order_id': orderId,
          if (providerId != null) 'provider_id': providerId,
          if (planId != null) 'plan_id': planId,
          if (notes != null) 'notes': notes,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Create Razorpay order error: $e');
      return null;
    }
  }

  /// Record a successful payment transaction in Supabase.
  /// NOTE: Status is always set to 'pending' on client-side insert.
  /// The webhook edge function (server-side, HMAC-verified) is the only
  /// authority that transitions status to 'success'. This prevents
  /// client-side payment status manipulation.
  Future<Map<String, dynamic>?> recordTransaction({
    required String razorpayPaymentId,
    required double amount,
    required String paymentType,
    required String description,
    String? razorpayOrderId,
    String? razorpaySignature,
    String? orderId,
    String? providerId,
    String? planId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return null;

      final result = await SupabaseService.instance.client
          .from('razorpay_transactions')
          .insert({
            'user_id': user.id,
            'razorpay_order_id': razorpayOrderId,
            'razorpay_payment_id': razorpayPaymentId,
            'razorpay_signature': razorpaySignature,
            'amount': amount,
            'currency': 'INR',
            'payment_type': paymentType,
            // Always 'pending' — webhook will update to 'success' after HMAC verification
            'status': 'pending',
            'description': description,
            if (orderId != null) 'order_id': orderId,
            if (providerId != null) 'provider_id': providerId,
            if (planId != null) 'plan_id': planId,
            'metadata': metadata ?? {},
            'webhook_verified': false,
            'fraud_flag': false,
          })
          .select()
          .single();

      return result;
    } catch (e) {
      debugPrint('Record transaction error: $e');
      return null;
    }
  }

  /// Update the payment status of an order after successful Razorpay payment.
  /// Sets payment_status = 'paid', stores razorpay_payment_id, razorpay_order_id,
  /// amount_paid, and payment_method on the orders row.
  Future<void> updateOrderPaymentStatus({
    required String orderId,
    required String razorpayPaymentId,
    required double amountPaid,
    String? razorpayOrderId,
  }) async {
    try {
      await SupabaseService.instance.client
          .from('orders')
          .update({
            'payment_status': 'paid',
            'razorpay_payment_id': razorpayPaymentId,
            if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
            'amount_paid': amountPaid,
            'payment_method': 'razorpay',
          })
          .eq('id', orderId);

      // Notify provider that payment has been received
      try {
        final orderRow = await SupabaseService.instance.client
            .from('orders')
            .select('provider_id, order_number, customer_id')
            .eq('id', orderId)
            .maybeSingle();
        if (orderRow != null) {
          final providerId = orderRow['provider_id'] as String?;
          final orderNumber = orderRow['order_number'] as String? ?? orderId;
          if (providerId != null && providerId.isNotEmpty) {
            final providerRow = await SupabaseService.instance.client
                .from('service_providers')
                .select('user_id')
                .eq('id', providerId)
                .maybeSingle();
            final providerUserId = providerRow?['user_id'] as String?;
            if (providerUserId != null && providerUserId.isNotEmpty) {
              await SupabaseService.instance.insertOrderNotification(
                userId: providerUserId,
                title: '💰 Payment Received',
                body: 'Payment for order $orderNumber has been received.',
                type: 'booking',
              );
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Update order payment status error: $e');
    }
  }

  /// Fetch transaction history for current user
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
    String? paymentType,
  }) async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return [];

      var query = SupabaseService.instance.client
          .from('razorpay_transactions')
          .select()
          .eq('user_id', user.id);

      // Only apply paymentType filter when explicitly provided
      if (paymentType != null && paymentType.isNotEmpty) {
        query = query.eq('payment_type', paymentType);
      }

      final result = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      debugPrint('Get transactions error: $e');
      return [];
    }
  }

  /// Show web-not-supported dialog
  static void showWebNotSupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFFF57C00),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Download App to Pay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Razorpay payments are available on the LocalConnect mobile app. Please download the app to complete your payment.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
