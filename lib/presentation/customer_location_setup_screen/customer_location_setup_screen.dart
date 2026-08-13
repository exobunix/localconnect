import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../widgets/address_quick_select_widget.dart';

/// Customer location setup screen — GPS / Map Pin / Manual
class CustomerLocationSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  const CustomerLocationSetupScreen({super.key, this.isFirstTime = false});

  @override
  State<CustomerLocationSetupScreen> createState() =>
      _CustomerLocationSetupScreenState();
}

class _CustomerLocationSetupScreenState
    extends State<CustomerLocationSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;
  String? _error;
  LocationData? _resolvedLocation;

  // GPS tab
  bool _gpsLoading = false;

  // Map tab
  final MapController _mapController = MapController();
  LatLng _mapPin = const LatLng(18.5204, 73.8567);
  bool _mapGeocoding = false;

  // Manual tab
  final _villageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _talukaCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Maharashtra');
  final _pincodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _villageCtrl.dispose();
    _cityCtrl.dispose();
    _talukaCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ─── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _useGpsLocation() async {
    setState(() {
      _gpsLoading = true;
      _error = null;
    });
    final loc = await LocationService.instance.getGpsLocation();
    if (!mounted) return;
    if (loc == null) {
      setState(() {
        _gpsLoading = false;
        _error =
            'Could not get GPS location. Please enable location services and try again.';
      });
      return;
    }
    setState(() {
      _gpsLoading = false;
      _resolvedLocation = loc;
    });
    _showConfirmDialog(loc);
  }

  // ─── Map ──────────────────────────────────────────────────────────────────

  Future<void> _confirmMapPin() async {
    setState(() => _mapGeocoding = true);
    final loc = await LocationService.instance.reverseGeocode(
      _mapPin.latitude,
      _mapPin.longitude,
    );
    if (!mounted) return;
    setState(() => _mapGeocoding = false);
    final resolved =
        loc ??
        LocationData(
          latitude: _mapPin.latitude,
          longitude: _mapPin.longitude,
          fullAddress:
              '${_mapPin.latitude.toStringAsFixed(4)}, ${_mapPin.longitude.toStringAsFixed(4)}',
          method: 'map',
        );
    _showConfirmDialog(resolved);
  }

  // ─── Manual ───────────────────────────────────────────────────────────────

  void _saveManual() {
    if (_districtCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter at least your district.');
      return;
    }
    final loc = LocationData(
      latitude: 0,
      longitude: 0,
      fullAddress: [
        _addressCtrl.text.trim(),
        _villageCtrl.text.trim(),
        _cityCtrl.text.trim(),
        _talukaCtrl.text.trim(),
        _districtCtrl.text.trim(),
        _stateCtrl.text.trim(),
        _pincodeCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(', '),
      village: _villageCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      taluka: _talukaCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      method: 'manual',
    );
    _showConfirmDialog(loc);
  }

  // ─── Confirm & Save ───────────────────────────────────────────────────────

  void _showConfirmDialog(LocationData loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationConfirmSheet(
        location: loc,
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _isLoading = true);
          await LocationService.instance.saveCustomerLocation(loc);
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSuccess();
        },
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isFirstTime ? 'Set Your Location' : 'Change Location',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.gps_fixed, size: 18), text: 'GPS'),
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Map Pin'),
            Tab(
              icon: Icon(Icons.edit_location_alt_outlined, size: 18),
              text: 'Manual',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Quick select from saved addresses ──────────────────────
              if (!widget.isFirstTime)
                InkWell(
                  onTap: () async {
                    final addr = await AddressQuickSelectWidget.show(
                      context,
                      updateCurrentLocation: true,
                    );
                    if (addr != null && mounted) {
                      _showSuccess();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: AppTheme.primaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quick select from saved addresses',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GpsTab(
                      isLoading: _gpsLoading,
                      error: _error,
                      onUseGps: _useGpsLocation,
                    ),
                    _MapPinTab(
                      mapController: _mapController,
                      pin: _mapPin,
                      isGeocoding: _mapGeocoding,
                      onPinChanged: (ll) => setState(() => _mapPin = ll),
                      onConfirm: _confirmMapPin,
                    ),
                    _ManualTab(
                      villageCtrl: _villageCtrl,
                      cityCtrl: _cityCtrl,
                      talukaCtrl: _talukaCtrl,
                      districtCtrl: _districtCtrl,
                      stateCtrl: _stateCtrl,
                      pincodeCtrl: _pincodeCtrl,
                      addressCtrl: _addressCtrl,
                      error: _error,
                      onSave: _saveManual,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// ─── GPS Tab ─────────────────────────────────────────────────────────────────

class _GpsTab extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onUseGps;

  const _GpsTab({
    required this.isLoading,
    required this.error,
    required this.onUseGps,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 4.h),
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gps_fixed, size: 12.w, color: AppTheme.primary),
          ),
          SizedBox(height: 3.h),
          Text(
            'Use Current Location',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'We\'ll automatically detect your location and fill in your village, city, taluka, district, state, and pincode.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Your exact GPS coordinates are never shared with providers. Only your area is used for matching.',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          if (error != null)
            Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                error!,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onUseGps,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                isLoading ? 'Detecting...' : 'Use Current Location',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map Pin Tab ──────────────────────────────────────────────────────────────

class _MapPinTab extends StatelessWidget {
  final MapController mapController;
  final LatLng pin;
  final bool isGeocoding;
  final ValueChanged<LatLng> onPinChanged;
  final VoidCallback onConfirm;

  const _MapPinTab({
    required this.mapController,
    required this.pin,
    required this.isGeocoding,
    required this.onPinChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: pin,
                  initialZoom: 13,
                  onTap: (_, ll) => onPinChanged(ll),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.localconnect',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Tap on the map to place your pin',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pin Location:',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.5.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGeocoding ? null : onConfirm,
                  icon: isGeocoding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isGeocoding
                        ? 'Getting address...'
                        : 'Confirm This Location',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
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

// ─── Manual Tab ───────────────────────────────────────────────────────────────

class _ManualTab extends StatelessWidget {
  final TextEditingController villageCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController talukaCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController pincodeCtrl;
  final TextEditingController addressCtrl;
  final String? error;
  final VoidCallback onSave;

  const _ManualTab({
    required this.villageCtrl,
    required this.cityCtrl,
    required this.talukaCtrl,
    required this.districtCtrl,
    required this.stateCtrl,
    required this.pincodeCtrl,
    required this.addressCtrl,
    required this.error,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1.h),
          Text(
            'Enter Your Address',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Fill in your address details to find nearby providers.',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildField(
            'Full Address (optional)',
            addressCtrl,
            hint: 'House no, street, area',
          ),
          _buildField(
            'Village / Locality',
            villageCtrl,
            hint: 'e.g. Murud, Cheher',
          ),
          _buildField('City / Town', cityCtrl, hint: 'e.g. Alibag, Panvel'),
          _buildField('Taluka', talukaCtrl, hint: 'e.g. Murud, Roha'),
          _buildField(
            'District *',
            districtCtrl,
            hint: 'e.g. Raigad, Pune',
            required: true,
          ),
          _buildField('State', stateCtrl, hint: 'Maharashtra'),
          _buildField(
            'Pincode',
            pincodeCtrl,
            hint: '6-digit pincode',
            keyboardType: TextInputType.number,
          ),
          if (error != null)
            Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                error!,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                'Save Location',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 0.5.h),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey[400],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.4.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location Confirm Bottom Sheet ───────────────────────────────────────────

class _LocationConfirmSheet extends StatelessWidget {
  final LocationData location;
  final VoidCallback onConfirm;

  const _LocationConfirmSheet({
    required this.location,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primary, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Confirm Location',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _infoRow('Address', location.fullAddress),
          if (location.village.isNotEmpty)
            _infoRow('Village', location.village),
          if (location.city.isNotEmpty) _infoRow('City', location.city),
          if (location.taluka.isNotEmpty) _infoRow('Taluka', location.taluka),
          if (location.district.isNotEmpty)
            _infoRow('District', location.district),
          _infoRow('State', location.state),
          if (location.pincode.isNotEmpty)
            _infoRow('Pincode', location.pincode),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Confirm & Save',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
