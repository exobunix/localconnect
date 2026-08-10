import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminCategoryMonetizationScreen extends StatefulWidget {
  const AdminCategoryMonetizationScreen({super.key});

  @override
  State<AdminCategoryMonetizationScreen> createState() =>
      _AdminCategoryMonetizationScreenState();
}

class _AdminCategoryMonetizationScreenState
    extends State<AdminCategoryMonetizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _configs = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';

  static const List<String> _categories = [
    'all',
    'home_maintenance',
    'shop',
    'rent',
    'event',
    'transport',
  ];

  static const Map<String, Color> _categoryColors = {
    'home_maintenance': Color(0xFF1565C0),
    'shop': Color(0xFF2E7D32),
    'rent': Color(0xFF6A1B9A),
    'event': Color(0xFFAD1457),
    'transport': Color(0xFFE65100),
  };

  static const Map<String, IconData> _categoryIcons = {
    'home_maintenance': Icons.home_repair_service_rounded,
    'shop': Icons.storefront_rounded,
    'rent': Icons.apartment_rounded,
    'event': Icons.celebration_rounded,
    'transport': Icons.local_shipping_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfigs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.client
          .from('category_monetization_config')
          .select()
          .order('category')
          .order('subcategory');
      if (mounted) {
        setState(() {
          _configs = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredConfigs {
    if (_selectedCategory == 'all') return _configs;
    return _configs.where((c) => c['category'] == _selectedCategory).toList();
  }

  Color _modelColor(String model) {
    switch (model) {
      case 'free':
        return const Color(0xFF2E7D32);
      case 'subscription':
        return const Color(0xFF1565C0);
      case 'pay_per_listing':
        return const Color(0xFFE65100);
      case 'pay_per_lead':
        return const Color(0xFF6A1B9A);
      case 'hybrid':
        return const Color(0xFFAD1457);
      default:
        return const Color(0xFF74777F);
    }
  }

  void _openEditDialog(Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (_) =>
          _MonetizationEditDialog(config: config, onSaved: _loadConfigs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1A1C1E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Category Monetization',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1C1E)),
            onPressed: _loadConfigs,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: const Color(0xFF74777F),
          indicatorColor: AppTheme.primary,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Pricing Rules'),
            Tab(text: 'Subscription Gates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPricingRulesTab(), _buildSubscriptionGatesTab()],
      ),
    );
  }

  Widget _buildPricingRulesTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildError()
              : _filteredConfigs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadConfigs,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    itemCount: _filteredConfigs.length,
                    itemBuilder: (_, i) =>
                        _buildConfigCard(_filteredConfigs[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final isSelected = _selectedCategory == cat;
            final color = cat == 'all'
                ? AppTheme.primary
                : (_categoryColors[cat] ?? AppTheme.primary);
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cat == 'all'
                        ? 'All'
                        : cat
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) => w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    final category = config['category'] as String? ?? '';
    final subcategory = config['subcategory'] as String? ?? '';
    final model = config['monetization_model'] as String? ?? 'subscription';
    final isActive = config['is_active'] as bool? ?? true;
    final catColor = _categoryColors[category] ?? AppTheme.primary;
    final catIcon = _categoryIcons[category] ?? Icons.category_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subcategory
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        category
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: const Color(0xFF74777F),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _modelColor(model).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    model.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                      color: _modelColor(model),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Switch(
                  value: isActive,
                  onChanged: (val) => _toggleActive(config, val),
                  activeThumbColor: AppTheme.success,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          // Pricing grid
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: [
                Row(
                  children: [
                    _PriceChip(
                      label: 'Free',
                      value:
                          '${config['free_plan_listings'] == -1 ? '∞' : config['free_plan_listings']} listings',
                      color: const Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 2.w),
                    _PriceChip(
                      label: 'Basic',
                      value:
                          '₹${config['basic_plan_price']?.toStringAsFixed(0) ?? '0'}',
                      color: const Color(0xFF1565C0),
                    ),
                    SizedBox(width: 2.w),
                    _PriceChip(
                      label: 'Standard',
                      value:
                          '₹${config['standard_plan_price']?.toStringAsFixed(0) ?? '299'}',
                      color: const Color(0xFF6A1B9A),
                    ),
                    SizedBox(width: 2.w),
                    _PriceChip(
                      label: 'Premium',
                      value:
                          '₹${config['premium_plan_price']?.toStringAsFixed(0) ?? '599'}',
                      color: const Color(0xFFAD1457),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    if (config['featured_listing_enabled'] == true)
                      _FeatureTag(
                        icon: Icons.star_rounded,
                        label:
                            'Featured ₹${config['featured_7day_price']?.toStringAsFixed(0) ?? '149'}/7d',
                        color: const Color(0xFFFF8F00),
                      ),
                    if (config['sponsored_listing_enabled'] == true) ...[
                      SizedBox(width: 1.5.w),
                      _FeatureTag(
                        icon: Icons.campaign_rounded,
                        label:
                            'Sponsored ₹${config['sponsored_listing_price']?.toStringAsFixed(0) ?? '399'}',
                        color: const Color(0xFF0277BD),
                      ),
                    ],
                    if (config['verified_badge_enabled'] == true) ...[
                      SizedBox(width: 1.5.w),
                      _FeatureTag(
                        icon: Icons.verified_rounded,
                        label:
                            'Badge ₹${config['verified_badge_price']?.toStringAsFixed(0) ?? '999'}',
                        color: const Color(0xFF00695C),
                      ),
                    ],
                  ],
                ),
                if (config['pay_per_lead_enabled'] == true ||
                    config['pay_per_listing_enabled'] == true) ...[
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      if (config['pay_per_listing_enabled'] == true)
                        _FeatureTag(
                          icon: Icons.add_box_rounded,
                          label:
                              'Per Listing ₹${config['pay_per_listing_price']?.toStringAsFixed(0) ?? '49'}',
                          color: const Color(0xFFE65100),
                        ),
                      if (config['pay_per_lead_enabled'] == true) ...[
                        SizedBox(width: 1.5.w),
                        _FeatureTag(
                          icon: Icons.person_add_rounded,
                          label:
                              'Per Lead ₹${config['pay_per_lead_price']?.toStringAsFixed(0) ?? '29'}',
                          color: const Color(0xFF6A1B9A),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Edit button
          Padding(
            padding: EdgeInsets.only(left: 3.w, right: 3.w, bottom: 2.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openEditDialog(config),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit Config'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: catColor,
                  side: BorderSide(color: catColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Map<String, dynamic> config, bool value) async {
    try {
      await SupabaseService.instance.client
          .from('category_monetization_config')
          .update({'is_active': value})
          .eq('id', config['id']);
      _loadConfigs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Widget _buildSubscriptionGatesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.security_rounded,
            title: 'Server-Side Enforcement',
            subtitle: 'DB functions that gate listing creation',
            color: AppTheme.primary,
          ),
          SizedBox(height: 2.h),
          _GateCard(
            icon: Icons.functions_rounded,
            title: 'provider_has_active_subscription()',
            description:
                'Returns TRUE if provider has a non-expired active subscription. Used as a gate before premium features.',
            color: const Color(0xFF1565C0),
            badge: 'FUNCTION',
          ),
          _GateCard(
            icon: Icons.functions_rounded,
            title: 'provider_active_plan()',
            description:
                'Returns the plan name (Free / Basic / Pro / Premium) for a provider. Used to determine listing limits.',
            color: const Color(0xFF2E7D32),
            badge: 'FUNCTION',
          ),
          _GateCard(
            icon: Icons.functions_rounded,
            title: 'provider_listing_limit()',
            description:
                'Returns the max listing count for a provider in a given category/subcategory based on their active plan.',
            color: const Color(0xFF6A1B9A),
            badge: 'FUNCTION',
          ),
          _GateCard(
            icon: Icons.functions_rounded,
            title: 'provider_can_create_listing()',
            description:
                'Returns a JSONB result with allowed: true/false, current count, limit, and upgrade reason. Call this before creating any listing.',
            color: const Color(0xFFAD1457),
            badge: 'FUNCTION',
          ),
          _GateCard(
            icon: Icons.functions_rounded,
            title: 'expire_stale_subscriptions()',
            description:
                'Bulk-expires all subscriptions past their expiry date. Run via a scheduled job or admin action.',
            color: const Color(0xFFE65100),
            badge: 'FUNCTION',
          ),
          _GateCard(
            icon: Icons.bolt_rounded,
            title: 'trg_subscription_expiry_check',
            description:
                'BEFORE UPDATE trigger on provider_subscriptions. Automatically sets status=expired when expires_at < NOW().',
            color: const Color(0xFF00695C),
            badge: 'TRIGGER',
          ),
          SizedBox(height: 2.h),
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'How to Use in Flutter',
            subtitle: 'Call these RPC functions from your Dart code',
            color: const Color(0xFF0277BD),
          ),
          SizedBox(height: 1.5.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''// Check if provider can create a listing
final result = await supabase.rpc(
  'provider_can_create_listing',
  params: {
    'p_provider_id': providerId,
    'p_category': 'home_maintenance',
    'p_subcategory': 'plumber',
  },
);
if (result['allowed'] == false) {
  showUpgradeDialog(result['reason']);
  return;
}
// Proceed with listing creation...''',
              style: GoogleFonts.sourceCodePro(
                fontSize: 9.sp,
                color: const Color(0xFF80CBC4),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _ExpireSubscriptionsButton(onExpired: _loadConfigs),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load configs',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFF74777F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadConfigs, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.price_change_rounded,
            color: const Color(0xFF74777F),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No configs found',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Dialog ───────────────────────────────────────────────────────────────
class _MonetizationEditDialog extends StatefulWidget {
  final Map<String, dynamic> config;
  final VoidCallback onSaved;

  const _MonetizationEditDialog({required this.config, required this.onSaved});

  @override
  State<_MonetizationEditDialog> createState() =>
      _MonetizationEditDialogState();
}

class _MonetizationEditDialogState extends State<_MonetizationEditDialog> {
  late String _model;
  late TextEditingController _freeListings;
  late TextEditingController _basicPrice;
  late TextEditingController _standardPrice;
  late TextEditingController _premiumPrice;
  late TextEditingController _basicListings;
  late TextEditingController _standardListings;
  late TextEditingController _premiumListings;
  late TextEditingController _pplPrice;
  late TextEditingController _pplListingPrice;
  late TextEditingController _featured7;
  late TextEditingController _featured15;
  late TextEditingController _featured30;
  late TextEditingController _sponsored;
  late TextEditingController _badge;
  late bool _pplEnabled;
  late bool _pplListingEnabled;
  late bool _featuredEnabled;
  late bool _sponsoredEnabled;
  late bool _badgeEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _model = c['monetization_model'] ?? 'subscription';
    _freeListings = TextEditingController(
      text: (c['free_plan_listings'] ?? 3).toString(),
    );
    _basicPrice = TextEditingController(
      text: (c['basic_plan_price'] ?? 0).toString(),
    );
    _standardPrice = TextEditingController(
      text: (c['standard_plan_price'] ?? 299).toString(),
    );
    _premiumPrice = TextEditingController(
      text: (c['premium_plan_price'] ?? 599).toString(),
    );
    _basicListings = TextEditingController(
      text: (c['basic_plan_listings'] ?? 10).toString(),
    );
    _standardListings = TextEditingController(
      text: (c['standard_plan_listings'] ?? 50).toString(),
    );
    _premiumListings = TextEditingController(
      text: (c['premium_plan_listings'] ?? -1).toString(),
    );
    _pplPrice = TextEditingController(
      text: (c['pay_per_lead_price'] ?? 29).toString(),
    );
    _pplListingPrice = TextEditingController(
      text: (c['pay_per_listing_price'] ?? 49).toString(),
    );
    _featured7 = TextEditingController(
      text: (c['featured_7day_price'] ?? 149).toString(),
    );
    _featured15 = TextEditingController(
      text: (c['featured_15day_price'] ?? 299).toString(),
    );
    _featured30 = TextEditingController(
      text: (c['featured_30day_price'] ?? 499).toString(),
    );
    _sponsored = TextEditingController(
      text: (c['sponsored_listing_price'] ?? 399).toString(),
    );
    _badge = TextEditingController(
      text: (c['verified_badge_price'] ?? 999).toString(),
    );
    _pplEnabled = c['pay_per_lead_enabled'] ?? false;
    _pplListingEnabled = c['pay_per_listing_enabled'] ?? false;
    _featuredEnabled = c['featured_listing_enabled'] ?? true;
    _sponsoredEnabled = c['sponsored_listing_enabled'] ?? true;
    _badgeEnabled = c['verified_badge_enabled'] ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _freeListings,
      _basicPrice,
      _standardPrice,
      _premiumPrice,
      _basicListings,
      _standardListings,
      _premiumListings,
      _pplPrice,
      _pplListingPrice,
      _featured7,
      _featured15,
      _featured30,
      _sponsored,
      _badge,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseService.instance.client
          .from('category_monetization_config')
          .update({
            'monetization_model': _model,
            'free_plan_listings': int.tryParse(_freeListings.text) ?? 3,
            'basic_plan_price': double.tryParse(_basicPrice.text) ?? 0,
            'standard_plan_price': double.tryParse(_standardPrice.text) ?? 299,
            'premium_plan_price': double.tryParse(_premiumPrice.text) ?? 599,
            'basic_plan_listings': int.tryParse(_basicListings.text) ?? 10,
            'standard_plan_listings':
                int.tryParse(_standardListings.text) ?? 50,
            'premium_plan_listings': int.tryParse(_premiumListings.text) ?? -1,
            'pay_per_lead_price': double.tryParse(_pplPrice.text) ?? 29,
            'pay_per_lead_enabled': _pplEnabled,
            'pay_per_listing_price':
                double.tryParse(_pplListingPrice.text) ?? 49,
            'pay_per_listing_enabled': _pplListingEnabled,
            'featured_7day_price': double.tryParse(_featured7.text) ?? 149,
            'featured_15day_price': double.tryParse(_featured15.text) ?? 299,
            'featured_30day_price': double.tryParse(_featured30.text) ?? 499,
            'featured_listing_enabled': _featuredEnabled,
            'sponsored_listing_price': double.tryParse(_sponsored.text) ?? 399,
            'sponsored_listing_enabled': _sponsoredEnabled,
            'verified_badge_price': double.tryParse(_badge.text) ?? 999,
            'verified_badge_enabled': _badgeEnabled,
          })
          .eq('id', widget.config['id']);

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Config updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.config['category'] as String? ?? '';
    final sub = widget.config['subcategory'] as String? ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h, maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.price_change_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((w) => w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          cat.replaceAll('_', ' '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Monetization Model'),
                    DropdownButtonFormField<String>(
                      initialValue: _model,
                      decoration: _inputDecoration('Model'),
                      items: const [
                        DropdownMenuItem(value: 'free', child: Text('Free')),
                        DropdownMenuItem(
                          value: 'subscription',
                          child: Text('Subscription'),
                        ),
                        DropdownMenuItem(
                          value: 'pay_per_listing',
                          child: Text('Pay Per Listing'),
                        ),
                        DropdownMenuItem(
                          value: 'pay_per_lead',
                          child: Text('Pay Per Lead'),
                        ),
                        DropdownMenuItem(
                          value: 'hybrid',
                          child: Text('Hybrid'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _model = v ?? 'subscription'),
                    ),
                    SizedBox(height: 2.h),
                    _label('Free Tier'),
                    _field(_freeListings, 'Free Listings (-1 = unlimited)'),
                    SizedBox(height: 2.h),
                    _label('Subscription Pricing'),
                    Row(
                      children: [
                        Expanded(child: _field(_basicPrice, 'Basic ₹')),
                        SizedBox(width: 2.w),
                        Expanded(child: _field(_standardPrice, 'Standard ₹')),
                        SizedBox(width: 2.w),
                        Expanded(child: _field(_premiumPrice, 'Premium ₹')),
                      ],
                    ),
                    SizedBox(height: 1.5.h),
                    _label('Listing Limits per Plan'),
                    Row(
                      children: [
                        Expanded(child: _field(_basicListings, 'Basic')),
                        SizedBox(width: 2.w),
                        Expanded(child: _field(_standardListings, 'Standard')),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _field(_premiumListings, 'Premium (-1=∞)'),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _label('Featured Listing Charges'),
                    _switchRow(
                      'Enable Featured',
                      _featuredEnabled,
                      (v) => setState(() => _featuredEnabled = v),
                    ),
                    if (_featuredEnabled) ...[
                      Row(
                        children: [
                          Expanded(child: _field(_featured7, '7-day ₹')),
                          SizedBox(width: 2.w),
                          Expanded(child: _field(_featured15, '15-day ₹')),
                          SizedBox(width: 2.w),
                          Expanded(child: _field(_featured30, '30-day ₹')),
                        ],
                      ),
                    ],
                    SizedBox(height: 1.5.h),
                    _label('Sponsored Listing'),
                    _switchRow(
                      'Enable Sponsored',
                      _sponsoredEnabled,
                      (v) => setState(() => _sponsoredEnabled = v),
                    ),
                    if (_sponsoredEnabled)
                      _field(_sponsored, 'Sponsored Price ₹'),
                    SizedBox(height: 1.5.h),
                    _label('Verified Badge'),
                    _switchRow(
                      'Enable Badge',
                      _badgeEnabled,
                      (v) => setState(() => _badgeEnabled = v),
                    ),
                    if (_badgeEnabled) _field(_badge, 'Badge Price ₹'),
                    SizedBox(height: 1.5.h),
                    _label('Pay Per Listing'),
                    _switchRow(
                      'Enable Pay-Per-Listing',
                      _pplListingEnabled,
                      (v) => setState(() => _pplListingEnabled = v),
                    ),
                    if (_pplListingEnabled)
                      _field(_pplListingPrice, 'Price per Listing ₹'),
                    SizedBox(height: 1.5.h),
                    _label('Pay Per Lead'),
                    _switchRow(
                      'Enable Pay-Per-Lead',
                      _pplEnabled,
                      (v) => setState(() => _pplEnabled = v),
                    ),
                    if (_pplEnabled) _field(_pplPrice, 'Price per Lead ₹'),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1C1E),
      ),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: _inputDecoration(hint),
      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
    ),
  );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 10.sp,
      color: const Color(0xFF74777F),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1565C0)),
    ),
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
  );
}

// ── Helper Widgets ────────────────────────────────────────────────────────────
class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String badge;

  const _GateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: const Color(0xFF74777F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpireSubscriptionsButton extends StatefulWidget {
  final VoidCallback onExpired;
  const _ExpireSubscriptionsButton({required this.onExpired});

  @override
  State<_ExpireSubscriptionsButton> createState() =>
      _ExpireSubscriptionsButtonState();
}

class _ExpireSubscriptionsButtonState
    extends State<_ExpireSubscriptionsButton> {
  bool _isRunning = false;
  String? _result;

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });
    try {
      final count = await SupabaseService.instance.client.rpc(
        'expire_stale_subscriptions',
      );
      if (mounted) {
        setState(() => _result = 'Expired $count stale subscription(s).');
        widget.onExpired();
      }
    } catch (e) {
      if (mounted) setState(() => _result = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _run,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.timer_off_rounded, size: 18),
            label: Text(
              _isRunning ? 'Running...' : 'Run: Expire Stale Subscriptions',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
