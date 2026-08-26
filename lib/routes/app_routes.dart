import 'package:flutter/material.dart';

import '../core/role_guard.dart';
import '../core/testing_mode.dart';
import '../presentation/active_booking_tracking_screen/active_booking_tracking_screen.dart';
import '../presentation/admin_login_screen/admin_login_screen.dart';
import '../presentation/admin_panel_screen/admin_advanced_reports_screen.dart';
import '../presentation/admin_panel_screen/admin_banner_ads_screen.dart';
import '../presentation/admin_panel_screen/admin_category_management_screen.dart';
import '../presentation/admin_panel_screen/admin_category_monetization_screen.dart';
import '../presentation/admin_panel_screen/admin_complaints_screen.dart';
import '../presentation/admin_panel_screen/admin_customer_management_screen.dart';
import '../presentation/admin_panel_screen/admin_delivery_management_screen.dart';
import '../presentation/admin_panel_screen/admin_document_review_screen.dart';
import '../presentation/admin_panel_screen/admin_event_management_screen.dart';
import '../presentation/admin_panel_screen/admin_kyc_verification_screen.dart';
import '../presentation/admin_panel_screen/admin_location_settings_screen.dart';
import '../presentation/admin_panel_screen/admin_media_moderation_screen.dart';
import '../presentation/admin_panel_screen/admin_panel_screen.dart';
import '../presentation/admin_panel_screen/admin_play_store_review_screen.dart';
import '../presentation/admin_panel_screen/admin_provider_management_screen.dart';
import '../presentation/admin_panel_screen/admin_quotation_monitoring_screen.dart';
import '../presentation/admin_panel_screen/admin_rent_analytics_screen.dart';
import '../presentation/admin_panel_screen/admin_reports_screen.dart';
import '../presentation/admin_panel_screen/admin_shop_management_screen.dart';
import '../presentation/admin_panel_screen/admin_subscription_management_screen.dart';
import '../presentation/admin_panel_screen/admin_transport_screen.dart';
import '../presentation/admin_panel_screen/admin_user_management_screen.dart';
import '../presentation/all_categories_screen/all_categories_screen.dart';
import '../presentation/booking_checkout_screen/booking_checkout_screen.dart';
import '../presentation/booking_confirmation_screen/booking_confirmation_screen.dart';
import '../presentation/booking_status_screen/booking_status_screen.dart';
import '../presentation/booking_summary_screen/booking_summary_screen.dart';
import '../presentation/category_detail_screen/category_detail_screen.dart';
import '../presentation/change_password_screen/change_password_screen.dart';
import '../presentation/chat_screen/chat_detail_screen.dart';
import '../presentation/chat_screen/chat_list_screen.dart';
import '../presentation/checkout_screen/checkout_screen.dart';
import '../presentation/customer_bookings_screen/customer_bookings_screen.dart';
import '../presentation/customer_home_screen/customer_home_screen.dart';
import '../presentation/customer_past_bookings_screen/customer_past_bookings_screen.dart';
import '../presentation/customer_payment_screen/customer_payment_screen.dart';
import '../presentation/customer_profile_screen/customer_profile_screen.dart';
import '../presentation/customer_quotation_bookings_screen/customer_quotation_bookings_screen.dart';
import '../presentation/customer_support_screen/customer_support_screen.dart';
import '../presentation/delivery_screen/admin_delivery_screen.dart';
import '../presentation/delivery_screen/delivery_customer_screen.dart';
import '../presentation/delivery_screen/delivery_vendor_dashboard.dart';
import '../presentation/delivery_screen/rider_app_screen.dart';
import '../presentation/e2e_verification_screen/e2e_verification_screen.dart';
import '../presentation/event_management_screen/decoration_catering_provider_dashboard.dart';
import '../presentation/event_management_screen/event_management_customer_screen.dart';
import '../presentation/event_management_screen/event_portfolio_packages_screen.dart';
import '../presentation/event_management_screen/event_provider_detail_screen.dart';
import '../presentation/event_management_screen/event_subscription_screen.dart';
import '../presentation/event_management_screen/makeup_mehendi_event_planner_dashboard.dart';
import '../presentation/event_management_screen/photography_provider_dashboard.dart';
import '../presentation/event_management_screen/sound_dj_provider_dashboard.dart';
import '../presentation/gps_location_testing_screen/gps_location_testing_screen.dart';
import '../presentation/home_maintenance_screen/carpenter_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/cleaning_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/daily_wage_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/electrician_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/home_maintenance_customer_screen.dart';
import '../presentation/home_maintenance_screen/home_maintenance_service_charges_screen.dart';
import '../presentation/home_maintenance_screen/mason_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/painter_provider_dashboard.dart';
import '../presentation/home_maintenance_screen/plumber_provider_dashboard.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/legal_screen/legal_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/map_discovery_screen/map_discovery_screen.dart';
import '../presentation/notification_screen/notification_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/order_management_screen/order_management_screen.dart';
import '../presentation/order_status_screen/order_status_screen.dart';
import '../presentation/phone_auth_screen/phone_auth_screen.dart';
import '../presentation/phone_auth_screen/phone_profile_setup_screen.dart';
import '../presentation/play_store_assets_screen/play_store_assets_screen.dart';
import '../presentation/provider_bookings_screen/provider_bookings_screen.dart';
import '../presentation/provider_dashboard_screen/provider_business_profile_edit_screen.dart';
import '../presentation/provider_dashboard_screen/provider_dashboard_screen.dart';
import '../presentation/provider_earnings_dashboard_screen/provider_earnings_dashboard_screen.dart';
import '../presentation/provider_incoming_bookings_screen/provider_incoming_bookings_screen.dart';
import '../presentation/provider_kyc_screen/provider_kyc_upload_screen.dart';
import '../presentation/provider_onboarding_screen/provider_onboarding_screen.dart';
import '../presentation/provider_pending_approval_screen/provider_pending_approval_screen.dart';
import '../presentation/provider_profile_screen/provider_profile_screen.dart';
import '../presentation/provider_profile_screen/provider_public_profile_screen.dart';
import '../presentation/provider_registration_screen/provider_registration_screen.dart';
import '../presentation/provider_subscription_screen/provider_subscription_center_screen.dart';
import '../presentation/provider_subscription_screen/provider_subscription_screen.dart';
import '../presentation/qa_developer_panel/qa_developer_panel_screen.dart';
import '../presentation/quotation_payment_screen/quotation_payment_screen.dart';
import '../presentation/quotation_payment_screen/quotation_payment_success_screen.dart';
import '../presentation/quotation_screen/customer_enquiry_screen.dart';
import '../presentation/quotation_screen/customer_received_quotations_screen.dart';
import '../presentation/quotation_screen/provider_enquiries_screen.dart';
import '../presentation/quotation_screen/quotation_negotiation_screen.dart';
import '../presentation/razorpay_dashboard_screen/razorpay_dashboard_screen.dart';
import '../presentation/razorpay_payment_confirmation_screen/razorpay_payment_confirmation_screen.dart';
import '../presentation/razorpay_transaction_history_screen/razorpay_transaction_history_screen.dart';
import '../presentation/referral_hub_screen/referral_hub_screen.dart';
import '../presentation/rent_screen/hostel_provider_dashboard.dart';
import '../presentation/rent_screen/pg_provider_dashboard.dart';
import '../presentation/rent_screen/rent_booking_confirmation_screen.dart';
import '../presentation/rent_screen/rent_customer_screen.dart';
import '../presentation/rent_screen/rent_ratings_screen.dart';
import '../presentation/rent_screen/rent_subscription_screen.dart';
import '../presentation/rent_screen/room_provider_dashboard.dart';
import '../presentation/rent_screen/tools_provider_dashboard.dart';
import '../presentation/rent_screen/villa_provider_dashboard.dart';
import '../presentation/review_submission_screen/review_submission_screen.dart';
import '../presentation/service_booking_screen/service_booking_screen.dart';
import '../presentation/service_order_confirmation_screen/service_order_confirmation_screen.dart';
import '../presentation/shop_screen/electrical_hardware_customer_screen.dart';
import '../presentation/shop_screen/electrical_ordering_screen.dart';
import '../presentation/shop_screen/electrical_provider_screen.dart';
import '../presentation/shop_screen/meat_shop_customer_screen.dart';
import '../presentation/shop_screen/plumbing_hardware_customer_screen.dart';
import '../presentation/shop_screen/plumbing_provider_screen.dart';
import '../presentation/shop_screen/previous_grocery_lists_screen.dart';
import '../presentation/shop_screen/seasonal_items_customer_screen.dart';
import '../presentation/shop_screen/shop_checkout_screen.dart';
import '../presentation/shop_screen/shop_customer_screen.dart';
import '../presentation/shop_screen/shop_home_screen.dart';
import '../presentation/shop_screen/shop_order_confirm_screen.dart';
import '../presentation/shop_screen/shop_order_confirmation_screen.dart';
import '../presentation/shop_screen/shop_order_status_screen.dart';
import '../presentation/shop_screen/shop_photo_request_screen.dart';
import '../presentation/shop_screen/shop_provider_dashboard_screen.dart';
import '../presentation/shop_screen/shop_return_request_screen.dart';
import '../presentation/shop_screen/vegetables_ordering_screen.dart';
import '../presentation/signup_screen/signup_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/transport_screen/transport_customer_screen.dart';
import '../presentation/transport_screen/transport_fare_config_screen.dart';
import '../presentation/transport_screen/transport_goods_provider_dashboard.dart';
import '../presentation/transport_screen/transport_live_map_screen.dart';
import '../presentation/transport_screen/transport_post_payment_screen.dart';
import '../presentation/transport_screen/transport_provider_chat_screen.dart';
import '../presentation/transport_screen/transport_quotation_screen.dart';
import '../presentation/transport_screen/transport_ride_provider_dashboard.dart';
import '../presentation/unified_inbox_screen/unified_inbox_screen.dart';
import '../presentation/upi_payment_screen/upi_payment_screen.dart';
import '../presentation/virtual_shop_setup_screen/virtual_shop_setup_screen.dart';

