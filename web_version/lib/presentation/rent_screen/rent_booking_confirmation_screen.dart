import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class RentBookingConfirmationScreen extends StatefulWidget {
  const RentBookingConfirmationScreen({super.key});

  @override
  State<RentBookingConfirmationScreen> createState() =>
      _RentBookingConfirmationScreenState();
}

class _RentBookingConfirmationScreenState
    extends State<RentBookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final bookingId =
        args['bookingId'] as String? ??
        'RNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final listingTitle = args['listingTitle'] as String? ?? 'Premium Property';
    final subcategory = args['subcategory'] as String? ?? 'Room';
    final providerName = args['providerName'] as String? ?? 'Property Owner';
    final providerPhone = args['providerPhone'] as String? ?? '';
    final providerRating = args['providerRating'] as double? ?? 4.7;
    final address = args['address'] as String? ?? '';
    final amount = args['amount'] as String? ?? '';
    final depositAmount = args['depositAmount'] as String? ?? '';
    final bookingType =
        args['bookingType'] as String? ?? 'visit'; // visit | book | enquiry
    final visitDate = args['visitDate'] as String? ?? '';
    final visitTime = args['visitTime'] as String? ?? '';
    final moveInDate = args['moveInDate'] as String? ?? '';
    final paymentMethod = args['paymentMethod'] as String? ?? 'cash';
    final amenities = args['amenities'] as List<dynamic>? ?? [];
    final listingImage = args['listingImage'] as String? ?? '';

    final subcategoryData = _getSubcategoryData(subcategory);
    final color = subcategoryData['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero Section ──────────────────────────────────────
                    _buildHeroSection(
                      color: color,
                      subcategory: subcategory,
                      subcategoryData: subcategoryData,
                      bookingType: bookingType,
                      bookingId: bookingId,
                      scaleAnim: _scaleAnim,
                      fadeAnim: _fadeAnim,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            // ── Property Card ─────────────────────────────
                            _buildPropertyCard(
                              listingTitle: listingTitle,
                              address: address,
                              listingImage: listingImage,
                              color: color,
                              subcategory: subcategory,
                              amenities: amenities,
                            ),
                            const SizedBox(height: 16),

                            // ── Provider Card ─────────────────────────────
                            _buildProviderCard(
                              providerName: providerName,
                              providerPhone: providerPhone,
                              providerRating: providerRating,
                              color: color,
                            ),
                            const SizedBox(height: 16),

                            // ── Booking Details Card ──────────────────────
                            _buildBookingDetailsCard(
                              bookingType: bookingType,
                              visitDate: visitDate,
                              visitTime: visitTime,
                              moveInDate: moveInDate,
                              amount: amount,
                              depositAmount: depositAmount,
                              paymentMethod: paymentMethod,
                              color: color,
                            ),
                            const SizedBox(height: 16),

                            // ── What's Next Card ──────────────────────────
                            _buildWhatsNextCard(
                              bookingType: bookingType,
                              color: color,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Bottom Actions ────────────────────────────────────────────
            _buildBottomActions(context, bookingType, color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection({
    required Color color,
    required String subcategory,
    required Map<String, dynamic> subcategoryData,
    required String bookingType,
    required String bookingId,
    required Animation<double> scaleAnim,
    required Animation<double> fadeAnim,
  }) {
    final typeLabel = _getBookingTypeLabel(bookingType);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: scaleAnim,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: fadeAnim,
            child: Column(
              children: [
                Text(
                  typeLabel['title']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  typeLabel['subtitle']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        subcategoryData['icon'] as IconData,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$subcategory · $bookingId',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard({
    required String listingTitle,
    required String address,
    required String listingImage,
    required Color color,
    required String subcategory,
    required List<dynamic> amenities,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          if (listingImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                listingImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: color.withValues(alpha: 0.1),
                  child: Icon(Icons.home_rounded, color: color, size: 48),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subcategory,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listingTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Color(0xFF78909C),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF78909C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: amenities.take(4).map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF44474E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String providerName,
    required String providerPhone,
    required double providerRating,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: color, size: 26),
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
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFF9A825),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$providerRating · Property Owner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (providerPhone.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.call_rounded, color: color, size: 20),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard({
    required String bookingType,
    required String visitDate,
    required String visitTime,
    required String moveInDate,
    required String amount,
    required String depositAmount,
    required String paymentMethod,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Booking Details',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 14),
          if (visitDate.isNotEmpty) ...[
            _buildDetailRow(
              Icons.calendar_today_rounded,
              bookingType == 'visit' ? 'Visit Date' : 'Move-in Date',
              visitDate,
              const Color(0xFF7B1FA2),
            ),
            const _DividerLine(),
          ],
          if (visitTime.isNotEmpty) ...[
            _buildDetailRow(
              Icons.access_time_rounded,
              'Time',
              visitTime,
              const Color(0xFF1565C0),
            ),
            const _DividerLine(),
          ],
          if (moveInDate.isNotEmpty && bookingType == 'book') ...[
            _buildDetailRow(
              Icons.home_rounded,
              'Move-in Date',
              moveInDate,
              color,
            ),
            const _DividerLine(),
          ],
          if (amount.isNotEmpty) ...[
            _buildDetailRow(
              Icons.currency_rupee_rounded,
              bookingType == 'visit' ? 'Visit Fee' : 'Rent Amount',
              amount,
              const Color(0xFF2E7D32),
              valueColor: const Color(0xFF2E7D32),
              valueBold: true,
            ),
            if (depositAmount.isNotEmpty) ...[
              const _DividerLine(),
              _buildDetailRow(
                Icons.security_rounded,
                'Security Deposit',
                depositAmount,
                const Color(0xFFE65100),
                valueColor: const Color(0xFFE65100),
              ),
            ],
            const _DividerLine(),
          ],
          _buildDetailRow(
            Icons.payment_rounded,
            'Payment',
            _paymentLabel(paymentMethod),
            const Color(0xFF6A1B9A),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF78909C),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNextCard({
    required String bookingType,
    required Color color,
  }) {
    final steps = _getNextSteps(bookingType);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                "What's Next?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF44474E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    String bookingType,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.rentRatingsScreen,
                  arguments: {
                    'bookingType': bookingType,
                    'listingTitle': 'Your Rental',
                  },
                );
              },
              icon: const Icon(Icons.star_rounded, size: 18),
              label: Text(
                'Rate Your Experience',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.rentCustomerScreen,
                  (route) => route.settings.name == AppRoutes.homeScreen,
                );
              },
              icon: const Icon(Icons.home_rounded, size: 16),
              label: Text(
                'Browse More Rentals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _getSubcategoryData(String subcategory) {
    const data = {
      'Room': {
        'icon': Icons.bedroom_parent_rounded,
        'color': Color(0xFF26A69A),
      },
      'PG': {'icon': Icons.apartment_rounded, 'color': Color(0xFF7B1FA2)},
      'Hostel': {'icon': Icons.hotel_rounded, 'color': Color(0xFF1565C0)},
      'Villa': {'icon': Icons.villa_rounded, 'color': Color(0xFFE65100)},
      'Tools': {'icon': Icons.build_rounded, 'color': Color(0xFF2E7D32)},
    };
    return data[subcategory] ??
        {'icon': Icons.home_rounded, 'color': Color(0xFF26A69A)};
  }

  Map<String, String> _getBookingTypeLabel(String bookingType) {
    switch (bookingType) {
      case 'visit':
        return {
          'title': 'Visit Scheduled!',
          'subtitle':
              'Your property visit has been confirmed.\nThe owner will contact you shortly.',
        };
      case 'enquiry':
        return {
          'title': 'Enquiry Sent!',
          'subtitle':
              'Your enquiry has been sent to the owner.\nExpect a response within 24 hours.',
        };
      default:
        return {
          'title': 'Booking Confirmed!',
          'subtitle':
              'Your rental booking is confirmed.\nThe owner will reach out to finalize details.',
        };
    }
  }

  List<String> _getNextSteps(String bookingType) {
    switch (bookingType) {
      case 'visit':
        return [
          'Owner reviews and confirms your visit request',
          'You receive a confirmation call or message',
          'Visit the property at the scheduled time',
          'Decide to book and complete the rental process',
        ];
      case 'enquiry':
        return [
          'Owner reviews your enquiry details',
          'Owner contacts you within 24 hours',
          'Discuss terms and schedule a property visit',
          'Finalize booking and make payment',
        ];
      default:
        return [
          'Owner confirms your booking request',
          'Complete security deposit payment if applicable',
          'Receive keys and move-in on the scheduled date',
          'Rate your experience after settling in',
        ];
    }
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'upi':
        return 'UPI / QR Code';
      case 'card':
        return 'Credit / Debit Card';
      case 'netbanking':
        return 'Net Banking';
      default:
        return 'Cash / On-site';
    }
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF0F0F0));
  }
}
