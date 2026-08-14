import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Shop Order Confirm Screen
/// Shows full order summary before final placement.
/// Supports COD and Online payment methods.
/// Reusable across all shop subcategories.
class ShopOrderConfirmScreen extends StatefulWidget {
  const ShopOrderConfirmScreen({super.key});

  @override
  State<ShopOrderConfirmScreen> createState() => _ShopOrderConfirmScreenState();
}

class _ShopOrderConfirmScreenState extends State<ShopOrderConfirmScreen> {
  final _supabase = Supabase.instance.client;

  // Passed from checkout
  String _providerId = '';
  String _providerName = '';
  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Grocery';
  List<Map<String, dynamic>> _cartItems = [];
  double _cartTotal = 0;
  double _deliveryCharge = 0;
  double _discount = 0;
  String _deliveryType = 'home_delivery';
  String _deliveryAddress = '';
  String? _deliverySlot;
  String _paymentMethod = 'cod';
  String _specialInstructions = '';

  bool _isPlacing = false;

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
      _deliveryCharge = (args['deliveryCharge'] as num?)?.toDouble() ?? 0;
      _discount = (args['discount'] as num?)?.toDouble() ?? 0;
      _deliveryType = args['deliveryType'] as String? ?? 'home_delivery';
      _deliveryAddress = args['deliveryAddress'] as String? ?? '';
      _deliverySlot = args['deliverySlot'] as String?;
      _paymentMethod = args['paymentMethod'] as String? ?? 'cod';
      _specialInstructions = args['specialInstructions'] as String? ?? '';
    }
  }

  double get _grandTotal => _cartTotal + _deliveryCharge - _discount;

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

  Future<void> _confirmOrder() async {
    setState(() => _isPlacing = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      final orderData = {
        'customer_id': userId,
        'provider_id': _providerId.isNotEmpty ? _providerId : null,
        'shop_subcategory': _subcategoryId,
        'order_status': 'pending',
        'items': _cartItems,
        'subtotal': _cartTotal,
        'delivery_charge': _deliveryCharge,
        'discount_amount': _discount,
        'total_amount': _grandTotal,
        'delivery_type': _deliveryType,
        'delivery_address':
            _deliveryType == 'home_delivery' && _deliveryAddress.isNotEmpty
            ? {'address': _deliveryAddress}
            : null,
        'delivery_slot': _deliverySlot,
        'payment_method': _paymentMethod,
        'payment_status': _paymentMethod == 'cod' ? 'pending' : 'initiated',
        'special_instructions': _specialInstructions,
      };

      final result = await _supabase
          .from('shop_orders')
          .insert(orderData)
          .select()
          .single();

      // Create a matching entry in the unified 'orders' table
      await SupabaseService.instance.createOrder(
        providerId: _providerId.isNotEmpty ? _providerId : null,
        providerName: _providerName.isNotEmpty ? _providerName : 'Shop Partner',
        service: _subcategoryName.isNotEmpty ? _subcategoryName : 'Shop Order',
        category: 'shop',
        scheduledDate: DateTime.now().toString().split(' ').first,
        scheduledTime: _deliverySlot.isNotEmpty ? _deliverySlot : 'Now',
        amount: '₹$_grandTotal',
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.shopOrderConfirmationScreen,
          arguments: {
            'orderId': result['id'],
            'orderNumber': (result['id'] as String)
                .substring(0, 8)
                .toUpperCase(),
            'providerName': _providerName,
            'subcategoryId': _subcategoryId,
            'subcategoryName': _subcategoryName,
            'grandTotal': _grandTotal,
            'deliveryType': _deliveryType,
            'deliverySlot': _deliverySlot,
            'paymentMethod': _paymentMethod,
            'cartItems': _cartItems,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: Text(
          'Confirm Order',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order Items ──────────────────────────────────────────────────
          _buildSectionHeader(
            Icons.shopping_cart_rounded,
            'Order Items',
            '${_cartItems.length} item${_cartItems.length != 1 ? 's' : ''}',
          ),
          const SizedBox(height: 8),
          _buildItemsCard(),
          const SizedBox(height: 16),

          // ── Delivery Details ─────────────────────────────────────────────
          _buildSectionHeader(
            Icons.local_shipping_rounded,
            'Delivery Details',
            null,
          ),
          const SizedBox(height: 8),
          _buildDeliveryCard(),
          const SizedBox(height: 16),

          // ── Payment Method ───────────────────────────────────────────────
          _buildSectionHeader(Icons.payment_rounded, 'Payment Method', null),
          const SizedBox(height: 8),
          _buildPaymentCard(),
          const SizedBox(height: 16),

          // ── Special Instructions ─────────────────────────────────────────
          if (_specialInstructions.isNotEmpty) ...[
            _buildSectionHeader(
              Icons.sticky_note_2_rounded,
              'Special Instructions',
              null,
            ),
            const SizedBox(height: 8),
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 18, color: _accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _specialInstructions,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF44474E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Price Summary ────────────────────────────────────────────────
          _buildSectionHeader(
            Icons.receipt_long_rounded,
            'Price Summary',
            null,
          ),
          const SizedBox(height: 8),
          _buildPriceSummaryCard(),
          const SizedBox(height: 16),

          // ── COD Notice ───────────────────────────────────────────────────
          if (_paymentMethod == 'cod')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB300), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFF8F00),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash on Delivery: Pay ₹${_grandTotal.toStringAsFixed(0)} when your order arrives. Final amount may vary based on actual weight/quantity.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_paymentMethod != 'cod')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.infoContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: AppTheme.info,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Secure online payment. You will be redirected to complete payment after order confirmation.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // ── Action Buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPlacing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    'Edit Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    side: BorderSide(color: _accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isPlacing ? null : _confirmOrder,
                  icon: _isPlacing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isPlacing ? 'Placing...' : 'Confirm Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String? trailing) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _accentColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildItemsCard() {
    return _buildCard(
      child: Column(
        children: _cartItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          final qty = item['quantity'] as int? ?? 1;
          final total = price > 0 ? price * qty : 0.0;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accentColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: _accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        if (item['unit'] != null)
                          Text(
                            item['unit'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                          'Qty: $qty',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (i < _cartItems.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE8EAED)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return _buildCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.local_shipping_rounded,
            label: 'Delivery Type',
            value: _deliveryType == 'home_delivery'
                ? 'Home Delivery'
                : 'Self Pickup',
            accentColor: _accentColor,
          ),
          if (_deliveryType == 'home_delivery' &&
              _deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: _deliveryAddress,
              accentColor: _accentColor,
            ),
          ],
          if (_deliverySlot != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Delivery Time',
              value: _deliverySlot!,
              accentColor: _accentColor,
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.store_rounded,
            label: 'Shop',
            value: _providerName,
            accentColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    final isCod = _paymentMethod == 'cod';
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCod ? const Color(0xFFFFF8E1) : AppTheme.infoContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCod ? Icons.money_rounded : Icons.payment_rounded,
              color: isCod ? const Color(0xFFFF8F00) : AppTheme.info,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCod
                      ? 'Cash on Delivery'
                      : _paymentMethodLabel(_paymentMethod),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  isCod
                      ? 'Pay when your order is delivered'
                      : 'Secure online payment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCod
                  ? const Color(0xFFFFF8E1)
                  : AppTheme.successContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCod ? 'COD' : 'ONLINE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCod ? const Color(0xFFFF8F00) : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return _buildCard(
      child: Column(
        children: [
          _PriceRow(
            label: 'Subtotal',
            value: '₹${_cartTotal.toStringAsFixed(0)}',
          ),
          if (_deliveryCharge > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Delivery Charge',
              value: '₹${_deliveryCharge.toStringAsFixed(0)}',
            ),
          ],
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
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
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          if (_cartTotal == 0) ...[
            const SizedBox(height: 8),
            Text(
              '* Final amount will be confirmed by the provider',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF74777F),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Card Payment';
      case 'razorpay':
        return 'Razorpay';
      default:
        return 'Online Payment';
    }
  }
}

// ── Reusable Row Widgets ───────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF74777F),
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
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF74777F),
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

