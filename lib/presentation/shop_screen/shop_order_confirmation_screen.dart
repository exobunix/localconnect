import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

/// Order confirmation screen after successful shop order placement
class ShopOrderConfirmationScreen extends StatelessWidget {
  const ShopOrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final orderId = args?['orderId'] as String? ?? '';
    final orderNumber = args?['orderNumber'] as String? ?? '';
    final providerName = args?['providerName'] as String? ?? 'Shop';
    final subcategoryName = args?['subcategoryName'] as String? ?? 'Shop';
    final subcategoryId = args?['subcategoryId'] as String? ?? 'grocery';
    final grandTotal = (args?['grandTotal'] as num?)?.toDouble() ?? 0;
    final deliveryType = args?['deliveryType'] as String? ?? 'home_delivery';
    final deliverySlot = args?['deliverySlot'] as String?;
    final paymentMethod = args?['paymentMethod'] as String? ?? 'cod';
    final cartItems = (args?['cartItems'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Success animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been sent to $providerName',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 32),
              // Order details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Order ID',
                      value: '#$orderNumber',
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Shop', value: providerName),
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Category', value: subcategoryName),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Total',
                      value: '₹${grandTotal.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Delivery',
                      value: deliveryType == 'home_delivery'
                          ? 'Home Delivery'
                          : 'Self Pickup',
                    ),
                    if (deliverySlot != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(label: 'Slot', value: deliverySlot),
                    ],
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Payment',
                      value: paymentMethod == 'cod'
                          ? 'Cash on Delivery'
                          : 'Online Payment',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Status info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.infoContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_rounded,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You will receive a notification once the shop accepts your order.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Return & Request More row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.shopReturnRequestScreen,
                        arguments: {
                          'orderId': orderId,
                          'orderNumber': '#$orderNumber',
                          'providerName': providerName,
                          'orderItems': cartItems,
                        },
                      ),
                      icon: const Icon(
                        Icons.assignment_return_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Return Goods',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.shopPhotoRequestScreen,
                        arguments: {
                          'subcategoryId': subcategoryId,
                          'subcategoryName': subcategoryName,
                          'providerId': '',
                          'providerName': providerName,
                        },
                      ),
                      icon: const Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Request More',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.homeScreen,
                        (route) => false,
                      ),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.shopOrderStatusScreen,
                        (route) => route.settings.name == AppRoutes.homeScreen,
                        arguments: {
                          'orderId': orderId,
                          'orderNumber': orderNumber,
                          'providerName': providerName,
                          'subcategoryName': subcategoryName,
                          'grandTotal': grandTotal,
                          'deliveryType': deliveryType,
                          'paymentMethod': paymentMethod,
                        },
                      ),
                      icon: const Icon(Icons.track_changes_rounded),
                      label: const Text('Track Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
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
            color: const Color(0xFF74777F),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}
