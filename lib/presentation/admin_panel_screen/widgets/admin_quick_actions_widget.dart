import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class AdminQuickActionsWidget extends StatelessWidget {
  const AdminQuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.manage_accounts_rounded,
        'User Mgmt',
        AppTheme.primary,
        AppRoutes.adminUserManagementScreen,
      ),
      (
        Icons.category_rounded,
        'Categories',
        AppTheme.catEvents,
        AppRoutes.adminCategoryManagementScreen,
      ),
      (
        Icons.campaign_rounded,
        'Banner Ads',
        AppTheme.secondary,
        AppRoutes.adminBannerAdsScreen,
      ),
      (
        Icons.notifications_active_rounded,
        'Notify All',
        AppTheme.catDoctor,
        AppRoutes.notificationScreen,
      ),
      (
        Icons.analytics_rounded,
        'Analytics',
        AppTheme.success,
        AppRoutes.adminReportsScreen,
      ),
      (
        Icons.report_rounded,
        'Reports',
        AppTheme.catRepair,
        AppRoutes.adminReportsScreen,
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Razorpay',
        Color(0xFF0D47A1),
        AppRoutes.razorpayDashboardScreen,
      ),
      (
        Icons.price_change_rounded,
        'Monetize',
        Color(0xFF6A1B9A),
        AppRoutes.adminCategoryMonetizationScreen,
      ),
      (
        Icons.photo_library_rounded,
        'Media',
        Color(0xFF7B1FA2),
        AppRoutes.adminMediaModerationScreen,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              itemBuilder: (_, i) {
                final action = actions[i];
                return Padding(
                  padding: EdgeInsets.only(
                    right: i < actions.length - 1 ? 10 : 0,
                  ),
                  child: _QuickActionChip(
                    icon: action.$1,
                    label: action.$2,
                    color: action.$3,
                    onTap: () {
                      if (action.$4.isNotEmpty) {
                        Navigator.pushNamed(context, action.$4);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
