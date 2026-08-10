import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';

class QaDeveloperPanelScreen extends StatelessWidget {
  const QaDeveloperPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6F00),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.science_rounded, size: 20),
            SizedBox(width: 2.w),
            Text(
              'QA Developer Panel',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            width: double.infinity,
            color: const Color(0xFFE65100),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
            child: Text(
              '🔒 Dev-only • Hidden in production builds',
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          _buildInfoBanner(),
          SizedBox(height: 2.h),
          // ── E2E Verification ──────────────────────────────────────────────
          _buildE2EVerificationCard(context),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.storefront_rounded,
            title: 'Shop Subcategories',
            color: const Color(0xFF1565C0),
            providers: [
              _ProviderEntry(
                label: 'General Shop',
                subtitle: 'Grocery / Retail',
                icon: Icons.store_rounded,
                route: AppRoutes.shopProviderDashboardScreen,
              ),
              _ProviderEntry(
                label: 'Plumbing Hardware',
                subtitle: 'Plumbing supplies shop',
                icon: Icons.plumbing_rounded,
                route: AppRoutes.plumbingProviderScreen,
              ),
              _ProviderEntry(
                label: 'Electrical Hardware',
                subtitle: 'Electrical supplies shop',
                icon: Icons.electrical_services_rounded,
                route: AppRoutes.electricalProviderScreen,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.local_shipping_rounded,
            title: 'Transport',
            color: const Color(0xFF00695C),
            providers: [
              _ProviderEntry(
                label: 'Ride Provider',
                subtitle: 'Taxi / Auto / Bike rides',
                icon: Icons.directions_car_rounded,
                route: AppRoutes.transportRideProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Goods Transport',
                subtitle: 'Truck / Mini-van logistics',
                icon: Icons.local_shipping_rounded,
                route: AppRoutes.transportGoodsProviderDashboard,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.home_repair_service_rounded,
            title: 'Home Maintenance',
            color: const Color(0xFF6A1B9A),
            providers: [
              _ProviderEntry(
                label: 'Plumber',
                subtitle: 'Plumbing services',
                icon: Icons.plumbing_rounded,
                route: AppRoutes.plumberProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Electrician',
                subtitle: 'Electrical services',
                icon: Icons.electrical_services_rounded,
                route: AppRoutes.electricianProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Painter',
                subtitle: 'Painting services',
                icon: Icons.format_paint_rounded,
                route: AppRoutes.painterProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Mason',
                subtitle: 'Masonry / Construction',
                icon: Icons.construction_rounded,
                route: AppRoutes.masonProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Carpenter',
                subtitle: 'Carpentry services',
                icon: Icons.handyman_rounded,
                route: AppRoutes.carpenterProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Daily Wage Worker',
                subtitle: 'General labour',
                icon: Icons.engineering_rounded,
                route: AppRoutes.dailyWageProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Cleaning',
                subtitle: 'Home cleaning services',
                icon: Icons.cleaning_services_rounded,
                route: AppRoutes.cleaningProviderDashboard,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.celebration_rounded,
            title: 'Events',
            color: const Color(0xFFC62828),
            providers: [
              _ProviderEntry(
                label: 'Photography',
                subtitle: 'Event photography',
                icon: Icons.camera_alt_rounded,
                route: AppRoutes.photographyProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Sound & DJ',
                subtitle: 'Sound systems & DJ',
                icon: Icons.music_note_rounded,
                route: AppRoutes.soundDjProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Decoration & Catering',
                subtitle: 'Mandap / Catering',
                icon: Icons.restaurant_rounded,
                route: AppRoutes.decorationCateringProviderDashboard,
                routeArgs: 'mandap',
              ),
              _ProviderEntry(
                label: 'Makeup & Mehendi',
                subtitle: 'Beauty & event planning',
                icon: Icons.face_retouching_natural_rounded,
                route: AppRoutes.makeupMehendiEventPlannerDashboard,
                routeArgs: 'makeup',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.apartment_rounded,
            title: 'Rent Subcategories',
            color: const Color(0xFF2E7D32),
            providers: [
              _ProviderEntry(
                label: 'Room Rental',
                subtitle: 'Single / double rooms',
                icon: Icons.bed_rounded,
                route: AppRoutes.roomProviderDashboard,
              ),
              _ProviderEntry(
                label: 'PG Provider',
                subtitle: 'Paying guest accommodation',
                icon: Icons.home_rounded,
                route: AppRoutes.pgProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Hostel',
                subtitle: 'Hostel accommodation',
                icon: Icons.hotel_rounded,
                route: AppRoutes.hostelProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Villa / Bungalow',
                subtitle: 'Premium rental properties',
                icon: Icons.villa_rounded,
                route: AppRoutes.villaProviderDashboard,
              ),
              _ProviderEntry(
                label: 'Tools & Equipment',
                subtitle: 'Rental tools & machinery',
                icon: Icons.build_rounded,
                route: AppRoutes.toolsProviderDashboard,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSection(
            context,
            icon: Icons.delivery_dining_rounded,
            title: 'Delivery',
            color: const Color(0xFFAD1457),
            providers: [
              _ProviderEntry(
                label: 'Delivery Vendor',
                subtitle: 'Vendor / merchant dashboard',
                icon: Icons.store_mall_directory_rounded,
                route: AppRoutes.deliveryVendorDashboard,
              ),
              _ProviderEntry(
                label: 'Rider',
                subtitle: 'Delivery rider app',
                icon: Icons.two_wheeler_rounded,
                route: AppRoutes.riderAppScreen,
              ),
            ],
          ),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFFF6F00),
            size: 18,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Tap any provider type below to open its dashboard directly — no separate login required. Use this to verify all dashboards before Play Store submission.',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: const Color(0xFF795548),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildE2EVerificationCard(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.e2eVerificationScreen),
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withAlpha(77),
              blurRadius: 10,
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
                color: Colors.white.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E2E Flow Verification',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    'Signup → Search → Request → Accept → Booking → Chat',
                    style: GoogleFonts.inter(
                      fontSize: 8.5.sp,
                      color: Colors.white.withAlpha(179),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Run',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<_ProviderEntry> providers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 2.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${providers.length}',
                style: GoogleFonts.inter(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        ...providers.map((entry) => _buildProviderTile(context, entry, color)),
      ],
    );
  }

  Widget _buildProviderTile(
    BuildContext context,
    _ProviderEntry entry,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () {
            Navigator.pushNamed(
              context,
              entry.route,
              arguments: entry.routeArgs,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            child: Row(
              children: [
                Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(entry.icon, color: color, size: 18),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        entry.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: const Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: color, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? routeArgs;

  const _ProviderEntry({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.routeArgs,
  });
}
