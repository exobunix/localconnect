import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/provider_subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});

  @override
  State<AdminSubscriptionManagementScreen> createState() =>
      _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState
    extends State<AdminSubscriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _subscriptions = [];
  Map<String, dynamic> _analytics = {};
  Map<String, String> _config = {};

  bool _isLoading = true;
  String? _error;
  String _subFilter = 'all';

  static const List<Color> _planColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
    Color(0xFF4527A0),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      await Future.wait([
        _loadPlans(),
        _loadSubscriptions(),
        _loadAnalytics(),
        _loadConfig(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlans() async {
    final result = await SupabaseService.instance.client
        .from('subscription_plans')
        .select()
        .order('display_order', ascending: true);
    if (mounted) {
      setState(() => _plans = List<Map<String, dynamic>>.from(result as List));
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final result = await SupabaseService.instance.client
          .from('provider_subscriptions')
          .select('''
            id, status, is_trial, start_date, end_date, expires_at,
            started_at, auto_renew, payment_ref, grace_period_end,
            razorpay_payment_id, created_at,
            subscription_plans(name, price, billing_cycle),
            service_providers(id, business_name, category, user_id)
          ''')
          .order('created_at', ascending: false)
          .limit(200);
      if (mounted) {
        setState(
          () =>
              _subscriptions = List<Map<String, dynamic>>.from(result as List),
        );
      }
    } catch (e) {
      debugPrint('Load subscriptions error: $e');
      try {
        final result = await SupabaseService.instance.client
            .from('provider_subscriptions')
            .select()
            .order('created_at', ascending: false)
            .limit(200);
        if (mounted) {
          setState(
            () => _subscriptions = List<Map<String, dynamic>>.from(
              result as List,
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _loadAnalytics() async {
    final analytics = await ProviderSubscriptionService.instance.getAnalytics();
    if (mounted) setState(() => _analytics = analytics);
  }

  Future<void> _loadConfig() async {
    final config = await ProviderSubscriptionService.instance.getConfig();
    if (mounted) setState(() => _config = config);
  }

  List<Map<String, dynamic>> get _filteredSubs {
    if (_subFilter == 'all') return _subscriptions;
    if (_subFilter == 'trial') {
      return _subscriptions
          .where((s) => s['is_trial'] == true && s['status'] == 'active')
          .toList();
    }
    return _subscriptions.where((s) => s['status'] == _subFilter).toList();
  }

  // ─── PLAN CRUD ────────────────────────────────────────────────────────────

  Future<void> _showAddEditPlanDialog([Map<String, dynamic>? existing]) async {
    final nameCtrl = TextEditingController(
      text: existing?['name'] as String? ?? '',
    );
    final nameMrCtrl = TextEditingController(
      text: existing?['name_mr'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    final daysCtrl = TextEditingController(
      text: existing?['duration_days']?.toString() ?? '30',
    );
    final descCtrl = TextEditingController(
      text: existing?['description'] as String? ?? '',
    );
    final discountCtrl = TextEditingController(
      text: existing?['discount_pct']?.toString() ?? '0',
    );
    final featuresCtrl = TextEditingController(
      text: existing?['features'] is List
          ? (existing!['features'] as List).join('\n')
          : '',
    );
    String billingCycle = existing?['billing_cycle'] as String? ?? 'monthly';
    bool isActive = existing?['is_active'] as bool? ?? true;
    bool isTrial = existing?['is_trial'] as bool? ?? false;

    final isEdit = existing != null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Plan' : 'Add New Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                _dialogField('Plan Name (EN)', nameCtrl),
                SizedBox(height: 1.h),
                _dialogField('Plan Name (MR)', nameMrCtrl),
                SizedBox(height: 1.h),
                _dialogField(
                  'Price (₹)',
                  priceCtrl,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 1.h),
                _dialogField(
                  'Duration (days)',
                  daysCtrl,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 1.h),
                _dialogField('Description', descCtrl),
                SizedBox(height: 1.h),
                _dialogField(
                  'Discount %',
                  discountCtrl,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 1.h),
                _dialogField(
                  'Features (one per line)',
                  featuresCtrl,
                  maxLines: 4,
                ),
                SizedBox(height: 1.h),
                // Billing cycle
                DropdownButtonFormField<String>(
                  initialValue: billingCycle,
                  decoration: InputDecoration(
                    labelText: 'Billing Cycle',
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                    filled: true,
                    fillColor: AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['monthly', 'quarterly', 'yearly', 'one_time']
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => billingCycle = v ?? 'monthly'),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          'Active',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                        ),
                        value: isActive,
                        onChanged: (v) => setDialogState(() => isActive = v),
                        activeThumbColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          'Trial',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
                        ),
                        value: isTrial,
                        onChanged: (v) => setDialogState(() => isTrial = v),
                        activeThumbColor: AppTheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final price =
                              double.tryParse(priceCtrl.text.trim()) ?? 0;
                          final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
                          if (name.isEmpty) return;

                          final featuresRaw = featuresCtrl.text.trim();
                          final featuresList = featuresRaw.isEmpty
                              ? <String>[]
                              : featuresRaw
                                    .split('\n')
                                    .map((f) => f.trim())
                                    .where((f) => f.isNotEmpty)
                                    .toList();

                          final data = {
                            'name': name,
                            'name_mr': nameMrCtrl.text.trim().isEmpty
                                ? name
                                : nameMrCtrl.text.trim(),
                            'price': price,
                            'duration_days': days,
                            'description': descCtrl.text.trim(),
                            'discount_pct':
                                double.tryParse(discountCtrl.text.trim()) ?? 0,
                            'billing_cycle': billingCycle,
                            'features': featuresList,
                            'is_active': isActive,
                            'is_trial': isTrial,
                            'updated_at': DateTime.now().toIso8601String(),
                          };

                          try {
                            if (isEdit) {
                              await SupabaseService.instance.client
                                  .from('subscription_plans')
                                  .update(data)
                                  .eq('id', existing['id'] as String);
                            } else {
                              await SupabaseService.instance.client
                                  .from('subscription_plans')
                                  .insert(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadPlans();
                            _showSnack(
                              isEdit ? 'Plan updated!' : 'Plan created!',
                              success: true,
                            );
                          } catch (e) {
                            _showSnack('Failed: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Update' : 'Create',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 12.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
      ),
    );
  }

  Future<void> _deletePlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Plan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure? This will deactivate the plan.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.instance.client
          .from('subscription_plans')
          .update({'is_active': false})
          .eq('id', planId);
      _loadPlans();
      _showSnack('Plan deactivated.', success: true);
    } catch (e) {
      _showSnack('Failed: $e');
    }
  }

  // ─── CONFIG MANAGEMENT ────────────────────────────────────────────────────

  Future<void> _showConfigDialog() async {
    final trialCtrl = TextEditingController(
      text: _config['trial_days'] ?? '30',
    );
    final graceCtrl = TextEditingController(
      text: _config['grace_period_days'] ?? '7',
    );
    final reminderCtrl = TextEditingController(
      text: _config['reminder_days'] ?? '7,3,1',
    );

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              _dialogField(
                'Trial Duration (days)',
                trialCtrl,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 1.h),
              _dialogField(
                'Grace Period (days)',
                graceCtrl,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 1.h),
              _dialogField(
                'Reminder Days (comma-separated, e.g. 7,3,1)',
                reminderCtrl,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final updates = [
                            {
                              'key': 'trial_days',
                              'value': trialCtrl.text.trim(),
                            },
                            {
                              'key': 'grace_period_days',
                              'value': graceCtrl.text.trim(),
                            },
                            {
                              'key': 'reminder_days',
                              'value': reminderCtrl.text.trim(),
                            },
                          ];
                          for (final u in updates) {
                            await SupabaseService.instance.client
                                .from('subscription_config')
                                .upsert(u, onConflict: 'key');
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadConfig();
                          _showSnack('Settings saved!', success: true);
                        } catch (e) {
                          _showSnack('Failed: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ADMIN ACTIONS ────────────────────────────────────────────────────────

  Future<void> _adminToggleSubscription(Map<String, dynamic> sub) async {
    final subId = sub['id'] as String;
    final status = sub['status'] as String? ?? '';
    final isActive = status == 'active';

    if (isActive) {
      final success = await ProviderSubscriptionService.instance
          .adminDeactivateSubscription(subId);
      _showSnack(
        success ? 'Subscription deactivated.' : 'Failed.',
        success: success,
      );
    } else {
      // Activate with current plan for 30 days
      final planId =
          sub['plan_id'] as String? ??
          (sub['subscription_plans'] as Map?)?['id'] as String?;
      if (planId == null) {
        _showSnack('Plan not found.');
        return;
      }
      final providerId =
          sub['provider_id'] as String? ??
          (sub['service_providers'] as Map?)?['id'] as String?;
      if (providerId == null) {
        _showSnack('Provider not found.');
        return;
      }
      final success = await ProviderSubscriptionService.instance
          .adminActivateSubscription(
            providerId: providerId,
            planId: planId,
            durationDays: 30,
          );
      _showSnack(
        success ? 'Subscription activated!' : 'Failed.',
        success: success,
      );
    }
    _loadSubscriptions();
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
        title: Text(
          'Subscription Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: _showConfigDialog,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddEditPlanDialog(),
            tooltip: 'Add Plan',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Plans'),
            Tab(text: 'Subscribers'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  SizedBox(height: 1.5.h),
                  Text(
                    'Failed to load data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.h),
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
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildPlansTab(),
                _buildSubscribersTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  // ─── ANALYTICS TAB ───────────────────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    final totalProviders = _analytics['total_providers'] ?? 0;
    final trialProviders = _analytics['trial_providers'] ?? 0;
    final activeProviders = _analytics['active_providers'] ?? 0;
    final expiredProviders = _analytics['expired_providers'] ?? 0;
    final totalRevenue = (_analytics['total_revenue'] as num?)?.toDouble() ?? 0;
    final monthlyRevenue =
        (_analytics['monthly_revenue'] as num?)?.toDouble() ?? 0;
    final renewalRate = _analytics['renewal_rate'] ?? '0';
    final churnRate = _analytics['churn_rate'] ?? '0';
    final planBreakdown =
        _analytics['plan_breakdown'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue cards
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Total Revenue',
                  '₹${totalRevenue.toStringAsFixed(0)}',
                  Icons.currency_rupee_rounded,
                  AppTheme.success,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _kpiCard(
                  'This Month',
                  '₹${monthlyRevenue.toStringAsFixed(0)}',
                  Icons.calendar_month_rounded,
                  AppTheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Active Paid',
                  '$activeProviders',
                  Icons.check_circle_rounded,
                  AppTheme.success,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _kpiCard(
                  'Trial Users',
                  '$trialProviders',
                  Icons.card_giftcard_rounded,
                  const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  'Expired',
                  '$expiredProviders',
                  Icons.cancel_rounded,
                  AppTheme.error,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _kpiCard(
                  'Total Providers',
                  '$totalProviders',
                  Icons.people_rounded,
                  const Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Rates
          Row(
            children: [
              Expanded(
                child: _rateCard(
                  'Renewal Rate',
                  '$renewalRate%',
                  Icons.trending_up_rounded,
                  AppTheme.success,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _rateCard(
                  'Churn Rate',
                  '$churnRate%',
                  Icons.trending_down_rounded,
                  AppTheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Plan breakdown
          if (planBreakdown.isNotEmpty) ...[
            Text(
              'Plan Distribution',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 1.5.h),
            ...planBreakdown.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final planName = entry.value.key;
              final count = entry.value.value as int;
              final total = planBreakdown.values.fold<int>(
                0,
                (s, v) => s + (v as int),
              );
              final pct = total > 0 ? count / total : 0.0;
              final color = _planColors[idx % _planColors.length];
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            planName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '$count subscribers',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppTheme.surfaceVariant,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}% of total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.sp,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
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
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: AppTheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PLANS TAB ────────────────────────────────────────────────────────────

  Widget _buildPlansTab() {
    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppTheme.outline,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'No plans found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: AppTheme.outline,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () => _showAddEditPlanDialog(),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add Plan', style: GoogleFonts.plusJakartaSans()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _plans.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (_, i) => _buildPlanCard(_plans[i], i),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final color = _planColors[index % _planColors.length];
    final name = plan['name'] as String? ?? 'Plan';
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final days = plan['duration_days'] as int? ?? 30;
    final isActive = plan['is_active'] as bool? ?? true;
    final isTrial = plan['is_trial'] as bool? ?? false;
    final billingCycle = plan['billing_cycle'] as String? ?? 'monthly';
    final discount = (plan['discount_pct'] as num?)?.toDouble() ?? 0;
    final features = plan['features'];
    List<String> featureList = [];
    if (features is List) {
      featureList = features.map((f) => f.toString()).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : AppTheme.outline,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isTrial) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TRIAL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          if (!isActive) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INACTIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '$days days • $billingCycle${discount > 0 ? ' • ${discount.toStringAsFixed(0)}% off' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price == 0 ? 'Free' : '₹${price.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: [
                if (featureList.isNotEmpty)
                  ...featureList
                      .take(3)
                      .map(
                        (f) => Padding(
                          padding: EdgeInsets.only(bottom: 0.4.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: color,
                                size: 12,
                              ),
                              SizedBox(width: 1.5.w),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    color: const Color(0xFF44474E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEditPlanDialog(plan),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deletePlan(plan['id'] as String),
                        icon: const Icon(Icons.delete_rounded, size: 14),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
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
        ],
      ),
    );
  }

  // ─── SUBSCRIBERS TAB ─────────────────────────────────────────────────────

  Widget _buildSubscribersTab() {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              for (final filter in [
                'all',
                'active',
                'trial',
                'expired',
                'cancelled',
              ])
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(
                      filter == 'all'
                          ? 'All (${_subscriptions.length})'
                          : filter == 'trial'
                          ? 'Trial (${_subscriptions.where((s) => s['is_trial'] == true && s['status'] == 'active').length})'
                          : '${filter[0].toUpperCase()}${filter.substring(1)} (${_subscriptions.where((s) => s['status'] == filter).length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _subFilter == filter,
                    onSelected: (v) => setState(() => _subFilter = filter),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: _subFilter == filter
                          ? AppTheme.primary
                          : const Color(0xFF44474E),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _filteredSubs.isEmpty
              ? Center(
                  child: Text(
                    'No subscriptions found.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: AppTheme.outline,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredSubs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (_, i) => _buildSubscriberCard(_filteredSubs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriberCard(Map<String, dynamic> sub) {
    final provider = sub['service_providers'] as Map<String, dynamic>?;
    final plan = sub['subscription_plans'] as Map<String, dynamic>?;
    final businessName = provider?['business_name'] as String? ?? 'Provider';
    final planName = plan?['name'] as String? ?? 'Plan';
    final status = sub['status'] as String? ?? 'unknown';
    final isTrial = sub['is_trial'] as bool? ?? false;
    final autoRenew = sub['auto_renew'] as bool? ?? false;
    final endDateStr =
        sub['end_date'] as String? ?? sub['expires_at'] as String?;
    final paymentRef = sub['payment_ref'] as String? ?? '';
    final razorpayId = sub['razorpay_payment_id'] as String? ?? '';

    DateTime? endDate = endDateStr != null
        ? DateTime.tryParse(endDateStr)
        : null;
    final daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays
        : 0;

    final statusColor = status == 'active'
        ? AppTheme.success
        : status == 'expired'
        ? AppTheme.error
        : AppTheme.outline;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    businessName.isNotEmpty
                        ? businessName[0].toUpperCase()
                        : 'P',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
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
                      businessName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          planName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isTrial) ...[
                          Text(
                            ' • ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              color: AppTheme.outline,
                            ),
                          ),
                          Text(
                            'Trial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.sp,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _subInfoChip(
                  Icons.timer_rounded,
                  status == 'active'
                      ? '$daysLeft days left'
                      : endDate != null
                      ? 'Expired ${endDate.day}/${endDate.month}/${endDate.year}'
                      : 'No date',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _subInfoChip(
                  Icons.autorenew_rounded,
                  autoRenew ? 'Auto-renew ON' : 'Manual renew',
                ),
              ),
            ],
          ),
          if (razorpayId.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Razorpay: ${razorpayId.length > 20 ? '${razorpayId.substring(0, 20)}...' : razorpayId}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: AppTheme.outline,
              ),
            ),
          ],
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _adminToggleSubscription(sub),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: status == 'active'
                        ? AppTheme.error
                        : AppTheme.success,
                    side: BorderSide(
                      color: status == 'active'
                          ? AppTheme.error
                          : AppTheme.success,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    status == 'active' ? 'Deactivate' : 'Activate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.outline),
          SizedBox(width: 1.w),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: AppTheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SETTINGS TAB ────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Configuration',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          SizedBox(height: 2.h),
          _configTile(
            'Free Trial Duration',
            '${_config['trial_days'] ?? '30'} days',
            Icons.card_giftcard_rounded,
            const Color(0xFF1565C0),
          ),
          _configTile(
            'Grace Period',
            '${_config['grace_period_days'] ?? '7'} days',
            Icons.hourglass_bottom_rounded,
            const Color(0xFFE65100),
          ),
          _configTile(
            'Reminder Days',
            _config['reminder_days'] ?? '7,3,1',
            Icons.notifications_rounded,
            const Color(0xFF6A1B9A),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showConfigDialog,
              icon: const Icon(Icons.settings_rounded),
              label: Text(
                'Edit Settings',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
          SizedBox(height: 2.h),
          Text(
            'Payment Security',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          SizedBox(height: 1.5.h),
          _securityTile(
            '✅ Server-side signature verification',
            'All Razorpay payments verified via HMAC-SHA256 on Edge Function',
          ),
          _securityTile(
            '✅ Client-side trust prevention',
            'Payment status never trusted from client — only webhook/server sets success',
          ),
          _securityTile(
            '✅ RLS policies active',
            'Supabase Row Level Security protects all subscription tables',
          ),
          _securityTile(
            '✅ Payment audit log',
            'All payment events recorded in subscription_payment_audit table',
          ),
          _securityTile(
            '✅ Razorpay secret server-only',
            'RAZORPAY_KEY_SECRET stored only in Edge Function environment',
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _configTile(String label, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityTile(String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B5E20),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
