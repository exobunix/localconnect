import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

/// Shop Checkout Screen - cart review, address confirmation, UPI/Card payment
class ShopCheckoutScreen extends StatefulWidget {
  const ShopCheckoutScreen({super.key});

  @override
  State<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends State<ShopCheckoutScreen> {
  String _providerId = '';
  String _providerName = '';
  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Grocery';
  List<Map<String, dynamic>> _cartItems = [];
  double _cartTotal = 0;
  List<String> _deliverySlots = [];

  String _deliveryType = 'home_delivery';
  String? _selectedSlot;
  String _paymentMethod = 'upi';
  String _selectedUpiApp = 'gpay';
  String _specialInstructions = '';
  final bool _isPlacingOrder = false;
  int _selectedAddressIndex = 0;

  final _addressCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  final _supabase = Supabase.instance.client;

  static const List<String> _defaultSlots = [
    'As soon as possible',
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'label': 'Home',
      'icon': Icons.home_rounded,
      'address': '12, Rose Garden Apartments, MG Road, Bengaluru - 560001',
      'isDefault': true,
    },
    {
      'label': 'Office',
      'icon': Icons.business_rounded,
      'address': '4th Floor, Tech Park, Whitefield, Bengaluru - 560066',
      'isDefault': false,
    },
  ];