// Shop module screens

// Transport module screens

// Rent module screens

// Home Maintenance module screens

// Event Management module screens

// Delivery module screens

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String onboardingScreen = '/onboarding-screen';
  static const String loginScreen = '/login-screen';
  static const String signupScreen = '/signup-screen';
  static const String adminLoginScreen = '/admin-login-screen';
  static const String homeScreen = '/home-screen';
  static const String providerProfileScreen = '/provider-profile-screen';
  static const String providerOnboardingScreen = '/provider-onboarding-screen';
  static const String providerRegistrationScreen =
      '/provider-registration-screen';
  static const String providerPendingApprovalScreen =
      '/provider-pending-approval-screen';
  static const String adminPanelScreen = '/admin-panel-screen';
  static const String categoryDetailScreen = '/category-detail-screen';
  static const String allCategoriesScreen = '/all-categories-screen';
  static const String orderManagementScreen = '/order-management-screen';
  static const String upiPaymentScreen = '/upi-payment-screen';
  static const String notificationScreen = '/notification-screen';
  static const String adminCategoryManagementScreen =
      '/admin-category-management-screen';
  static const String adminUserManagementScreen =
      '/admin-user-management-screen';
  static const String adminBannerAdsScreen = '/admin-banner-ads-screen';
  static const String adminReportsScreen = '/admin-reports-screen';
  static const String adminComplaintsScreen = '/admin-complaints-screen';
  static const String checkoutScreen = '/checkout-screen';
  static const String chatListScreen = '/chat-list-screen';
  static const String chatDetailScreen = '/chat-detail-screen';
  static const String reviewSubmissionScreen = '/review-submission-screen';
  static const String customerProfileScreen = '/customer-profile-screen';
  static const String providerDashboardScreen = '/provider-dashboard-screen';
  static const String providerEarningsDashboardScreen =
      '/provider-earnings-dashboard-screen';
  static const String mapDiscoveryScreen = '/map-discovery-screen';
  static const String legalScreen = '/legal-screen';
  static const String orderStatusScreen = '/order-status-screen';
  static const String customerSupportScreen = '/customer-support-screen';
  static const String bookingConfirmationScreen =
      '/booking-confirmation-screen';
  static const String serviceBookingScreen = '/service-booking-screen';
  static const String serviceOrderConfirmationScreen =
      '/service-order-confirmation-screen';
  static const String providerSubscriptionScreen =
      '/provider-subscription-screen';
  static const String providerSubscriptionCenterScreen =
      '/provider-subscription-center-screen';
  static const String bookingSummaryScreen = '/booking-summary-screen';
  static const String bookingCheckoutScreen = '/booking-checkout-screen';
  static const String customerPaymentScreen = '/customer-payment-screen';

  // ── Booking Status Screen ─────────────────────────────────────────────────
  static const String bookingStatusScreen = '/booking-status-screen';

  // ── Virtual Shop & Quotation Routes ──────────────────────────────────────
  static const String virtualShopSetupScreen = '/virtual-shop-setup-screen';
  static const String providerEnquiriesScreen = '/provider-enquiries-screen';
  static const String providerQuotationBuilderScreen =
      '/provider-quotation-builder-screen';
  static const String customerEnquiryScreen = '/customer-enquiry-screen';
  static const String adminQuotationMonitoringScreen =
      '/admin-quotation-monitoring-screen';
  static const String customerReceivedQuotationsScreen =
      '/customer-received-quotations-screen';
  static const String quotationNegotiationScreen =
      '/quotation-negotiation-screen';

  // ── Shop Module Routes ────────────────────────────────────────────────────
  static const String shopHomeScreen = '/shop-home-screen';
  static const String shopProviderDashboardScreen =
      '/shop-provider-dashboard-screen';
  static const String shopCustomerScreen = '/shop-customer-screen';
  static const String meatShopCustomerScreen = '/meat-shop-customer-screen';
  static const String electricalHardwareCustomerScreen =
      '/electrical-hardware-customer-screen';
  static const String seasonalItemsCustomerScreen =
      '/seasonal-items-customer-screen';
  static const String shopCheckoutScreen = '/shop-checkout-screen';
  static const String shopOrderConfirmationScreen =
      '/shop-order-confirmation-screen';

  // ── Vegetables Ordering Route ─────────────────────────────────────────────
  static const String vegetablesOrderingScreen = '/vegetables-ordering-screen';

  // ── Shop Return & Photo Request Routes ────────────────────────────────────
  static const String shopReturnRequestScreen = '/shop-return-request-screen';
  static const String shopPhotoRequestScreen = '/shop-photo-request-screen';
  static const String shopOrderStatusScreen = '/shop-order-status-screen';

  // ── Previous Grocery Lists Route ──────────────────────────────────────────
  static const String previousGroceryListsScreen =
      '/previous-grocery-lists-screen';

  // ── Shop Order Confirm Route (pre-placement confirmation) ─────────────────
  static const String shopOrderConfirmScreen = '/shop-order-confirm-screen';

  // ── Plumbing & Hardware dedicated route ───────────────────────────────────
  static const String plumbingHardwareCustomerScreen =
      '/plumbing-hardware-customer-screen';
  static const String plumbingProviderScreen = '/plumbing-provider-screen';

  // ── Electrical & Hardware Provider dedicated route ────────────────────────
  static const String electricalProviderScreen = '/electrical-provider-screen';

  // ── Electrical & Hardware Customer dedicated route ────────────────────────
  static const String electricalOrderingScreen = '/electrical-ordering-screen';

  // ── Customer Home Dashboard ───────────────────────────────────────────────
  static const String customerHomeScreen = '/customer-home-screen';

  // ── Transport Module Routes ───────────────────────────────────────────────
  static const String transportCustomerScreen = '/transport-customer-screen';
  static const String transportQuotationScreen = '/transport-quotation-screen';
  static const String transportRideProviderDashboard =
      '/transport-ride-provider-dashboard';
  static const String transportGoodsProviderDashboard =
      '/transport-goods-provider-dashboard';
  static const String adminTransportScreen = '/admin-transport-screen';
  static const String transportProviderChatScreen =
      '/transport-provider-chat-screen';
  static const String transportLiveMapScreen = '/transport-live-map-screen';
  static const String transportPostPaymentScreen =
      '/transport-post-payment-screen';

  // ── Rent Module Routes ────────────────────────────────────────────────────
  static const String rentCustomerScreen = '/rent-customer-screen';
  static const String roomProviderDashboard = '/room-provider-dashboard';
  static const String pgProviderDashboard = '/pg-provider-dashboard';
  static const String hostelProviderDashboard = '/hostel-provider-dashboard';
  static const String villaProviderDashboard = '/villa-provider-dashboard';
  static const String toolsProviderDashboard = '/tools-provider-dashboard';
  static const String rentBookingConfirmationScreen =
      '/rent-booking-confirmation-screen';
  static const String rentRatingsScreen = '/rent-ratings-screen';
  static const String adminRentAnalyticsScreen = '/admin-rent-analytics-screen';
  static const String rentListingDetailScreen = '/rent-listing-detail-screen';
  static const String rentSubscriptionScreen = '/rent-subscription-screen';

  // ── Home Maintenance Module Routes ────────────────────────────────────────
  static const String homeMaintenanceCustomerScreen =
      '/home-maintenance-customer-screen';
  static const String plumberProviderDashboard = '/plumber-provider-dashboard';
  static const String electricianProviderDashboard =
      '/electrician-provider-dashboard';
  static const String painterProviderDashboard = '/painter-provider-dashboard';
  static const String masonProviderDashboard = '/mason-provider-dashboard';
  static const String carpenterProviderDashboard =
      '/carpenter-provider-dashboard';
  static const String dailyWageProviderDashboard =
      '/daily-wage-provider-dashboard';
  static const String cleaningProviderDashboard =
      '/cleaning-provider-dashboard';

  // ── Event Management Module Routes ────────────────────────────────────────
  static const String eventManagementCustomerScreen =
      '/event-management-customer-screen';
  static const String photographyProviderDashboard =
      '/photography-provider-dashboard';
  static const String soundDjProviderDashboard = '/sound-dj-provider-dashboard';
  static const String decorationCateringProviderDashboard =
      '/decoration-catering-provider-dashboard';
  static const String makeupMehendiEventPlannerDashboard =
      '/makeup-mehendi-event-planner-dashboard';
  static const String eventProviderDetailScreen =
      '/event-provider-detail-screen';
  static const String eventSubscriptionScreen = '/event-subscription-screen';
  static const String adminEventManagementScreen =
      '/admin-event-management-screen';

  // ── Delivery Module Routes ────────────────────────────────────────────────
  static const String deliveryCustomerScreen = '/delivery-customer-screen';
  static const String deliveryVendorDashboard = '/delivery-vendor-dashboard';
  static const String riderAppScreen = '/rider-app-screen';
  static const String adminDeliveryScreen = '/admin-delivery-screen';

  // ── Unified Inbox Route ───────────────────────────────────────────────────
  static const String unifiedInboxScreen = '/unified-inbox-screen';

  // ── Razorpay Payment Routes ───────────────────────────────────────────────
  static const String razorpayPaymentConfirmationScreen =
      '/razorpay-payment-confirmation-screen';
  static const String razorpayTransactionHistoryScreen =
      '/razorpay-transaction-history-screen';
  static const String razorpayDashboardScreen = '/razorpay-dashboard-screen';

  // ── New Admin Module Routes ───────────────────────────────────────────────
  static const String adminProviderManagementScreen =
      '/admin-provider-management-screen';
  static const String adminShopManagementScreen =
      '/admin-shop-management-screen';
  static const String adminSubscriptionManagementScreen =
      '/admin-subscription-management-screen';
  static const String adminDeliveryManagementScreen =
      '/admin-delivery-management-screen';
  static const String adminAdvancedReportsScreen =
      '/admin-advanced-reports-screen';
  static const String adminCustomerManagementScreen =
      '/admin-customer-management-screen';
  static const String adminLocationSettingsScreen =
      '/admin-location-settings-screen';

  // ── Category Monetization Config ──────────────────────────────────────────
  static const String adminCategoryMonetizationScreen =
      '/admin-category-monetization-screen';

  // ── Admin Media Moderation ────────────────────────────────────────────────
  static const String adminMediaModerationScreen =
      '/admin-media-moderation-screen';

  // ── GPS Location Testing Screen ───────────────────────────────────────────
  static const String gpsLocationTestingScreen = '/gps-location-testing-screen';
  static const String changePasswordScreen = '/change-password-screen';

  // ── QA Developer Panel ────────────────────────────────────────────────────
  static const String qaDeveloperPanelScreen = '/qa-developer-panel-screen';

  // ── E2E Verification Screen ───────────────────────────────────────────────
  static const String e2eVerificationScreen = '/e2e-verification-screen';

  static const String providerBusinessProfileEditScreen =
      '/provider-business-profile-edit-screen';
  static const String transportFareConfigScreen =
      '/transport-fare-config-screen';
  static const String homeMaintenanceServiceChargesScreen =
      '/home-maintenance-service-charges-screen';
  static const String eventPortfolioPackagesScreen =
      '/event-portfolio-packages-screen';
  static const String providerPublicProfileScreen =
      '/provider-public-profile-screen';

  static const String customerPastBookingsScreen =
      '/customer-past-bookings-screen';

  static const String customerBookingsScreen = '/customer-bookings-screen';

  static const String providerBookingsScreen = '/provider-bookings-screen';

  // ── Provider Incoming Bookings (from quotations) ──────────────────────────
  static const String providerIncomingBookingsScreen =
      '/provider-incoming-bookings-screen';

  // ── Customer Quotation Bookings ───────────────────────────────────────────
  static const String customerQuotationBookingsScreen =
      '/customer-quotation-bookings-screen';

  // ── Quotation Payment Routes ──────────────────────────────────────────────
  static const String quotationPaymentScreen = '/quotation-payment-screen';
  static const String quotationPaymentSuccessScreen =
      '/quotation-payment-success-screen';

  // ── KYC Routes ────────────────────────────────────────────────────────────
  static const String providerKycUploadScreen = '/provider-kyc-upload-screen';
  static const String adminKycVerificationScreen =
      '/admin-kyc-verification-screen';
  static const String adminDocumentReviewScreen =
      '/admin-document-review-screen';

  // ── Referral Hub Route ────────────────────────────────────────────────────
  static const String referralHubScreen = '/referral-hub-screen';

  // ── Play Store Assets Route ───────────────────────────────────────────────
  static const String playStoreAssetsScreen = '/play-store-assets-screen';
  static const String adminPlayStoreReviewScreen =
      '/admin-play-store-review-screen';

  // ── Phone Auth Routes ─────────────────────────────────────────────────────
  static const String inviteFriendsScreen = '/invite-friends-screen';
  static const String phoneAuthScreen = '/phone-auth-screen';
  static const String phoneProfileSetupScreen = '/phone-profile-setup-screen';

  // ── Active Booking Live Tracking ──────────────────────────────────────────
  static const String activeBookingTrackingScreen =
      '/active-booking-tracking-screen';

  static const String customerLocationSetupScreen =
      '/customer-location-setup-screen';
  static const String providerServiceAreaScreen =
      '/provider-service-area-screen';

  static Map<String, WidgetBuilder> get routes {
    return {
      initial: (context) => const SplashScreen(),
      splashScreen: (context) => const SplashScreen(),
      onboardingScreen: (context) => const OnboardingScreen(),
      loginScreen: (context) => const LoginScreen(key: null),
      phoneAuthScreen: (context) => const PhoneAuthScreen(),
      phoneProfileSetupScreen: (context) => const PhoneProfileSetupScreen(),
      signupScreen: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String?;
        return SignupScreen(initialEmail: email);
      },
      adminLoginScreen: (context) => const AdminLoginScreen(),
      // ── Customer-only routes ──────────────────────────────────────────────,
      homeScreen: (context) =>
          const RoleGuard(requiredRole: 'customer', child: HomeScreen()),
      allCategoriesScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: AllCategoriesScreen(),
      ),
      categoryDetailScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CategoryDetailScreen(),
      ),
      checkoutScreen: (context) =>
          const RoleGuard(requiredRole: 'customer', child: CheckoutScreen()),
      upiPaymentScreen: (context) =>
          const RoleGuard(requiredRole: 'customer', child: UpiPaymentScreen()),
      bookingConfirmationScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: BookingConfirmationScreen(),
      ),
      serviceBookingScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ServiceBookingScreen(),
      ),
      serviceOrderConfirmationScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ServiceOrderConfirmationScreen(),
      ),
      customerProfileScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerProfileScreen(),
      ),
      reviewSubmissionScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ReviewSubmissionScreen(),
      ),
      mapDiscoveryScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: MapDiscoveryScreen(),
      ),
      // ── Shop Customer Routes ──────────────────────────────────────────────,
      shopHomeScreen: (context) =>
          const RoleGuard(requiredRole: 'customer', child: ShopHomeScreen()),
      shopCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopCustomerScreen(),
      ),
      meatShopCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: MeatShopCustomerScreen(),
      ),
      electricalHardwareCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ElectricalHardwareCustomerScreen(),
      ),
      seasonalItemsCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: SeasonalItemsCustomerScreen(),
      ),
      shopCheckoutScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopCheckoutScreen(),
      ),
      shopOrderConfirmationScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopOrderConfirmationScreen(),
      ),
      vegetablesOrderingScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: VegetablesOrderingScreen(),
      ),
      shopReturnRequestScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopReturnRequestScreen(),
      ),
      shopPhotoRequestScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopPhotoRequestScreen(),
      ),
      shopOrderStatusScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopOrderStatusScreen(),
      ),
      previousGroceryListsScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: PreviousGroceryListsScreen(),
      ),
      shopOrderConfirmScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ShopOrderConfirmScreen(),
      ),
      plumbingHardwareCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: PlumbingHardwareCustomerScreen(),
      ),
      plumbingProviderScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: PlumbingProviderScreen(),
      ),
      electricalProviderScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ElectricalProviderScreen(),
      ),
      electricalOrderingScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ElectricalOrderingScreen(),
      ),
      customerHomeScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerHomeScreen(),
      ),
      // ── Transport Customer Routes ─────────────────────────────────────────,
      transportCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: TransportCustomerScreen(),
      ),
      transportQuotationScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: TransportQuotationScreen(),
      ),
      // ── Transport Provider Routes ─────────────────────────────────────────,
      transportRideProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: TransportRideProviderDashboard(),
      ),
      transportGoodsProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: TransportGoodsProviderDashboard(),
      ),
      transportProviderChatScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: TransportProviderChatScreen(),
      ),
      transportLiveMapScreen: (context) => const TransportLiveMapScreen(),
      transportPostPaymentScreen: (context) =>
          const TransportPostPaymentScreen(),
      adminTransportScreen: (context) =>
          const RoleGuard(requiredRole: 'admin', child: AdminTransportScreen()),
      // ── Rent Customer Routes ──────────────────────────────────────────────,
      rentCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: RentCustomerScreen(),
      ),
      rentBookingConfirmationScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: RentBookingConfirmationScreen(),
      ),
      rentRatingsScreen: (context) =>
          const RoleGuard(requiredRole: 'customer', child: RentRatingsScreen()),
      rentSubscriptionScreen: (context) => const RentSubscriptionScreen(),
      // ── Rent Provider Routes ──────────────────────────────────────────────,
      roomProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: RoomProviderDashboard(),
      ),
      pgProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: PgProviderDashboard(),
      ),
      hostelProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: HostelProviderDashboard(),
      ),
      villaProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: VillaProviderDashboard(),
      ),
      toolsProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ToolsProviderDashboard(),
      ),
      // ── Shop Provider Routes ──────────────────────────────────────────────,
      shopProviderDashboardScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ShopProviderDashboardScreen(),
      ),
      // ── Provider-only routes ──────────────────────────────────────────────,
      providerDashboardScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderDashboardScreen(),
      ),
      providerEarningsDashboardScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderEarningsDashboardScreen(),
      ),
      providerSubscriptionScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderSubscriptionScreen(),
      ),
      providerSubscriptionCenterScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderSubscriptionCenterScreen(),
      ),
      providerBookingsScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderBookingsScreen(),
      ),
      providerIncomingBookingsScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderIncomingBookingsScreen(),
      ),
      customerQuotationBookingsScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerQuotationBookingsScreen(),
      ),
      // ── KYC Routes ────────────────────────────────────────────────────────,
      providerKycUploadScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderKycUploadScreen(),
      ),
      adminKycVerificationScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminKycVerificationScreen(),
      ),
      adminDocumentReviewScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminDocumentReviewScreen(),
      ),
      // ── Admin-only routes ─────────────────────────────────────────────────,
      adminPanelScreen: (context) =>
          const RoleGuard(requiredRole: 'admin', child: AdminPanelScreen()),
      adminCategoryManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminCategoryManagementScreen(),
      ),
      adminUserManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminUserManagementScreen(),
      ),
      adminBannerAdsScreen: (context) =>
          const RoleGuard(requiredRole: 'admin', child: AdminBannerAdsScreen()),
      adminReportsScreen: (context) =>
          const RoleGuard(requiredRole: 'admin', child: AdminReportsScreen()),
      adminComplaintsScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminComplaintsScreen(),
      ),
      adminRentAnalyticsScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminRentAnalyticsScreen(),
      ),
      adminProviderManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminProviderManagementScreen(),
      ),
      adminShopManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminShopManagementScreen(),
      ),
      adminSubscriptionManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminSubscriptionManagementScreen(),
      ),
      adminAdvancedReportsScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminAdvancedReportsScreen(),
      ),
      adminCustomerManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminCustomerManagementScreen(),
      ),
      adminCategoryMonetizationScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminCategoryMonetizationScreen(),
      ),
      adminMediaModerationScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminMediaModerationScreen(),
      ),
      adminLocationSettingsScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminLocationSettingsScreen(),
      ),
      // ── Home Maintenance Customer Routes ─────────────────────────────────,
      homeMaintenanceCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: HomeMaintenanceCustomerScreen(),
      ),
      // ── Home Maintenance Provider Routes ─────────────────────────────────,
      plumberProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: PlumberProviderDashboard(),
      ),
      electricianProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ElectricianProviderDashboard(),
      ),
      painterProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: PainterProviderDashboard(),
      ),
      masonProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: MasonProviderDashboard(),
      ),
      carpenterProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: CarpenterProviderDashboard(),
      ),
      dailyWageProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: DailyWageProviderDashboard(),
      ),
      cleaningProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: CleaningProviderDashboard(),
      ),
      // ── Event Management Customer Routes ─────────────────────────────────,
      eventManagementCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: EventManagementCustomerScreen(),
      ),
      // ── Event Management Provider Routes ─────────────────────────────────,
      photographyProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: PhotographyProviderDashboard(),
      ),
      soundDjProviderDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: SoundDjProviderDashboard(),
      ),
      decorationCateringProviderDashboard: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final sub = args is String ? args : 'mandap';
        return RoleGuard(
          requiredRole: 'provider',
          child: DecorationCateringProviderDashboard(subcategory: sub),
        );
      },
      makeupMehendiEventPlannerDashboard: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final sub = args is String ? args : 'makeup';
        return RoleGuard(
          requiredRole: 'provider',
          child: MakeupMehendiEventPlannerDashboard(subcategory: sub),
        );
      },
      eventSubscriptionScreen: (context) => const EventSubscriptionScreen(),
      eventProviderDetailScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return EventProviderDetailScreen(
          provider: args?['provider'] as Map<String, dynamic>? ?? {},
          subcategory:
              args?['subcategory'] as Map<String, dynamic>? ??
              {
                'id': 'photography',
                'label': 'Photography',
                'color': Color(0xFFAD1457),
              },
        );
      },
      adminEventManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminEventManagementScreen(),
      ),
      // ── Delivery Customer Routes ──────────────────────────────────────────,
      deliveryCustomerScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: DeliveryCustomerScreen(),
      ),
      // ── Delivery Vendor Routes ────────────────────────────────────────────,
      deliveryVendorDashboard: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: DeliveryVendorDashboard(),
      ),
      riderAppScreen: (context) =>
          const RoleGuard(requiredRole: 'provider', child: RiderAppScreen()),
      // ── Admin Delivery Routes ─────────────────────────────────────────────,
      adminDeliveryScreen: (context) =>
          const RoleGuard(requiredRole: 'admin', child: AdminDeliveryScreen()),
      adminDeliveryManagementScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminDeliveryManagementScreen(),
      ),
      // ── Unified Inbox ─────────────────────────────────────────────────────,
      unifiedInboxScreen: (context) => const UnifiedInboxScreen(),
      referralHubScreen: (context) => const ReferralHubScreen(),
      playStoreAssetsScreen: (context) => const PlayStoreAssetsScreen(),
      adminPlayStoreReviewScreen: (context) =>
          const AdminPlayStoreReviewScreen(),
      // ── Razorpay Routes ───────────────────────────────────────────────────,
      razorpayPaymentConfirmationScreen: (context) =>
          const RazorpayPaymentConfirmationScreen(),
      razorpayTransactionHistoryScreen: (context) =>
          const RazorpayTransactionHistoryScreen(),
      razorpayDashboardScreen: (context) => const RazorpayDashboardScreen(),
      // ── Quotation Payment Routes ──────────────────────────────────────────
      quotationPaymentScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: QuotationPaymentScreen(),
      ),
      quotationPaymentSuccessScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: QuotationPaymentSuccessScreen(),
      ),
      // ── Shared routes (accessible by multiple roles) ──────────────────────,
      providerProfileScreen: (context) => const ProviderProfileScreen(),
      providerOnboardingScreen: (context) => const ProviderOnboardingScreen(),
      providerRegistrationScreen: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String?;
        return ProviderRegistrationScreen(initialEmail: email);
      },
      providerPendingApprovalScreen: (context) =>
          const ProviderPendingApprovalScreen(),
      orderManagementScreen: (context) => const OrderManagementScreen(),
      notificationScreen: (context) => const NotificationScreen(),
      chatListScreen: (context) => const ChatListScreen(),
      chatDetailScreen: (context) => const ChatDetailScreen(),
      legalScreen: (context) => const LegalScreen(),
      orderStatusScreen: (context) => const OrderStatusScreen(),
      customerSupportScreen: (context) => const CustomerSupportScreen(),
      // ── QA Developer Panel (testing mode only) ────────────────────────────
      // Guard: only accessible when TESTING_MODE=true (never in production)
      qaDeveloperPanelScreen: (context) {
        if (!TestingMode.isEnabled) {
          return const SplashScreen();
        }
        return const QaDeveloperPanelScreen();
      },
      e2eVerificationScreen: (context) => const E2EVerificationScreen(),
      gpsLocationTestingScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: GpsLocationTestingScreen(),
      ),
      changePasswordScreen: (context) => const ChangePasswordScreen(),
      providerBusinessProfileEditScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderBusinessProfileEditScreen(),
      ),
      transportFareConfigScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: TransportFareConfigScreen(),
      ),
      homeMaintenanceServiceChargesScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: HomeMaintenanceServiceChargesScreen(),
      ),
      eventPortfolioPackagesScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: EventPortfolioPackagesScreen(),
      ),
      providerPublicProfileScreen: (context) =>
          const ProviderPublicProfileScreen(),
      customerPastBookingsScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerPastBookingsScreen(),
      ),
      customerBookingsScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerBookingsScreen(),
      ),
      activeBookingTrackingScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: ActiveBookingTrackingScreen(),
      ),
      bookingSummaryScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: BookingSummaryScreen(),
      ),
      bookingCheckoutScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: BookingCheckoutScreen(),
      ),
      customerPaymentScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerPaymentScreen(),
      ),
      bookingStatusScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: BookingStatusScreen(),
      ),
      virtualShopSetupScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: VirtualShopSetupScreen(isEditing: true),
      ),
      providerEnquiriesScreen: (context) => const RoleGuard(
        requiredRole: 'provider',
        child: ProviderEnquiriesScreen(),
      ),
      customerEnquiryScreen: (context) => const RoleGuard(
        requiredRole: 'customer',
        child: CustomerEnquiryScreen(),
      ),
      adminQuotationMonitoringScreen: (context) => const RoleGuard(
        requiredRole: 'admin',
        child: AdminQuotationMonitoringScreen(),
      ),
      customerReceivedQuotationsScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return RoleGuard(
          requiredRole: 'customer',
          child: CustomerReceivedQuotationsScreen(
            initialFilter: args?['filter'] as String?,
          ),
        );
      },
      quotationNegotiationScreen: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final role = args?['role'] as String? ?? 'customer';
        final quotation = args?['quotation'] as Map<String, dynamic>?;
        return QuotationNegotiationScreen(
          quotation: quotation ?? {},
          role: role,
        );
      },
    };
  }
}
