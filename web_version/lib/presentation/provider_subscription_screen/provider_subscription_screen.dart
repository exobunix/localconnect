import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/razorpay_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/razorpay_payment_widget.dart';

class ProviderSubscriptionScreen extends StatefulWidget {
  const ProviderSubscriptionScreen({super.key});

  @override
  State<ProviderSubscriptionScreen> createState() =>
      _ProviderSubscriptionScreenState();
}

class _ProviderSubscriptionScreenState extends State<ProviderSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _billingHistory = [];
  Map<String, dynamic>? _providerProfile;

  bool _autoRenew = true;
  bool _updatingAutoRenew = false;
  bool _isRenewing = false;

  // Payout state
  List<Map<String, dynamic>> _payoutHistory = [];
  double _availableBalance = 0;
  final _upiCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _requestingPayout = false;

  bool _isMr = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiCtrl.dispose();
    _amountCtrl.dispose();
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
          _error = _t(
            'Provider profile not found.',
            'प्रदाता प्रोफाइल सापडली नाही.',
          );
          _isLoading = false;
        });
        return;
      }
      _providerProfile = provider;
      final providerId = provider['id'] as String;
      final client = SupabaseService.instance.client;

      // Load plans
      final plansRes = await client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price');

      // Load active subscription
      final subRes = await client
          .from('provider_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('provider_id', providerId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      // Load billing history
      List billingRes = [];
      try {
        billingRes = await client
            .from('subscription_billing_history')
            .select('*, subscription_plans(name, name_mr, price)')
            .eq('provider_id', providerId)
            .order('billed_at', ascending: false)
            .limit(20);
      } catch (_) {}

      // Load payout history
      final payoutRes = await client
          .from('payout_requests')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(20);

      // Calculate available balance
      final ordersRes = await client
          .from('orders')
          .select('amount')
          .eq('provider_id', providerId)
          .eq('status', 'completed');

      double totalEarned = 0;
      for (final o in (ordersRes as List)) {
        final amt = o['amount'] as String? ?? '0';
        totalEarned +=
            double.tryParse(amt.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
      double totalPaidOut = 0;
      for (final p in (payoutRes as List)) {
        if ((p['status'] as String?) == 'completed') {
          totalPaidOut += (p['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      final activeSub = (subRes as List).isNotEmpty
          ? Map<String, dynamic>.from(subRes.first as Map)
          : null;

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(plansRes as List);
          _activeSub = activeSub;
          _autoRenew = (activeSub?['auto_renew'] as bool?) ?? true;
          _billingHistory = List<Map<String, dynamic>>.from(billingRes);
          _payoutHistory = List<Map<String, dynamic>>.from(payoutRes);
          _availableBalance = totalEarned - totalPaidOut;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _t(
            'Failed to load data. Please try again.',
            'डेटा लोड करण्यात अयशस्वी. पुन्हा प्रयत्न करा.',
          );
          _isLoading = false;
        });
      }
    }
  }

  String _t(String en, String mr) => _isMr ? mr : en;

  // ─── AUTO-RENEW TOGGLE ────────────────────────────────────────────────────

  Future<void> _toggleAutoRenew(bool value) async {
    final subId = _activeSub?['id'] as String?;
    if (subId == null) return;
    setState(() => _updatingAutoRenew = true);
    try {
      await SupabaseService.instance.client
          .from('provider_subscriptions')
          .update({'auto_renew': value})
          .eq('id', subId);
      if (mounted) {
        setState(() => _autoRenew = value);
        _showSnack(
          value
              ? _t('Auto-renew enabled', 'स्वयं-नूतनीकरण सक्षम')
              : _t('Auto-renew disabled', 'स्वयं-नूतनीकरण अक्षम'),
          success: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack(_t('Update failed. Try again.', 'अद्यतन अयशस्वी.'));
      }
    } finally {
      if (mounted) setState(() => _updatingAutoRenew = false);
    }
  }

  // ─── ONE-TAP RENEWAL ──────────────────────────────────────────────────────

  Future<void> _renewSubscription() async {
    final providerId = _providerProfile?['id'] as String?;
    if (providerId == null || _activeSub == null) return;

    final plan = _activeSub!['subscription_plans'] as Map<String, dynamic>?;
    if (plan == null) return;

    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final planName = _isMr
        ? (plan['name_mr'] as String? ?? '')
        : (plan['name'] as String? ?? '');
    final durationDays = (plan['duration_days'] as int?) ?? 30;

    // Payment confirmation dialog
    final confirmed = await _showPaymentConfirmationDialog(
      planName: planName,
      price: price,
      durationDays: durationDays,
    );
    if (confirmed != true) return;

    setState(() => _isRenewing = true);
    try {
      // For paid plans, open Razorpay first
      if (price > 0) {
        if (kIsWeb) {
          RazorpayService.showWebNotSupportedDialog(context);
          setState(() => _isRenewing = false);
          return;
        }
        // Show Razorpay sheet
        _openRazorpayForSubscription(
          plan: plan,
          planName: planName,
          price: price,
          durationDays: durationDays,
          providerId: providerId,
          isRenewal: true,
        );
        setState(() => _isRenewing = false);
        return;
      }

      // Free plan — activate directly
      await _activateSubscription(
        plan: plan,
        planName: planName,
        price: 0,
        durationDays: durationDays,
        providerId: providerId,
        paymentRef: 'FREE',
        isRenewal: true,
      );
    } catch (e) {
      if (mounted) {
        _showSnack(_t('Renewal failed. Try again.', 'नूतनीकरण अयशस्वी.'));
      }
    } finally {
      if (mounted) setState(() => _isRenewing = false);
    }
  }

  void _openRazorpayForSubscription({
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E8EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRenewal
                  ? _t('Renew Subscription', 'सदस्यता नूतनीकृत करा')
                  : _t('Subscribe to Plan', 'प्लान सदस्यता घ्या'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$planName — ₹${price.toStringAsFixed(0)} / $durationDays days',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 20),
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
                final paymentRef =
                    'RZP_${DateTime.now().millisecondsSinceEpoch}';
                await _activateSubscription(
                  plan: plan,
                  planName: planName,
                  price: price,
                  durationDays: durationDays,
                  providerId: providerId,
                  paymentRef: paymentRef,
                  isRenewal: isRenewal,
                );
                // Navigate to confirmation
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.razorpayPaymentConfirmationScreen,
                    arguments: {
                      'isSuccess': true,
                      'amount': price,
                      'description': 'LocalConnect $planName Subscription',
                      'paymentType': 'subscription',
                    },
                  );
                }
              },
              onPaymentFailed: (error) {
                Navigator.pop(ctx);
                _showSnack(
                  _t('Payment failed: $error', 'पेमेंट अयशस्वी: $error'),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: Color(0xFF74777F),
                ),
                const SizedBox(width: 4),
                Text(
                  'Secured by Razorpay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
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

  Future<void> _activateSubscription({
    required Map<String, dynamic> plan,
    required String planName,
    required double price,
    required int durationDays,
    required String providerId,
    required String paymentRef,
    required bool isRenewal,
  }) async {
    final client = SupabaseService.instance.client;
    final now = DateTime.now();
    final expires = now.add(Duration(days: durationDays));

    if (isRenewal && _activeSub != null) {
      // Cancel current active sub
      await client
          .from('provider_subscriptions')
          .update({'status': 'expired'})
          .eq('id', _activeSub!['id'] as String);
    } else {
      // Cancel any existing active subs
      await client
          .from('provider_subscriptions')
          .update({'status': 'cancelled'})
          .eq('provider_id', providerId)
          .eq('status', 'active');
    }

    final insertData = {
      'provider_id': providerId,
      'plan_id': plan['id'],
      'status': 'active',
      'started_at': now.toIso8601String(),
      'expires_at': expires.toIso8601String(),
      'auto_renew': _autoRenew,
      'payment_ref': paymentRef,
      if (isRenewal && _activeSub != null) 'renewed_from': _activeSub!['id'],
    };

    final newSub = await client
        .from('provider_subscriptions')
        .insert(insertData)
        .select()
        .single();

    if (price > 0) {
      try {
        await client.from('subscription_billing_history').insert({
          'provider_id': providerId,
          'plan_id': plan['id'],
          'subscription_id': newSub['id'],
          'amount': price,
          'payment_ref': paymentRef,
          'payment_method': 'Razorpay',
          'status': 'paid',
          'description':
              '${isRenewal ? 'Renewal' : 'New subscription'} — $planName plan',
        });
      } catch (_) {}
    }

    if (mounted) {
      _showSnack(
        isRenewal
            ? _t('Plan renewed successfully!', 'प्लान यशस्वीरित्या नूतनीकृत!')
            : _t(
                'Subscribed to $planName!',
                '$planName प्लानची सदस्यता घेतली!',
              ),
        success: true,
      );
      _loadData();
    }
  }

  // ─── PAYMENT CONFIRMATION DIALOG ─────────────────────────────────────────

  Future<bool?> _showPaymentConfirmationDialog({
    required String planName,
    required double price,
    required int durationDays,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('Confirm Renewal', 'नूतनीकरण पुष्टੀ करा'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Renew your $planName plan for another $durationDays days.',
                  '$planName प्लान आणखी $durationDays दिवसांसाठी नूतनीकृत करा.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF74777F),
                ),
              ),
              const SizedBox(height: 20),
              // Payment summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _paymentRow(_t('Plan', 'प्लान'), planName),
                    const SizedBox(height: 8),
                    _paymentRow(
                      _t('Duration', 'कालावधी'),
                      _t('$durationDays days', '$durationDays दिवस'),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _paymentRow(
                      _t('Amount', 'रक्कम'),
                      price == 0
                          ? _t('Free', 'मोफत')
                          : '₹${price.toStringAsFixed(0)}',
                      highlight: true,
                    ),
                    if (price > 0) ...[
                      const SizedBox(height: 8),
                      _paymentRow(_t('Payment via', 'भरणा'), 'UPI'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppTheme.outline),
                      ),
                      child: Text(
                        _t('Cancel', 'रद्द करा'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        price == 0
                            ? _t('Activate', 'सक्रिय करा')
                            : _t('Pay & Renew', 'भरा आणि नूतनीकृत करा'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
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

  Widget _paymentRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF74777F),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: highlight ? 16 : 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.primary : const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  // ─── SUBSCRIBE TO NEW PLAN ────────────────────────────────────────────────

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    final providerId = _providerProfile?['id'] as String?;
    if (providerId == null) return;

    final planName = _isMr
        ? (plan['name_mr'] as String? ?? '')
        : (plan['name'] as String? ?? '');
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final durationDays = (plan['duration_days'] as int?) ?? 30;

    // For paid plans, use Razorpay
    if (price > 0) {
      if (kIsWeb) {
        RazorpayService.showWebNotSupportedDialog(context);
        return;
      }
      _openRazorpayForSubscription(
        plan: plan,
        planName: planName,
        price: price,
        durationDays: durationDays,
        providerId: providerId,
        isRenewal: false,
      );
      return;
    }

    // Free plan — show confirmation dialog and activate
    final confirmed = await _showPaymentConfirmationDialog(
      planName: planName,
      price: price,
      durationDays: durationDays,
    );
    if (confirmed != true) return;

    try {
      await _activateSubscription(
        plan: plan,
        planName: planName,
        price: 0,
        durationDays: durationDays,
        providerId: providerId,
        paymentRef: 'FREE',
        isRenewal: false,
      );
    } catch (e) {
      if (mounted) {
        _showSnack(_t('Subscription failed.', 'सदस्यता अयशस्वी.'));
      }
    }
  }

  // ─── PAYOUT ───────────────────────────────────────────────────────────────

  Future<void> _requestPayout() async {
    final providerId = _providerProfile?['id'] as String?;
    if (providerId == null) return;

    final upiId = _upiCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (upiId.isEmpty) {
      _showSnack(_t('Enter your UPI ID.', 'तुमचा UPI ID टाका.'));
      return;
    }
    if (amount <= 0) {
      _showSnack(_t('Enter a valid amount.', 'वैध रक्कम टाका.'));
      return;
    }
    if (amount > _availableBalance) {
      _showSnack(
        _t(
          'Amount exceeds available balance.',
          'रक्कम उपलब्ध शिल्लकपेक्षा जास्त आहे.',
        ),
      );
      return;
    }

    setState(() => _requestingPayout = true);
    try {
      await SupabaseService.instance.client.from('payout_requests').insert({
        'provider_id': providerId,
        'amount': amount,
        'upi_id': upiId,
        'status': 'pending',
      });

      if (mounted) {
        _upiCtrl.clear();
        _amountCtrl.clear();
        _showSnack(
          _t('Payout request submitted!', 'पेआउट विनंती सादर केली!'),
          success: true,
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          _t(
            'Request failed. Try again.',
            'विनंती अयशस्वी. पुन्हा प्रयत्न करा.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingPayout = false);
    }
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
          _t('Subscription & Payouts', 'सदस्यता आणि पेआउट'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isMr = !_isMr),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isMr ? 'EN' : 'मर',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: _t('My Plan', 'माझा प्लान')),
            Tab(text: _t('Plans', 'प्लान्स')),
            Tab(text: _t('Payouts', 'पेआउट')),
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
                _buildPayoutsTab(),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF44474E),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(_t('Retry', 'पुन्हा प्रयत्न करा')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
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

  // ─── MY PLAN TAB ──────────────────────────────────────────────────────────

  Widget _buildMyPlanTab() {
    if (_activeSub == null) {
      return _buildNoPlanState();
    }

    final plan = _activeSub!['subscription_plans'] as Map<String, dynamic>?;
    final planName = _isMr
        ? (plan?['name_mr'] as String? ?? 'Basic')
        : (plan?['name'] as String? ?? 'Basic');
    final price = (plan?['price'] as num?)?.toDouble() ?? 0;
    final expiresAt = _activeSub!['expires_at'] as String?;
    final startedAt = _activeSub!['started_at'] as String?;
    DateTime? expiry = expiresAt != null ? DateTime.tryParse(expiresAt) : null;
    DateTime? started = startedAt != null ? DateTime.tryParse(startedAt) : null;

    final daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays
        : 0;
    final isExpiringSoon = daysLeft <= 7 && daysLeft >= 0;
    final isExpired = daysLeft < 0;
    final isPro = plan?['name'] == 'Pro';
    final isPremium = plan?['name'] == 'Premium';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Current Plan Hero Card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isPremium
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
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPremium
                              ? Icons.workspace_premium_rounded
                              : isPro
                              ? Icons.star_rounded
                              : Icons.person_outline_rounded,
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
                              _t('Current Plan', 'सध्याचा प्लान'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              planName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpired
                              ? _t('Expired', 'समाप्त')
                              : _t('Active', 'सक्रिय'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _planStatItem(
                          _t('Price', 'किंमत'),
                          price == 0
                              ? _t('Free', 'मोफत')
                              : '₹${price.toStringAsFixed(0)}/mo',
                          Icons.currency_rupee_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _planStatItem(
                          _t('Renewal Date', 'नूतनीकरण तारीख'),
                          expiry != null
                              ? '${expiry.day}/${expiry.month}/${expiry.year}'
                              : '—',
                          Icons.event_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _planStatItem(
                          _t('Days Left', 'उरलेले दिवस'),
                          isExpired ? _t('Expired', 'समाप्त') : '$daysLeft',
                          Icons.timer_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (started != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        'Started: ${started.day}/${started.month}/${started.year}',
                        'सुरुवात: ${started.day}/${started.month}/${started.year}',
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Expiry Warning ──────────────────────────────────────────
            if (isExpiringSoon || isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isExpired
                      ? AppTheme.errorContainer
                      : AppTheme.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired
                          ? Icons.error_rounded
                          : Icons.warning_amber_rounded,
                      color: isExpired ? AppTheme.error : AppTheme.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired
                            ? _t(
                                'Your plan has expired. Renew to continue receiving bookings.',
                                'तुमचा प्लान संपला आहे. बुकिंग सुरू ठेवण्यासाठी नूतनीकृत करा.',
                              )
                            : _t(
                                'Plan expires in $daysLeft days. Renew now to avoid interruption.',
                                'प्लान $daysLeft दिवसांत संपेल. व्यत्यय टाळण्यासाठी आता नूतनीकृत करा.',
                              ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isExpired ? AppTheme.error : AppTheme.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Auto-Renew Toggle ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.autorenew_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Auto-Renew', 'स्वयं-नूतनीकरण'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          _autoRenew
                              ? _t(
                                  'Plan renews automatically on expiry',
                                  'प्लान समाप्तीवर स्वयंचलितपणे नूतनीकृत होतो',
                                )
                              : _t(
                                  'Manual renewal required',
                                  'मॅन्युअल नूतनीकरण आवश्यक',
                                ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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
                          onChanged: _toggleAutoRenew,
                          activeColor: AppTheme.primary,
                        ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── One-Tap Renewal Button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRenewing ? null : _renewSubscription,
                icon: _isRenewing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  _isRenewing
                      ? _t('Processing...', 'प्रक्रिया होत आहे...')
                      : price == 0
                      ? _t('Renew Free Plan', 'मोफत प्लान नूतनीकृत करा')
                      : _t(
                          'Renew Now — ₹${price.toStringAsFixed(0)}',
                          'आता नूतनीकृत करा — ₹${price.toStringAsFixed(0)}',
                        ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Billing History ─────────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _t('Billing History', 'बिलिंग इतिहास'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_billingHistory.isEmpty)
              _buildEmptyBillingHistory()
            else
              ..._billingHistory.map((b) => _buildBillingItem(b)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _planStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white60,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildBillingItem(Map<String, dynamic> billing) {
    final plan = billing['subscription_plans'] as Map<String, dynamic>?;
    final planName = _isMr
        ? (plan?['name_mr'] as String? ?? '')
        : (plan?['name'] as String? ?? '');
    final amount = (billing['amount'] as num?)?.toDouble() ?? 0;
    final status = billing['status'] as String? ?? 'paid';
    final description = billing['description'] as String? ?? '';
    final paymentRef = billing['payment_ref'] as String? ?? '';
    final billedAt = billing['billed_at'] as String?;
    DateTime? dt = billedAt != null ? DateTime.tryParse(billedAt) : null;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = AppTheme.success;
        statusLabel = _t('Paid', 'भरले');
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusLabel = _t('Pending', 'प्रलंबित');
        statusIcon = Icons.schedule_rounded;
        break;
      case 'failed':
        statusColor = AppTheme.error;
        statusLabel = _t('Failed', 'अयशस्वी');
        statusIcon = Icons.cancel_rounded;
        break;
      case 'refunded':
        statusColor = AppTheme.info;
        statusLabel = _t('Refunded', 'परत केले');
        statusIcon = Icons.undo_rounded;
        break;
      default:
        statusColor = AppTheme.success;
        statusLabel = _t('Paid', 'भरले');
        statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : planName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (paymentRef.isNotEmpty && paymentRef != 'FREE')
                  Text(
                    'Ref: $paymentRef',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF90A4AE),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (dt != null)
                  Text(
                    '${dt.day}/${dt.month}/${dt.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF90A4AE),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount == 0
                    ? _t('Free', 'मोफत')
                    : '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBillingHistory() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 44, color: AppTheme.outline),
          const SizedBox(height: 10),
          Text(
            _t('No billing records yet', 'अद्याप कोणतेही बिलिंग रेकॉर्ड नाही'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Your payment history will appear here.',
              'तुमचा पेमेंट इतिहास येथे दिसेल.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.subscriptions_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('No Active Plan', 'कोणताही सक्रिय प्लान नाही'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Subscribe to a plan to start receiving bookings and grow your business.',
                'बुकिंग मिळवण्यासाठी आणि व्यवसाय वाढवण्यासाठी प्लान सदस्यता घ्या.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: Text(
                _t('View Plans', 'प्लान पहा'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeSub != null) _buildActiveSubBanner(),
          const SizedBox(height: 16),
          Text(
            _t('Choose Your Plan', 'तुमचा प्लान निवडा'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Upgrade to get more bookings and visibility.',
              'अधिक बुकिंग आणि दृश्यमानतेसाठी अपग्रेड करा.',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 16),
          ..._plans.map((plan) => _buildPlanCard(plan)),
        ],
      ),
    );
  }

  Widget _buildActiveSubBanner() {
    final plan = _activeSub?['subscription_plans'] as Map<String, dynamic>?;
    final planName = _isMr
        ? (plan?['name_mr'] as String? ?? '')
        : (plan?['name'] as String? ?? '');
    final expiresAt = _activeSub?['expires_at'] as String?;
    DateTime? expiry;
    if (expiresAt != null) expiry = DateTime.tryParse(expiresAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Active Plan: $planName', 'सक्रिय प्लान: $planName'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (expiry != null)
                  Text(
                    _t(
                      'Expires ${expiry.day}/${expiry.month}/${expiry.year}',
                      'समाप्ती ${expiry.day}/${expiry.month}/${expiry.year}',
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _t('Active', 'सक्रिय'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final planName = _isMr
        ? (plan['name_mr'] as String? ?? '')
        : (plan['name'] as String? ?? '');
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final features = (plan['features'] as List?) ?? [];
    final isCurrentPlan =
        _activeSub != null &&
        (_activeSub!['plan_id'] as String?) == (plan['id'] as String?);
    final isPro = plan['name'] == 'Pro';
    final isPremium = plan['name'] == 'Premium';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPlan
            ? Border.all(color: AppTheme.primary, width: 2)
            : isPremium
            ? Border.all(color: const Color(0xFFFFB300), width: 2)
            : Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : isPro
                  ? AppTheme.primaryGradient
                  : null,
              color: isPremium || isPro ? null : AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPremium
                      ? Icons.workspace_premium_rounded
                      : isPro
                      ? Icons.star_rounded
                      : Icons.person_outline_rounded,
                  color: isPremium || isPro
                      ? Colors.white
                      : const Color(0xFF78909C),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isPremium || isPro
                              ? Colors.white
                              : const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        price == 0
                            ? _t('Free forever', 'कायमचे मोफत')
                            : _t(
                                '₹${price.toStringAsFixed(0)}/month',
                                '₹${price.toStringAsFixed(0)}/महिना',
                              ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isPremium || isPro
                              ? Colors.white70
                              : const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _t('Current', 'सध्याचा'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPremium || isPro
                            ? Colors.white
                            : AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: isPremium
                              ? const Color(0xFFFFB300)
                              : AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF44474E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan
                        ? null
                        : () => _subscribeToPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium
                          ? const Color(0xFFFFB300)
                          : isPro
                          ? AppTheme.primary
                          : AppTheme.surfaceVariant,
                      foregroundColor: isPremium || isPro
                          ? Colors.white
                          : AppTheme.primary,
                      disabledBackgroundColor: AppTheme.successContainer,
                      disabledForegroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? _t('✓ Subscribed', '✓ सदस्य आहात')
                          : price == 0
                          ? _t('Activate Free', 'मोफत सक्रिय करा')
                          : _t(
                              'Subscribe — ₹${price.toStringAsFixed(0)}',
                              'सदस्यता घ्या — ₹${price.toStringAsFixed(0)}',
                            ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  // ─── PAYOUTS TAB ──────────────────────────────────────────────────────────

  Widget _buildPayoutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildPayoutRequestCard(),
          const SizedBox(height: 20),
          Text(
            _t('Payout History', 'पेआउट इतिहास'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (_payoutHistory.isEmpty)
            _buildEmptyPayouts()
          else
            ..._payoutHistory.map((p) => _buildPayoutItem(p)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                _t('Available Balance', 'उपलब्ध शिल्लक'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_availableBalance.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Earnings minus paid out amounts',
              'कमाई वजा पेआउट केलेली रक्कम',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutRequestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _t('Request Payout', 'पेआउट विनंती करा'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _upiCtrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              labelText: _t('Your UPI ID', 'तुमचा UPI ID'),
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              hintText: 'yourname@upi',
              prefixIcon: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              labelText: _t('Amount (₹)', 'रक्कम (₹)'),
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              hintText: '0.00',
              prefixIcon: const Icon(Icons.currency_rupee, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _requestingPayout ? null : _requestPayout,
              icon: _requestingPayout
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _t('Submit Request', 'विनंती सादर करा'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              '⏱ Payouts are processed within 2–3 business days.',
              '⏱ पेआउट 2–3 कामकाजाच्या दिवसांत प्रक्रिया केले जातात.',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(Map<String, dynamic> payout) {
    final status = payout['status'] as String? ?? 'pending';
    final amount = (payout['amount'] as num?)?.toDouble() ?? 0;
    final upiId = payout['upi_id'] as String? ?? '';
    final requestedAt = payout['requested_at'] as String?;
    DateTime? dt;
    if (requestedAt != null) dt = DateTime.tryParse(requestedAt);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'completed':
        statusColor = AppTheme.success;
        statusLabel = _t('Paid', 'भरले');
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'processing':
        statusColor = AppTheme.warning;
        statusLabel = _t('Processing', 'प्रक्रिया');
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusLabel = _t('Rejected', 'नाकारले');
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppTheme.info;
        statusLabel = _t('Pending', 'प्रलंबित');
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  upiId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF74777F),
                  ),
                ),
                if (dt != null)
                  Text(
                    '${dt.day}/${dt.month}/${dt.year}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF90A4AE),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPayouts() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppTheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            _t('No payout requests yet', 'अद्याप कोणतीही पेआउट विनंती नाही'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF74777F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Submit a request above to withdraw your earnings.',
              'तुमची कमाई काढण्यासाठी वरील विनंती सादर करा.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ],
      ),
    );
  }
}
