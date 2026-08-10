import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/provider_subscription_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/razorpay_payment_widget.dart';

class ProviderSubscriptionCenterScreen extends StatefulWidget {
  const ProviderSubscriptionCenterScreen({super.key});

  @override
  State<ProviderSubscriptionCenterScreen> createState() =>
      _ProviderSubscriptionCenterScreenState();
}

class _ProviderSubscriptionCenterScreenState
    extends State<ProviderSubscriptionCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSub;
  SubscriptionStatus? _subStatus;
  List<Map<String, dynamic>> _paymentHistory = [];
  Map<String, dynamic>? _providerProfile;

  bool _autoRenew = false;
  bool _updatingAutoRenew = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = await SupabaseService.instance.getMyProviderProfile();
      if (provider == null) {
        setState(() {
          _error = 'Provider profile not found.';
          _isLoading = false;
        });
        return;
      }
      _providerProfile = provider;
      final providerId = provider['id'] as String;

      final results = await Future.wait([
        SupabaseService.instance.client
            .from('subscription_plans')
            .select()
            .eq('is_active', true)
            .order('display_order') as Future<dynamic>,
        ProviderSubscriptionService.instance.getCurrentSubscription(providerId) as Future<dynamic>,
        ProviderSubscriptionService.instance.getPaymentHistory(providerId) as Future<dynamic>,
      ]);

      final plans = List<Map<String, dynamic>>.from(results[0] as List);
      final sub = results[1] as Map<String, dynamic>?;
      final history = results[2] as List<Map<String, dynamic>>;

      final status = ProviderSubscriptionService.instance.analyzeStatus(sub);

      // Send reminders if needed
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        ProviderSubscriptionService.instance.checkAndSendReminders(
          providerId,
          userId,
        );
      }

      if (mounted) {
        setState(() {
          _plans = plans;
          _currentSub = sub;
          _subStatus = status;
          _autoRenew = (sub?['auto_renew'] as bool?) ?? false;
          _paymentHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load subscription data.';
          _isLoading = false;
        });
      }
    }
  }

  // ─── AUTO-RENEW TOGGLE ────────────────────────────────────────────────────

  Future<void> _toggleAutoRenew(bool value) async {
    final subId = _currentSub?['id'] as String?;
    if (subId == null) return;
    setState(() => _updatingAutoRenew = true);
    final success = await ProviderSubscriptionService.instance.toggleAutoRenew(
      subId,
      value,
    );
    if (mounted) {
      setState(() {
        _updatingAutoRenew = false;
        if (success) _autoRenew = value;
      });
      _showSnack(
        success
            ? (value ? 'Auto-renewal enabled' : 'Auto-renewal disabled')
            : 'Update failed. Try again.',
        success: success,
      );
    }
  }

  // ─── SUBSCRIBE / RENEW ────────────────────────────────────────────────────

  Future<void> _subscribeToPlan(
    Map<String, dynamic> plan, {
    bool isRenewal = false,
  }) async {
    final providerId = _providerProfile?['id'] as String?;
    if (providerId == null) return;

    final planName = plan['name'] as String? ?? 'Plan';
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final durationDays = (plan['duration_days'] as int?) ?? 30;

    if (price > 0) {
      if (kIsWeb) {
        RazorpayService.showWebNotSupportedDialog(context);
        return;
      }
      _openRazorpaySheet(
        plan: plan,
        planName: planName,
        price: price,
        durationDays: durationDays,
        providerId: providerId,
        isRenewal: isRenewal,
      );
      return;
    }

    // Free plan
    final confirmed = await _showConfirmDialog(
      title: isRenewal ? 'Renew Plan' : 'Activate Plan',
      message: 'Activate $planName for $durationDays days?',
      confirmLabel: 'Activate',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _activateFreeSubscription(
        plan: plan,
        providerId: providerId,
        isRenewal: isRenewal,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openRazorpaySheet({
    required Map<String, dynamic> plan,
    required String planName,
    required double price,
    required int durationDays,
    required String providerId,
    required bool isRenewal,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E8EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              isRenewal ? 'Renew Subscription' : 'Subscribe to $planName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 1.h),
            _buildPaymentSummaryCard(planName, price, durationDays),
            SizedBox(height: 2.h),
            RazorpayPaymentWidget(
              amount: price,
              description: 'LocalConnect $planName Subscription',
              paymentType: 'subscription',
              providerId: providerId,
              planId: plan['id'] as String?,
              notes: {
                'plan': planName,
                'duration_days': durationDays.toString(),
                'type': isRenewal ? 'renewal' : 'new_subscription',
              },
              onPaymentSuccess: () async {
                Navigator.pop(ctx);
                _showSnack(
                  'Payment successful! Activating subscription...',
                  success: true,
                );
                // The webhook will verify and activate, but also do client-side activation
                await _activatePaidSubscription(
                  plan: plan,
                  providerId: providerId,
                  isRenewal: isRenewal,
                  paymentRef: 'RZP_${DateTime.now().millisecondsSinceEpoch}',
                );
              },
              onPaymentFailed: (error) {
                Navigator.pop(ctx);
                _showSnack('Payment failed: $error');
              },
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: Color(0xFF74777F),
                ),
                const SizedBox(width: 4),
                Text(
                  'Secured by Razorpay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(
    String planName,
    double price,
    int durationDays,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow('Plan', planName),
          SizedBox(height: 0.8.h),
          _summaryRow('Duration', '$durationDays days'),
          const Divider(height: 16),
          _summaryRow(
            'Total Amount',
            price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            color: const Color(0xFF74777F),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: highlight ? 14.sp : 12.sp,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.primary : const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Future<void> _activatePaidSubscription({
    required Map<String, dynamic> plan,
    required String providerId,
    required bool isRenewal,
    required String paymentRef,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final now = DateTime.now();
      final durationDays = (plan['duration_days'] as int?) ?? 30;
      final endDate = now.add(Duration(days: durationDays));

      // Expire existing
      await client
          .from('provider_subscriptions')
          .update({'status': 'expired', 'updated_at': now.toIso8601String()})
          .eq('provider_id', providerId)
          .eq('status', 'active');

      // Create new
      await client.from('provider_subscriptions').insert({
        'provider_id': providerId,
        'plan_id': plan['id'],
        'status': 'active',
        'is_trial': false,
        'start_date': now.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'started_at': now.toIso8601String(),
        'expires_at': endDate.toIso8601String(),
        'auto_renew': _autoRenew,
        'payment_ref': paymentRef,
      });

      // Billing history
      final price = (plan['price'] as num?)?.toDouble() ?? 0;
      if (price > 0) {
        await client.from('subscription_billing_history').insert({
          'provider_id': providerId,
          'plan_id': plan['id'],
          'amount': price,
          'payment_ref': paymentRef,
          'payment_method': 'Razorpay',
          'status': 'paid',
          'description':
              '${isRenewal ? 'Renewal' : 'New'} — ${plan['name']} plan',
        });
      }

      if (mounted) {
        _showSnack(
          isRenewal
              ? 'Subscription renewed successfully!'
              : 'Subscribed to ${plan['name']}!',
          success: true,
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Activation failed. Please contact support.');
      }
    }
  }

  Future<void> _activateFreeSubscription({
    required Map<String, dynamic> plan,
    required String providerId,
    required bool isRenewal,
  }) async {
    await _activatePaidSubscription(
      plan: plan,
      providerId: providerId,
      isRenewal: isRenewal,
      paymentRef: 'FREE',
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Subscription Center',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'My Plan'),
            Tab(text: 'Plans'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyPlanTab(),
                _buildPlansTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          SizedBox(height: 1.5.h),
          Text(
            _error!,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.plusJakartaSans()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MY PLAN TAB ──────────────────────────────────────────────────────────

  Widget _buildMyPlanTab() {
    final status = _subStatus;
    if (status == null ||
        status.type == SubscriptionStatusType.noSubscription) {
      return _buildNoSubscriptionState();
    }

    final plan = _currentSub?['subscription_plans'] as Map<String, dynamic>?;
    final planName = plan?['name'] as String? ?? 'Basic';
    final price = (plan?['price'] as num?)?.toDouble() ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner for grace period / expiry
            if (status.type == SubscriptionStatusType.gracePeriod)
              _buildGracePeriodBanner(status),
            if (status.type == SubscriptionStatusType.trialExpired ||
                status.type == SubscriptionStatusType.expired)
              _buildExpiredBanner(),

            // Hero plan card
            _buildPlanHeroCard(planName, price, status),
            SizedBox(height: 2.h),

            // Countdown card
            _buildCountdownCard(status),
            SizedBox(height: 2.h),

            // Auto-renewal toggle
            _buildAutoRenewalCard(),
            SizedBox(height: 2.h),

            // Quick actions
            _buildQuickActions(status),
            SizedBox(height: 2.h),

            // Plan features
            if (plan != null) _buildPlanFeatures(plan),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildGracePeriodBanner(SubscriptionStatus status) {
    final graceDays = status.gracePeriodEnd != null
        ? status.gracePeriodEnd!.difference(DateTime.now()).inDays
        : 0;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE65100),
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Grace Period Active — $graceDays days left',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
                Text(
                  'You can log in and renew. Customers cannot discover you until renewed.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Expired',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
                Text(
                  'Renew now to restore your visibility and accept bookings.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanHeroCard(
    String planName,
    double price,
    SubscriptionStatus status,
  ) {
    final isPremium = planName.toLowerCase().contains('premium');
    final isPro = planName.toLowerCase().contains('pro');
    final gradient = isPremium
        ? const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : isPro
        ? AppTheme.primaryGradient
        : const LinearGradient(
            colors: [Color(0xFF546E7A), Color(0xFF78909C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPremium
                      ? Icons.workspace_premium_rounded
                      : isPro
                      ? Icons.star_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.isTrial ? 'Free Trial' : 'Current Plan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      planName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: status.isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _heroStat(
                'Price',
                price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}/mo',
                Icons.currency_rupee_rounded,
              ),
              _verticalDivider(),
              _heroStat(
                'Renewal Date',
                status.endDate != null
                    ? '${status.endDate!.day}/${status.endDate!.month}/${status.endDate!.year}'
                    : '—',
                Icons.event_rounded,
              ),
              _verticalDivider(),
              _heroStat(
                'Days Left',
                status.daysLeft > 0 ? '${status.daysLeft}' : 'Expired',
                Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          SizedBox(height: 0.3.h),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 4.h,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildCountdownCard(SubscriptionStatus status) {
    final daysLeft = status.daysLeft;
    final isExpiringSoon = daysLeft <= 7 && daysLeft > 0;
    final isExpired = !status.isActive && !status.isInGracePeriod;

    Color cardColor = isExpired
        ? const Color(0xFFFFEBEE)
        : isExpiringSoon
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);

    Color textColor = isExpired
        ? AppTheme.error
        : isExpiringSoon
        ? const Color(0xFFE65100)
        : AppTheme.success;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isExpired ? '!' : '$daysLeft',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Subscription Expired'
                      : isExpiringSoon
                      ? 'Expiring Soon!'
                      : status.isTrial
                      ? 'Free Trial Active'
                      : 'Subscription Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  isExpired
                      ? 'Renew now to restore your visibility'
                      : isExpiringSoon
                      ? '$daysLeft days remaining — renew to avoid interruption'
                      : status.isTrial
                      ? '$daysLeft days of free trial remaining'
                      : '$daysLeft days until renewal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRenewalCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.autorenew_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Renewal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  _autoRenew
                      ? 'Subscription will auto-renew before expiry'
                      : 'Manual renewal required before expiry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
              ],
            ),
          ),
          _updatingAutoRenew
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _autoRenew,
                  onChanged: _currentSub != null ? _toggleAutoRenew : null,
                  activeThumbColor: AppTheme.primary,
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(SubscriptionStatus status) {
    final canRenew = _currentSub != null;
    return Row(
      children: [
        if (canRenew)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () {
                      final plan =
                          _currentSub?['subscription_plans']
                              as Map<String, dynamic>?;
                      if (plan != null) {
                        _subscribeToPlan(plan, isRenewal: true);
                      } else {
                        _tabController.animateTo(1);
                      }
                    },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Renew Now',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (canRenew) SizedBox(width: 3.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.upgrade_rounded, size: 16),
            label: Text(
              'Upgrade Plan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanFeatures(Map<String, dynamic> plan) {
    final features = plan['features'];
    List<String> featureList = [];
    if (features is List) {
      featureList = features.map((f) => f.toString()).toList();
    }
    if (featureList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Features',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          SizedBox(height: 1.5.h),
          ...featureList.map(
            (f) => Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        color: const Color(0xFF44474E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 10.w,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Subscription',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Choose a plan to start accepting bookings and grow your business.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                color: const Color(0xFF74777F),
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.star_rounded),
              label: Text(
                'View Plans',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PLANS TAB ────────────────────────────────────────────────────────────

  Widget _buildPlansTab() {
    if (_plans.isEmpty) {
      return Center(
        child: Text(
          'No plans available.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            color: AppTheme.outline,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trial info banner
          Container(
            padding: EdgeInsets.all(3.w),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '🎁 New providers get 30 days FREE trial — no payment required!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._plans.asMap().entries.map((e) => _buildPlanCard(e.value, e.key)),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final planColors = [
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
      const Color(0xFF00695C),
      const Color(0xFF4527A0),
    ];
    final color = planColors[index % planColors.length];
    final name = plan['name'] as String? ?? 'Plan';
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final durationDays = (plan['duration_days'] as int?) ?? 30;
    final billingCycle = plan['billing_cycle'] as String? ?? 'monthly';
    final discount = (plan['discount_pct'] as num?)?.toDouble() ?? 0;
    final description = plan['description'] as String? ?? '';
    final features = plan['features'];
    List<String> featureList = [];
    if (features is List) {
      featureList = features.map((f) => f.toString()).toList();
    }

    final isCurrentPlan = _currentSub?['plan_id'] == plan['id'];
    final isActive = _subStatus?.isActive == true && isCurrentPlan;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isActive ? color : color.withValues(alpha: 0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          if (discount > 0) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Save ${discount.toStringAsFixed(0)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      price == 0
                          ? '$durationDays days'
                          : _billingLabel(billingCycle, durationDays),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Features
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                ...featureList
                    .take(4)
                    .map(
                      (f) => Padding(
                        padding: EdgeInsets.only(bottom: 0.6.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: color,
                              size: 14,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                f,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF44474E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (featureList.length > 4)
                  Text(
                    '+${featureList.length - 4} more features',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: isActive
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            'Current Plan',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color),
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _subscribeToPlan(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            price == 0 ? 'Activate Free' : 'Subscribe Now',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _billingLabel(String cycle, int days) {
    switch (cycle) {
      case 'quarterly':
        return '/ 3 months';
      case 'yearly':
        return '/ year';
      default:
        return '/ month';
    }
  }

  // ─── HISTORY TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppTheme.outline,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'No payment history yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _paymentHistory.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (_, i) => _buildHistoryItem(_paymentHistory[i]),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final plan = item['subscription_plans'] as Map<String, dynamic>?;
    final planName = plan?['name'] as String? ?? 'Plan';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final status = item['status'] as String? ?? 'paid';
    final billedAt = item['billed_at'] as String?;
    final paymentRef = item['payment_ref'] as String? ?? '';
    final method = item['payment_method'] as String? ?? 'Razorpay';
    final description = item['description'] as String? ?? '';

    DateTime? date = billedAt != null ? DateTime.tryParse(billedAt) : null;

    final statusColor = status == 'paid'
        ? AppTheme.success
        : status == 'failed'
        ? AppTheme.error
        : const Color(0xFFE65100);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'paid'
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: const Color(0xFF74777F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Text(
                      method,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    if (paymentRef.isNotEmpty && paymentRef != 'FREE') ...[
                      Text(
                        ' • ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          paymentRef.length > 20
                              ? '${paymentRef.substring(0, 20)}...'
                              : paymentRef,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            color: const Color(0xFF74777F),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount == 0 ? 'Free' : '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: const Color(0xFF74777F),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
