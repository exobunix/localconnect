import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/connectivity_service.dart';
import '../../services/notification_hub_service.dart';
import '../../services/supabase_service.dart';
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
  String _selectedCity = 'Pune';
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
    _scrollController.addListener(_onScroll);
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) _loadUserProfile();
      }
    });
    _loadUserProfile();
    _loadUnreadCount();
    _subscribeToMessageUpdates();
    // Initialize notification hub for badge counter
    NotificationHubService.instance.initialize();
    NotificationHubService.instance.addListener(_onNotificationHubUpdate);
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
          _selectedCity = data?['city'] as String? ?? 'Pune';
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
        _selectedCity = profile['city'] as String? ?? 'Pune';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.mapDiscoveryScreen),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.map_rounded, size: 20),
        label: Text(
          'Map View',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                      isOnline: _isOnline,
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

  void _showCitySelector() {
    final cities = [
      'Pune',
      'Mumbai',
      'Nashik',
      'Aurangabad',
      'Nagpur',
      'Kolhapur',
      'Alibag',
      'Roha',
      'Nagothane',
      'Pen',
      'Mangaon',
      'Mahad',
      'Poladpur',
      'Shrivardhan',
      'Murud',
      'Panvel',
      'Khopoli',
      'Karjat',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            Text(
              'शहर निवडा / Select City',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cities
                  .map(
                    (c) => GestureDetector(
                      onTap: () {
                        setState(() => _selectedCity = c);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCity == c
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCity == c
                                ? AppTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: _selectedCity == c
                                ? AppTheme.primary
                                : const Color(0xFF44474E),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
