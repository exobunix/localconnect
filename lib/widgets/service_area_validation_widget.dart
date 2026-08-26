import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';

/// Widget that validates service area eligibility before booking confirmation
class ServiceAreaValidationWidget extends StatefulWidget {
  final String providerId;
  final VoidCallback onEligible;
  final Widget child;

  const ServiceAreaValidationWidget({
    super.key,
    required this.providerId,
    required this.onEligible,
    required this.child,
  });

  @override
  State<ServiceAreaValidationWidget> createState() =>
      _ServiceAreaValidationWidgetState();
}

class _ServiceAreaValidationWidgetState
    extends State<ServiceAreaValidationWidget> {
  bool _isChecking = false;
  bool? _isEligible;
  String? _reason;
  double? _distanceKm;
  String? _matchType;
  List<Map<String, dynamic>> _alternativeProviders = [];

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    setState(() => _isChecking = true);

    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (!uuidRegex.hasMatch(widget.providerId)) {
      setState(() {
        _isEligible = true;
        _isChecking = false;
      });
      return;
    }

    final customerLoc = await LocationService.instance.getCustomerLocation();
    if (customerLoc == null || customerLoc.latitude == 0) {
      // No location set — allow booking but suggest setting location
      setState(() {
        _isEligible = true;
        _isChecking = false;
      });
      return;
    }

    final result = await LocationService.instance.validateServiceArea(
      providerId: widget.providerId,
      customerLat: customerLoc.latitude,
      customerLng: customerLoc.longitude,
      customerVillage: customerLoc.village,
      customerTaluka: customerLoc.taluka,
      customerDistrict: customerLoc.district,
    );

    final eligible = result['eligible'] as bool? ?? true;
    final reason = result['reason'] as String?;
    final distance = (result['distance_km'] as num?)?.toDouble();
    final matchType = result['match_type'] as String?;

    if (!eligible) {
      // Load alternative providers
      final alternatives = await LocationService.instance.getNearbyProviders(
        lat: customerLoc.latitude,
        lng: customerLoc.longitude,
        radiusKm: 50,
        village: customerLoc.village,
        taluka: customerLoc.taluka,
        district: customerLoc.district,
        limit: 3,
      );
      if (mounted) {
        setState(() {
          _alternativeProviders = alternatives
              .where((p) => p['id'] != widget.providerId)
              .take(3)
              .toList();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isEligible = eligible;
        _reason = reason;
        _distanceKm = distance;
        _matchType = matchType;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade600,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Checking service area eligibility...',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          widget.child,
        ],
      );
    }

    if (_isEligible == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_distanceKm != null && _distanceKm! > 0)
            Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _matchType == 'radius'
                        ? Icons.gps_fixed
                        : Icons.location_city_outlined,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _matchType == 'radius'
                        ? LocationService.instance.formatDistance(_distanceKm!)
                        : 'Serving your area',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          widget.child,
        ],
      );
    }

    // Not eligible
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    color: Colors.red.shade700,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _reason ??
                          'This provider does not currently serve your location.',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_alternativeProviders.isNotEmpty) ...[
                SizedBox(height: 1.5.h),
                Text(
                  'Nearby providers who serve your area:',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 0.8.h),
                ..._alternativeProviders.map(
                  (p) => _AlternativeProviderTile(
                    provider: p,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.providerProfileScreen,
                      arguments: {'providerId': p['id']},
                    ),
                  ),
                ),
              ],
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/customer-location-setup-screen',
                  ),
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                  label: Text(
                    'Update My Location',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlternativeProviderTile extends StatelessWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onTap;

  const _AlternativeProviderTile({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final distance = (provider['distance_km'] as num?)?.toDouble();
    final matchType = provider['match_type'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 0.8.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.store_outlined, color: AppTheme.primary, size: 5.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['business_name'] as String? ??
                        provider['shop_name'] as String? ??
                        'Provider',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    distance != null && distance > 0
                        ? LocationService.instance.formatDistance(distance)
                        : matchType == 'area'
                        ? 'Serving your area'
                        : '',
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
