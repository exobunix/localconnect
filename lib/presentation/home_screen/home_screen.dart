import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/connectivity_service.dart';
import '../../services/notification_hub_service.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../widgets/offline_banner_widget.dart';
import '../../widgets/share_widgets.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/home_banner_slider_widget.dart';
import './widgets/home_best_offers_widget.dart';
import './widgets/home_bottom_nav_widget.dart';
import './widgets/home_category_grid_widget.dart';
import './widgets/home_nearby_providers_widget.dart';
import './widgets/home_quick_actions_widget.dart';
import './widgets/home_search_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  bool _navVisible = true;
  final ScrollController _scrollController = ScrollController();
  String _selectedCity = '';
  String _userName = '';
  int _unreadMessageCount = 0;
  String _userRole = 'customer';
  RealtimeChannel? _msgSubscription;
  bool _isOnline = true;
  String? _cacheAge;

  static const _cacheKeyProfile = 'home_user_profile';

  @override
  void initState() {
    super.initState();
    _selectedCity = SupabaseService.instance.selectedCity;
    _scrollController.addListener(_onScroll);
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) _loadUserProfile();
      }
    });
    _loadUserProfile();
    _initLocation();
    _loadUnreadCount();
    _subscribeToMessageUpdates();
    // Initialize notification hub for badge counter
    NotificationHubService.instance.initialize();
    NotificationHubService.instance.addListener(_onNotificationHubUpdate);
  }

  Future<void> _initLocation() async {
    // 1. Check local cache
    final cached = await LocationService.instance.getCachedLocalLocation();
    if (cached != null && cached.displayCity.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedCity = cached.displayCity;
          SupabaseService.instance.selectedCity = _selectedCity;
        });
      }
    }

    // 2. Request GPS location dynamically
    try {
      final loc = await LocationService.instance.getGpsLocation(
        timeout: const Duration(seconds: 6),
      );
      if (loc != null && loc.displayCity.isNotEmpty && mounted) {
        setState(() {
          _selectedCity = loc.displayCity;
          SupabaseService.instance.selectedCity = _selectedCity;
        });
        final userId = SupabaseService.instance.currentUser?.id;
        if (userId != null) {
          await LocationService.instance.saveCustomerLocation(loc);
        }
      }
    } catch (e) {
      debugPrint('[HomeScreen] GPS init error: $e');
    }
  }

  void _onNotificationHubUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUserProfile() async {
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
          _userName = data?['full_name'] as String? ?? '';
          final city = data?['city'] as String? ?? '';
          if (city.isNotEmpty) {
            _selectedCity = city;
            SupabaseService.instance.selectedCity = _selectedCity;
          }
          _userRole = data?['role'] as String? ?? 'customer';
          _cacheAge = ConnectivityService.instance.formatCacheAge(ts);
        });
      }
      return;
    }

    final profile = await SupabaseService.instance.getUserProfile(userId);
    if (mounted && profile != null) {
      setState(() {
        _userName = profile['full_name'] as String? ?? '';
        final city = profile['city'] as String? ?? '';
        if (city.isNotEmpty) {
          _selectedCity = city;
          SupabaseService.instance.selectedCity = _selectedCity;
        }
        _userRole = profile['role'] as String? ?? 'customer';
      });
      await ConnectivityService.instance.cacheData(_cacheKeyProfile, profile);
    }
  }

  Future<void> _loadUnreadCount() async {
    if (!_isOnline) return;
    final count = await SupabaseService.instance.getUnreadMessageCount();
    if (mounted) setState(() => _unreadMessageCount = count);
  }

  void _subscribeToMessageUpdates() {
    _msgSubscription = SupabaseService.instance.subscribeToConversations(
      onUpdate: () {
        if (mounted) _loadUnreadCount();
      },
    );
  }

  Future<void> _handleSignOut() async {
    await SupabaseService.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  void _handleProfileTap() {
    Navigator.pushNamed(context, AppRoutes.customerProfileScreen);
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _navVisible) {
      setState(() => _navVisible = false);
    } else if (direction == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true);
    }
  }

  void _handleRetry() {
    setState(() {});
    _loadUserProfile();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _msgSubscription?.unsubscribe();
    NotificationHubService.instance.removeListener(_onNotificationHubUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final unreadNotifCount = NotificationHubService.instance.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            OfflineBannerWidget(onRetry: _handleRetry),
            HomeAppBarWidget(
              selectedCity: _selectedCity,
              onCityTap: _showCitySelector,
              onNotificationTap: () => Navigator.pushNamed(
                context,
                AppRoutes.notificationScreen,
              ).then((_) => NotificationHubService.instance.reinitialize()),
              onProfileTap: _handleProfileTap,
              onSignOut: _handleSignOut,
              unreadNotificationCount: unreadNotifCount,
            ),
            if (!_isOnline && _cacheAge != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(children: [OfflineChipWidget(cacheAge: _cacheAge)]),
              ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: HomeSearchWidget(onSearch: (_) {})),
                  const SliverToBoxAdapter(child: HomeBannerSliderWidget()),
                  SliverToBoxAdapter(
                    child: HomeCategoryGridWidget(
                      isTablet: isTablet,
                      onCategoryTap: (categoryId) {
                        if (categoryId == 'all') {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.allCategoriesScreen,
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.categoryDetailScreen,
                            arguments: categoryId,
                          );
                        }
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomeNearbyProvidersWidget(
                      key: ValueKey(_selectedCity),
                      isOnline: _isOnline,
                      city: _selectedCity,
                      onProviderTap: (id) => Navigator.pushNamed(
                        context,
                        AppRoutes.providerProfileScreen,
                        arguments: {'providerId': id},
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomeBestOffersWidget(isOnline: _isOnline),
                  ),
                  const SliverToBoxAdapter(child: HomeQuickActionsWidget()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: _buildShareInviteCard(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavWidget(
        selectedIndex: _selectedNavIndex,
        isVisible: _navVisible,
        unreadMessageCount: _unreadMessageCount,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.allCategoriesScreen);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.orderManagementScreen);
          } else if (index == 3) {
            Navigator.pushNamed(
              context,
              AppRoutes.chatListScreen,
            ).then((_) => _loadUnreadCount());
          } else if (index == 4) {
            Navigator.pushNamed(context, AppRoutes.customerProfileScreen);
          }
        },
      ),
    );
  }

  Widget _buildProviderDashboardBanner() {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.providerDashboardScreen),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
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
                    'Provider Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Manage orders, earnings & completion rate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, List<double>> _cityCoords = {
    'Pune': [18.5204, 73.8567],
    'Mumbai': [19.0760, 72.8777],
    'Nashik': [19.9975, 73.7898],
    'Aurangabad': [19.8762, 75.3433],
    'Nagpur': [21.1458, 79.0882],
    'Kolhapur': [16.7050, 74.2433],
    'Alibag': [18.6584, 72.8777],
    'Roha': [18.4385, 73.1160],
    'Nagothane': [18.5298, 73.1311],
    'Pen': [18.7324, 73.0934],
    'Mangaon': [18.2468, 73.2872],
    'Mahad': [18.0863, 73.4216],
    'Poladpur': [17.9788, 73.4650],
    'Shrivardhan': [18.0492, 73.0182],
    'Murud': [18.2831, 72.9634],
    'Panvel': [18.9894, 73.1175],
    'Khopoli': [18.7904, 73.3444],
    'Karjat': [18.9102, 73.3282],
  };

  void _showCitySelector() {
    List<Map<String, dynamic>> savedAddresses = [];
    bool loadingAddresses = true;
    bool showAddAddressForm = false;
    bool gpsLoading = false;
    bool hasFetched = false;

    final labelCtrl = TextEditingController();
    final line1Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final stateCtrl = TextEditingController(text: 'Maharashtra');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (!hasFetched) {
            hasFetched = true;
            SupabaseService.instance.getSavedAddresses().then((list) {
              setSheetState(() {
                savedAddresses = list;
                loadingAddresses = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (showAddAddressForm)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              setSheetState(() => showAddAddressForm = false);
                            },
                          ),
                        Text(
                          showAddAddressForm ? 'Add New Address' : 'Select Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (showAddAddressForm) ...[
                      // Address Form
                      TextField(
                        controller: labelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Label (e.g. Home, Work, Other)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: line1Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Address Line 1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'City / Village',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: districtCtrl,
                              decoration: InputDecoration(
                                labelText: 'District',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: pincodeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Pincode',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final label = labelCtrl.text.trim();
                            final line1 = line1Ctrl.text.trim();
                            final city = cityCtrl.text.trim();
                            final dist = districtCtrl.text.trim();
                            final pin = pincodeCtrl.text.trim();
                            
                            if (label.isEmpty || line1.isEmpty || city.isEmpty || pin.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }

                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              await SupabaseService.instance.addAddress(
                                label: label,
                                addressLine1: line1,
                                city: city,
                                pincode: pin,
                                district: dist,
                                fullAddress: '$line1, $city, ${stateCtrl.text}, $pin',
                              );

                              final loc = LocationData(
                                latitude: 18.5204,
                                longitude: 73.8567,
                                fullAddress: '$line1, $city, ${stateCtrl.text}, $pin',
                                village: '',
                                city: city,
                                taluka: '',
                                district: dist,
                                state: stateCtrl.text,
                                pincode: pin,
                                method: 'manual',
                              );

                              await LocationService.instance.saveCustomerLocation(loc);
                              setState(() {
                                _selectedCity = city;
                                SupabaseService.instance.selectedCity = _selectedCity;
                              });

                              if (context.mounted) {
                                Navigator.pop(context); // Pop loading dialog
                                Navigator.pop(context); // Pop sheet
                              }
                            } catch (e) {
                              if (context.mounted) Navigator.pop(context); // Pop loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to save address. Please try again.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Save Address & Select',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      // GPS Button
                      GestureDetector(
                        onTap: gpsLoading
                            ? null
                            : () async {
                                setSheetState(() => gpsLoading = true);
                                final loc = await LocationService.instance.getGpsLocation();
                                if (loc != null) {
                                  await LocationService.instance.saveCustomerLocation(loc);
                                  setState(() {
                                    _selectedCity = loc.city.isNotEmpty ? loc.city : loc.district;
                                    SupabaseService.instance.selectedCity = _selectedCity;
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Location updated to ${loc.city}!'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                } else {
                                  setSheetState(() => gpsLoading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to detect GPS location.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
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
                                  : Icon(Icons.gps_fixed, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                gpsLoading ? 'Detecting Location…' : 'Use Current GPS Location',
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved Addresses:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setSheetState(() => showAddAddressForm = true);
                            },
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              'Add New',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (loadingAddresses)
                        const Center(child: CircularProgressIndicator())
                      else if (savedAddresses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No saved addresses found.\nAdd one using the "Add New" button above.',
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedAddresses.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final addr = savedAddresses[index];
                            final city = addr['city'] as String? ?? '';
                            final label = addr['label'] as String? ?? 'Address';
                            final line1 = addr['address_line1'] as String? ?? '';
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  label.toLowerCase() == 'home'
                                      ? Icons.home_outlined
                                      : label.toLowerCase() == 'work'
                                          ? Icons.work_outline
                                          : Icons.location_on_outlined,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                line1.isNotEmpty ? '$line1, $city' : city,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                final lat = (addr['latitude'] as num?)?.toDouble() ?? 18.5204;
                                final lng = (addr['longitude'] as num?)?.toDouble() ?? 73.8567;
                                final loc = LocationData(
                                  latitude: lat,
                                  longitude: lng,
                                  fullAddress: addr['full_address'] as String? ?? '',
                                  village: addr['village'] as String? ?? '',
                                  city: city,
                                  taluka: addr['taluka'] as String? ?? '',
                                  district: addr['district'] as String? ?? '',
                                  state: addr['state'] as String? ?? 'Maharashtra',
                                  pincode: addr['pincode'] as String? ?? '',
                                  method: addr['location_method'] as String? ?? 'manual',
                                );

                                await LocationService.instance.saveCustomerLocation(loc);
                                setState(() {
                                  _selectedCity = city;
                                  SupabaseService.instance.selectedCity = _selectedCity;
                                });
                                if (mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareInviteCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Friends',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Share LocalConnect & earn rewards',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.inviteFriendsScreen),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Invite',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ShareAppButton(compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

