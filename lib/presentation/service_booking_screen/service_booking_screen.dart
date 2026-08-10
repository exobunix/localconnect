import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  // Date/time selection state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  int _selectedPaymentIndex = 0;
  final _notesController = TextEditingController();

  // Available time slots
  final List<String> _timeSlots = [
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
      'id': 'razorpay',
      'label': 'Razorpay',
      'subtitle': 'Cards, UPI, Wallets',
      'icon': Icons.payment_rounded,
      'color': Color(0xFF3395FF),
    },
    {
      'id': 'cash',
      'label': 'Cash on Delivery',
      'subtitle': 'Pay after service',
      'icon': Icons.money_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'id': 'upi',
      'label': 'UPI / QR Code',
      'subtitle': 'PhonePe, GPay, Paytm',
      'icon': Icons.qr_code_rounded,
      'color': Color(0xFF6A1B9A),
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Generate next 7 days for date picker
  List<DateTime> get _availableDates {
    final today = DateTime.now();
    return List.generate(7, (i) => today.add(Duration(days: i + 1)));
  }

  String _formatDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatMonthDay(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _proceedToPayment(Map<String, dynamic> args) {
    final category = args['category'] as String? ?? '';
    final isOnDemand = _isOnDemandCategory(category);

    // On-demand services (transport, home maintenance) don't require slot selection
    if (!isOnDemand && _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a time slot',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final selectedPayment = _paymentMethods[_selectedPaymentIndex];
    final dateStr = _formatMonthDay(_selectedDate);
    final dayStr = _formatDayName(_selectedDate);

    Navigator.pushNamed(
      context,
      AppRoutes.bookingCheckoutScreen,
      arguments: {
        ...args,
        'scheduledDate': isOnDemand ? 'Now' : '$dayStr, $dateStr',
        'scheduledTime': isOnDemand ? 'On Demand' : _selectedTimeSlot,
        'paymentMethod': selectedPayment['id'],
        'notes': _notesController.text.trim(),
      },
    );
  }

  /// Returns true for on-demand categories that don't use appointment slots
  bool _isOnDemandCategory(String category) {
    const onDemandCategories = [
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
    return onDemandCategories.contains(category.toLowerCase());
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
    final providerName = args['providerName'] as String? ?? '';
    final providerRating = args['providerRating'] as double? ?? 4.8;
    final providerJobsCount = args['providerJobsCount'] as int? ?? 120;
    final basePrice =
        args['basePrice'] as String? ??
        args['price'] as String? ??
        args['amount'] as String? ??
        '₹0';
    final duration = args['duration'] as String? ?? '1-2 hrs';
    final category = args['category'] as String? ?? '';
    final providerImage = args['providerImage'] as String? ?? '';
    final serviceDescription =
        args['serviceDescription'] as String? ??
        'Professional service delivered at your doorstep by a verified expert.';

    final isOnDemand = _isOnDemandCategory(category);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            _BookingAppBar(serviceName: serviceName),

            // ── Scrollable Content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Details Card
                    _ServiceDetailsCard(
                      serviceName: serviceName,
                      providerName: providerName,
                      providerRating: providerRating,
                      providerJobsCount: providerJobsCount,
                      basePrice: basePrice,
                      duration: duration,
                      category: category,
                      providerImage: providerImage,
                      serviceDescription: serviceDescription,
                    ),
                    SizedBox(height: 2.h),

                    // On-demand availability banner (replaces slot selection for transport)
                    if (isOnDemand) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This is an on-demand service. No appointment slot needed — the provider will respond to your request in real time.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Date Selection (only for appointment-based services)
                    if (!isOnDemand) ...[
                      _SectionHeader(
                        icon: Icons.calendar_today_rounded,
                        title: 'Select Date',
                        color: AppTheme.primary,
                      ),
                      SizedBox(height: 1.h),
                      _DateSelector(
                        availableDates: _availableDates,
                        selectedDate: _selectedDate,
                        isSameDay: _isSameDay,
                        formatDayName: _formatDayName,
                        formatMonthDay: _formatMonthDay,
                        onDateSelected: (date) =>
                            setState(() => _selectedDate = date),
                      ),
                      SizedBox(height: 2.h),

                      // Time Slot Selection
                      _SectionHeader(
                        icon: Icons.access_time_rounded,
                        title: 'Select Time Slot',
                        color: AppTheme.info,
                      ),
                      SizedBox(height: 1.h),
                      _TimeSlotGrid(
                        timeSlots: _timeSlots,
                        selectedSlot: _selectedTimeSlot,
                        onSlotSelected: (slot) =>
                            setState(() => _selectedTimeSlot = slot),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Payment Method
                    _SectionHeader(
                      icon: Icons.payment_rounded,
                      title: 'Payment Method',
                      color: const Color(0xFF6A1B9A),
                    ),
                    SizedBox(height: 1.h),
                    _PaymentMethodSelector(
                      methods: _paymentMethods,
                      selectedIndex: _selectedPaymentIndex,
                      onSelected: (i) =>
                          setState(() => _selectedPaymentIndex = i),
                    ),
                    SizedBox(height: 2.h),

                    // Special Instructions
                    _SectionHeader(
                      icon: Icons.notes_rounded,
                      title: 'Special Instructions',
                      color: AppTheme.warning,
                      subtitle: 'Optional',
                    ),
                    SizedBox(height: 1.h),
                    _NotesField(controller: _notesController),
                    SizedBox(height: 2.h),

                    // Price Summary
                    _PriceSummaryCard(basePrice: basePrice, duration: duration),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────
            _BottomCTA(
              selectedTimeSlot: _selectedTimeSlot,
              selectedDate: _selectedDate,
              formatDayName: _formatDayName,
              formatMonthDay: _formatMonthDay,
              onProceed: () => _proceedToPayment(args),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _BookingAppBar extends StatelessWidget {
  final String serviceName;
  const _BookingAppBar({required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  serviceName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Secure',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: const Color(0xFF74777F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Service Details Card ──────────────────────────────────────────────────────
class _ServiceDetailsCard extends StatelessWidget {
  final String serviceName;
  final String providerName;
  final double providerRating;
  final int providerJobsCount;
  final String basePrice;
  final String duration;
  final String category;
  final String providerImage;
  final String serviceDescription;

  const _ServiceDetailsCard({
    required this.serviceName,
    required this.providerName,
    required this.providerRating,
    required this.providerJobsCount,
    required this.basePrice,
    required this.duration,
    required this.category,
    required this.providerImage,
    required this.serviceDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Header gradient band
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  AppTheme.primaryLight.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF9A825),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            providerRating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF57F17),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($providerJobsCount jobs)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              color: const Color(0xFF90A4AE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Provider info
          if (providerName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryContainer,
                    backgroundImage: providerImage.isNotEmpty
                        ? NetworkImage(providerImage)
                        : null,
                    child: providerImage.isEmpty
                        ? Text(
                            providerName[0].toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppTheme.success,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Verified Provider',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                      color: AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Open Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Text(
              serviceDescription,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: const Color(0xFF546E7A),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Price & Duration chips
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.currency_rupee_rounded,
                  label: basePrice,
                  color: AppTheme.success,
                  bgColor: AppTheme.successContainer,
                ),
                const SizedBox(width: 10),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: duration,
                  color: AppTheme.info,
                  bgColor: AppTheme.infoContainer,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: AppTheme.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Insured',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Selector ─────────────────────────────────────────────────────────────
class _DateSelector extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime selectedDate;
  final bool Function(DateTime, DateTime) isSameDay;
  final String Function(DateTime) formatDayName;
  final String Function(DateTime) formatMonthDay;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.availableDates,
    required this.selectedDate,
    required this.isSameDay,
    required this.formatDayName,
    required this.formatMonthDay,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: availableDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final date = availableDates[i];
          final isSelected = isSameDay(date, selectedDate);
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppTheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formatDayName(date),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF74777F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMonthDay(date).split(' ')[0],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF90A4AE),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Time Slot Grid ────────────────────────────────────────────────────────────
class _TimeSlotGrid extends StatelessWidget {
  final List<String> timeSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  const _TimeSlotGrid({
    required this.timeSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: timeSlots.map((slot) {
        final isSelected = slot == selectedSlot;
        return GestureDetector(
          onTap: () => onSlotSelected(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.outlineVariant,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: isSelected ? Colors.white : AppTheme.info,
                ),
                const SizedBox(width: 5),
                Text(
                  slot,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Payment Method Selector ───────────────────────────────────────────────────
class _PaymentMethodSelector extends StatelessWidget {
  final List<Map<String, dynamic>> methods;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PaymentMethodSelector({
    required this.methods,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(methods.length, (i) {
        final method = methods[i];
        final isSelected = i == selectedIndex;
        final color = method['color'] as Color;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : AppTheme.outlineVariant,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    method['icon'] as IconData,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        method['subtitle'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : AppTheme.outline,
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Notes Field ───────────────────────────────────────────────────────────────
class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.sp,
          color: const Color(0xFF1A1C1E),
        ),
        decoration: InputDecoration(
          hintText: 'E.g. Please bring your own tools, call before arriving...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: const Color(0xFF90A4AE),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

// ── Price Summary Card ────────────────────────────────────────────────────────
class _PriceSummaryCard extends StatelessWidget {
  final String basePrice;
  final String duration;

  const _PriceSummaryCard({required this.basePrice, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.06),
            AppTheme.primaryLight.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          _PriceRow(label: 'Service Charge', value: basePrice),
          const SizedBox(height: 6),
          _PriceRow(label: 'Platform Fee', value: '₹0'),
          const SizedBox(height: 6),
          _PriceRow(label: 'Taxes & Charges', value: 'Included'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFDDE3EA)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                basePrice,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.info,
                size: 13,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Final price may vary based on actual work. Duration: $duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: AppTheme.info,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: const Color(0xFF546E7A),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────
class _BottomCTA extends StatelessWidget {
  final String? selectedTimeSlot;
  final DateTime selectedDate;
  final String Function(DateTime) formatDayName;
  final String Function(DateTime) formatMonthDay;
  final VoidCallback onProceed;

  const _BottomCTA({
    required this.selectedTimeSlot,
    required this.selectedDate,
    required this.formatDayName,
    required this.formatMonthDay,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final hasSlot = selectedTimeSlot != null;
    final dayStr = formatDayName(selectedDate);
    final dateStr = formatMonthDay(selectedDate);

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
          // Selected slot summary
          if (hasSlot)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: AppTheme.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$dayStr, $dateStr at $selectedTimeSlot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 16,
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSlot ? AppTheme.primary : AppTheme.outline,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: hasSlot ? 2 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    hasSlot ? 'Proceed to Payment' : 'Select a Time Slot',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasSlot) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
