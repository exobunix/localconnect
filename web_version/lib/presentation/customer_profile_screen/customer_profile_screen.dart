import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../core/theme_provider.dart';
import '../../services/account_deletion_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/location_service.dart';
import '../../services/referral_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/offline_banner_widget.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _savingProfile = false;

  // Location
  LocationData? _customerLocation;
  bool _loadingLocation = false;

  // Addresses
  List<Map<String, dynamic>> _addresses = [];
  bool _loadingAddresses = true;

  // Payment Methods
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _loadingPayments = true;

  // Preferences
  Map<String, dynamic>? _prefs;
  bool _loadingPrefs = true;
  bool _savingPrefs = false;
  String _prefTimeSlot = 'morning';
  String _prefPaymentType = 'cash';
  bool _prefAutoReorder = false;
  bool _prefNotifyOffers = true;
  bool _prefNotifyOrders = true;
  bool _prefNotifyMessages = true;
  String _prefLanguage = 'en';

  // Connectivity
  bool _isOnline = true;
  String? _cacheAge;

  // Account deletion
  bool _isDeletingAccount = false;

  static const _cacheKeyProfile = 'profile_user_data';
  static const _cacheKeyAddresses = 'profile_addresses';
  static const _cacheKeyPayments = 'profile_payments';
  static const _cacheKeyPrefs = 'profile_preferences';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) _loadAll();
      }
    });
    _loadAll();
    _loadCustomerLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadAddresses(),
      _loadPayments(),
      _loadPreferences(),
    ]);
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedMap(
        _cacheKeyProfile,
      );
      if (cached != null && mounted) {
        final data = cached['data'] as Map<String, dynamic>?;
        final ts = ConnectivityService.instance.getCachedTimestamp(cached);
        setState(() {
          _profile = data;
          _nameCtrl.text = data?['full_name'] as String? ?? '';
          _phoneCtrl.text = data?['phone'] as String? ?? '';
          _cacheAge = ConnectivityService.instance.formatCacheAge(ts);
          _loadingProfile = false;
        });
      } else if (mounted) {
        setState(() => _loadingProfile = false);
      }
      return;
    }

    final data = await SupabaseService.instance.getUserProfile(userId);
    if (mounted) {
      setState(() {
        _profile = data;
        _nameCtrl.text = data?['full_name'] as String? ?? '';
        _phoneCtrl.text = data?['phone'] as String? ?? '';
        _cacheAge = null;
        _loadingProfile = false;
      });
      if (data != null) {
        await ConnectivityService.instance.cacheData(_cacheKeyProfile, data);
      }
    }
  }

  Future<void> _loadAddresses() async {
    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(
        _cacheKeyAddresses,
      );
      if (cached != null && mounted) {
        final list = cached['data'];
        setState(() {
          _addresses = list is List
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loadingAddresses = false;
        });
      } else if (mounted) {
        setState(() => _loadingAddresses = false);
      }
      return;
    }

    final list = await SupabaseService.instance.getSavedAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _loadingAddresses = false;
      });
      await ConnectivityService.instance.cacheData(_cacheKeyAddresses, list);
    }
  }

  Future<void> _loadPayments() async {
    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(
        _cacheKeyPayments,
      );
      if (cached != null && mounted) {
        final list = cached['data'];
        setState(() {
          _paymentMethods = list is List
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loadingPayments = false;
        });
      } else if (mounted) {
        setState(() => _loadingPayments = false);
      }
      return;
    }

    final list = await SupabaseService.instance.getPaymentMethods();
    if (mounted) {
      setState(() {
        _paymentMethods = list;
        _loadingPayments = false;
      });
      await ConnectivityService.instance.cacheData(_cacheKeyPayments, list);
    }
  }

  Future<void> _loadPreferences() async {
    if (!_isOnline) {
      final cached = await ConnectivityService.instance.getCachedData(
        _cacheKeyPrefs,
      );
      if (cached != null && mounted) {
        final data = cached['data'];
        if (data is Map<String, dynamic>) {
          setState(() {
            _prefs = data;
            _prefTimeSlot = data['preferred_time_slot'] as String? ?? 'morning';
            _prefPaymentType =
                data['preferred_payment_type'] as String? ?? 'cash';
            _prefAutoReorder = data['auto_reorder'] as bool? ?? false;
            _prefNotifyOffers = data['notify_offers'] as bool? ?? true;
            _prefNotifyOrders = data['notify_order_updates'] as bool? ?? true;
            _prefNotifyMessages = data['notify_messages'] as bool? ?? true;
            _prefLanguage = data['language'] as String? ?? 'en';
            _loadingPrefs = false;
          });
        } else if (mounted) {
          setState(() => _loadingPrefs = false);
        }
      } else if (mounted) {
        setState(() => _loadingPrefs = false);
      }
      return;
    }

    final data = await SupabaseService.instance.getOrderPreferences();
    if (mounted) {
      setState(() {
        _prefs = data;
        if (data != null) {
          _prefTimeSlot = data['preferred_time_slot'] as String? ?? 'morning';
          _prefPaymentType =
              data['preferred_payment_type'] as String? ?? 'cash';
          _prefAutoReorder = data['auto_reorder'] as bool? ?? false;
          _prefNotifyOffers = data['notify_offers'] as bool? ?? true;
          _prefNotifyOrders = data['notify_order_updates'] as bool? ?? true;
          _prefNotifyMessages = data['notify_messages'] as bool? ?? true;
          _prefLanguage = data['language'] as String? ?? 'en';
        }
        _loadingPrefs = false;
      });
      if (data != null) {
        await ConnectivityService.instance.cacheData(_cacheKeyPrefs, data);
      }
    }
  }

  Future<void> _loadCustomerLocation() async {
    setState(() => _loadingLocation = true);
    final loc = await LocationService.instance.getCustomerLocation();
    if (mounted) {
      setState(() {
        _customerLocation = loc;
        _loadingLocation = false;
      });
    }
  }

  void _openLocationSetup() {
    _showSetLocationSheet();
  }

  void _showSetLocationSheet() {
    final houseDetailsCtrl = TextEditingController();
    final villageCtrl = TextEditingController(text: _customerLocation?.village ?? '');
    final cityCtrl = TextEditingController(text: _customerLocation?.city ?? '');
    final talukaCtrl = TextEditingController(text: _customerLocation?.taluka ?? '');
    final districtCtrl = TextEditingController(text: _customerLocation?.district ?? '');
    final stateCtrl = TextEditingController(text: _customerLocation?.state ?? 'Maharashtra');
    final pincodeCtrl = TextEditingController(text: _customerLocation?.pincode ?? '');
    
    // Extract house details if existing full_address has it
    if (_customerLocation != null && _customerLocation!.fullAddress.isNotEmpty) {
      final full = _customerLocation!.fullAddress;
      final parts = full.split(', ');
      if (parts.isNotEmpty) {
        final List<String> matchParts = [
          _customerLocation!.village,
          _customerLocation!.city,
          _customerLocation!.taluka,
          _customerLocation!.district,
          _customerLocation!.state,
          _customerLocation!.pincode
        ].where((e) => e.isNotEmpty).toList();
        
        final List<String> houseParts = [];
        for (var p in parts) {
          if (!matchParts.contains(p)) {
            houseParts.add(p);
          }
        }
        if (houseParts.isNotEmpty) {
          houseDetailsCtrl.text = houseParts.join(', ');
        }
      }
    }

    double? savedLat = _customerLocation?.latitude;
    double? savedLng = _customerLocation?.longitude;
    String savedMethod = _customerLocation?.method ?? 'manual';
    bool gpsLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set Your Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // GPS Button
                  GestureDetector(
                    onTap: gpsLoading
                        ? null
                        : () async {
                            setSheetState(() => gpsLoading = true);
                            final loc = await LocationService.instance.getGpsLocation();
                            if (loc != null) {
                              villageCtrl.text = loc.village;
                              cityCtrl.text = loc.city;
                              talukaCtrl.text = loc.taluka;
                              districtCtrl.text = loc.district;
                              stateCtrl.text = loc.state;
                              pincodeCtrl.text = loc.pincode;
                              savedLat = loc.latitude;
                              savedLng = loc.longitude;
                              savedMethod = 'gps';
                            }
                            setSheetState(() => gpsLoading = false);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          gpsLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.gps_fixed,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                          const SizedBox(width: 8),
                          Text(
                            gpsLoading
                                ? 'Detecting Location…'
                                : 'Use Current GPS Location',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (savedLat != null && savedLng != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS Coordinates Entered Successfully',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: houseDetailsCtrl,
                    decoration: _sheetInputDecoration('Flat / House No, Building, Street *'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: villageCtrl,
                          decoration: _sheetInputDecoration('Village / Locality'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: talukaCtrl,
                          decoration: _sheetInputDecoration('Taluka'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: districtCtrl,
                          decoration: _sheetInputDecoration('District *'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: _sheetInputDecoration('City *'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pincodeCtrl,
                          decoration: _sheetInputDecoration('Pincode *'),
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stateCtrl,
                          decoration: _sheetInputDecoration('State'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final house = houseDetailsCtrl.text.trim();
                        final dist = districtCtrl.text.trim();
                        final city = cityCtrl.text.trim();
                        final pin = pincodeCtrl.text.trim();
                        
                        if (house.isEmpty || dist.isEmpty || city.isEmpty || pin.isEmpty) {
                          _showSnack('Please fill all required (*) fields');
                          return;
                        }

                        final full = [
                          house,
                          villageCtrl.text.trim(),
                          talukaCtrl.text.trim(),
                          dist,
                          city,
                          pin,
                          stateCtrl.text.trim()
                        ].where((s) => s.isNotEmpty).join(', ');

                        final loc = LocationData(
                          latitude: savedLat ?? 0.0,
                          longitude: savedLng ?? 0.0,
                          fullAddress: full,
                          village: villageCtrl.text.trim(),
                          city: city,
                          taluka: talukaCtrl.text.trim(),
                          district: dist,
                          state: stateCtrl.text.trim(),
                          pincode: pin,
                          method: savedMethod,
                        );

                        await LocationService.instance.saveCustomerLocation(loc);
                        _loadCustomerLocation();
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showSnack('Location updated successfully!', success: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_isOnline) {
      _showSnack('Cannot save while offline');
      return;
    }
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;
    setState(() => _savingProfile = true);
    try {
      await SupabaseService.instance.updateUserProfile(
        userId: userId,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) _showSnack('Profile updated!', success: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to update profile');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_isOnline) {
      _showSnack('Cannot save while offline');
      return;
    }
    setState(() => _savingPrefs = true);
    try {
      await SupabaseService.instance.upsertOrderPreferences(
        preferredTimeSlot: _prefTimeSlot,
        preferredPaymentType: _prefPaymentType,
        autoReorder: _prefAutoReorder,
        notifyOffers: _prefNotifyOffers,
        notifyOrderUpdates: _prefNotifyOrders,
        notifyMessages: _prefNotifyMessages,
        language: _prefLanguage,
      );
      if (mounted) _showSnack('Preferences saved!', success: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to save preferences');
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          OfflineBannerWidget(onRetry: _loadAll),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  title: Row(
                    children: [
                      Text(
                        'My Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (!_isOnline) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Offline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_outline, size: 18),
                        text: 'Profile',
                      ),
                      Tab(
                        icon: Icon(Icons.location_on_outlined, size: 18),
                        text: 'Addresses',
                      ),
                      Tab(
                        icon: Icon(Icons.payment_outlined, size: 18),
                        text: 'Payments',
                      ),
                      Tab(
                        icon: Icon(Icons.tune_outlined, size: 18),
                        text: 'Preferences',
                      ),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildAddressesTab(),
                  _buildPaymentsTab(),
                  _buildPreferencesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final email = SupabaseService.instance.currentUser?.email ?? '';
    final name = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Customer';
    final initials = name.trim().isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'C';

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROFILE TAB ─────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            child: Column(
              children: [
                _inputField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                _inputField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _infoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: SupabaseService.instance.currentUser?.email ?? '—',
                  muted: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _savingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ─── Location Card ─────────────────────────────────────────────
          _sectionCard(
            title: 'My Location',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingLocation)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_customerLocation != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _customerLocation!.method == 'gps'
                              ? Icons.gps_fixed
                              : _customerLocation!.method == 'map'
                              ? Icons.map_outlined
                              : Icons.edit_location_alt_outlined,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_customerLocation!.district.isNotEmpty)
                              Text(
                                '${_customerLocation!.district}, ${_customerLocation!.state}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (_customerLocation!.taluka.isNotEmpty)
                              Text(
                                'Taluka: ${_customerLocation!.taluka}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (_customerLocation!.village.isNotEmpty)
                              Text(
                                'Village: ${_customerLocation!.village}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (_customerLocation!.pincode.isNotEmpty)
                              Text(
                                'Pincode: ${_customerLocation!.pincode}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No location set',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openLocationSetup,
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      size: 16,
                    ),
                    label: Text(
                      _customerLocation != null
                          ? 'Change Location'
                          : 'Set Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Account',
            icon: Icons.manage_accounts_outlined,
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.support_agent_rounded,
                  label: 'Customer Support',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.customerSupportScreen,
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.history_rounded,
                  label: 'Past Bookings',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/customer-past-bookings-screen',
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.receipt_long_rounded,
                  label: 'Payment History (Razorpay)',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.razorpayTransactionHistoryScreen,
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => _showChangePasswordSheet(),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.legalScreen,
                    arguments: {'tab': 0},
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.legalScreen,
                    arguments: {'tab': 1},
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.inbox_rounded,
                  label: 'Unified Inbox',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.unifiedInboxScreen,
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.share_rounded,
                  label: 'Share & Invite Friends',
                  onTap: () async {
                    final message = ReferralService.instance.shareMessage;
                    await Share.share(message, subject: 'LocalConnect App');
                    await ReferralService.instance.logShare(
                      shareType: 'app',
                      platform: 'native',
                    );
                  },
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppTheme.error,
                  onTap: () async {
                    await SupabaseService.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.loginScreen,
                        (r) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ─── SHARE & INVITE ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.hub_rounded,
                  label: 'Referral Hub',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.referralHubScreen),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.people_alt_rounded,
                  label: 'Invite Friends',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.inviteFriendsScreen,
                  ),
                ),
                const Divider(height: 1),
                _actionRow(
                  icon: Icons.share_rounded,
                  label: 'Share LocalConnect',
                  onTap: () async {
                    final message = ReferralService.instance.shareMessage;
                    await Share.share(message, subject: 'LocalConnect App');
                    await ReferralService.instance.logShare(
                      shareType: 'app',
                      platform: 'native',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ─── DELETE ACCOUNT ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeletingAccount ? null : _showDeleteAccountFlow,
                icon: _isDeletingAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.error,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded, size: 18),
                label: Text(
                  'Delete My Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deleting your account is permanent and cannot be undone.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.error.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── ADDRESSES TAB ───────────────────────────────────────────────────────────
  Widget _buildAddressesTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Address',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? _emptyState(
              icon: Icons.location_off_outlined,
              title: 'No saved addresses',
              subtitle: 'Add your home or work address for faster checkout',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _addressCard(_addresses[i]),
            ),
    );
  }

  Widget _addressCard(Map<String, dynamic> addr) {
    final isDefault = addr['is_default'] as bool? ?? false;
    final label = addr['label'] as String? ?? 'Address';
    final line1 = addr['address_line1'] as String? ?? '';
    final line2 = addr['address_line2'] as String? ?? '';
    final city = addr['city'] as String? ?? '';
    final pincode = addr['pincode'] as String? ?? '';
    final village = addr['village'] as String? ?? '';
    final taluka = addr['taluka'] as String? ?? '';
    final district = addr['district'] as String? ?? '';
    final locationMethod = addr['location_method'] as String? ?? 'manual';

    final iconData = label.toLowerCase() == 'home'
        ? Icons.home_outlined
        : label.toLowerCase() == 'work'
        ? Icons.work_outline
        : Icons.location_on_outlined;

    // Build a rich address summary
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (village.isNotEmpty) village,
      if (taluka.isNotEmpty) taluka,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
      if (pincode.isNotEmpty) pincode,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDefault
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDefault
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    iconData,
                    color: isDefault
                        ? AppTheme.primary
                        : const Color(0xFF78909C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Default',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // GPS badge
                          if (locationMethod == 'gps' ||
                              locationMethod == 'map')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.gps_fixed,
                                    size: 10,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    locationMethod.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parts.join(', '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF74777F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF90A4AE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) async {
                    if (v == 'default') {
                      await SupabaseService.instance.setDefaultAddress(
                        addr['id'] as String,
                      );
                      _loadAddresses();
                    } else if (v == 'edit') {
                      _showAddressSheet(existing: addr);
                    } else if (v == 'delete') {
                      await SupabaseService.instance.deleteAddress(
                        addr['id'] as String,
                      );
                      _loadAddresses();
                    }
                  },
                  itemBuilder: (_) => [
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('Set as Default'),
                      ),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // ── Use for location button ──────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final lat = (addr['latitude'] as num?)?.toDouble();
                      final lng = (addr['longitude'] as num?)?.toDouble();
                      if (lat != null && lng != null) {
                        final loc = LocationData(
                          latitude: lat,
                          longitude: lng,
                          fullAddress: parts.join(', '),
                          village: village,
                          city: city,
                          taluka: taluka,
                          district: district,
                          state: addr['state'] as String? ?? 'Maharashtra',
                          pincode: pincode,
                          method: locationMethod,
                        );
                        await LocationService.instance.saveCustomerLocation(
                          loc,
                        );
                        _loadCustomerLocation();
                        _showSnack(
                          '$label set as current location',
                          success: true,
                        );
                      } else {
                        _showSnack(
                          'No GPS data for this address. Use GPS to set location.',
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location_outlined, size: 14),
                    label: Text(
                      'Use as Current Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── PAYMENTS TAB ────────────────────────────────────────────────────────────
  Widget _buildPaymentsTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentSheet(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Payment',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loadingPayments
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
          ? _emptyState(
              icon: Icons.payment_outlined,
              title: 'No payment methods',
              subtitle: 'Add UPI, card, or cash for quick checkout',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _paymentMethods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _paymentCard(_paymentMethods[i]),
            ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> pm) {
    final isDefault = pm['is_default'] as bool? ?? false;
    final type = pm['type'] as String? ?? 'cash';
    final label = pm['label'] as String? ?? 'Payment';
    final details = pm['details'] as Map<String, dynamic>? ?? {};

    IconData icon;
    Color iconColor;
    String subtitle = '';

    switch (type) {
      case 'upi':
        icon = Icons.account_balance_wallet_outlined;
        iconColor = const Color(0xFF6A1B9A);
        subtitle = details['upi_id'] as String? ?? '';
        break;
      case 'card':
        icon = Icons.credit_card_outlined;
        iconColor = AppTheme.primary;
        final last4 = details['last4'] as String? ?? '';
        subtitle = last4.isNotEmpty ? '•••• $last4' : '';
        break;
      case 'netbanking':
        icon = Icons.account_balance_outlined;
        iconColor = AppTheme.info;
        subtitle = details['bank'] as String? ?? '';
        break;
      default:
        icon = Icons.money_outlined;
        iconColor = AppTheme.success;
        subtitle = 'Pay at doorstep';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDefault
            ? Border.all(color: AppTheme.primary, width: 1.5)
            : Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
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
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
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
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Color(0xFF90A4AE),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) async {
                if (v == 'default') {
                  await SupabaseService.instance.setDefaultPaymentMethod(
                    pm['id'] as String,
                  );
                  _loadPayments();
                } else if (v == 'delete') {
                  await SupabaseService.instance.deletePaymentMethod(
                    pm['id'] as String,
                  );
                  _loadPayments();
                }
              },
              itemBuilder: (_) => [
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Set as Default'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREFERENCES TAB ─────────────────────────────────────────────────────────
  Widget _buildPreferencesTab() {
    if (_loadingPrefs) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _sectionCard(
            title: 'Repeat Order Defaults',
            icon: Icons.repeat_rounded,
            child: Column(
              children: [
                _dropdownRow(
                  icon: Icons.access_time_outlined,
                  label: 'Preferred Time Slot',
                  value: _prefTimeSlot,
                  items: const {
                    'morning': 'Morning (6 AM – 12 PM)',
                    'afternoon': 'Afternoon (12 PM – 5 PM)',
                    'evening': 'Evening (5 PM – 9 PM)',
                    'anytime': 'Anytime',
                  },
                  onChanged: (v) => setState(() => _prefTimeSlot = v!),
                ),
                const Divider(height: 24),
                _dropdownRow(
                  icon: Icons.payment_outlined,
                  label: 'Preferred Payment',
                  value: _prefPaymentType,
                  items: const {
                    'cash': 'Cash on Delivery',
                    'upi': 'UPI',
                    'card': 'Card',
                    'netbanking': 'Net Banking',
                  },
                  onChanged: (v) => setState(() => _prefPaymentType = v!),
                ),
                const Divider(height: 24),
                _switchRow(
                  icon: Icons.autorenew_rounded,
                  label: 'Auto Reorder',
                  subtitle: 'Automatically reorder your last service',
                  value: _prefAutoReorder,
                  onChanged: (v) => setState(() => _prefAutoReorder = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            child: Column(
              children: [
                _switchRow(
                  icon: Icons.local_offer_outlined,
                  label: 'Offers & Promotions',
                  subtitle: 'Get notified about deals near you',
                  value: _prefNotifyOffers,
                  onChanged: (v) => setState(() => _prefNotifyOffers = v),
                ),
                const Divider(height: 24),
                _switchRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Order Updates',
                  subtitle: 'Status changes for your orders',
                  value: _prefNotifyOrders,
                  onChanged: (v) => setState(() => _prefNotifyOrders = v),
                ),
                const Divider(height: 24),
                _switchRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  subtitle: 'New messages from providers',
                  value: _prefNotifyMessages,
                  onChanged: (v) => setState(() => _prefNotifyMessages = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Language / भाषा',
            icon: Icons.language_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marathi ↔ English quick toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _prefLanguage = 'en'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _prefLanguage == 'en'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _prefLanguage == 'en'
                                  ? AppTheme.cardShadow
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'English',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _prefLanguage == 'en'
                                        ? Colors.white
                                        : const Color(0xFF74777F),
                                  ),
                                ),
                                Text(
                                  'A B C',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: _prefLanguage == 'en'
                                        ? Colors.white70
                                        : const Color(0xFF90A4AE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _prefLanguage = 'mr'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _prefLanguage == 'mr'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _prefLanguage == 'mr'
                                  ? AppTheme.cardShadow
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'मराठी',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _prefLanguage == 'mr'
                                        ? Colors.white
                                        : const Color(0xFF74777F),
                                  ),
                                ),
                                Text(
                                  'अ आ इ',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: _prefLanguage == 'mr'
                                        ? Colors.white70
                                        : const Color(0xFF90A4AE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Also keep Hindi option via dropdown
                _dropdownRow(
                  icon: Icons.translate_outlined,
                  label: 'More Languages',
                  value: _prefLanguage,
                  items: const {
                    'en': 'English',
                    'hi': 'हिंदी (Hindi)',
                    'mr': 'मराठी (Marathi)',
                  },
                  onChanged: (v) => setState(() => _prefLanguage = v!),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppTheme.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _prefLanguage == 'mr'
                              ? 'मराठी भाषा निवडली आहे. बदल जतन करा.'
                              : 'Language preference saved with your profile.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dark Mode section
          _sectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: _switchRow(
              icon: Icons.dark_mode_rounded,
              label: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: ThemeProvider.instance.isDarkMode,
              onChanged: (v) => ThemeProvider.instance.setDarkMode(v),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingPrefs ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _savingPrefs
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Preferences',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFF74777F),
        ),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool muted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: muted ? const Color(0xFF90A4AE) : AppTheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: muted
                      ? const Color(0xFF74777F)
                      : const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? const Color(0xFF44474E)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? const Color(0xFF1A1C1E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: color ?? const Color(0xFF90A4AE),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _dropdownRow({
    required IconData icon,
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1C1E),
                  ),
                  items: items.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF90A4AE)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF74777F),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM SHEETS ────────────────────────────────────────────────────────────
  void _showAddressSheet({Map<String, dynamic>? existing}) {
    final line1Ctrl = TextEditingController(
      text: existing?['address_line1'] as String? ?? '',
    );
    final line2Ctrl = TextEditingController(
      text: existing?['address_line2'] as String? ?? '',
    );
    final cityCtrl = TextEditingController(
      text: existing?['city'] as String? ?? '',
    );
    final pincodeCtrl = TextEditingController(
      text: existing?['pincode'] as String? ?? '',
    );
    final villageCtrl = TextEditingController(
      text: existing?['village'] as String? ?? '',
    );
    final talukaCtrl = TextEditingController(
      text: existing?['taluka'] as String? ?? '',
    );
    final districtCtrl = TextEditingController(
      text: existing?['district'] as String? ?? '',
    );
    String selectedLabel = existing?['label'] as String? ?? 'Home';
    double? savedLat = (existing?['latitude'] as num?)?.toDouble();
    double? savedLng = (existing?['longitude'] as num?)?.toDouble();
    String savedMethod = existing?['location_method'] as String? ?? 'manual';
    bool gpsLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing != null ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Address type chips ──────────────────────────────────
                  Row(
                    children: ['Home', 'Work', 'Other'].map((l) {
                      final sel = selectedLabel == l;
                      IconData ic = l == 'Home'
                          ? Icons.home_outlined
                          : l == 'Work'
                          ? Icons.work_outline
                          : Icons.location_on_outlined;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedLabel = l),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primaryContainer
                                  : AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ic,
                                  size: 14,
                                  color: sel
                                      ? AppTheme.primary
                                      : const Color(0xFF44474E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? AppTheme.primary
                                        : const Color(0xFF44474E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // ── GPS auto-fill button ────────────────────────────────
                  GestureDetector(
                    onTap: gpsLoading
                        ? null
                        : () async {
                            setSheetState(() => gpsLoading = true);
                            final loc = await LocationService.instance
                                .getGpsLocation();
                            if (loc != null) {
                              line1Ctrl.text = loc.village.isNotEmpty
                                  ? loc.village
                                  : loc.city;
                              cityCtrl.text = loc.city.isNotEmpty
                                  ? loc.city
                                  : loc.district;
                              pincodeCtrl.text = loc.pincode;
                              villageCtrl.text = loc.village;
                              talukaCtrl.text = loc.taluka;
                              districtCtrl.text = loc.district;
                              savedLat = loc.latitude;
                              savedLng = loc.longitude;
                              savedMethod = 'gps';
                            }
                            setSheetState(() => gpsLoading = false);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          gpsLoading
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.gps_fixed,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                          const SizedBox(width: 6),
                          Text(
                            gpsLoading
                                ? 'Detecting location…'
                                : 'Use Current GPS Location',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (savedLat != null && savedLng != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GPS coordinates saved',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: line1Ctrl,
                    decoration: _sheetInputDecoration('Address Line 1 *'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: line2Ctrl,
                    decoration: _sheetInputDecoration(
                      'Address Line 2 (optional)',
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: villageCtrl,
                          decoration: _sheetInputDecoration('Village'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: talukaCtrl,
                          decoration: _sheetInputDecoration('Taluka'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: districtCtrl,
                          decoration: _sheetInputDecoration('District'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: _sheetInputDecoration('City *'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pincodeCtrl,
                    decoration: _sheetInputDecoration('Pincode'),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (line1Ctrl.text.isEmpty || cityCtrl.text.isEmpty) {
                          return;
                        }
                        Navigator.pop(ctx);
                        if (existing != null) {
                          await SupabaseService.instance.updateAddress(
                            id: existing['id'] as String,
                            label: selectedLabel,
                            addressLine1: line1Ctrl.text.trim(),
                            addressLine2: line2Ctrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            pincode: pincodeCtrl.text.trim(),
                            village: villageCtrl.text.trim(),
                            taluka: talukaCtrl.text.trim(),
                            district: districtCtrl.text.trim(),
                            latitude: savedLat,
                            longitude: savedLng,
                            locationMethod: savedMethod,
                          );
                        } else {
                          await SupabaseService.instance.addAddress(
                            label: selectedLabel,
                            addressLine1: line1Ctrl.text.trim(),
                            addressLine2: line2Ctrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            pincode: pincodeCtrl.text.trim(),
                            village: villageCtrl.text.trim(),
                            taluka: talukaCtrl.text.trim(),
                            district: districtCtrl.text.trim(),
                            latitude: savedLat,
                            longitude: savedLng,
                            locationMethod: savedMethod,
                          );
                        }
                        _loadAddresses();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        existing != null ? 'Update Address' : 'Save Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    String selectedType = 'upi';
    final upiCtrl = TextEditingController();
    final last4Ctrl = TextEditingController();
    final bankCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    _paymentTypeChip(
                      'upi',
                      'UPI',
                      selectedType,
                      (v) => setSheetState(() => selectedType = v),
                    ),
                    _paymentTypeChip(
                      'card',
                      'Card',
                      selectedType,
                      (v) => setSheetState(() => selectedType = v),
                    ),
                    _paymentTypeChip(
                      'netbanking',
                      'Net Banking',
                      selectedType,
                      (v) => setSheetState(() => selectedType = v),
                    ),
                    _paymentTypeChip(
                      'cash',
                      'Cash',
                      selectedType,
                      (v) => setSheetState(() => selectedType = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (selectedType == 'upi')
                  TextField(
                    controller: upiCtrl,
                    decoration: _sheetInputDecoration('UPI ID (e.g. name@upi)'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                if (selectedType == 'card')
                  TextField(
                    controller: last4Ctrl,
                    decoration: _sheetInputDecoration('Last 4 digits of card'),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                if (selectedType == 'netbanking')
                  TextField(
                    controller: bankCtrl,
                    decoration: _sheetInputDecoration('Bank name'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      Map<String, dynamic> details = {};
                      String label = 'Cash on Delivery';
                      if (selectedType == 'upi') {
                        details = {'upi_id': upiCtrl.text.trim()};
                        label = 'UPI';
                      } else if (selectedType == 'card') {
                        details = {'last4': last4Ctrl.text.trim()};
                        label = 'Card';
                      } else if (selectedType == 'netbanking') {
                        details = {'bank': bankCtrl.text.trim()};
                        label = 'Net Banking';
                      }
                      await SupabaseService.instance.addPaymentMethod(
                        type: selectedType,
                        label: label,
                        details: details,
                      );
                      _loadPayments();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Payment Method',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentTypeChip(
    String value,
    String label,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primaryContainer : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: sel ? AppTheme.primary : const Color(0xFF44474E),
          ),
        ),
      ),
    );
  }

  // ─── DELETE ACCOUNT FLOW ─────────────────────────────────────────────────

  Future<void> _showDeleteAccountFlow() async {
    // Step 1: Check for blocking issues
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    setState(() => _isDeletingAccount = true);
    final issues = await AccountDeletionService.instance
        .getCustomerBlockingIssues(userId);
    setState(() => _isDeletingAccount = false);

    if (!mounted) return;

    // Show blocking issues if any
    if (issues.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Cannot Delete Account',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please resolve the following before deleting your account:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Step 2: Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_forever_rounded,
              color: AppTheme.error,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'All your personal data, profile information, listings, orders, chats, and account history will be permanently removed.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF74777F),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete Permanently',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 3: Re-authentication
    final isPhone = AccountDeletionService.instance.isPhoneUser();
    final isGoogle = AccountDeletionService.instance.isGoogleUser();

    if (!isPhone && !isGoogle) {
      // Email/password user — ask for password
      final verified = await _showPasswordVerificationDialog();
      if (!verified) return;
    }
    // For phone/Google users we skip re-auth (OTP re-auth requires Twilio flow)

    // Step 4: Perform deletion
    if (!mounted) return;
    setState(() => _isDeletingAccount = true);

    final error = await AccountDeletionService.instance.deleteAccount();

    if (!mounted) return;
    setState(() => _isDeletingAccount = false);

    if (error != null) {
      _showSnack('Deletion failed: $error');
      return;
    }

    // Step 5: Success — navigate to login
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Account Deleted',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been permanently deleted. We\'re sorry to see you go.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.loginScreen,
                    (r) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _showPasswordVerificationDialog() async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Verify Your Identity',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your password to confirm account deletion.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  errorText: errorMsg,
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF74777F),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = passwordCtrl.text.trim();
                if (pwd.isEmpty) {
                  setDialogState(() => errorMsg = 'Password is required');
                  return;
                }
                final err = await AccountDeletionService.instance
                    .reauthenticateWithPassword(pwd);
                if (err != null) {
                  setDialogState(() => errorMsg = err);
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Verify',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
    passwordCtrl.dispose();
    return result == true;
  }

  void _showChangePasswordSheet() {
    Navigator.pushNamed(context, AppRoutes.changePasswordScreen);
  }

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF90A4AE),
      ),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
