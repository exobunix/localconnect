import 'package:google_fonts/google_fonts.dart';

import '../core/app_export.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

/// A bottom sheet widget that lets users quickly pick a saved address.
/// Can be used during service booking or location change flows.
class AddressQuickSelectWidget extends StatefulWidget {
  /// Called when user selects an address. Returns the address map.
  final void Function(Map<String, dynamic> address)? onAddressSelected;

  /// If true, selecting an address also updates the customer's current location.
  final bool updateCurrentLocation;

  const AddressQuickSelectWidget({
    super.key,
    this.onAddressSelected,
    this.updateCurrentLocation = false,
  });

  /// Show the quick-select bottom sheet and return the selected address.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    bool updateCurrentLocation = false,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressQuickSelectWidget(
        updateCurrentLocation: updateCurrentLocation,
      ),
    );
  }

  @override
  State<AddressQuickSelectWidget> createState() =>
      _AddressQuickSelectWidgetState();
}

class _AddressQuickSelectWidgetState extends State<AddressQuickSelectWidget> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  bool _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final list = await SupabaseService.instance.getSavedAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _loading = false;
      });
    }
  }

  Future<void> _useGpsLocation() async {
    setState(() => _gpsLoading = true);
    final loc = await LocationService.instance.getGpsLocation();
    if (!mounted) return;
    setState(() => _gpsLoading = false);

    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not get GPS location. Please enable location services.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
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

    if (widget.updateCurrentLocation) {
      await LocationService.instance.saveCustomerLocation(loc);
    }

    final addrMap = {
      'label': 'Current GPS',
      'address_line1': loc.village.isNotEmpty ? loc.village : loc.city,
      'address_line2': '',
      'city': loc.city,
      'state': loc.state,
      'pincode': loc.pincode,
      'village': loc.village,
      'taluka': loc.taluka,
      'district': loc.district,
      'full_address': loc.fullAddress,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'location_method': 'gps',
      'is_default': false,
    };

    if (mounted) {
      widget.onAddressSelected?.call(addrMap);
      Navigator.pop(context, addrMap);
    }
  }

  void _selectAddress(Map<String, dynamic> addr) async {
    if (widget.updateCurrentLocation) {
      final lat = (addr['latitude'] as num?)?.toDouble();
      final lng = (addr['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final loc = LocationData(
          latitude: lat,
          longitude: lng,
          fullAddress: addr['full_address'] as String? ?? '',
          village: addr['village'] as String? ?? '',
          city: addr['city'] as String? ?? '',
          taluka: addr['taluka'] as String? ?? '',
          district: addr['district'] as String? ?? '',
          state: addr['state'] as String? ?? 'Maharashtra',
          pincode: addr['pincode'] as String? ?? '',
          method: addr['location_method'] as String? ?? 'manual',
        );
        await LocationService.instance.saveCustomerLocation(loc);
      }
    }
    widget.onAddressSelected?.call(addr);
    if (mounted) Navigator.pop(context, addr);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        'Choose a saved address or use GPS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF74777F),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── GPS option ──────────────────────────────────────────────────
          InkWell(
            onTap: _gpsLoading ? null : _useGpsLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _gpsLoading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.gps_fixed,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Current GPS Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Detect your location automatically',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ── Saved addresses ─────────────────────────────────────────────
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _addresses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 40,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved addresses',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add addresses in your profile for quick access',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (_, i) => _AddressTile(
                      address: _addresses[i],
                      onTap: () => _selectAddress(_addresses[i]),
                    ),
                  ),
          ),
          // ── Manage addresses link ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/customer-profile-screen');
              },
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: Text(
                'Manage Saved Addresses',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onTap;

  const _AddressTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDefault = address['is_default'] as bool? ?? false;
    final label = address['label'] as String? ?? 'Address';
    final line1 = address['address_line1'] as String? ?? '';
    final village = address['village'] as String? ?? '';
    final taluka = address['taluka'] as String? ?? '';
    final district = address['district'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final pincode = address['pincode'] as String? ?? '';

    final iconData = label.toLowerCase() == 'home'
        ? Icons.home_outlined
        : label.toLowerCase() == 'work'
        ? Icons.work_outline
        : Icons.location_on_outlined;

    final subtitle = [
      if (line1.isNotEmpty) line1,
      if (village.isNotEmpty) village,
      if (taluka.isNotEmpty) taluka,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
      if (pincode.isNotEmpty) pincode,
    ].join(', ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDefault
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: isDefault ? AppTheme.primary : const Color(0xFF78909C),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF90A4AE),
            ),
          ],
        ),
      ),
    );
  }
}
