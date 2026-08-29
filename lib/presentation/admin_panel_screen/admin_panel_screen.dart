import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/role_guard.dart';
import '../../core/testing_mode.dart';
import '../../core/theme_provider.dart';
import '../../services/demo_seeder_service.dart';
import '../../services/supabase_service.dart';
import './admin_advanced_reports_screen.dart';
import './admin_customer_management_screen.dart';
import './admin_provider_management_screen.dart';
import './admin_quotation_monitoring_screen.dart';
import './admin_referral_management_screen.dart';
import './admin_shop_management_screen.dart';
import './admin_subscription_management_screen.dart';
import './admin_transport_screen.dart';
import './widgets/admin_app_bar_widget.dart';
import './widgets/admin_chart_widget.dart';
import './widgets/admin_complaints_widget.dart';
import './widgets/admin_kpi_grid_widget.dart';
import './widgets/admin_kyc_summary_widget.dart';
import './widgets/admin_order_metrics_widget.dart';
import './widgets/admin_pending_approvals_widget.dart';
import './widgets/admin_quick_actions_widget.dart';
import './widgets/admin_quotation_funnel_widget.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedNavIndex = 0;
  bool _navVisible = true;
  bool _isCheckingRole = true;
  bool _isAdmin = false;
  final ScrollController _scrollController = ScrollController();

  // QA Testing state
  bool _isSeeding = false;
  bool _isClearing = false;
  String? _seedMessage;

  final List<String> _navLabels = [
    'Dashboard',
    'Providers',
    'Customers',
    'Shops',
    'Analytics',
    'Subs',
    'Delivery',
    'Transport',
    'Settings',
  ];
  final List<IconData> _navIcons = [
    Icons.dashboard_rounded,
    Icons.store_rounded,
    Icons.people_rounded,
    Icons.storefront_rounded,
    Icons.bar_chart_rounded,
    Icons.workspace_premium_rounded,
    Icons.delivery_dining_rounded,
    Icons.local_shipping_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    if (isAdminSessionActive || canAccess(AppRoutes.adminPanelScreen)) {
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _isCheckingRole = false;
        });
      }
      return;
    }
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.adminLoginScreen);
        }
        return;
      }
      final profile = await SupabaseService.instance.getUserProfile(userId);
      final role = profile?['role'] as String? ?? '';
      if (mounted) {
        if (role != 'admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminLoginScreen);
          return;
        }
        setAdminSessionActive(true);
        setState(() {
          _isAdmin = true;
          _isCheckingRole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminLoginScreen);
      }
    }
  }

  Future<void> _seedDemoData() async {
    setState(() {
      _isSeeding = true;
      _seedMessage = null;
    });
    final result = await DemoSeederService.instance.seedDemoData();
    if (mounted) {
      setState(() {
        _isSeeding = false;
        switch (result) {
          case 'seeded':
            _seedMessage =
                '✅ Demo data seeded successfully! 3 customers, 3 providers, 8 orders, 4 reviews.';
            break;
          case 'already_seeded':
            _seedMessage =
                'ℹ️ Demo data already exists. Clear first to re-seed.';
            break;
          case 'disabled':
            _seedMessage = '⚠️ Testing mode is disabled.';
            break;
          default:
            _seedMessage = result.startsWith('error')
                ? '❌ ${result.replaceFirst('error: ', '')}'
                : '✅ $result';
        }
      });
    }
  }

  Future<void> _clearDemoData() async {
    setState(() {
      _isClearing = true;
      _seedMessage = null;
    });
    final result = await DemoSeederService.instance.clearDemoData();
    if (mounted) {
      setState(() {
        _isClearing = false;
        switch (result) {
          case 'cleared':
            _seedMessage = '🗑️ All demo data cleared successfully.';
            break;
          case 'no_demo_data':
            _seedMessage = 'ℹ️ No demo data found to clear.';
            break;
          case 'disabled':
            _seedMessage = '⚠️ Testing mode is disabled.';
            break;
          default:
            _seedMessage = result.startsWith('error')
                ? '❌ ${result.replaceFirst('error: ', '')}'
                : '🗑️ $result';
        }
      });
    }
  }

  void _onScroll() {
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _navVisible) {
      setState(() => _navVisible = false);
    } else if (dir == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTabContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return const AdminProviderManagementScreen();
      case 2:
        return const AdminCustomerManagementScreen();
      case 3:
        return const AdminShopManagementScreen();
      case 4:
        return const AdminAdvancedReportsScreen();
      case 5:
        return const AdminSubscriptionManagementScreen();
      case 6:
        return _buildDeliveryTab();
      case 7:
        return const AdminTransportScreen();
      case 8:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDeliveryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Hero card for dedicated management screen
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2),
                    Color(0xFF42A5F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vendors • Riders • Pricing • Commission • KPIs • Live Map',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick action tiles
          _buildSettingsTile(
            icon: Icons.map_rounded,
            title: 'Live Rider Map',
            subtitle: 'View real-time rider locations and status',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.business_rounded,
            title: 'Vendor Management',
            subtitle: 'Approve, suspend, and manage delivery vendors',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.directions_bike_rounded,
            title: 'Rider Management',
            subtitle: 'Track and manage all delivery riders',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.layers_rounded,
            title: 'Pricing Tiers',
            subtitle: 'Configure Standard, Express, Economy, Bulk tiers',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.percent_rounded,
            title: 'Commission Rules',
            subtitle: 'Set and manage platform commission rates',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.bar_chart_rounded,
            title: 'Performance KPIs',
            subtitle: 'Delivery metrics, top riders, city performance',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDeliveryManagementScreen,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Order Management',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.receipt_long_rounded,
            title: 'All Orders',
            subtitle: 'View and manage all platform orders',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.orderManagementScreen),
          ),
          _buildSettingsTile(
            icon: Icons.pending_actions_rounded,
            title: 'Pending Approvals',
            subtitle: 'Review provider approval requests',
            onTap: () => setState(() => _selectedNavIndex = 1),
          ),
          _buildSettingsTile(
            icon: Icons.report_problem_rounded,
            title: 'Complaints',
            subtitle: 'Handle customer and provider complaints',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminComplaintsScreen),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const AdminKpiGridWidget(),
          const SizedBox(height: 16),
          const AdminQuickActionsWidget(),
          const SizedBox(height: 16),
          const AdminChartWidget(),
          const SizedBox(height: 16),
          const AdminOrderMetricsWidget(),
          const SizedBox(height: 16),
          const AdminQuotationFunnelWidget(),
          const SizedBox(height: 16),
          const AdminKycSummaryWidget(),
          const SizedBox(height: 16),
          const AdminPendingApprovalsWidget(),
          const SizedBox(height: 16),
          const AdminComplaintsWidget(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProvidersTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const AdminPendingApprovalsWidget(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Admin Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.category_rounded,
            title: 'Category Management',
            subtitle: 'Add, edit, or disable service categories',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminCategoryManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.campaign_rounded,
            title: 'Banner Advertisements',
            subtitle: 'Manage promotional banners',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminBannerAdsScreen),
          ),
          _buildSettingsTile(
            icon: Icons.workspace_premium_rounded,
            title: 'Subscription Plans',
            subtitle: 'Manage provider subscription tiers',
            onTap: () => setState(() => _selectedNavIndex = 5),
          ),
          _buildSettingsTile(
            icon: Icons.home_work_rounded,
            title: 'Rent Analytics',
            subtitle: 'View rent module performance',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminRentAnalyticsScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.celebration_rounded,
            title: 'Event Management',
            subtitle: 'Manage event providers, bookings & revenue',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminEventManagementScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.photo_library_rounded,
            title: 'Media Moderation',
            subtitle: 'Approve, reject & remove provider photos/videos',
            color: const Color(0xFF7B1FA2),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminMediaModerationScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.verified_user_rounded,
            title: 'KYC Verification',
            subtitle: 'Review provider identity & business documents',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminKycVerificationScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.fact_check_rounded,
            title: 'Document Review & Activation',
            subtitle: 'Approve or reject identity & business license docs',
            color: const Color(0xFF2E7D32),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminDocumentReviewScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.request_quote_rounded,
            title: 'Quotation Monitoring',
            subtitle: 'Monitor all enquiries, quotations & analytics',
            color: const Color(0xFF7B1FA2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminQuotationMonitoringScreen(),
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.campaign_rounded,
            title: 'Push Notification Hub',
            subtitle: 'Dispatch broadcast & targeted push alerts with sound',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminNotificationHubScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.report_problem_rounded,
            title: 'Complaints',
            subtitle: 'View and resolve user complaints',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminComplaintsScreen),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications Feed',
            subtitle: 'View all platform notification activities',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          _buildSettingsTile(
            icon: Icons.gavel_rounded,
            title: 'Legal & Policies',
            subtitle: 'Privacy policy, terms of service',
            onTap: () => Navigator.pushNamed(context, AppRoutes.legalScreen),
          ),
          _buildSettingsTile(
            icon: Icons.store_rounded,
            title: 'Play Store Assets',
            subtitle: 'App listing, screenshots, legal & promo content',
            color: const Color(0xFF00897B),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.playStoreAssetsScreen),
          ),
          _buildSettingsTile(
            icon: Icons.checklist_rounded,
            title: 'Play Store Review',
            subtitle:
                'Verify app name, screenshots, icon, SDK, privacy policy & billing compliance',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminPlayStoreReviewScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.people_alt_rounded,
            title: 'Referral Management',
            subtitle: 'Configure referral program, rewards & analytics',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminReferralManagementScreen(),
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.gps_fixed_rounded,
            title: 'Location Search Settings',
            subtitle:
                'Configure GPS search radius, smart expansion & category defaults',
            color: const Color(0xFF00695C),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.adminLocationSettingsScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.science_outlined,
            title: 'GPS Location Testing',
            subtitle:
                'Verify GPS detection, distance calc, radius & booking eligibility',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.gpsLocationTestingScreen,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your admin account password securely',
            color: const Color(0xFF6A1B9A),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.changePasswordScreen),
          ),
          // ── QA Testing Mode (only visible when TESTING_MODE=true) ──
          if (TestingMode.isEnabled) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.science_rounded,
                        color: Color(0xFFE65100),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'QA Testing Mode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ENABLED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auto-populate Supabase with demo customers, providers, orders, reviews, and transactions for end-to-end QA.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                  if (_seedMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _seedMessage!.startsWith('error')
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _seedMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _seedMessage!.startsWith('error')
                              ? const Color(0xFFC62828)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSeeding || _isClearing
                              ? null
                              : _seedDemoData,
                          icon: _isSeeding
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            _isSeeding ? 'Seeding...' : 'Seed Demo Data',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSeeding || _isClearing
                              ? null
                              : _clearDemoData,
                          icon: _isClearing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_sweep_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _isClearing ? 'Clearing...' : 'Clear Demo Data',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
          // Dark Mode Toggle
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dark_mode_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Switch between light and dark theme',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              trailing: Switch(
                value: ThemeProvider.instance.isDarkMode,
                onChanged: (v) => ThemeProvider.instance.setDarkMode(v),
                activeColor: AppTheme.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Log out of admin panel',
            color: AppTheme.error,
            onTap: () async {
              await SupabaseService.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
              }
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color == AppTheme.error
                    ? AppTheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.outline,
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ScreenLoadingWidget(message: 'Verifying access...'),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ScreenLoadingWidget(message: 'Redirecting...'),
      );
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isTablet) {
      return _buildTabletLayout();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AdminAppBarWidget(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingNav(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedNavIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedNavIndex = i),
              backgroundColor: Colors.white,
              indicatorColor: AppTheme.primaryContainer,
              selectedIconTheme: const IconThemeData(color: AppTheme.primary),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFF90A4AE),
              ),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
              unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF90A4AE),
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'LC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              destinations: List.generate(
                _navLabels.length,
                (i) => NavigationRailDestination(
                  icon: Icon(_navIcons[i]),
                  label: Text(_navLabels[i]),
                ),
              ),
            ),
            Container(width: 1, color: AppTheme.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  const AdminAppBarWidget(),
                  Expanded(
                    child: _selectedNavIndex == 0
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      children: const [
                                        AdminKpiGridWidget(),
                                        SizedBox(height: 16),
                                        AdminChartWidget(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: const [
                                        AdminPendingApprovalsWidget(),
                                        SizedBox(height: 16),
                                        AdminComplaintsWidget(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildTabContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNav() {
    return AnimatedSlide(
      offset: _navVisible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _navVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(999),
              boxShadow: AppTheme.floatingNavShadow,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _navLabels.length,
                  (i) => _AdminNavItem(
                    icon: _navIcons[i],
                    label: _navLabels[i],
                    isSelected: _selectedNavIndex == i,
                    onTap: () => setState(() => _selectedNavIndex = i),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
