import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class TransportQuotationScreen extends StatefulWidget {
  const TransportQuotationScreen({super.key});

  @override
  State<TransportQuotationScreen> createState() =>
      _TransportQuotationScreenState();
}

class _TransportQuotationScreenState extends State<TransportQuotationScreen> {
  Map<String, dynamic> _args = {};
  List<Map<String, dynamic>> _selectedProviders = [];
  String _vehicleLabel = 'Transport';
  Color _vehicleColor = AppTheme.catTransport;
  bool _hasGoods = false;

  // Quotation state
  List<Map<String, dynamic>> _quotations = [];
  bool _isWaiting = true;
  String? _confirmedProviderId;
  bool _isConfirming = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _args = Map<String, dynamic>.from(args);
      _selectedProviders = List<Map<String, dynamic>>.from(
        _args['selectedProviders'] as List? ?? [],
      );
      _vehicleLabel = _args['vehicleLabel'] as String? ?? 'Transport';
      final colorVal = _args['vehicleColor'] as int?;
      if (colorVal != null) _vehicleColor = Color(colorVal);
      final vt = _args['vehicleType'] as String? ?? '';
      _hasGoods = ['tempo', 'pickup_van', 'truck'].contains(vt);
      _generateMockQuotations();
    }
  }

  void _generateMockQuotations() {
    // Simulate quotations arriving from providers
    // In production these would come from Supabase realtime
    final fares = [850, 720, 950, 680, 800];
    final etas = [15, 22, 10, 30, 18];

    _quotations = List.generate(_selectedProviders.length, (i) {
      final p = _selectedProviders[i];
      return {
        'provider_id': p['id'],
        'provider_name': p['business_name'],
        'rating': p['rating'],
        'review_count': p['review_count'],
        'vehicle_no': p['vehicle_no'] ?? 'MH15 XX ${1000 + i}',
        'fare': fares[i % fares.length],
        'eta_minutes': etas[i % etas.length],
        'note': i == 1
            ? 'Includes loading assistance'
            : i == 3
            ? 'AC vehicle, experienced driver'
            : '',
        'received': true,
      };
    });

    // Simulate delay for quotation arrival
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isWaiting = false);
    });
  }

  void _confirmQuotation(String providerId) async {
    setState(() {
      _isConfirming = true;
      _confirmedProviderId = providerId;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final q = _quotations.firstWhere((q) => q['provider_id'] == providerId);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.transportPostPaymentScreen,
      arguments: {
        'providerName': q['provider_name'],
        'provider_name': q['provider_name'],
        'rating': q['rating'],
        'review_count': q['review_count'],
        'vehicleNo': q['vehicle_no'],
        'vehicle_no': q['vehicle_no'],
        'fare': q['fare'],
        'amount': q['fare'],
        'etaMinutes': q['eta_minutes'],
        'eta_minutes': q['eta_minutes'],
        'pickup': _args['pickup'] ?? '',
        'drop': _args['drop'] ?? '',
        'vehicleType': _args['vehicleType'] ?? 'rickshaw',
        'paymentRef':
            'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _vehicleColor,
        title: Text(
          _hasGoods ? 'Compare Quotations' : 'Confirm Booking',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTripSummaryCard(),
          if (_isWaiting && _hasGoods)
            Expanded(child: _buildWaitingState())
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_hasGoods) ...[
                    _buildPrivacyNotice(),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _hasGoods
                        ? '${_quotations.length} Quotations Received'
                        : 'Available Providers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._quotations.map((q) => _buildQuotationCard(q)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    final pickup = _args['pickup'] as String? ?? '';
    final drop = _args['drop'] as String? ?? '';
    final goodsType = _args['goodsType'] as String?;
    final weight = _args['weight'] as String?;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: _vehicleColor),
              const SizedBox(width: 6),
              Text(
                'Trip Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _tripRow(Icons.my_location_rounded, AppTheme.success, pickup),
          const SizedBox(height: 6),
          _tripRow(Icons.location_on_rounded, AppTheme.error, drop),
          if (goodsType != null) ...[
            const SizedBox(height: 6),
            _tripRow(
              Icons.inventory_2_rounded,
              _vehicleColor,
              '$goodsType${weight != null && weight.isNotEmpty ? " • ${weight}kg" : ""}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _tripRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF44474E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _vehicleColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Waiting for quotations...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Providers are reviewing your request',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.infoContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppTheme.info),
                const SizedBox(width: 6),
                Text(
                  'Quotations are private & confidential',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, size: 18, color: AppTheme.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Private Quotation System — Providers cannot see each other\'s bids or details until you confirm.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> q) {
    final providerId = q['provider_id'] as String;
    final isConfirmed = _confirmedProviderId == providerId;
    final name = q['provider_name'] as String? ?? 'Provider';
    final rating = (q['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = q['review_count'] as int? ?? 0;
    final fare = q['fare'] as int? ?? 0;
    final eta = q['eta_minutes'] as int? ?? 0;
    final vehicleNo = q['vehicle_no'] as String? ?? '';
    final note = q['note'] as String? ?? '';

    // Find best fare for highlighting
    final fares = _quotations.map((q) => q['fare'] as int? ?? 0).toList();
    final minFare = fares.reduce((a, b) => a < b ? a : b);
    final isBestFare = fare == minFare;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestFare ? AppTheme.success : Colors.transparent,
          width: 1.5,
        ),
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
          if (isBestFare)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: const BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_up_rounded,
                    size: 12,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Best Fare',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _vehicleColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _vehicleColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${rating.toStringAsFixed(1)} ($reviewCount)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$fare',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _vehicleColor,
                          ),
                        ),
                        Text(
                          'Estimated fare',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip(
                      Icons.access_time_rounded,
                      '$eta min ETA',
                      AppTheme.warningContainer,
                      AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.directions_car_rounded,
                      vehicleNo,
                      AppTheme.surfaceVariant,
                      const Color(0xFF44474E),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 12,
                          color: Color(0xFF74777F),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF74777F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConfirming
                        ? null
                        : () => _confirmQuotation(providerId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConfirmed
                          ? AppTheme.success
                          : _vehicleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isConfirming && isConfirmed
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm This Quotation',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _infoChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
