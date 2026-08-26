import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/address_quick_select_widget.dart';
import '../../widgets/razorpay_stub.dart';
import '../../widgets/service_area_validation_widget.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  int _selectedPaymentIndex = 0;
  bool _isConfirming = false;

  // Selected service address
  Map<String, dynamic>? _selectedAddress;

  // Razorpay SDK instance (mobile only)
  Razorpay? _razorpay;

  // Stored after Supabase order creation, used in payment callbacks
  String? _pendingOrderId;
  double _pendingAmount = 0;
  Map<String, dynamic> _pendingArgs = {};

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'label': 'Cash on Service',
      'subtitle': 'Pay after service is done',
      'icon': Icons.money_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'id': 'razorpay',
      'label': 'Pay Online',
      'subtitle': 'Cards, UPI, Netbanking & more',
      'icon': Icons.payment_rounded,
      'color': Color(0xFF3395FF),
    },
  ];

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

  // ── Parse amount string like "₹500" or "500" to double ──────────────────
  double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // ── Razorpay payment sheet ───────────────────────────────────────────────
  void _openRazorpaySheet({required bool upiPreferred}) {
    final keyId = RazorpayService.instance.keyId;
    if (keyId.isEmpty) {
      _showError('Razorpay Key ID not configured.');
      if (mounted) setState(() => _isConfirming = false);
      return;
    }

    final user = SupabaseService.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final phone = user?.userMetadata?['phone'] as String? ?? '';
    final name = user?.userMetadata?['full_name'] as String? ?? 'Customer';

    if (kIsWeb) {
      RazorpayService.instance.openRazorpayWeb(
        amount: _pendingAmount,
        description: _pendingArgs['service'] as String? ??
            _pendingArgs['serviceName'] as String? ??
            'Service Booking',
        orderId: _pendingOrderId ?? '',
        customerName: name,
        customerEmail: email,
        customerPhone: phone,
        notes: {
          'service': _pendingArgs['service'] ?? '',
          'provider': _pendingArgs['providerName'] ?? '',
          'category': _pendingArgs['category'] ?? '',
          if (_pendingOrderId != null) 'order_id': _pendingOrderId!,
        },
        onSuccess: (paymentId, orderId, signature) async {
          if (!mounted) return;
          
          await RazorpayService.instance.recordTransaction(
            razorpayPaymentId: paymentId,
            amount: _pendingAmount,
            paymentType: 'one_time',
            description: _pendingArgs['service'] as String? ??
                _pendingArgs['serviceName'] as String? ??
                'Service Booking',
            razorpayOrderId: orderId,
            razorpaySignature: signature,
            orderId: _pendingOrderId,
            providerId: _pendingArgs['providerId'] as String?,
          );

          if (_pendingOrderId != null && _pendingOrderId!.isNotEmpty) {
            await RazorpayService.instance.updateOrderPaymentStatus(
              orderId: _pendingOrderId!,
              razorpayPaymentId: paymentId,
              amountPaid: _pendingAmount,
              razorpayOrderId: orderId,
            );
          }

          if (!mounted) return;
          setState(() => _isConfirming = false);
          _navigateToSummary(
            args: _pendingArgs,
            orderNumber: _pendingOrderId ?? 'ORD-000001',
            paymentMethodId: _paymentMethods[_selectedPaymentIndex]['id'] as String,
            paymentStatus: 'Paid',
          );
        },
        onFailure: (error) {
          if (!mounted) return;
          setState(() => _isConfirming = false);
          _showError(error);
        },
      );
      return;
    }

    final options = <String, dynamic>{
      'key': keyId,
      'amount': (_pendingAmount * 100).toInt(),
      'currency': 'INR',
      'name': 'LocalConnect',
      'description':
          _pendingArgs['service'] as String? ??
          _pendingArgs['serviceName'] as String? ??
          'Service Booking',
      'order_id': '', 
      'prefill': {'name': name, 'email': email, 'contact': phone},
      'theme': {'color': '#1565C0'},
      'retry': {'enabled': true, 'max_count': 3},
      'redirect': {'return_url': 'localconnect://razorpay'},
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      _showError('Could not open payment sheet. Please try again.');
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  // ── Razorpay callbacks ───────────────────────────────────────────────────
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    final paymentId = response.paymentId ?? '';
    final razorpayOrderId = response.orderId;
    final signature = response.signature;

    // Record transaction in razorpay_transactions table
    await RazorpayService.instance.recordTransaction(
      razorpayPaymentId: paymentId,
      amount: _pendingAmount,
      paymentType: 'one_time',
      description:
          _pendingArgs['service'] as String? ??
          _pendingArgs['serviceName'] as String? ??
          'Service Booking',
      razorpayOrderId: razorpayOrderId,
      razorpaySignature: signature,
      orderId: _pendingOrderId,
      providerId: _pendingArgs['providerId'] as String?,
    );

    // Update order payment_status to 'paid'
    if (_pendingOrderId != null && _pendingOrderId!.isNotEmpty) {
      await RazorpayService.instance.updateOrderPaymentStatus(
        orderId: _pendingOrderId!,
        razorpayPaymentId: paymentId,
        amountPaid: _pendingAmount,
        razorpayOrderId: razorpayOrderId,
      );
    }

    if (!mounted) return;
    setState(() => _isConfirming = false);
    _navigateToSummary(
      args: _pendingArgs,
      orderNumber: _pendingOrderId ?? 'ORD-000001',
      paymentMethodId: _paymentMethods[_selectedPaymentIndex]['id'] as String,
      paymentStatus: 'Paid',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isConfirming = false);
    final message = response.message ?? 'Payment failed. Please try again.';
    _showError(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isConfirming = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName ?? ""}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: AppTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Main confirm flow ────────────────────────────────────────────────────
  Future<void> _confirmBooking(Map<String, dynamic> args) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    final selectedPayment = _paymentMethods[_selectedPaymentIndex];
    final paymentMethodId = selectedPayment['id'] as String;
    final amountStr =
        args['amount'] as String? ??
        args['basePrice'] as String? ??
        args['price'] as String? ??
        '₹0';

    // Build address string from selected address
    final addrParts = <String>[];
    if (_selectedAddress != null) {
      final a = _selectedAddress!;
      if ((a['address_line1'] as String? ?? '').isNotEmpty) {
        addrParts.add(a['address_line1'] as String);
      }
      if ((a['village'] as String? ?? '').isNotEmpty) {
        addrParts.add(a['village'] as String);
      }
      if ((a['city'] as String? ?? '').isNotEmpty) {
        addrParts.add(a['city'] as String);
      }
      if ((a['pincode'] as String? ?? '').isNotEmpty) {
        addrParts.add(a['pincode'] as String);
      }
    }
    final addressStr = addrParts.isNotEmpty
        ? addrParts.join(', ')
        : args['address'] as String? ?? '';

    final enrichedArgs = Map<String, dynamic>.from(args)
      ..['address'] = addressStr;

    try {
      // Step 1: Always create the order in Supabase first
      final result = await SupabaseService.instance.createOrder(
        providerName: enrichedArgs['providerName'] as String? ?? '',
        service:
            enrichedArgs['service'] as String? ??
            enrichedArgs['serviceName'] as String? ??
            '',
        category: enrichedArgs['category'] as String? ?? '',
        scheduledDate: enrichedArgs['scheduledDate'] as String? ?? '',
        scheduledTime: enrichedArgs['scheduledTime'] as String? ?? '',
        amount: amountStr,
        providerId: enrichedArgs['providerId'] as String?,
        paymentMethod: paymentMethodId,
      );

      if (!mounted) return;

      if (result == null) {
        final errorMsg = SupabaseService.instance.lastOrderError != null
            ? 'Failed to confirm booking: ${SupabaseService.instance.lastOrderError}'
            : 'Failed to confirm booking. Please try again.';
        _showError(errorMsg);
        setState(() => _isConfirming = false);
        return;
      }

      final orderNumber = result['order_number'] as String? ?? 'ORD-000001';
      final orderId = result['id'] as String? ?? '';

      // Step 2: Branch on payment method
      if (paymentMethodId == 'cash') {
        // Cash — no payment processing needed, navigate directly
        setState(() => _isConfirming = false);
        _navigateToSummary(
          args: enrichedArgs,
          orderNumber: orderNumber,
          paymentMethodId: paymentMethodId,
          paymentStatus: 'Pending',
        );
      } else {
        // Razorpay or UPI — store pending state and open payment sheet
        _pendingOrderId = orderId;
        _pendingAmount = _parseAmount(amountStr);
        _pendingArgs = Map<String, dynamic>.from(enrichedArgs);

        // _isConfirming stays true while payment sheet is open;
        // it will be reset inside success/error callbacks
        _openRazorpaySheet(upiPreferred: paymentMethodId == 'upi');
      }
    } catch (e) {
      if (mounted) {
        _showError('Something went wrong: $e');
        setState(() => _isConfirming = false);
      }
    }
  }

  // ── Navigation helper ────────────────────────────────────────────────────
  void _navigateToSummary({
    required Map<String, dynamic> args,
    required String orderNumber,
    required String paymentMethodId,
    required String paymentStatus,
  }) {
    final amountStr =
        args['amount'] as String? ??
        args['basePrice'] as String? ??
        args['price'] as String? ??
        '₹0';

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bookingSummaryScreen,
      (route) => route.settings.name == AppRoutes.homeScreen,
      arguments: {
        'orderNumber': orderNumber,
        'service':
            args['service'] as String? ??
            args['serviceName'] as String? ??
            'Service',
        'providerName': args['providerName'] as String? ?? '',
        'amount': amountStr,
        'scheduledDate': args['scheduledDate'] as String? ?? '',
        'scheduledTime': args['scheduledTime'] as String? ?? '',
        'paymentMethod': paymentMethodId,
        'paymentStatus': paymentStatus,
        'address': args['address'] as String? ?? '',
        'category': args['category'] as String? ?? '',
      },
    );
  }

  // ── Error snackbar helper ────────────────────────────────────────────────
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: AppTheme.error,
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

    final serviceName =
        args['service'] as String? ??
        args['serviceName'] as String? ??
        'Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final providerImage = args['providerImage'] as String? ?? '';
    final providerRating = args['providerRating'] as double? ?? 4.8;
    final amount =
        args['amount'] as String? ??
        args['basePrice'] as String? ??
        args['price'] as String? ??
        '₹0';
    final scheduledDate = args['scheduledDate'] as String? ?? '';
    final scheduledTime = args['scheduledTime'] as String? ?? '';
    final category = args['category'] as String? ?? '';
    final duration = args['duration'] as String? ?? '';
    final providerId = args['providerId'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
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
                    serviceName: serviceName,
                    providerName: providerName,
                    providerImage: providerImage,
                    providerRating: providerRating,
                    scheduledDate: scheduledDate,
                    scheduledTime: scheduledTime,
                    category: category,
                    duration: duration,
                    amount: amount,
                  ),
                  const SizedBox(height: 16),

                  // ── Service Area Validation ───────────────────────────
                  if (providerId != null && providerId.isNotEmpty)
                    ServiceAreaValidationWidget(
                      providerId: providerId,
                      onEligible: () {},
                      child: const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 16),

                  // ── Service Address Section ───────────────────────────
                  _ServiceAddressSection(
                    selectedAddress: _selectedAddress,
                    onSelectAddress: () async {
                      final addr = await AddressQuickSelectWidget.show(
                        context,
                        updateCurrentLocation: false,
                      );
                      if (addr != null && mounted) {
                        setState(() => _selectedAddress = addr);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Payment Method Section ────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Color(0xFF6A1B9A),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Payment Method',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._paymentMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    final isSelected = _selectedPaymentIndex == index;
                    final color = method['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentMethodTile(
                        icon: method['icon'] as IconData,
                        label: method['label'] as String,
                        subtitle: method['subtitle'] as String,
                        color: color,
                        isSelected: isSelected,
                        onTap: () =>
                            setState(() => _selectedPaymentIndex = index),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // ── Price Breakdown ───────────────────────────────────
                  _PriceBreakdownCard(amount: amount),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ConfirmBottomBar(
        amount: amount,
        isConfirming: _isConfirming,
        selectedPaymentId:
            _paymentMethods[_selectedPaymentIndex]['id'] as String,
        onConfirm: () => _confirmBooking(args),
      ),
    );
  }
}

// ── Booking Summary Card ──────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final String serviceName;
  final String providerName;
  final String providerImage;
  final double providerRating;
  final String scheduledDate;
  final String scheduledTime;
  final String category;
  final String duration;
  final String amount;

  const _BookingSummaryCard({
    required this.serviceName,
    required this.providerName,
    required this.providerImage,
    required this.providerRating,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.category,
    required this.duration,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  AppTheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Booking Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Provider row
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: AppTheme.surfaceVariant,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: providerImage.isNotEmpty
                          ? Image.network(
                              providerImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person_rounded,
                                color: AppTheme.primary,
                                size: 28,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: AppTheme.primary,
                              size: 28,
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
                              color: const Color(0xFF1A1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFA726),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                providerRating.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF78909C),
                                ),
                              ),
                              if (category.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F2F5)),
                const SizedBox(height: 16),

                // Service detail rows
                _DetailRow(
                  icon: Icons.home_repair_service_rounded,
                  iconColor: AppTheme.primary,
                  label: 'Service',
                  value: serviceName,
                ),
                if (scheduledDate.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppTheme.warning,
                    label: 'Date',
                    value: scheduledDate,
                  ),
                ],
                if (scheduledTime.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    iconColor: AppTheme.info,
                    label: 'Time',
                    value: scheduledTime,
                  ),
                ],
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.timelapse_rounded,
                    iconColor: const Color(0xFF00695C),
                    label: 'Duration',
                    value: duration,
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

