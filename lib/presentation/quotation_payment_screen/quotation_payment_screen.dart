import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class QuotationPaymentScreen extends StatefulWidget {
  const QuotationPaymentScreen({super.key});

  @override
  State<QuotationPaymentScreen> createState() => _QuotationPaymentScreenState();
}

class _QuotationPaymentScreenState extends State<QuotationPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _selectedMethod = 'upi'; // upi | card | netbanking
  String _selectedUpiApp = 'gpay';
  String _selectedBank = 'sbi';
  bool _isProcessing = false;

  // Card form
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
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
    _upiIdCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtAmount(dynamic val) {
    if (val == null) return '₹0';
    final amount = val is num
        ? val.toDouble()
        : double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
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
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _fmtTime(String? raw) {
    if (raw == null) return '';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  Future<void> _processPayment(Map<String, dynamic> booking) async {
    if (_isProcessing) return;

    // Validate inputs
    if (_selectedMethod == 'upi' && _selectedUpiApp == 'other') {
      final upiId = _upiIdCtrl.text.trim();
      if (upiId.isEmpty || !upiId.contains('@')) {
        _showSnack('Please enter a valid UPI ID (e.g. name@upi)');
        return;
      }
    }
    if (_selectedMethod == 'card') {
      if (_cardNumberCtrl.text.replaceAll(' ', '').length < 16) {
        _showSnack('Please enter a valid 16-digit card number');
        return;
      }
      if (_cardNameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter the cardholder name');
        return;
      }
      if (_expiryCtrl.text.length < 5) {
        _showSnack('Please enter a valid expiry date (MM/YY)');
        return;
      }
      if (_cvvCtrl.text.length < 3) {
        _showSnack('Please enter a valid CVV');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final orderId = booking['id'] as String?;
      if (orderId == null) throw Exception('Invalid booking');

      // Update payment status in orders table
      await SupabaseService.instance.client
          .from('orders')
          .update({
            'payment_status': 'paid',
            'payment_method': _selectedMethod,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      if (!mounted) return;

      // Navigate to success screen
      Navigator.pushReplacementNamed(
        context,
        '/quotation-payment-success-screen',
        arguments: {
          'booking': booking,
          'paymentMethod': _selectedMethod,
          'amount': booking['total_amount'],
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Payment failed. Please try again.');
      }
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final booking = args['booking'] as Map<String, dynamic>? ?? {};

    final provider = booking['provider'];
    final providerName = provider is Map
        ? (provider['business_name'] as String?) ?? 'Provider'
        : 'Provider';
    final providerCategory = provider is Map
        ? (provider['category'] as String?) ?? ''
        : '';
    final providerCity = provider is Map
        ? (provider['city'] as String?) ?? ''
        : '';
    final providerImage = provider is Map
        ? (provider['image_url'] as String?)
        : null;

    final serviceName =
        (booking['service_name'] as String?) ?? 'Service Booking';
    final orderNumber = (booking['order_number'] as String?) ?? '—';
    final scheduledDate = booking['scheduled_date'] as String?;
    final scheduledTime = booking['scheduled_time'] as String?;
    final totalAmount = booking['total_amount'];
    final notes = (booking['notes'] as String?) ?? '';
    final address = (booking['address'] as String?) ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking summary card
              _buildBookingSummaryCard(
                providerName: providerName,
                providerCategory: providerCategory,
                providerCity: providerCity,
                providerImage: providerImage,
                serviceName: serviceName,
                orderNumber: orderNumber,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                totalAmount: totalAmount,
                notes: notes,
                address: address,
              ),
              SizedBox(height: 2.h),

              // Amount breakdown
              _buildAmountCard(totalAmount),
              SizedBox(height: 2.h),

              // Payment method selector
              _buildPaymentMethodSection(),
              SizedBox(height: 3.h),

              // Pay button
              _buildPayButton(booking, totalAmount),
              SizedBox(height: 2.h),

              // Security note
              _buildSecurityNote(),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Payment',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Secure checkout',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 11,
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
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SSL Secured',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard({
    required String providerName,
    required String providerCategory,
    required String providerCity,
    String? providerImage,
    required String serviceName,
    required String orderNumber,
    String? scheduledDate,
    String? scheduledTime,
    dynamic totalAmount,
    required String notes,
    required String address,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Accepted',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.primaryContainer,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: providerImage != null && providerImage.isNotEmpty
                          ? Image.network(
                              providerImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.store_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            )
                          : const Icon(
                              Icons.store_rounded,
                              color: AppTheme.primary,
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
                              color: const Color(0xFF1A1C1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (providerCategory.isNotEmpty ||
                              providerCity.isNotEmpty)
                            Text(
                              [
                                providerCategory,
                                providerCity,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEF0F4)),
                const SizedBox(height: 14),

                // Details rows
                _detailRow(Icons.build_circle_outlined, 'Service', serviceName),
                const SizedBox(height: 10),
                _detailRow(
                  Icons.confirmation_number_outlined,
                  'Order No.',
                  orderNumber,
                  valueColor: AppTheme.primary,
                  valueBold: true,
                ),
                if (scheduledDate != null) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Scheduled',
                    scheduledTime != null
                        ? '${_fmtDate(scheduledDate)} at ${_fmtTime(scheduledTime)}'
                        : _fmtDate(scheduledDate),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(Icons.location_on_outlined, 'Address', address),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(Icons.notes_rounded, 'Notes', notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.outline),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1A1C1E),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(dynamic totalAmount) {
    final amount = totalAmount is num
        ? totalAmount.toDouble()
        : double.tryParse(
                totalAmount?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ??
                    '0',
              ) ??
              0.0;
    final platformFee = (amount * 0.02).roundToDouble();
    final gst = (amount * 0.18).roundToDouble();
    final total = amount + platformFee + gst;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Amount Breakdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
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
                _amountRow('Service Amount', '₹${amount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _amountRow(
                  'Platform Fee (2%)',
                  '₹${platformFee.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _amountRow('GST (18%)', '₹${gst.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFEEF0F4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Payable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.outline,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payment_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Method tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _methodTab('upi', Icons.account_balance_wallet_rounded, 'UPI'),
                const SizedBox(width: 8),
                _methodTab('card', Icons.credit_card_rounded, 'Card'),
                const SizedBox(width: 8),
                _methodTab(
                  'netbanking',
                  Icons.account_balance_rounded,
                  'Net Banking',
                ),
              ],
            ),
          ),

          // Method content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _selectedMethod == 'upi'
                ? _buildUpiSection()
                : _selectedMethod == 'card'
                ? _buildCardSection()
                : _buildNetBankingSection(),
          ),
        ],
      ),
    );
  }

  Widget _methodTab(String method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE1E8EF),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.outline,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiSection() {
    return Padding(
      key: const ValueKey('upi'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select UPI App',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _upiAppTile('gpay', 'Google Pay', '💳'),
              const SizedBox(width: 8),
              _upiAppTile('phonepe', 'PhonePe', '📱'),
              const SizedBox(width: 8),
              _upiAppTile('paytm', 'Paytm', '💰'),
              const SizedBox(width: 8),
              _upiAppTile('other', 'Other', '🔗'),
            ],
          ),
          if (_selectedUpiApp == 'other') ...[
            const SizedBox(height: 14),
            Text(
              'Enter UPI ID',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _upiIdCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'yourname@upi',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.outline,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: AppTheme.outline,
                  size: 18,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.infoContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.info,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be redirected to your UPI app to complete the payment.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upiAppTile(String app, String label, String emoji) {
    final isSelected = _selectedUpiApp == app;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUpiApp = app),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.08)
                : const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE1E8EF),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.outline,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection() {
    return Padding(
      key: const ValueKey('card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardField(
            controller: _cardNumberCtrl,
            label: 'Card Number',
            hint: '1234 5678 9012 3456',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            maxLength: 19,
          ),
          const SizedBox(height: 12),
          _cardField(
            controller: _cardNameCtrl,
            label: 'Cardholder Name',
            hint: 'Name as on card',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _cardField(
                  controller: _expiryCtrl,
                  label: 'Expiry',
                  hint: 'MM/YY',
                  icon: Icons.date_range_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cardField(
                  controller: _cvvCtrl,
                  label: 'CVV',
                  hint: '•••',
                  icon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppTheme.success,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Your card details are encrypted and secure.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.outline,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppTheme.outline, size: 18),
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetBankingSection() {
    final banks = [
      {'id': 'sbi', 'name': 'State Bank of India', 'short': 'SBI'},
      {'id': 'hdfc', 'name': 'HDFC Bank', 'short': 'HDFC'},
      {'id': 'icici', 'name': 'ICICI Bank', 'short': 'ICICI'},
      {'id': 'axis', 'name': 'Axis Bank', 'short': 'Axis'},
      {'id': 'kotak', 'name': 'Kotak Mahindra', 'short': 'Kotak'},
      {'id': 'pnb', 'name': 'Punjab National Bank', 'short': 'PNB'},
    ];

    return Padding(
      key: const ValueKey('netbanking'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Bank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          ...banks.map(
            (bank) => _bankTile(bank['id']!, bank['name']!, bank['short']!),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be redirected to your bank\'s secure portal.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankTile(String id, String name, String short) {
    final isSelected = _selectedBank == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedBank = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE1E8EF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : const Color(0xFFE8EDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  short.substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.primary : AppTheme.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFF1A1C1E),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayButton(Map<String, dynamic> booking, dynamic totalAmount) {
    final amount = totalAmount is num
        ? totalAmount.toDouble()
        : double.tryParse(
                totalAmount?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ??
                    '0',
              ) ??
              0.0;
    final platformFee = (amount * 0.02).roundToDouble();
    final gst = (amount * 0.18).roundToDouble();
    final total = amount + platformFee + gst;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _processPayment(booking),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.outline,
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
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${total.toStringAsFixed(0)} Securely',
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

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppTheme.outline,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          '256-bit SSL encrypted • PCI DSS compliant',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }
}

// ─── Input Formatters ──────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
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
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}