  bool _addingNewAddress = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _providerId = args['providerId'] as String? ?? '';
      _providerName = args['providerName'] as String? ?? 'Shop';
      _subcategoryId = args['subcategoryId'] as String? ?? 'grocery';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Grocery';
      _cartItems = (args['cartItems'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _cartTotal = (args['cartTotal'] as num?)?.toDouble() ?? 0;
      _deliverySlots =
          (args['deliverySlots'] as List?)?.map((e) => e.toString()).toList() ??
          _defaultSlots;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _instructionsCtrl.dispose();
    _upiIdCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  double get _deliveryCharge =>
      _deliveryType == 'home_delivery' && _cartTotal < 500 ? 30 : 0;
  double get _discount => _cartTotal > 800 ? 50 : 0;
  double get _grandTotal => _cartTotal + _deliveryCharge - _discount;

  Future<void> _placeOrder() async {
    if (_deliveryType == 'home_delivery') {
      if (!_addingNewAddress && _savedAddresses.isEmpty) {
        _showSnack('Please add a delivery address');
        return;
      }
      if (_addingNewAddress && _addressCtrl.text.trim().isEmpty) {
        _showSnack('Please enter delivery address');
        return;
      }
    }

    String deliveryAddress = '';
    if (_deliveryType == 'home_delivery') {
      deliveryAddress = _addingNewAddress
          ? _addressCtrl.text.trim()
          : _savedAddresses[_selectedAddressIndex]['address'] as String;
    }

    // Navigate to Order Confirm screen instead of placing directly
    Navigator.pushNamed(
      context,
      AppRoutes.shopOrderConfirmScreen,
      arguments: {
        'providerId': _providerId,
        'providerName': _providerName,
        'subcategoryId': _subcategoryId,
        'subcategoryName': _subcategoryName,
        'cartItems': _cartItems,
        'cartTotal': _cartTotal,
        'deliveryCharge': _deliveryCharge,
        'discount': _discount,
        'deliveryType': _deliveryType,
        'deliveryAddress': deliveryAddress,
        'deliverySlot': _selectedSlot,
        'paymentMethod': _paymentMethod,
        'specialInstructions': _instructionsCtrl.text.trim(),
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  Color get _accentColor {
    switch (_subcategoryId) {
      case 'grocery':
        return AppTheme.catGrocery;
      case 'vegetables':
        return const Color(0xFF2E7D32);
      case 'meat_fish':
        return const Color(0xFFD32F2F);
      case 'electrical':
        return const Color(0xFFF57C00);
      case 'plumbing_hardware':
        return const Color(0xFF0277BD);
      case 'seasonal':
        return const Color(0xFFFFB300);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Checkout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withAlpha(40)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Cart Review ──────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.shopping_cart_rounded,
            title: 'Cart Review',
            accentColor: _accentColor,
            trailing: Text(
              '${_cartItems.length} item${_cartItems.length != 1 ? 's' : ''}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildCartReview(),
          const SizedBox(height: 16),

          // ── Delivery Option ──────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.local_shipping_rounded,
            title: 'Delivery Option',
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          _buildDeliveryOptions(),
          const SizedBox(height: 16),

          // ── Address Confirmation ─────────────────────────────────────────
          if (_deliveryType == 'home_delivery') ...[
            _SectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Delivery Address',
              accentColor: _accentColor,
            ),
            const SizedBox(height: 8),
            _buildAddressSection(),
            const SizedBox(height: 16),
          ],

          // ── Delivery Slot ────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.schedule_rounded,
            title: 'Delivery Time',
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          _buildDeliverySlots(),
          const SizedBox(height: 16),

          // ── Payment Method ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.payment_rounded,
            title: 'Payment Method',
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          _buildPaymentSection(),
          const SizedBox(height: 16),

          // ── Special Instructions ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.sticky_note_2_rounded,
            title: 'Special Instructions',
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          _buildCard(
            child: TextField(
              controller: _instructionsCtrl,
              maxLines: 2,
              onChanged: (v) => _specialInstructions = v,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Any special requests or notes...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF74777F),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Order Summary ────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Order Summary',
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // ── Place Order Button ───────────────────────────────────────────
          _buildPlaceOrderButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Cart Review ────────────────────────────────────────────────────────────
  Widget _buildCartReview() {
    if (_cartItems.isEmpty) {
      return _buildCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No items in cart',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
            ),
          ),
        ),
      );
    }
    return _buildCard(
      child: Column(
        children: _cartItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final itemTotal =
              (item['total_price'] ??
                      (item['price'] as num? ?? 0) *
                          (item['quantity'] as num? ?? 1))
                  as num;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item icon / image placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String? ?? 'Item',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (item['unit'] != null)
                              _SpecChip(
                                label: item['unit'] as String,
                                color: _accentColor,
                              ),
                            if (item['cut_type'] != null)
                              _SpecChip(
                                label: item['cut_type'] as String,
                                color: _accentColor,
                              ),
                            if (item['weight_kg'] != null)
                              _SpecChip(
                                label:
                                    '${(item['weight_kg'] as num).toStringAsFixed(2)} kg',
                                color: _accentColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${itemTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Qty: ${item['quantity'] ?? 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (i < _cartItems.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: const Color(0xFFE8EAED)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Delivery Options ───────────────────────────────────────────────────────
  Widget _buildDeliveryOptions() {
    return _buildCard(
      child: Column(
        children: [
          _DeliveryOption(
            icon: Icons.delivery_dining_rounded,
            title: 'Home Delivery',
            subtitle: _cartTotal >= 500
                ? 'Free delivery on this order'
                : 'Delivery charge: ₹30',
            badge: _cartTotal >= 500 ? 'FREE' : null,
            isSelected: _deliveryType == 'home_delivery',
            accentColor: _accentColor,
            onTap: () => setState(() => _deliveryType = 'home_delivery'),
          ),
          const SizedBox(height: 8),
          _DeliveryOption(
            icon: Icons.store_rounded,
            title: 'Self Pickup',
            subtitle: 'Pick up from the shop — no delivery charge',
            isSelected: _deliveryType == 'self_pickup',
            accentColor: _accentColor,
            onTap: () => setState(() => _deliveryType = 'self_pickup'),
          ),
        ],
      ),
    );
  }

  // ── Address Section ────────────────────────────────────────────────────────
  Widget _buildAddressSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saved addresses
          ..._savedAddresses.asMap().entries.map((entry) {
            final i = entry.key;
            final addr = entry.value;
            final isSelected = !_addingNewAddress && _selectedAddressIndex == i;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAddressIndex = i;
                _addingNewAddress = false;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accentColor.withAlpha(15)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _accentColor : const Color(0xFFE8EAED),
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
                            ? _accentColor.withAlpha(25)
                            : const Color(0xFFE8EAED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        addr['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? _accentColor
                            : const Color(0xFF74777F),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                addr['label'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? _accentColor
                                      : const Color(0xFF1A1C1E),
                                ),
                              ),
                              if (addr['isDefault'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addr['address'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: _accentColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),

          // Add new address toggle
          GestureDetector(
            onTap: () => setState(() => _addingNewAddress = !_addingNewAddress),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _addingNewAddress
                    ? _accentColor.withAlpha(15)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _addingNewAddress
                      ? _accentColor
                      : const Color(0xFFE8EAED),
                  width: _addingNewAddress ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _addingNewAddress
                          ? _accentColor.withAlpha(25)
                          : const Color(0xFFE8EAED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_location_alt_rounded,
                      size: 18,
                      color: _addingNewAddress
                          ? _accentColor
                          : const Color(0xFF74777F),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _addingNewAddress
                          ? _accentColor
                          : const Color(0xFF44474E),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _addingNewAddress
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF74777F),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_addingNewAddress) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: Icon(Icons.home_rounded, color: _accentColor),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Delivery Slots ─────────────────────────────────────────────────────────
  Widget _buildDeliverySlots() {
    return _buildCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _deliverySlots.map((slot) {
          final isSelected = _selectedSlot == slot;
          return GestureDetector(
            onTap: () => setState(() => _selectedSlot = slot),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withAlpha(20)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _accentColor : const Color(0xFFE8EAED),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                slot,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? _accentColor : const Color(0xFF44474E),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Payment Section ────────────────────────────────────────────────────────
  Widget _buildPaymentSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method tabs
          Row(
            children: [
              _PaymentTab(
                icon: Icons.account_balance_wallet_rounded,
                label: 'UPI',
                isSelected: _paymentMethod == 'upi',
                accentColor: _accentColor,
                onTap: () => setState(() => _paymentMethod = 'upi'),
              ),
              const SizedBox(width: 8),
              _PaymentTab(
                icon: Icons.credit_card_rounded,
                label: 'Card',
                isSelected: _paymentMethod == 'card',
                accentColor: _accentColor,
                onTap: () => setState(() => _paymentMethod = 'card'),
              ),
              const SizedBox(width: 8),
              _PaymentTab(
                icon: Icons.money_rounded,
                label: 'Cash',
                isSelected: _paymentMethod == 'cod',
                accentColor: _accentColor,
                onTap: () => setState(() => _paymentMethod = 'cod'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // UPI options
          if (_paymentMethod == 'upi') ...[
            Text(
              'Select UPI App',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _UpiAppTile(
                  label: 'GPay',
                  color: const Color(0xFF4285F4),
                  icon: Icons.g_mobiledata_rounded,
                  isSelected: _selectedUpiApp == 'gpay',
                  onTap: () => setState(() => _selectedUpiApp = 'gpay'),
                ),
                const SizedBox(width: 8),
                _UpiAppTile(
                  label: 'PhonePe',
                  color: const Color(0xFF5F259F),
                  icon: Icons.phone_android_rounded,
                  isSelected: _selectedUpiApp == 'phonepe',
                  onTap: () => setState(() => _selectedUpiApp = 'phonepe'),
                ),
                const SizedBox(width: 8),
                _UpiAppTile(
                  label: 'Paytm',
                  color: const Color(0xFF00BAF2),
                  icon: Icons.wallet_rounded,
                  isSelected: _selectedUpiApp == 'paytm',
                  onTap: () => setState(() => _selectedUpiApp = 'paytm'),
                ),
                const SizedBox(width: 8),
                _UpiAppTile(
                  label: 'BHIM',
                  color: const Color(0xFF0A6EBD),
                  icon: Icons.account_balance_rounded,
                  isSelected: _selectedUpiApp == 'bhim',
                  onTap: () => setState(() => _selectedUpiApp = 'bhim'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Or enter UPI ID',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _upiIdCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'yourname@upi',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: _accentColor,
                  size: 18,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lock_rounded, size: 11, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Secured by UPI — 256-bit encryption',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ],

          // Card options
          if (_paymentMethod == 'card') ...[
            TextField(
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: '1234  5678  9012  3456',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                labelText: 'Card Number',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
                prefixIcon: Icon(
                  Icons.credit_card_rounded,
                  color: _accentColor,
                  size: 18,
                ),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cardNameCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Name on card',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                labelText: 'Cardholder Name',
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: _accentColor,
                  size: 18,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cardExpiryCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFFADB5BD),
                      ),
                      labelText: 'Expiry',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cardCvvCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '•••',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFFADB5BD),
                      ),
                      labelText: 'CVV',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _accentColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.lock_rounded, size: 11, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  'Your card details are encrypted and secure',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ],

          // COD
          if (_paymentMethod == 'cod') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.money_rounded, color: AppTheme.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                        Text(
                          'Pay in cash when your order arrives',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return _buildCard(
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal (${_cartItems.length} items)',
            value: '₹${_cartTotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Delivery Charge',
            value: _deliveryCharge == 0
                ? 'FREE'
                : '₹${_deliveryCharge.toStringAsFixed(0)}',
            valueColor: _deliveryCharge == 0 ? AppTheme.success : null,
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Discount',
              value: '- ₹${_discount.toStringAsFixed(0)}',
              valueColor: AppTheme.success,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE8EAED)),
          ),
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
                '₹${_grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🎉 You save ₹${_discount.toStringAsFixed(0)} on this order!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Payment method badge
          Row(
            children: [
              Icon(
                _paymentMethod == 'upi'
                    ? Icons.account_balance_wallet_rounded
                    : _paymentMethod == 'card'
                    ? Icons.credit_card_rounded
                    : Icons.money_rounded,
                size: 14,
                color: const Color(0xFF74777F),
              ),
              const SizedBox(width: 5),
              Text(
                'Paying via ${_paymentMethod == 'upi'
                    ? 'UPI'
                    : _paymentMethod == 'card'
                    ? 'Card'
                    : 'Cash on Delivery'}',
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

  // ── Place Order Button ─────────────────────────────────────────────────────
  Widget _buildPlaceOrderButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Place Order  •  ₹${_grandTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 12, color: AppTheme.success),
            const SizedBox(width: 4),
            Text(
              'Safe & Secure Checkout',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SpecChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF44474E),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}

class _PaymentTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _PaymentTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accentColor : const Color(0xFFE8EAED),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF74777F),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF44474E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpiAppTile extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UpiAppTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(20) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE8EAED),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : const Color(0xFF74777F),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF44474E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withAlpha(15)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE8EAED),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : const Color(0xFF74777F),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? accentColor
                              : const Color(0xFF1A1C1E),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
