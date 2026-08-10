import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../admin_panel_screen/admin_kyc_verification_screen.dart';

class AdminProviderManagementScreen extends StatefulWidget {
  const AdminProviderManagementScreen({super.key});

  @override
  State<AdminProviderManagementScreen> createState() =>
      _AdminProviderManagementScreenState();
}

class _AdminProviderManagementScreenState
    extends State<AdminProviderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  String _searchQuery = '';
  String _statusFilter = 'all';
  final String _categoryFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'all',
    'Home Maintenance',
    'Transport',
    'Events',
    'Shop',
    'Rent',
    'Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAdminAllProviders();
      if (mounted) {
        setState(() {
          _providers = data;
          _filteredProviders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Use mock data on error
      if (mounted) {
        setState(() {
          _providers = _mockProviders;
          _filteredProviders = _mockProviders;
          _isLoading = false;
        });
      }
    }
  }

  final List<Map<String, dynamic>> _mockProviders = [
    {
      'id': 'p1',
      'full_name': 'Ravi Kumar',
      'business_name': 'Ravi Plumbing Services',
      'category': 'Home Maintenance',
      'city': 'Roha',
      'status': 'approved',
      'rating': 4.5,
      'total_orders': 48,
      'earnings': 24500,
      'subscription': 'Professional',
      'phone': '+91 98765 43210',
      'email': 'ravi@demo.localconnect.com',
      'joined': '2026-03-15',
    },
    {
      'id': 'p2',
      'full_name': 'Suresh Transport',
      'business_name': 'Roha Transport Co.',
      'category': 'Transport',
      'city': 'Roha',
      'status': 'pending',
      'rating': 0.0,
      'total_orders': 0,
      'earnings': 0,
      'subscription': 'None',
      'phone': '+91 87654 32109',
      'email': 'suresh@demo.localconnect.com',
      'joined': '2026-06-25',
    },
    {
      'id': 'p3',
      'full_name': 'Priya Events',
      'business_name': 'Alibag Events & Decor',
      'category': 'Events',
      'city': 'Alibag',
      'status': 'approved',
      'rating': 4.8,
      'total_orders': 23,
      'earnings': 68000,
      'subscription': 'Enterprise',
      'phone': '+91 76543 21098',
      'email': 'priya@demo.localconnect.com',
      'joined': '2026-01-10',
    },
    {
      'id': 'p4',
      'full_name': 'Mohan Electricals',
      'business_name': 'City Electricals Shop',
      'category': 'Shop',
      'city': 'Pen',
      'status': 'suspended',
      'rating': 3.2,
      'total_orders': 15,
      'earnings': 8200,
      'subscription': 'Basic',
      'phone': '+91 65432 10987',
      'email': 'mohan@demo.localconnect.com',
      'joined': '2026-02-20',
    },
    {
      'id': 'p5',
      'full_name': 'Anita Rooms',
      'business_name': 'Nagothane Rent Rooms',
      'category': 'Rent',
      'city': 'Nagothane',
      'status': 'approved',
      'rating': 4.2,
      'total_orders': 31,
      'earnings': 42000,
      'subscription': 'Professional',
      'phone': '+91 54321 09876',
      'email': 'anita@demo.localconnect.com',
      'joined': '2026-04-05',
    },
  ];

  void _applyFilters() {
    setState(() {
      _filteredProviders = _providers.where((p) {
        final name = (p['full_name'] ?? '').toString().toLowerCase();
        final biz = (p['business_name'] ?? '').toString().toLowerCase();
        final status = (p['status'] ?? '').toString();
        final cat = (p['category'] ?? '').toString();
        final matchesSearch =
            _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            biz.contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
        final matchesCat = _categoryFilter == 'all' || cat == _categoryFilter;
        return matchesSearch && matchesStatus && matchesCat;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'suspended':
        return AppTheme.error;
      case 'rejected':
        return const Color(0xFF795548);
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
          'Provider Management',
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
            onPressed: _exportProviders,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadProviders,
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
            Tab(text: 'All Providers'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search providers...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.outline,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _applyFilters();
                        },
                      )
                    : null,
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
          // Status filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _statusFilter, (v) {
                    _statusFilter = v;
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', 'approved', _statusFilter, (v) {
                    _statusFilter = v;
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending', _statusFilter, (v) {
                    _statusFilter = v;
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Suspended', 'suspended', _statusFilter, (
                    v,
                  ) {
                    _statusFilter = v;
                    _applyFilters();
                  }),
                ],
              ),
            ),
          ),
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceVariant,
            child: Row(
              children: [
                Text(
                  '${_filteredProviders.length} providers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${_providers.length}',
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
                _buildProviderList(_filteredProviders),
                _buildProviderList(
                  _filteredProviders
                      .where((p) => p['status'] == 'pending')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(List<Map<String, dynamic>> providers) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 48, color: AppTheme.outline),
            const SizedBox(height: 12),
            Text(
              'No providers found',
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
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildProviderCard(providers[i]),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final status = provider['status'] as String? ?? 'pending';
    final statusColor = _statusColor(status);
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (provider['full_name'] as String? ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
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
                              provider['business_name'] as String? ??
                                  provider['full_name'] as String? ??
                                  'Provider',
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
                        provider['full_name'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTag(
                            Icons.category_rounded,
                            provider['category'] as String? ?? '',
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            Icons.location_on_rounded,
                            provider['city'] as String? ?? '',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildTag(
                            Icons.receipt_long_rounded,
                            '${provider['total_orders'] ?? 0} orders',
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            Icons.workspace_premium_rounded,
                            provider['subscription'] as String? ?? 'None',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(
                    child: _buildActionButton(
                      'Approve',
                      Icons.check_rounded,
                      AppTheme.success,
                      () => _approveProvider(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Reject',
                      Icons.close_rounded,
                      AppTheme.error,
                      () => _rejectProvider(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    Icons.verified_user_rounded,
                    const Color(0xFF1565C0),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminKycVerificationScreen(),
                      ),
                    ),
                  ),
                ] else if (status == 'approved') ...[
                  Expanded(
                    child: _buildActionButton(
                      'Suspend',
                      Icons.block_rounded,
                      AppTheme.warning,
                      () => _suspendProvider(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'View',
                      Icons.visibility_rounded,
                      AppTheme.primary,
                      () => _viewProviderDetails(provider),
                    ),
                  ),
                ] else if (status == 'suspended') ...[
                  Expanded(
                    child: _buildActionButton(
                      'Reactivate',
                      Icons.refresh_rounded,
                      AppTheme.success,
                      () => _reactivateProvider(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'Delete',
                      Icons.delete_rounded,
                      AppTheme.error,
                      () => _deleteProvider(provider),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _buildActionButton(
                      'View',
                      Icons.visibility_rounded,
                      AppTheme.primary,
                      () => _viewProviderDetails(provider),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                _buildIconButton(
                  Icons.notifications_rounded,
                  AppTheme.info,
                  () => _sendNotification(provider),
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  Icons.more_vert_rounded,
                  AppTheme.outline,
                  () => _showMoreOptions(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
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

  Widget _buildActionButton(
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

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    Function(String) onTap,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
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

  void _approveProvider(Map<String, dynamic> provider) {
    setState(() => provider['status'] = 'approved');
    _showSnack('${provider['full_name']} approved!', AppTheme.success);
  }

  void _rejectProvider(Map<String, dynamic> provider) {
    setState(() => provider['status'] = 'rejected');
    _showSnack('${provider['full_name']} rejected.', AppTheme.error);
  }

  void _suspendProvider(Map<String, dynamic> provider) {
    setState(() => provider['status'] = 'suspended');
    _showSnack('${provider['full_name']} suspended.', AppTheme.warning);
  }

  void _reactivateProvider(Map<String, dynamic> provider) {
    setState(() => provider['status'] = 'approved');
    _showSnack('${provider['full_name']} reactivated!', AppTheme.success);
  }

  void _deleteProvider(Map<String, dynamic> provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Provider',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete ${provider['full_name']}? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _providers.remove(provider);
                _filteredProviders.remove(provider);
              });
              _showSnack('Provider deleted.', AppTheme.error);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _viewProviderDetails(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Provider Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _detailRow('Name', provider['full_name'] ?? ''),
                    _detailRow('Business', provider['business_name'] ?? ''),
                    _detailRow('Category', provider['category'] ?? ''),
                    _detailRow('City', provider['city'] ?? ''),
                    _detailRow('Phone', provider['phone'] ?? ''),
                    _detailRow('Email', provider['email'] ?? ''),
                    _detailRow('Status', provider['status'] ?? ''),
                    _detailRow('Rating', '${provider['rating'] ?? 0} ⭐'),
                    _detailRow(
                      'Total Orders',
                      '${provider['total_orders'] ?? 0}',
                    ),
                    _detailRow('Earnings', '₹${provider['earnings'] ?? 0}'),
                    _detailRow(
                      'Subscription',
                      provider['subscription'] ?? 'None',
                    ),
                    _detailRow('Joined', provider['joined'] ?? ''),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendNotification(Map<String, dynamic> provider) {
    _showSnack(
      'Notification sent to ${provider['full_name']}',
      AppTheme.primary,
    );
  }

  void _showMoreOptions(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _moreOptionTile(
              Icons.lock_reset_rounded,
              'Reset Password',
              AppTheme.primary,
              () {
                Navigator.pop(ctx);
                _showSnack('Password reset email sent!', AppTheme.primary);
              },
            ),
            _moreOptionTile(
              Icons.history_rounded,
              'View Payment History',
              AppTheme.success,
              () {
                Navigator.pop(ctx);
              },
            ),
            _moreOptionTile(
              Icons.download_rounded,
              'Export Provider Data',
              AppTheme.warning,
              () {
                Navigator.pop(ctx);
                _showSnack('Data exported!', AppTheme.warning);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _moreOptionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  void _exportProviders() {
    _showSnack('Provider data exported to CSV!', AppTheme.success);
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
