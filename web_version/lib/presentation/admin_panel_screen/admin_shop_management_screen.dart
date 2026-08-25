import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminShopManagementScreen extends StatefulWidget {
  const AdminShopManagementScreen({super.key});

  @override
  State<AdminShopManagementScreen> createState() =>
      _AdminShopManagementScreenState();
}

class _AdminShopManagementScreenState extends State<AdminShopManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _shops = [
    {
      'id': 'sh1',
      'name': 'Roha Fresh Vegetables',
      'owner': 'Ramesh Patil',
      'category': 'Vegetables & Fruits',
      'city': 'Roha',
      'status': 'approved',
      'rating': 4.6,
      'orders': 234,
      'revenue': 45600,
      'subscription': 'Professional',
      'joined': '2026-01-15',
    },
    {
      'id': 'sh2',
      'name': 'Alibag Meat Corner',
      'owner': 'Salim Khan',
      'category': 'Meat & Fish',
      'city': 'Alibag',
      'status': 'pending',
      'rating': 0.0,
      'orders': 0,
      'revenue': 0,
      'subscription': 'None',
      'joined': '2026-06-28',
    },
    {
      'id': 'sh3',
      'name': 'City Electricals',
      'owner': 'Mohan Sharma',
      'category': 'Electrical & Hardware',
      'city': 'Pen',
      'status': 'suspended',
      'rating': 3.1,
      'orders': 45,
      'revenue': 12300,
      'subscription': 'Basic',
      'joined': '2026-03-10',
    },
    {
      'id': 'sh4',
      'name': 'Nagothane Plumbing Store',
      'owner': 'Vijay Desai',
      'category': 'Plumbing & Hardware',
      'city': 'Nagothane',
      'status': 'approved',
      'rating': 4.3,
      'orders': 89,
      'revenue': 28900,
      'subscription': 'Professional',
      'joined': '2026-02-20',
    },
    {
      'id': 'sh5',
      'name': 'Seasonal Bazaar',
      'owner': 'Priya Joshi',
      'category': 'Seasonal Items',
      'city': 'Mumbai',
      'status': 'approved',
      'rating': 4.7,
      'orders': 312,
      'revenue': 67800,
      'subscription': 'Enterprise',
      'joined': '2025-12-01',
    },
  ];

  List<Map<String, dynamic>> get _filteredShops {
    return _shops.where((s) {
      final name = (s['name'] as String).toLowerCase();
      final owner = (s['owner'] as String).toLowerCase();
      final status = s['status'] as String;
      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          owner.contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'suspended':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Shop Management',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
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
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () =>
                _showSnack('Shop data exported!', AppTheme.success),
            tooltip: 'Export CSV',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All Shops'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search shops...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.outline,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildChip('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _buildChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildChip('Suspended', 'suspended'),
                ],
              ),
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceVariant,
            child: Row(
              children: [
                Text(
                  '${_filteredShops.length} shops',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_shops.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShopList(_filteredShops),
                _buildShopList(
                  _filteredShops
                      .where((s) => s['status'] == 'pending')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopList(List<Map<String, dynamic>> shops) {
    if (shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 48,
              color: AppTheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No shops found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildShopCard(shops[i]),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final status = shop['status'] as String;
    final statusColor = _statusColor(status);
    final rating = (shop['rating'] as num).toDouble();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
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
                              shop['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C1E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shop['owner'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          _tag(
                            Icons.category_rounded,
                            shop['category'] as String,
                          ),
                          _tag(
                            Icons.location_on_rounded,
                            shop['city'] as String,
                          ),
                          if (rating > 0)
                            _tag(
                              Icons.star_rounded,
                              '${rating.toStringAsFixed(1)} ⭐',
                            ),
                          _tag(
                            Icons.receipt_long_rounded,
                            '${shop['orders']} orders',
                          ),
                          _tag(
                            Icons.workspace_premium_rounded,
                            shop['subscription'] as String,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Revenue bar
          if ((shop['revenue'] as int) > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_rupee_rounded,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Revenue: ₹${shop['revenue']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: _actionBtn(
                      'Approve',
                      Icons.check_rounded,
                      AppTheme.success,
                      () {
                        setState(() => shop['status'] = 'approved');
                        _showSnack('Shop approved!', AppTheme.success);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionBtn(
                      'Reject',
                      Icons.close_rounded,
                      AppTheme.error,
                      () {
                        setState(() => shop['status'] = 'rejected');
                        _showSnack('Shop rejected.', AppTheme.error);
                      },
                    ),
                  ),
                ] else if (status == 'approved') ...[
                  Expanded(
                    child: _actionBtn(
                      'Suspend',
                      Icons.block_rounded,
                      AppTheme.warning,
                      () {
                        setState(() => shop['status'] = 'suspended');
                        _showSnack('Shop suspended.', AppTheme.warning);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionBtn(
                      'View Orders',
                      Icons.receipt_long_rounded,
                      AppTheme.primary,
                      () => _showSnack('Viewing orders...', AppTheme.primary),
                    ),
                  ),
                ] else if (status == 'suspended') ...[
                  Expanded(
                    child: _actionBtn(
                      'Reactivate',
                      Icons.refresh_rounded,
                      AppTheme.success,
                      () {
                        setState(() => shop['status'] = 'approved');
                        _showSnack('Shop reactivated!', AppTheme.success);
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _actionBtn(
                      'View',
                      Icons.visibility_rounded,
                      AppTheme.primary,
                      () {},
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.outline),
        const SizedBox(width: 2),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.outline,
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
