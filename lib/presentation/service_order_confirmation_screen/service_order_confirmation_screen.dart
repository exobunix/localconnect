import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/razorpay_stub.dart';

/// Unified screen: confirm service details → pick time slot → choose payment → create order
class ServiceOrderConfirmationScreen extends StatefulWidget {
  const ServiceOrderConfirmationScreen({super.key});

  @override
  State<ServiceOrderConfirmationScreen> createState() =>
      _ServiceOrderConfirmationScreenState();
}

class _ServiceOrderConfirmationScreenState
    extends State<ServiceOrderConfirmationScreen> {
  // ── Args passed from provider profile ─────────────────────────────────────
  Map<String, dynamic> _args = {};

  // ── Date / time selection ─────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;

  // ── Payment ───────────────────────────────────────────────────────────────
  int _selectedPaymentIndex = 0;
  bool _isConfirming = false;

  // ── Razorpay (mobile only) ────────────────────────────────────────────────
  Razorpay? _razorpay;
  String? _pendingOrderId;
  double _pendingAmount = 0;

  // ── Provider data ─────────────────────────────────────────────────────────
  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _serviceCharges = [];
  bool _isLoadingProvider = true;

  // ── Selected service charge ───────────────────────────────────────────────
  Map<String, dynamic>? _selectedService;

  static const List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'label': 'Cash on Service',
      'subtitle': 'Pay after service is done',
      'icon': Icons.money_rounded,
      'color': const Color(0xFF2E7D32),
    },
    {
      'id': 'razorpay',
      'label': 'Razorpay',
      'subtitle': 'Cards, UPI, Wallets & more',
      'icon': Icons.payment_rounded,
      'color': const Color(0xFF3395FF),
    },
    {
      'id': 'upi',
      'label': 'UPI / QR Code',
      'subtitle': 'PhonePe, GPay, Paytm',
      'icon': Icons.qr_code_rounded,
      'color': const Color(0xFF6A1B9A),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (routeArgs != null && _args.isEmpty) {
      _args = Map<String, dynamic>.from(routeArgs);
      _loadProviderData();
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadProviderData() async {
    final providerId = _args['providerId'] as String?;
    if (providerId == null) {
      if (mounted) setState(() => _isLoadingProvider = false);
      return;
    }
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('service_providers')
            .select()
            .eq('id', providerId)
            .maybeSingle(),
        Supabase.instance.client
            .from('provider_service_charges')
            .select()
            .eq('provider_id', providerId)
            .eq('is_enabled', true)
            .order('sort_order'),
      ]);
      if (mounted) {
        setState(() {
          _provider = results[0] as Map<String, dynamic>?;
          final charges =
              List<Map<String, dynamic>>.from(results[1] as List? ?? [])
                  .where(
                    (s) =>
                        !(s['service_name'] as String? ?? '').startsWith('__'),
                  )
                  .toList();
          _serviceCharges = charges;
          // Pre-select first service if available
          if (_selectedService == null && charges.isNotEmpty) {
            _selectedService = charges.first;
          }
          _isLoadingProvider = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProvider = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<DateTime> get _availableDates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));

  String _formatDayName(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _formatMonthDay(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _parseAmount(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String get _providerName =>
      (_provider?['business_name'] as String?) ??
      (_provider?['owner_name'] as String?) ??
      (_args['providerName'] as String?) ??
      'Provider';

  String get _providerImage => _provider?['image_url'] as String? ?? '';

  String get _category =>
      _args['category'] as String? ??
      _provider?['category'] as String? ??
      'service';

  String get _serviceLabel =>
      _selectedService?['service_name'] as String? ??
      _args['service'] as String? ??
      _args['serviceName'] as String? ??
      'Service';

  String get _servicePrice {
    if (_selectedService != null) {
      final price = _selectedService!['price'];
      if (price != null) return '₹${price.toString()}';
    }
    return _args['amount'] as String? ??
        _args['basePrice'] as String? ??
        _args['price'] as String? ??
        '₹0';
  }

  bool get _isOnDemand {
    const onDemand = [
      'transport',
      'rickshaw',
      'car',
      'taxi',
      'pickup',
      'truck',
      'minivan',
      'home_maintenance',
      'plumber',
      'electrician',
      'carpenter',
      'painter',
      'mason',
      'cleaning',
      'daily_wage',
    ];
    return onDemand.contains(_category.toLowerCase());
  }

  // ── Confirm & pay ─────────────────────────────────────────────────────────

  Future<void> _confirmOrder() async {
    if (_isConfirming) return;

    if (!_isOnDemand && _selectedTimeSlot == null) {
      _showSnack('Please select a time slot', isError: true);
      return;
    }

    setState(() => _isConfirming = true);

    final paymentMethodId =
        _paymentMethods[_selectedPaymentIndex]['id'] as String;
    final dateStr = _isOnDemand ? 'Now' : _formatMonthDay(_selectedDate);
    final dayStr = _isOnDemand ? '' : '${_formatDayName(_selectedDate)}, ';
    final scheduledDate = _isOnDemand ? 'Now' : '$dayStr$dateStr';
    final scheduledTime = _isOnDemand ? 'On Demand' : _selectedTimeSlot!;

    final orderArgs = {
      ..._args,
      'service': _serviceLabel,
      'serviceName': _serviceLabel,
      'amount': _servicePrice,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'paymentMethod': paymentMethodId,
      'providerName': _providerName,
      'category': _category,
    };

    try {
      final result = await SupabaseService.instance.createOrder(
        providerName: _providerName,
        service: _serviceLabel,
        category: _category,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        amount: _servicePrice,
        providerId: _args['providerId'] as String?,
        paymentMethod: paymentMethodId,
      );

      if (!mounted) return;

      if (result == null) {
        _showSnack('Failed to create order. Please try again.', isError: true);
        setState(() => _isConfirming = false);
        return;
      }

      final orderNumber = result['order_number'] as String? ?? 'ORD-000001';
      final orderId = result['id'] as String? ?? '';

      if (paymentMethodId == 'cash') {
        setState(() => _isConfirming = false);
        _navigateToSummary(
          args: orderArgs,
          orderNumber: orderNumber,
          paymentMethodId: paymentMethodId,
          paymentStatus: 'Pending',
        );
      } else {
        _pendingOrderId = orderId;
        _pendingAmount = _parseAmount(_servicePrice);
        _openRazorpaySheet(
          args: orderArgs,
          orderNumber: orderNumber,
          upiPreferred: paymentMethodId == 'upi',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Something went wrong. Please try again.', isError: true);
        setState(() => _isConfirming = false);
      }
    }
  }

  void _openRazorpaySheet({
    required Map<String, dynamic> args,
    required String orderNumber,
    required bool upiPreferred,
  }) {
    if (kIsWeb) {
      RazorpayService.showWebNotSupportedDialog(context);
      if (mounted) setState(() => _isConfirming = false);
      return;
    }

    final keyId = RazorpayService.instance.keyId;
    if (keyId.isEmpty) {
      _showSnack('Razorpay not configured.', isError: true);
      if (mounted) setState(() => _isConfirming = false);
      return;
    }

    final user = SupabaseService.instance.client.auth.currentUser;
    final options = <String, dynamic>{
      'key': keyId,
      'amount': (_pendingAmount * 100).toInt(),
      'currency': 'INR',
      'name': 'LocalConnect',
      'description': _serviceLabel,
      'prefill': {
        'name': user?.userMetadata?['full_name'] ?? 'Customer',
        'email': user?.email ?? '',
        'contact': user?.userMetadata?['phone'] ?? '',
      },
      'theme': {'color': '#1565C0'},
      'retry': {'enabled': true, 'max_count': 3},
    };

    if (upiPreferred) {
      options['method'] = {
        'upi': true,
        'card': false,
        'netbanking': false,
        'wallet': false,
      };
    }

    // Store args for callbacks
    _pendingArgs = args;
    _pendingOrderNumber = orderNumber;

    try {
      _razorpay?.open(options);
    } catch (_) {
      _showSnack('Could not open payment. Please try again.', isError: true);
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Map<String, dynamic> _pendingArgs = {};
  String _pendingOrderNumber = '';

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    final paymentId = response.paymentId ?? '';

    await RazorpayService.instance.recordTransaction(
      razorpayPaymentId: paymentId,
      amount: _pendingAmount,
      paymentType: 'one_time',
      description: _serviceLabel,
      razorpayOrderId: response.orderId,
      razorpaySignature: response.signature,
      orderId: _pendingOrderId,
      providerId: _args['providerId'] as String?,
    );

    if (_pendingOrderId != null && _pendingOrderId!.isNotEmpty) {
      await RazorpayService.instance.updateOrderPaymentStatus(
        orderId: _pendingOrderId!,
        razorpayPaymentId: paymentId,
        amountPaid: _pendingAmount,
        razorpayOrderId: response.orderId,
      );
    }

    if (!mounted) return;
    setState(() => _isConfirming = false);
    _navigateToSummary(
      args: _pendingArgs,
      orderNumber: _pendingOrderNumber,
      paymentMethodId: _paymentMethods[_selectedPaymentIndex]['id'] as String,
      paymentStatus: 'Paid',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isConfirming = false);
    _showSnack(
      response.message ?? 'Payment failed. Please try again.',
      isError: true,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isConfirming = false);
    _showSnack('Wallet selected: ${response.walletName ?? ""}');
  }

  void _navigateToSummary({
    required Map<String, dynamic> args,
    required String orderNumber,
    required String paymentMethodId,
    required String paymentStatus,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bookingSummaryScreen,
      (route) => route.settings.name == AppRoutes.homeScreen,
      arguments: {
        'orderNumber': orderNumber,
        'service': _serviceLabel,
        'providerName': _providerName,
        'amount': _servicePrice,
        'scheduledDate': args['scheduledDate'] ?? '',
        'scheduledTime': args['scheduledTime'] ?? '',
        'paymentMethod': paymentMethodId,
        'paymentStatus': paymentStatus,
        'address': _provider?['address'] as String? ?? '',
        'category': _category,
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Confirm Booking',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingProvider
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProviderSummaryCard(
                          providerName: _providerName,
                          providerImage: _providerImage,
                          category: _category,
                          address: _provider?['address'] as String? ?? '',
                          rating:
                              (_provider?['rating'] as num?)?.toDouble() ?? 0.0,
                          reviewCount: _provider?['review_count'] as int? ?? 0,
                        ),
                        const SizedBox(height: 16),
                        _ServiceSelectionCard(
                          serviceCharges: _serviceCharges,
                          selectedService: _selectedService,
                          fallbackLabel:
                              _args['service'] as String? ??
                              _args['serviceName'] as String? ??
                              'Service',
                          fallbackPrice:
                              _args['amount'] as String? ??
                              _args['basePrice'] as String? ??
                              _args['price'] as String? ??
                              '₹0',
                          onServiceSelected: (s) =>
                              setState(() => _selectedService = s),
                        ),
                        const SizedBox(height: 16),
                        if (!_isOnDemand) ...[
                          _DatePickerCard(
                            availableDates: _availableDates,
                            selectedDate: _selectedDate,
                            onDateSelected: (d) =>
                                setState(() => _selectedDate = d),
                            isSameDay: _isSameDay,
                            formatDayName: _formatDayName,
                            formatMonthDay: _formatMonthDay,
                          ),
                          const SizedBox(height: 16),
                          _TimeSlotCard(
                            timeSlots: _timeSlots,
                            selectedSlot: _selectedTimeSlot,
                            onSlotSelected: (s) =>
                                setState(() => _selectedTimeSlot = s),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          _OnDemandBadge(category: _category),
                          const SizedBox(height: 16),
                        ],
                        _PaymentMethodCard(
                          paymentMethods: _paymentMethods,
                          selectedIndex: _selectedPaymentIndex,
                          onSelected: (i) =>
                              setState(() => _selectedPaymentIndex = i),
                        ),
                        const SizedBox(height: 16),
                        _OrderSummaryCard(
                          serviceLabel: _serviceLabel,
                          servicePrice: _servicePrice,
                          scheduledDate: _isOnDemand
                              ? 'Now (On Demand)'
                              : '${_formatDayName(_selectedDate)}, ${_formatMonthDay(_selectedDate)}',
                          scheduledTime: _isOnDemand
                              ? 'On Demand'
                              : (_selectedTimeSlot ?? 'Not selected'),
                          paymentMethod:
                              _paymentMethods[_selectedPaymentIndex]['label']
                                  as String,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _ConfirmButton(
                  isConfirming: _isConfirming,
                  servicePrice: _servicePrice,
                  onConfirm: _confirmOrder,
                ),
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProviderSummaryCard extends StatelessWidget {
  final String providerName;
  final String providerImage;
  final String category;
  final String address;
  final double rating;
  final int reviewCount;

  const _ProviderSummaryCard({
    required this.providerName,
    required this.providerImage,
    required this.category,
    required this.address,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: providerImage.isNotEmpty
                ? Image.network(
                    providerImage,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _PlaceholderAvatar(name: providerName),
                    semanticLabel:
                        'Profile photo of $providerName service provider',
                  )
                : _PlaceholderAvatar(name: providerName),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF57C00),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating > 0
                          ? '${rating.toStringAsFixed(1)} ($reviewCount reviews)'
                          : 'New Provider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF666680),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF9E9EB8),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF9E9EB8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category.replaceAll('_', ' ').toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  final String name;
  const _PlaceholderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ServiceSelectionCard extends StatelessWidget {
  final List<Map<String, dynamic>> serviceCharges;
  final Map<String, dynamic>? selectedService;
  final String fallbackLabel;
  final String fallbackPrice;
  final ValueChanged<Map<String, dynamic>> onServiceSelected;

  const _ServiceSelectionCard({
    required this.serviceCharges,
    required this.selectedService,
    required this.fallbackLabel,
    required this.fallbackPrice,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Service Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (serviceCharges.isEmpty)
            _FallbackServiceTile(label: fallbackLabel, price: fallbackPrice)
          else
            ...serviceCharges.map((s) {
              final isSelected = selectedService?['id'] == s['id'];
              final price = s['price'];
              final priceStr = price != null ? '₹${price.toString()}' : '';
              final unit = s['unit'] as String? ?? '';
              return GestureDetector(
                onTap: () => onServiceSelected(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryContainer
                        : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFE8ECF4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFFB0BEC5),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['service_name'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            if (unit.isNotEmpty)
                              Text(
                                unit,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF9E9EB8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (priceStr.isNotEmpty)
                        Text(
                          priceStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFF1A1A2E),
                          ),
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

class _FallbackServiceTile extends StatelessWidget {
  final String label;
  final String price;
  const _FallbackServiceTile({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          if (price != '₹0')
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime, DateTime) isSameDay;
  final String Function(DateTime) formatDayName;
  final String Function(DateTime) formatMonthDay;

  const _DatePickerCard({
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isSameDay,
    required this.formatDayName,
    required this.formatMonthDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF1565C0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Date',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final date = availableDates[i];
                final isSelected = isSameDay(date, selectedDate);
                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.primaryGradient : null,
                      color: isSelected ? null : const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : const Color(0xFFE8ECF4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatDayName(date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF9E9EB8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          formatMonthDay(date).split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF9E9EB8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final List<String> timeSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  const _TimeSlotCard({
    required this.timeSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFF57C00),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Time Slot',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              if (selectedSlot == null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Required',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((slot) {
              final isSelected = selectedSlot == slot;
              return GestureDetector(
                onTap: () => onSlotSelected(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFE8ECF4),
                    ),
                  ),
                  child: Text(
                    slot,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF444466),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OnDemandBadge extends StatelessWidget {
  final String category;
  const _OnDemandBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flash_on_rounded,
            color: Color(0xFF2E7D32),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Demand Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  'Provider will arrive as soon as possible after booking.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF4CAF50),
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

class _PaymentMethodCard extends StatelessWidget {
  final List<Map<String, dynamic>> paymentMethods;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PaymentMethodCard({
    required this.paymentMethods,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Color(0xFF6A1B9A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...paymentMethods.asMap().entries.map((entry) {
            final i = entry.key;
            final method = entry.value;
            final isSelected = selectedIndex == i;
            final color = method['color'] as Color;
            return GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.07)
                      : const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE8ECF4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? color
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            method['subtitle'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF9E9EB8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? color : const Color(0xFFD0D0E0),
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

class _OrderSummaryCard extends StatelessWidget {
  final String serviceLabel;
  final String servicePrice;
  final String scheduledDate;
  final String scheduledTime;
  final String paymentMethod;

  const _OrderSummaryCard({
    required this.serviceLabel,
    required this.servicePrice,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.build_rounded,
            label: 'Service',
            value: serviceLabel,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: scheduledDate,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: scheduledTime,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.payment_rounded,
            label: 'Payment',
            value: paymentMethod,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                servicePrice,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
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

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isConfirming;
  final String servicePrice;
  final VoidCallback onConfirm;

  const _ConfirmButton({
    required this.isConfirming,
    required this.servicePrice,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
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
      child: GestureDetector(
        onTap: isConfirming ? null : onConfirm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: isConfirming
                ? const LinearGradient(
                    colors: [Color(0xFFB0BEC5), Color(0xFFB0BEC5)],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isConfirming
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isConfirming)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                isConfirming ? 'Confirming...' : 'Confirm & Pay $servicePrice',
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
    );
  }
}