// ── Service Address Section ───────────────────────────────────────────────────

class _ServiceAddressSection extends StatelessWidget {
  final Map<String, dynamic>? selectedAddress;
  final VoidCallback onSelectAddress;

  const _ServiceAddressSection({
    required this.selectedAddress,
    required this.onSelectAddress,
  });

  @override
  Widget build(BuildContext context) {
    final addr = selectedAddress;
    final label = addr?['label'] as String? ?? '';
    final line1 = addr?['address_line1'] as String? ?? '';
    final village = addr?['village'] as String? ?? '';
    final city = addr?['city'] as String? ?? '';
    final pincode = addr?['pincode'] as String? ?? '';

    final parts = [
      if (line1.isNotEmpty) line1,
      if (village.isNotEmpty) village,
      if (city.isNotEmpty) city,
      if (pincode.isNotEmpty) pincode,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Service Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onSelectAddress,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: addr != null
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : AppTheme.outlineVariant,
                width: addr != null ? 1.5 : 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: addr != null
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    addr == null
                        ? Icons.add_location_alt_outlined
                        : label.toLowerCase() == 'home'
                        ? Icons.home_outlined
                        : label.toLowerCase() == 'work'
                        ? Icons.work_outline
                        : Icons.location_on_outlined,
                    color: addr != null
                        ? AppTheme.primary
                        : const Color(0xFF78909C),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: addr == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Service Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Choose from saved addresses or use GPS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label.isNotEmpty ? label : 'Selected Address',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            if (parts.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                parts.join(', '),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF74777F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: addr != null
                      ? AppTheme.primary
                      : const Color(0xFF90A4AE),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: iconColor, size: 14),
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

// ── Payment Method Tile ───────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE8EAED),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF90A4AE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCFD8DC),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price Breakdown Card ──────────────────────────────────────────────────────

class _PriceBreakdownCard extends StatelessWidget {
  final String amount;

  const _PriceBreakdownCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppTheme.success,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Price Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Charge',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF78909C),
                ),
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
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Confirm Bottom Bar ────────────────────────────────────────────────────────

class _ConfirmBottomBar extends StatelessWidget {
  final String amount;
  final bool isConfirming;
  final String selectedPaymentId;
  final VoidCallback onConfirm;

  const _ConfirmBottomBar({
    required this.amount,
    required this.isConfirming,
    required this.selectedPaymentId,
    required this.onConfirm,
  });

  String get _buttonLabel {
    if (selectedPaymentId == 'cash') return 'Confirm Booking';
    if (selectedPaymentId == 'upi') return 'Pay via UPI';
    return 'Pay via Razorpay';
  }

  IconData get _buttonIcon {
    if (selectedPaymentId == 'cash') return Icons.check_circle_rounded;
    return Icons.payment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
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
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isConfirming ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_buttonIcon, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _buttonLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
