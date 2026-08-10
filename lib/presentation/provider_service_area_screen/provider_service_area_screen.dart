import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';

/// Provider Service Area Management Screen
class ProviderServiceAreaScreen extends StatefulWidget {
  final String? providerId;
  const ProviderServiceAreaScreen({super.key, this.providerId});

  @override
  State<ProviderServiceAreaScreen> createState() =>
      _ProviderServiceAreaScreenState();
}

class _ProviderServiceAreaScreenState extends State<ProviderServiceAreaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _providerId;
  Map<String, dynamic>? _providerData;

  // Business location
  final MapController _mapController = MapController();
  LatLng _businessPin = const LatLng(18.5204, 73.8567);
  bool _mapGeocoding = false;
  LocationData? _businessLocation;

  // Service radius
  double _serviceRadius = 10;
  final List<double> _radiusOptions = [2, 5, 10, 15, 20, 25, 50];
  final _customRadiusCtrl = TextEditingController();
  bool _useCustomRadius = false;

  // Service mode
  String _serviceMode = 'radius'; // radius, area, mixed

  // Administrative areas
  final _villageInputCtrl = TextEditingController();
  final _talukaInputCtrl = TextEditingController();
  final _districtInputCtrl = TextEditingController();
  List<String> _selectedVillages = [];
  List<String> _selectedTalukas = [];
  List<String> _selectedDistricts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProviderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customRadiusCtrl.dispose();
    _villageInputCtrl.dispose();
    _talukaInputCtrl.dispose();
    _districtInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    setState(() => _isLoading = true);
    try {
      final provider = widget.providerId != null
          ? await SupabaseService.instance.client
                .from('service_providers')
                .select()
                .eq('id', widget.providerId!)
                .maybeSingle()
          : await SupabaseService.instance.getMyProviderProfile();

      if (provider != null) {
        _providerId = provider['id'] as String?;
        _providerData = provider;

        final lat = (provider['business_latitude'] as num?)?.toDouble();
        final lng = (provider['business_longitude'] as num?)?.toDouble();
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          _businessPin = LatLng(lat, lng);
          _businessLocation = LocationData(
            latitude: lat,
            longitude: lng,
            fullAddress: provider['business_address'] as String? ?? '',
            village: provider['village'] as String? ?? '',
            city: provider['city'] as String? ?? '',
            taluka: provider['taluka'] as String? ?? '',
            district: provider['district'] as String? ?? '',
            state: provider['state'] as String? ?? 'Maharashtra',
            pincode: provider['pincode'] as String? ?? '',
            method: 'map',
          );
        }

        _serviceRadius =
            (provider['service_radius_km'] as num?)?.toDouble() ?? 10;
        _serviceMode = provider['service_mode'] as String? ?? 'radius';

        final villages = provider['service_villages'];
        final talukas = provider['service_talukas'];
        final districts = provider['service_districts'];

        _selectedVillages = villages is List
            ? List<String>.from(villages.map((e) => e.toString()))
            : [];
        _selectedTalukas = talukas is List
            ? List<String>.from(talukas.map((e) => e.toString()))
            : [];
        _selectedDistricts = districts is List
            ? List<String>.from(districts.map((e) => e.toString()))
            : [];
      }
    } catch (e) {
      _error = 'Failed to load provider data.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmBusinessPin() async {
    setState(() => _mapGeocoding = true);
    final loc = await LocationService.instance.reverseGeocode(
      _businessPin.latitude,
      _businessPin.longitude,
    );
    if (!mounted) return;
    setState(() {
      _mapGeocoding = false;
      _businessLocation =
          loc ??
          LocationData(
            latitude: _businessPin.latitude,
            longitude: _businessPin.longitude,
            fullAddress:
                '${_businessPin.latitude.toStringAsFixed(4)}, ${_businessPin.longitude.toStringAsFixed(4)}',
            method: 'map',
          );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business pin updated. Save to apply changes.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _useGpsForBusiness() async {
    setState(() => _mapGeocoding = true);
    final loc = await LocationService.instance.getGpsLocation();
    if (!mounted) return;
    if (loc == null) {
      setState(() => _mapGeocoding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get GPS location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _mapGeocoding = false;
      _businessPin = LatLng(loc.latitude, loc.longitude);
      _businessLocation = loc;
    });
    _mapController.move(_businessPin, 15);
  }

  Future<void> _saveAll() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);

    try {
      // Save business location if set
      if (_businessLocation != null) {
        await LocationService.instance.saveProviderLocation(
          providerId: _providerId!,
          location: _businessLocation!,
        );
      }

      // Save service area
      final radius = _useCustomRadius
          ? (double.tryParse(_customRadiusCtrl.text) ?? _serviceRadius)
          : _serviceRadius;

      await LocationService.instance.saveProviderServiceArea(
        providerId: _providerId!,
        radiusKm: radius,
        serviceMode: _serviceMode,
        villages: _selectedVillages,
        talukas: _selectedTalukas,
        districts: _selectedDistricts,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service area saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _addToList(
    String value,
    List<String> list,
    Function(List<String>) onUpdate,
  ) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || list.contains(trimmed)) return;
    onUpdate([...list, trimmed]);
  }

  void _removeFromList(
    String value,
    List<String> list,
    Function(List<String>) onUpdate,
  ) {
    onUpdate(list.where((e) => e != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Service Area Management',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Service Area Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAll,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.store_outlined, size: 18), text: 'Business'),
            Tab(icon: Icon(Icons.radar, size: 18), text: 'Radius'),
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Areas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BusinessLocationTab(
            mapController: _mapController,
            pin: _businessPin,
            location: _businessLocation,
            isGeocoding: _mapGeocoding,
            onPinChanged: (ll) => setState(() => _businessPin = ll),
            onConfirmPin: _confirmBusinessPin,
            onUseGps: _useGpsForBusiness,
          ),
          _ServiceRadiusTab(
            selectedRadius: _serviceRadius,
            radiusOptions: _radiusOptions,
            useCustom: _useCustomRadius,
            customCtrl: _customRadiusCtrl,
            serviceMode: _serviceMode,
            onRadiusChanged: (r) => setState(() => _serviceRadius = r),
            onCustomToggle: (v) => setState(() => _useCustomRadius = v),
            onModeChanged: (m) => setState(() => _serviceMode = m),
          ),
          _AdminAreasTab(
            villages: _selectedVillages,
            talukas: _selectedTalukas,
            districts: _selectedDistricts,
            villageCtrl: _villageInputCtrl,
            talukaCtrl: _talukaInputCtrl,
            districtCtrl: _districtInputCtrl,
            onAddVillage: (v) => setState(
              () => _addToList(
                v,
                _selectedVillages,
                (l) => _selectedVillages = l,
              ),
            ),
            onRemoveVillage: (v) => setState(
              () => _removeFromList(
                v,
                _selectedVillages,
                (l) => _selectedVillages = l,
              ),
            ),
            onAddTaluka: (v) => setState(
              () =>
                  _addToList(v, _selectedTalukas, (l) => _selectedTalukas = l),
            ),
            onRemoveTaluka: (v) => setState(
              () => _removeFromList(
                v,
                _selectedTalukas,
                (l) => _selectedTalukas = l,
              ),
            ),
            onAddDistrict: (v) => setState(
              () => _addToList(
                v,
                _selectedDistricts,
                (l) => _selectedDistricts = l,
              ),
            ),
            onRemoveDistrict: (v) => setState(
              () => _removeFromList(
                v,
                _selectedDistricts,
                (l) => _selectedDistricts = l,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Business Location Tab ────────────────────────────────────────────────────

class _BusinessLocationTab extends StatelessWidget {
  final MapController mapController;
  final LatLng pin;
  final LocationData? location;
  final bool isGeocoding;
  final ValueChanged<LatLng> onPinChanged;
  final VoidCallback onConfirmPin;
  final VoidCallback onUseGps;

  const _BusinessLocationTab({
    required this.mapController,
    required this.pin,
    required this.location,
    required this.isGeocoding,
    required this.onPinChanged,
    required this.onConfirmPin,
    required this.onUseGps,
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
                  initialZoom: 14,
                  onTap: (_, ll) => onPinChanged(ll),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.localconnect.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 40,
                        height: 50,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FloatingActionButton.small(
                  onPressed: onUseGps,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: AppTheme.primary),
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 60,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
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
                      'Tap to pin your business location',
                      style: GoogleFonts.inter(fontSize: 10.sp),
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
              if (location != null) ...[
                Text(
                  'Business Address:',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  location!.fullAddress.isNotEmpty
                      ? location!.fullAddress
                      : '${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}',
                  style: GoogleFonts.inter(fontSize: 10.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isGeocoding ? null : onConfirmPin,
                  icon: isGeocoding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.pin_drop_outlined),
                  label: Text(
                    isGeocoding ? 'Getting address...' : 'Confirm Business Pin',
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

// ─── Service Radius Tab ───────────────────────────────────────────────────────

class _ServiceRadiusTab extends StatelessWidget {
  final double selectedRadius;
  final List<double> radiusOptions;
  final bool useCustom;
  final TextEditingController customCtrl;
  final String serviceMode;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<bool> onCustomToggle;
  final ValueChanged<String> onModeChanged;

  const _ServiceRadiusTab({
    required this.selectedRadius,
    required this.radiusOptions,
    required this.useCustom,
    required this.customCtrl,
    required this.serviceMode,
    required this.onRadiusChanged,
    required this.onCustomToggle,
    required this.onModeChanged,
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
            'Service Mode',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          _ModeCard(
            mode: 'radius',
            selected: serviceMode == 'radius',
            title: 'Radius Only',
            subtitle: 'Serve customers within a distance radius',
            icon: Icons.radar,
            onTap: () => onModeChanged('radius'),
          ),
          _ModeCard(
            mode: 'area',
            selected: serviceMode == 'area',
            title: 'Administrative Areas Only',
            subtitle: 'Serve specific villages, talukas, districts',
            icon: Icons.map_outlined,
            onTap: () => onModeChanged('area'),
          ),
          _ModeCard(
            mode: 'mixed',
            selected: serviceMode == 'mixed',
            title: 'Radius + Administrative Areas',
            subtitle: 'Combine both methods for maximum coverage',
            icon: Icons.layers_outlined,
            onTap: () => onModeChanged('mixed'),
          ),
          SizedBox(height: 2.h),
          if (serviceMode != 'area') ...[
            Text(
              'Service Radius',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: radiusOptions.map((r) {
                final selected = !useCustom && selectedRadius == r;
                return GestureDetector(
                  onTap: () {
                    onCustomToggle(false);
                    onRadiusChanged(r);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '${r.toInt()} km',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Checkbox(
                  value: useCustom,
                  onChanged: (v) => onCustomToggle(v ?? false),
                  activeColor: AppTheme.primary,
                ),
                Text(
                  'Enter custom radius (km)',
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
              ],
            ),
            if (useCustom) ...[
              SizedBox(height: 0.5.h),
              TextField(
                controller: customCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 35',
                  suffixText: 'km',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.4.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String mode;
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withAlpha(20)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : Colors.grey[500],
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppTheme.primary : Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppTheme.primary, size: 5.w),
          ],
        ),
      ),
    );
  }
}

// ─── Administrative Areas Tab ─────────────────────────────────────────────────

class _AdminAreasTab extends StatelessWidget {
  final List<String> villages;
  final List<String> talukas;
  final List<String> districts;
  final TextEditingController villageCtrl;
  final TextEditingController talukaCtrl;
  final TextEditingController districtCtrl;
  final ValueChanged<String> onAddVillage;
  final ValueChanged<String> onRemoveVillage;
  final ValueChanged<String> onAddTaluka;
  final ValueChanged<String> onRemoveTaluka;
  final ValueChanged<String> onAddDistrict;
  final ValueChanged<String> onRemoveDistrict;

  const _AdminAreasTab({
    required this.villages,
    required this.talukas,
    required this.districts,
    required this.villageCtrl,
    required this.talukaCtrl,
    required this.districtCtrl,
    required this.onAddVillage,
    required this.onRemoveVillage,
    required this.onAddTaluka,
    required this.onRemoveTaluka,
    required this.onAddDistrict,
    required this.onRemoveDistrict,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Add villages, talukas, and districts you serve. Customers from these areas will see you in search results.',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          _AreaSection(
            title: 'Villages / Localities',
            icon: Icons.location_city_outlined,
            items: villages,
            controller: villageCtrl,
            hint: 'e.g. Murud, Cheher, Agardanda',
            onAdd: onAddVillage,
            onRemove: onRemoveVillage,
          ),
          SizedBox(height: 2.h),
          _AreaSection(
            title: 'Talukas',
            icon: Icons.account_balance_outlined,
            items: talukas,
            controller: talukaCtrl,
            hint: 'e.g. Murud, Roha, Alibag',
            onAdd: onAddTaluka,
            onRemove: onRemoveTaluka,
          ),
          SizedBox(height: 2.h),
          _AreaSection(
            title: 'Districts',
            icon: Icons.domain_outlined,
            items: districts,
            controller: districtCtrl,
            hint: 'e.g. Raigad, Pune, Thane',
            onAdd: onAddDistrict,
            onRemove: onRemoveDistrict,
          ),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }
}

class _AreaSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _AreaSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.controller,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[400],
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.2.h,
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
            ),
            SizedBox(width: 2.w),
            ElevatedButton(
              onPressed: () {
                onAdd(controller.text);
                controller.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.4.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 0.8.h,
            children: items.map((item) {
              return Chip(
                label: Text(item, style: GoogleFonts.inter(fontSize: 10.sp)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => onRemove(item),
                backgroundColor: AppTheme.primary.withAlpha(26),
                deleteIconColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withAlpha(77)),
              );
            }).toList(),
          ),
        ] else ...[
          SizedBox(height: 0.8.h),
          Text(
            'No ${title.toLowerCase()} added yet.',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[400]),
          ),
        ],
      ],
    );
  }
}
