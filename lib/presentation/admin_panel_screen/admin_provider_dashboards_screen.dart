import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
// Shop provider screens
import '../shop_screen/shop_provider_dashboard_screen.dart';
import '../shop_screen/plumbing_provider_screen.dart';
import '../shop_screen/electrical_provider_screen.dart';
// Transport provider screens
import '../transport_screen/transport_ride_provider_dashboard.dart';
import '../transport_screen/transport_goods_provider_dashboard.dart';
// Home Maintenance provider screens
import '../home_maintenance_screen/plumber_provider_dashboard.dart';
import '../home_maintenance_screen/electrician_provider_dashboard.dart';
import '../home_maintenance_screen/painter_provider_dashboard.dart';
import '../home_maintenance_screen/mason_provider_dashboard.dart';
import '../home_maintenance_screen/carpenter_provider_dashboard.dart';
import '../home_maintenance_screen/daily_wage_provider_dashboard.dart';
import '../home_maintenance_screen/cleaning_provider_dashboard.dart';
// Event provider screens
import '../event_management_screen/photography_provider_dashboard.dart';
import '../event_management_screen/sound_dj_provider_dashboard.dart';
import '../event_management_screen/decoration_catering_provider_dashboard.dart';
import '../event_management_screen/makeup_mehendi_event_planner_dashboard.dart';
// Rent provider screens
import '../rent_screen/room_provider_dashboard.dart';
import '../rent_screen/pg_provider_dashboard.dart';
import '../rent_screen/hostel_provider_dashboard.dart';
import '../rent_screen/villa_provider_dashboard.dart';
import '../rent_screen/tools_provider_dashboard.dart';
// Delivery provider screens
import '../delivery_screen/delivery_vendor_dashboard.dart';
import '../delivery_screen/rider_app_screen.dart';

class AdminProviderDashboardsScreen extends StatelessWidget {
  const AdminProviderDashboardsScreen({super.key});

