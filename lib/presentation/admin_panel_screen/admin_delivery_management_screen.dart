import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:localconnect/core/supabase_mock.dart';

class AdminDeliveryManagementScreen extends StatefulWidget {
  const AdminDeliveryManagementScreen({super.key});

  @override
  State<AdminDeliveryManagementScreen> createState() =>
      _AdminDeliveryManagementScreenState();
}

class _AdminDeliveryManagementScreenState
    extends State<AdminDeliveryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  static const Color _primary = Color(0xFF0D47A1);
  static const Color _accent = Color(0xFF1565C0);
  static const Color _green = Color(0xFF2ECC71);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _red = Color(0xFFE53935);

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _riders = [];
  List<Map<String, dynamic>> _pricingTiers = [];
  List<Map<String, dynamic>> _commissionRules = [];
  Map<String, dynamic> _surcharges = {
    'peak_hour': 15,
    'night_charge': 20,
    'rain_surcharge': 10,
    'holiday_surcharge': 25,
  };
  String? _surchargesId;

  // KPI aggregates
  int _totalDeliveries = 0;
  int _activeRidersCount = 0;
  double _totalRevenue = 0;
  double _totalCommission = 0;

  String _riderFilter = 'all';

  // Form controllers
  final _vendorNameCtrl = TextEditingController();
  final _vendorCityCtrl = TextEditingController();
  final _vendorContactCtrl = TextEditingController();
  final _vendorPhoneCtrl = TextEditingController();

  final _riderNameCtrl = TextEditingController();
  final _riderPhoneCtrl = TextEditingController();
  final _riderCityCtrl = TextEditingController();
  final _riderVehicleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vendorNameCtrl.dispose();
    _vendorCityCtrl.dispose();
    _vendorContactCtrl.dispose();
    _vendorPhoneCtrl.dispose();
    _riderNameCtrl.dispose();
    _riderPhoneCtrl.dispose();
    _riderCityCtrl.dispose();
    _riderVehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _loadVendors(),
        _loadRiders(),
        _loadPricingTiers(),
        _loadCommissionRules(),
        _loadSurcharges(),
        _loadKPIs(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVendors() async {
    final data = await _supabase
        .from('delivery_vendors')
        .select()
        .order('created_at', ascending: false);
    setState(() => _vendors = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadRiders() async {
    final data = await _supabase
        .from('delivery_riders')
        .select('*, delivery_vendors(name)')
        .order('deliveries_today', ascending: false);
    setState(() {
      _riders = List<Map<String, dynamic>>.from(data);
      _activeRidersCount = _riders
          .where((r) => r['status'] != 'offline')
          .length;
    });
  }

  Future<void> _loadPricingTiers() async {
    final data = await _supabase
        .from('delivery_pricing_tiers')
        .select()
        .order('base_charge', ascending: true);
    setState(() => _pricingTiers = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadCommissionRules() async {
    final data = await _supabase
        .from('delivery_commission_rules')
        .select()
        .order('created_at', ascending: true);
    setState(() => _commissionRules = List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadSurcharges() async {
    final data = await _supabase
        .from('delivery_surcharges')
        .select()
        .limit(1)
        .maybeSingle();
    if (data != null) {
      setState(() {
        _surchargesId = data['id'];
        _surcharges = {
          'peak_hour': data['peak_hour'] ?? 15,
          'night_charge': data['night_charge'] ?? 20,
          'rain_surcharge': data['rain_surcharge'] ?? 10,
          'holiday_surcharge': data['holiday_surcharge'] ?? 25,
        };
      });
    }
  }

  Future<void> _loadKPIs() async {
    // Total deliveries from delivery_tracking
    final deliveriesResp = await _supabase
        .from('delivery_tracking')
        .select('id');
    // Revenue & commission from vendors
    final vendorData = await _supabase
        .from('delivery_vendors')
        .select('revenue_today, commission_today');
    double rev = 0;
    double comm = 0;
    for (final v in vendorData) {
      rev += (v['revenue_today'] as num?)?.toDouble() ?? 0;
      comm += (v['commission_today'] as num?)?.toDouble() ?? 0;
    }
    setState(() {
      _totalDeliveries = deliveriesResp.length;
      _totalRevenue = rev;
      _totalCommission = comm;
    });
  }

  // ── CRUD Actions ──────────────────────────────────────────────────────────

  Future<void> _approveVendor(Map<String, dynamic> vendor) async {
    try {
      await _supabase
          .from('delivery_vendors')
          .update({'status': 'active'})
          .eq('id', vendor['id']);
      await _loadVendors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${vendor['name']} approved!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to approve vendor');
    }
  }

  Future<void> _toggleVendorStatus(Map<String, dynamic> vendor) async {
    final newStatus = vendor['status'] == 'active' ? 'suspended' : 'active';
    try {
      await _supabase
          .from('delivery_vendors')
          .update({'status': newStatus})
          .eq('id', vendor['id']);
      await _loadVendors();
    } catch (e) {
      _showError('Failed to update vendor status');
    }
  }

  Future<void> _toggleRiderStatus(Map<String, dynamic> rider) async {
    final newStatus = rider['status'] == 'offline' ? 'online' : 'offline';
    try {
      await _supabase
          .from('delivery_riders')
          .update({'status': newStatus})
          .eq('id', rider['id']);
      await _loadRiders();
    } catch (e) {
      _showError('Failed to update rider status');
    }
  }

  Future<void> _togglePricingTier(String id, bool isActive) async {
    try {
      await _supabase
          .from('delivery_pricing_tiers')
          .update({'is_active': isActive})
          .eq('id', id);
      await _loadPricingTiers();
    } catch (e) {
      _showError('Failed to update pricing tier');
    }
  }

  Future<void> _toggleCommissionRule(String id, bool isActive) async {
    try {
      await _supabase
          .from('delivery_commission_rules')
          .update({'is_active': isActive})
          .eq('id', id);
      await _loadCommissionRules();
    } catch (e) {
      _showError('Failed to update commission rule');
    }
  }

  Future<void> _addVendor() async {
    if (_vendorNameCtrl.text.trim().isEmpty) return;
    try {
      await _supabase.from('delivery_vendors').insert({
        'name': _vendorNameCtrl.text.trim(),
        'city': _vendorCityCtrl.text.trim(),
        'contact_name': _vendorContactCtrl.text.trim(),
        'phone': _vendorPhoneCtrl.text.trim(),
        'status': 'pending',
      });
      _vendorNameCtrl.clear();
      _vendorCityCtrl.clear();
      _vendorContactCtrl.clear();
      _vendorPhoneCtrl.clear();
      await _loadVendors();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add vendor');
    }
  }

  Future<void> _addRider() async {
    if (_riderNameCtrl.text.trim().isEmpty) return;
    try {
      await _supabase.from('delivery_riders').insert({
        'name': _riderNameCtrl.text.trim(),
        'city': _riderCityCtrl.text.trim(),
        'vehicle': _riderVehicleCtrl.text.trim().isEmpty
            ? 'Bike'
            : _riderVehicleCtrl.text.trim(),
        'status': 'offline',
      });
      _riderNameCtrl.clear();
      _riderPhoneCtrl.clear();
      _riderCityCtrl.clear();
      _riderVehicleCtrl.clear();
      await _loadRiders();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add rider');
    }
  }

  Future<void> _addCommissionRule(
    String name,
    String type,
    double value,
    String appliesTo,
  ) async {
    try {
      await _supabase.from('delivery_commission_rules').insert({
        'name': name,
        'type': type,
        'value': value,
        'applies_to': appliesTo,
        'is_active': true,
      });
      await _loadCommissionRules();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add commission rule');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: _primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Delivery Management',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadAll,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                ),
                onPressed: _showAddVendorSheet,
                tooltip: 'Add Vendor',
              ),
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                onPressed: _showAddRiderSheet,
                tooltip: 'Add Rider',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.map_rounded, size: 16), text: 'Live Map'),
                Tab(
                  icon: Icon(Icons.business_rounded, size: 16),
                  text: 'Vendors',
                ),
                Tab(
                  icon: Icon(Icons.directions_bike_rounded, size: 16),
                  text: 'Riders',
                ),
                Tab(
                  icon: Icon(Icons.layers_rounded, size: 16),
                  text: 'Pricing',
                ),
                Tab(
                  icon: Icon(Icons.percent_rounded, size: 16),
                  text: 'Commission',
                ),
                Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 16),
                  text: 'KPIs',
                ),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveMapTab(),
                  _buildVendorsTab(),
                  _buildRidersTab(),
                  _buildPricingTiersTab(),
                  _buildCommissionTab(),
                  _buildKPIsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: _red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadAll,
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — LIVE MAP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLiveMapTab() {
    final onlineCount = _riders.where((r) => r['status'] == 'online').length;
    final onDeliveryCount = _riders
        .where((r) => r['status'] == 'on_delivery')
        .length;
    final offlineCount = _riders.where((r) => r['status'] == 'offline').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip('Online', onlineCount, _green),
              const SizedBox(width: 8),
              _buildStatusChip('On Delivery', onDeliveryCount, _orange),
              const SizedBox(width: 8),
              _buildStatusChip('Offline', offlineCount, Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 32.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFD0E8FF), Color(0xFFB3D4F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(double.infinity, 32.h),
                  painter: _MapGridPainter(),
                ),
                Positioned(top: 20, left: 30, child: _buildCityLabel('Mumbai')),
                Positioned(top: 60, right: 50, child: _buildCityLabel('Pune')),
                Positioned(
                  bottom: 60,
                  left: 60,
                  child: _buildCityLabel('Aurangabad'),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: _buildCityLabel('Nagpur'),
                ),
                Positioned(
                  top: 40,
                  left: 120,
                  child: _buildCityLabel('Nashik'),
                ),
                ..._buildRiderDots(),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendDot(_green, 'Online'),
                        const SizedBox(width: 10),
                        _buildLegendDot(_orange, 'On Delivery'),
                        const SizedBox(width: 10),
                        _buildLegendDot(Colors.grey, 'Offline'),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Active Riders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          ..._riders
              .where((r) => r['status'] != 'offline')
              .map((r) => _buildRiderMapCard(r)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<Widget> _buildRiderDots() {
    final rng = Random(42);
    final positions = [
      [0.12, 0.25],
      [0.55, 0.35],
      [0.20, 0.60],
      [0.75, 0.65],
      [0.38, 0.20],
      [0.65, 0.18],
      [0.80, 0.45],
    ];
    return List.generate(_riders.length, (i) {
      final r = _riders[i];
      final pos = i < positions.length
          ? positions[i]
          : [rng.nextDouble(), rng.nextDouble()];
      final color = r['status'] == 'online'
          ? _green
          : r['status'] == 'on_delivery'
          ? _orange
          : Colors.grey;
      return Positioned(
        left: (pos[0] * 85 + 5).toDouble().clamp(5, 90).toDouble() * 0.01 * 100,
        top: (pos[1] * 80 + 5).toDouble().clamp(5, 85).toDouble() * 0.01 * 100,
        child: GestureDetector(
          onTap: () => _showRiderDetail(r),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.directions_bike_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCityLabel(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        city,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _primary,
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderMapCard(Map<String, dynamic> rider) {
    final statusColor = rider['status'] == 'online' ? _green : _orange;
    final statusLabel = rider['status'] == 'online' ? 'Online' : 'On Delivery';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bike_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider['name'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${rider['city'] ?? ''} • ${rider['vehicle'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${rider['deliveries_today'] ?? 0} deliveries',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — VENDORS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildVendorsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _vendors.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildVendorSummaryRow(),
          );
        }
        return _buildVendorCard(_vendors[i - 1]);
      },
    );
  }

  Widget _buildVendorSummaryRow() {
    final active = _vendors.where((v) => v['status'] == 'active').length;
    final pending = _vendors.where((v) => v['status'] == 'pending').length;
    final suspended = _vendors.where((v) => v['status'] == 'suspended').length;
    return Row(
      children: [
        _buildMiniKpi(
          'Total',
          '${_vendors.length}',
          Icons.business_rounded,
          _primary,
        ),
        const SizedBox(width: 8),
        _buildMiniKpi('Active', '$active', Icons.check_circle_rounded, _green),
        const SizedBox(width: 8),
        _buildMiniKpi('Pending', '$pending', Icons.pending_rounded, _orange),
        const SizedBox(width: 8),
        _buildMiniKpi('Suspended', '$suspended', Icons.block_rounded, _red),
      ],
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final statusColors = {
      'active': _green,
      'pending': _orange,
      'suspended': _red,
    };
    final color = statusColors[vendor['status']] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_city_rounded,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          vendor['city'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.directions_bike_rounded,
                          size: 11,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${vendor['total_riders'] ?? 0} riders',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ((vendor['status'] as String?) ?? '').toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (vendor['status'] == 'active') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVendorStat(
                  'Today',
                  '${vendor['completed_today'] ?? 0}',
                  Icons.check_rounded,
                ),
                _buildVendorStat(
                  'Revenue',
                  '₹${vendor['revenue_today'] ?? 0}',
                  Icons.currency_rupee_rounded,
                ),
                _buildVendorStat(
                  'Commission',
                  '₹${vendor['commission_today'] ?? 0}',
                  Icons.percent_rounded,
                ),
                _buildVendorStat(
                  'Rating',
                  '${vendor['rating'] ?? 0}',
                  Icons.star_rounded,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showVendorDetail(vendor),
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: _primary,
                  ),
                  label: Text(
                    'Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (vendor['status'] == 'pending') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveVendor(vendor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleVendorStatus(vendor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vendor['status'] == 'active'
                          ? _red
                          : _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      vendor['status'] == 'active' ? 'Suspend' : 'Reactivate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendorStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — RIDERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRidersTab() {
    final filtered = _riderFilter == 'all'
        ? _riders
        : _riders.where((r) => r['status'] == _riderFilter).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10),
          child: Row(
            children: [
              _buildFilterChip('all', 'All'),
              const SizedBox(width: 8),
              _buildFilterChip('online', 'Online'),
              const SizedBox(width: 8),
              _buildFilterChip('on_delivery', 'On Delivery'),
              const SizedBox(width: 8),
              _buildFilterChip('offline', 'Offline'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildRiderCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _riderFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _riderFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider) {
    final statusColors = {
      'online': _green,
      'on_delivery': _orange,
      'offline': Colors.grey,
    };
    final statusLabels = {
      'online': 'Online',
      'on_delivery': 'On Delivery',
      'offline': 'Offline',
    };
    final color = statusColors[rider['status']] ?? Colors.grey;
    final label = statusLabels[rider['status']] ?? 'Unknown';
    final vendorName =
        (rider['delivery_vendors'] as Map<String, dynamic>?)?['name'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vendorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${rider['rating'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRiderStat(
                Icons.check_circle_rounded,
                '${rider['deliveries_today'] ?? 0}',
                'Today',
              ),
              _buildRiderStat(
                Icons.currency_rupee_rounded,
                '₹${rider['earnings_today'] ?? 0}',
                'Earnings',
              ),
              _buildRiderStat(
                Icons.two_wheeler_rounded,
                rider['vehicle'] ?? 'Bike',
                'Vehicle',
              ),
              _buildRiderStat(
                Icons.location_on_rounded,
                rider['city'] ?? '',
                'City',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRiderDetail(rider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                  ),
                  child: Text(
                    'View Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toggleRiderStatus(rider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rider['status'] == 'offline'
                        ? _green
                        : _red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                  ),
                  child: Text(
                    rider['status'] == 'offline' ? 'Activate' : 'Deactivate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildRiderStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4 — PRICING TIERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPricingTiersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Delivery Pricing Tiers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure base rates for each delivery tier. Vendors may add surcharges.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ..._pricingTiers.map((tier) => _buildPricingTierCard(tier)),
          const SizedBox(height: 16),
          _buildSurchargesCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPricingTierCard(Map<String, dynamic> tier) {
    final colorHex = tier['color_hex'] as String? ?? '#1565C0';
    final color = Color(int.parse('0xFF${colorHex.replaceAll('#', '')}'));
    final isActive = tier['is_active'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.layers_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tier['name'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) => _togglePricingTier(tier['id'], v),
                  activeThumbColor: color,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPricingRow(
                  'Base Charge',
                  '₹${tier['base_charge'] ?? 0}',
                  color,
                ),
                _buildPricingRow(
                  'Per KM Rate',
                  '₹${tier['per_km_rate'] ?? 0}/km',
                  color,
                ),
                _buildPricingRow(
                  'Weight Surcharge',
                  '₹${tier['weight_charge'] ?? 0}/kg',
                  color,
                ),
                _buildPricingRow(
                  'Max Weight',
                  '${tier['max_weight'] ?? 0} kg',
                  color,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditPricingSheet(tier),
                    icon: Icon(Icons.edit_rounded, size: 14, color: color),
                    label: Text(
                      'Edit Tier',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildPricingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurchargesCard() {
    final surchargeLabels = {
      'peak_hour': 'Peak Hour (6–9 PM)',
      'night_charge': 'Night Charge (10 PM–6 AM)',
      'rain_surcharge': 'Rain Surcharge',
      'holiday_surcharge': 'Holiday Surcharge',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt_rounded, color: _orange, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Dynamic Surcharges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._surcharges.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    surchargeLabels[e.key] ?? e.key,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+₹${e.value}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _orange,
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

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 5 — COMMISSION RULES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCommissionTab() {
    final activeRules = _commissionRules
        .where((r) => r['is_active'] == true)
        .length;
    final totalCommissionDisplay = '₹${_totalCommission.toStringAsFixed(0)}';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, const Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commission Overview',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalCommissionDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total commission today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildCommissionChip('Active Rules', '$activeRules'),
                    const SizedBox(height: 8),
                    _buildCommissionChip(
                      'Total Rules',
                      '${_commissionRules.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commission Rules',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddCommissionSheet,
                icon: Icon(Icons.add_rounded, size: 16, color: _primary),
                label: Text(
                  'Add Rule',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._commissionRules.map((rule) => _buildCommissionRuleCard(rule)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCommissionChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionRuleCard(Map<String, dynamic> rule) {
    final isActive = rule['is_active'] as bool? ?? true;
    final isPercentage = rule['type'] == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _primary.withValues(alpha: 0.2) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isActive ? _primary : Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPercentage ? Icons.percent_rounded : Icons.attach_money_rounded,
              color: isActive ? _primary : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['name'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey[500],
                  ),
                ),
                Text(
                  rule['applies_to'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPercentage
                    ? '${rule['value']}%'
                    : '₹${(rule['value'] as num?)?.toStringAsFixed(0) ?? '0'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isActive ? _primary : Colors.grey,
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (v) => _toggleCommissionRule(rule['id'], v),
                activeThumbColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 6 — KPIs
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKPIsTab() {
    final sorted = List<Map<String, dynamic>>.from(_riders)
      ..sort(
        (a, b) => ((b['deliveries_today'] as int?) ?? 0).compareTo(
          (a['deliveries_today'] as int?) ?? 0,
        ),
      );
    final top3 = sorted.take(3).toList();

    // City performance from vendors
    final cityMap = <String, int>{};
    for (final v in _vendors) {
      final city = v['city'] as String? ?? '';
      cityMap[city] =
          (cityMap[city] ?? 0) + ((v['completed_today'] as int?) ?? 0);
    }
    final cityData =
        cityMap.entries
            .map((e) => {'city': e.key, 'deliveries': e.value})
            .toList()
          ..sort(
            (a, b) =>
                (b['deliveries'] as int).compareTo(a['deliveries'] as int),
          );
    final maxDeliveries = cityData.isEmpty
        ? 1
        : cityData
              .map((c) => c['deliveries'] as int)
              .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Revenue — Today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_totalRevenue.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: _green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Live from Supabase',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRevenueChip(
                      'Commission',
                      '₹${_totalCommission.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 8),
                    _buildRevenueChip('Vendors', '${_vendors.length}'),
                    const SizedBox(width: 8),
                    _buildRevenueChip('Riders', '${_riders.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Performance KPIs',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                'Total Deliveries',
                '$_totalDeliveries',
                Icons.local_shipping_rounded,
                _primary,
                '',
              ),
              _buildKpiCard(
                'Active Vendors',
                '${_vendors.where((v) => v['status'] == 'active').length}',
                Icons.business_rounded,
                _orange,
                '',
              ),
              _buildKpiCard(
                'Active Riders',
                '$_activeRidersCount',
                Icons.directions_bike_rounded,
                _green,
                '',
              ),
              _buildKpiCard(
                'Pending Vendors',
                '${_vendors.where((v) => v['status'] == 'pending').length}',
                Icons.pending_rounded,
                _red,
                '',
              ),
              _buildKpiCard(
                'Total Revenue',
                '₹${_totalRevenue.toStringAsFixed(0)}',
                Icons.currency_rupee_rounded,
                const Color(0xFF9B59B6),
                '',
              ),
              _buildKpiCard(
                'Commission Earned',
                '₹${_totalCommission.toStringAsFixed(0)}',
                Icons.percent_rounded,
                const Color(0xFF00897B),
                '',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (cityData.isNotEmpty)
            _buildCityPerformanceCard(cityData, maxDeliveries),
          const SizedBox(height: 16),
          if (top3.isNotEmpty) _buildTopRidersCard(top3),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (change.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: change.startsWith('+')
                        ? _green.withValues(alpha: 0.1)
                        : _red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    change,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: change.startsWith('+') ? _green : _red,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityPerformanceCard(
    List<Map<String, dynamic>> cityData,
    int maxDeliveries,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City Performance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...cityData.take(5).map((c) {
            final pct = maxDeliveries > 0
                ? (c['deliveries'] as int) / maxDeliveries
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c['city'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${c['deliveries']} deliveries',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopRidersCard(List<Map<String, dynamic>> top3) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Top Performers Today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(top3.length, (i) {
            final rider = top3[i];
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Text(medals[i], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider['name'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          rider['city'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rider['deliveries_today'] ?? 0} orders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                      Text(
                        '₹${rider['earnings_today'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMiniKpi(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Sheets ─────────────────────────────────────────────────────────
  void _showRiderDetail(Map<String, dynamic> rider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildRiderDetailSheet(rider),
    );
  }

  void _showVendorDetail(Map<String, dynamic> vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildVendorDetailSheet(vendor),
    );
  }

  Widget _buildRiderDetailSheet(Map<String, dynamic> rider) {
    final statusColor = rider['status'] == 'online'
        ? _green
        : rider['status'] == 'on_delivery'
        ? _orange
        : Colors.grey;
    final vendorName =
        (rider['delivery_vendors'] as Map<String, dynamic>?)?['name'] ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: statusColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      rider['id'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ((rider['status'] as String?) ?? '')
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.business_rounded, 'Vendor', vendorName),
          _buildDetailRow(
            Icons.location_city_rounded,
            'City',
            rider['city'] ?? '',
          ),
          _buildDetailRow(
            Icons.two_wheeler_rounded,
            'Vehicle',
            rider['vehicle'] ?? '',
          ),
          _buildDetailRow(
            Icons.check_circle_rounded,
            'Deliveries Today',
            '${rider['deliveries_today'] ?? 0}',
          ),
          _buildDetailRow(
            Icons.currency_rupee_rounded,
            'Earnings Today',
            '₹${rider['earnings_today'] ?? 0}',
          ),
          _buildDetailRow(
            Icons.star_rounded,
            'Rating',
            '${rider['rating'] ?? 0} / 5.0',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVendorDetailSheet(Map<String, dynamic> vendor) {
    final statusColor = vendor['status'] == 'active'
        ? _green
        : vendor['status'] == 'pending'
        ? _orange
        : _red;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.business_rounded, color: _primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vendor['id'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
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
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ((vendor['status'] as String?) ?? '').toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            Icons.location_city_rounded,
            'City',
            vendor['city'] ?? '',
          ),
          _buildDetailRow(
            Icons.directions_bike_rounded,
            'Total Riders',
            '${vendor['total_riders'] ?? 0}',
          ),
          _buildDetailRow(
            Icons.person_rounded,
            'Contact',
            vendor['contact_name'] ?? '',
          ),
          _buildDetailRow(Icons.phone_rounded, 'Phone', vendor['phone'] ?? ''),
          if (vendor['status'] == 'active') ...[
            _buildDetailRow(
              Icons.check_rounded,
              'Deliveries Today',
              '${vendor['completed_today'] ?? 0}',
            ),
            _buildDetailRow(
              Icons.currency_rupee_rounded,
              'Revenue Today',
              '₹${vendor['revenue_today'] ?? 0}',
            ),
            _buildDetailRow(
              Icons.percent_rounded,
              'Commission Today',
              '₹${vendor['commission_today'] ?? 0}',
            ),
            _buildDetailRow(
              Icons.star_rounded,
              'Rating',
              '${vendor['rating'] ?? 0} / 5.0',
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit Sheets ─────────────────────────────────────────────────────
  void _showAddVendorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 55.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.add_business_rounded, color: _primary),
                    const SizedBox(width: 10),
                    Text(
                      'Add Delivery Vendor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildInputField(
                        _vendorNameCtrl,
                        'Vendor Name',
                        Icons.business_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _vendorCityCtrl,
                        'City',
                        Icons.location_city_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _vendorContactCtrl,
                        'Contact Person',
                        Icons.person_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _vendorPhoneCtrl,
                        'Phone Number',
                        Icons.phone_rounded,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addVendor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Create Vendor Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRiderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 60.h,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, color: _primary),
                    const SizedBox(width: 10),
                    Text(
                      'Add Rider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildInputField(
                        _riderNameCtrl,
                        'Full Name',
                        Icons.person_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _riderPhoneCtrl,
                        'Phone Number',
                        Icons.phone_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _riderCityCtrl,
                        'City',
                        Icons.location_city_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        _riderVehicleCtrl,
                        'Vehicle Type',
                        Icons.two_wheeler_rounded,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addRider,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Register Rider',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPricingSheet(Map<String, dynamic> tier) {
    final baseCtrl = TextEditingController(text: '${tier['base_charge'] ?? 0}');
    final perKmCtrl = TextEditingController(
      text: '${tier['per_km_rate'] ?? 0}',
    );
    final weightCtrl = TextEditingController(
      text: '${tier['weight_charge'] ?? 0}',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit ${tier['name']} Tier',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              baseCtrl,
              'Base Charge (₹)',
              Icons.currency_rupee_rounded,
            ),
            const SizedBox(height: 12),
            _buildInputField(perKmCtrl, 'Per KM Rate (₹)', Icons.route_rounded),
            const SizedBox(height: 12),
            _buildInputField(
              weightCtrl,
              'Weight Surcharge (₹/kg)',
              Icons.scale_rounded,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _supabase
                        .from('delivery_pricing_tiers')
                        .update({
                          'base_charge':
                              double.tryParse(baseCtrl.text) ??
                              tier['base_charge'],
                          'per_km_rate':
                              double.tryParse(perKmCtrl.text) ??
                              tier['per_km_rate'],
                          'weight_charge':
                              double.tryParse(weightCtrl.text) ??
                              tier['weight_charge'],
                        })
                        .eq('id', tier['id']);
                    await _loadPricingTiers();
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${tier['name']} tier updated!',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          backgroundColor: _primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    _showError('Failed to update tier');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddCommissionSheet() {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final appliesToCtrl = TextEditingController();
    String selectedType = 'percentage';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Commission Rule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(nameCtrl, 'Rule Name', Icons.label_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedType = 'percentage'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedType == 'percentage'
                              ? _primary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Percentage',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selectedType == 'percentage'
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'flat'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedType == 'flat'
                              ? _primary
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Flat (₹)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selectedType == 'flat'
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputField(
                rateCtrl,
                selectedType == 'percentage' ? 'Rate (%)' : 'Amount (₹)',
                Icons.percent_rounded,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                appliesToCtrl,
                'Applies To',
                Icons.group_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addCommissionRule(
                    nameCtrl.text.trim(),
                    selectedType,
                    double.tryParse(rateCtrl.text) ?? 0,
                    appliesToCtrl.text.trim().isEmpty
                        ? 'All Vendors'
                        : appliesToCtrl.text.trim(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Create Rule',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primary, size: 20),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // Keep legacy _buildTextField for backward compat
  Widget _buildTextField(String hint, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primary, size: 20),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

// ── Custom painter for map grid ───────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.3)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width,
        size.height * 0.4,
      );
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.8,
        size.height,
      );
    canvas.drawPath(path2, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