  void _openDashboard(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Provider Dashboards',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            // Header banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF283593),
                    Color(0xFF3949AB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider Dashboards',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.4.h),
                        Text(
                          'Open, inspect & modify any provider dashboard',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Shop subcategories
            _buildSection(
              context,
              icon: Icons.storefront_rounded,
              title: 'Shop',
              color: const Color(0xFF1565C0),
              entries: [
                _DashEntry(
                  label: 'General Shop',
                  subtitle: 'Grocery / Retail provider',
                  icon: Icons.store_rounded,
                  screenBuilder: () => const ShopProviderDashboardScreen(),
                ),
                _DashEntry(
                  label: 'Plumbing Hardware Shop',
                  subtitle: 'Plumbing supplies provider',
                  icon: Icons.plumbing_rounded,
                  screenBuilder: () => const PlumbingProviderScreen(),
                ),
                _DashEntry(
                  label: 'Electrical Hardware Shop',
                  subtitle: 'Electrical supplies provider',
                  icon: Icons.electrical_services_rounded,
                  screenBuilder: () => const ElectricalProviderScreen(),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Transport subcategories
            _buildSection(
              context,
              icon: Icons.local_shipping_rounded,
              title: 'Transport',
              color: const Color(0xFF00695C),
              entries: [
                _DashEntry(
                  label: 'Ride Provider',
                  subtitle: 'Taxi / Auto / Bike rides',
                  icon: Icons.directions_car_rounded,
                  screenBuilder: () => const TransportRideProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Goods Transport',
                  subtitle: 'Truck / Mini-van logistics',
                  icon: Icons.local_shipping_rounded,
                  screenBuilder: () => const TransportGoodsProviderDashboard(),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Home Maintenance subcategories
            _buildSection(
              context,
              icon: Icons.home_repair_service_rounded,
              title: 'Home Maintenance',
              color: const Color(0xFF6A1B9A),
              entries: [
                _DashEntry(
                  label: 'Plumber',
                  subtitle: 'Plumbing services',
                  icon: Icons.plumbing_rounded,
                  screenBuilder: () => const PlumberProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Electrician',
                  subtitle: 'Electrical services',
                  icon: Icons.electrical_services_rounded,
                  screenBuilder: () => const ElectricianProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Painter',
                  subtitle: 'Painting services',
                  icon: Icons.format_paint_rounded,
                  screenBuilder: () => const PainterProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Mason',
                  subtitle: 'Masonry / Construction',
                  icon: Icons.construction_rounded,
                  screenBuilder: () => const MasonProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Carpenter',
                  subtitle: 'Carpentry services',
                  icon: Icons.handyman_rounded,
                  screenBuilder: () => const CarpenterProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Daily Wage Worker',
                  subtitle: 'General labour',
                  icon: Icons.engineering_rounded,
                  screenBuilder: () => const DailyWageProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Cleaning',
                  subtitle: 'Home cleaning services',
                  icon: Icons.cleaning_services_rounded,
                  screenBuilder: () => const CleaningProviderDashboard(),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Events subcategories
            _buildSection(
              context,
              icon: Icons.celebration_rounded,
              title: 'Events',
              color: const Color(0xFFC62828),
              entries: [
                _DashEntry(
                  label: 'Photography',
                  subtitle: 'Event photography',
                  icon: Icons.camera_alt_rounded,
                  screenBuilder: () => const PhotographyProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Sound & DJ',
                  subtitle: 'Sound systems & DJ',
                  icon: Icons.music_note_rounded,
                  screenBuilder: () => const SoundDjProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Decoration & Catering',
                  subtitle: 'Mandap / Catering',
                  icon: Icons.restaurant_rounded,
                  screenBuilder: () =>
                      const DecorationCateringProviderDashboard(
                        subcategory: 'mandap',
                      ),
                ),
                _DashEntry(
                  label: 'Makeup & Mehendi',
                  subtitle: 'Beauty & event planning',
                  icon: Icons.face_retouching_natural_rounded,
                  screenBuilder: () => const MakeupMehendiEventPlannerDashboard(
                    subcategory: 'makeup',
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Rent subcategories
            _buildSection(
              context,
              icon: Icons.apartment_rounded,
              title: 'Rent',
              color: const Color(0xFF2E7D32),
              entries: [
                _DashEntry(
                  label: 'Room Rental',
                  subtitle: 'Single / double rooms',
                  icon: Icons.bed_rounded,
                  screenBuilder: () => const RoomProviderDashboard(),
                ),
                _DashEntry(
                  label: 'PG Provider',
                  subtitle: 'Paying guest accommodation',
                  icon: Icons.home_rounded,
                  screenBuilder: () => const PgProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Hostel',
                  subtitle: 'Hostel accommodation',
                  icon: Icons.hotel_rounded,
                  screenBuilder: () => const HostelProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Villa / Bungalow',
                  subtitle: 'Premium rental properties',
                  icon: Icons.villa_rounded,
                  screenBuilder: () => const VillaProviderDashboard(),
                ),
                _DashEntry(
                  label: 'Tools & Equipment',
                  subtitle: 'Rental tools & machinery',
                  icon: Icons.build_rounded,
                  screenBuilder: () => const ToolsProviderDashboard(),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Delivery subcategories
            _buildSection(
              context,
              icon: Icons.delivery_dining_rounded,
              title: 'Delivery',
              color: const Color(0xFFAD1457),
              entries: [
                _DashEntry(
                  label: 'Delivery Vendor',
                  subtitle: 'Vendor / merchant dashboard',
                  icon: Icons.store_mall_directory_rounded,
                  screenBuilder: () => const DeliveryVendorDashboard(),
                ),
                _DashEntry(
                  label: 'Rider App',
                  subtitle: 'Delivery rider dashboard',
                  icon: Icons.two_wheeler_rounded,
                  screenBuilder: () => const RiderAppScreen(),
                ),
              ],
            ),
            SizedBox(height: 3.h),
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
    required List<_DashEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 2.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${entries.length} dashboards',
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        // Dashboard tiles
        ...entries.map((e) => _buildDashboardTile(context, e, color)),
      ],
    );
  }

  Widget _buildDashboardTile(
    BuildContext context,
    _DashEntry entry,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(entry.icon, color: accentColor, size: 20),
        ),
        title: Text(
          entry.label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          entry.subtitle,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: const Color(0xFF6B7280),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded, color: accentColor, size: 14),
              const SizedBox(width: 4),
              Text(
                'Open',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _openDashboard(context, entry.screenBuilder()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}

class _DashEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget Function() screenBuilder;

  const _DashEntry({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.screenBuilder,
  });
}
