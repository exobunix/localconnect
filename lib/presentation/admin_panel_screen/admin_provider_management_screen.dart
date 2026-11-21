import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_routes.dart';
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
      final isSuper = SupabaseService.instance.isSuperAdmin;
      final assignedArea = SupabaseService.instance.currentAdminArea.trim().toLowerCase();
      final areaFiltered = isSuper
          ? data
          : data.where((p) {
              final city = (p['city'] ?? p['business_city'] ?? '').toString().toLowerCase();
              return city.contains(assignedArea) || assignedArea.contains(city);
            }).toList();
      if (mounted) {
        setState(() {
          _providers = areaFiltered;
          _filteredProviders = areaFiltered;
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
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            onPressed: _showAddProviderDialog,
            tooltip: 'Add New Provider',
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(
          'Add Provider',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: _showAddProviderDialog,
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
                  Icons.edit_rounded,
                  AppTheme.primary,
                  () => _showEditProviderDialog(provider),
                  tooltip: 'Edit Profile & Contact',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  Icons.notifications_rounded,
                  AppTheme.info,
                  () => _sendNotification(provider),
                  tooltip: 'Send Notification',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  Icons.more_vert_rounded,
                  AppTheme.outline,
                  () => _showMoreOptions(provider),
                  tooltip: 'More Options',
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

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap, {String? tooltip}) {
    final button = GestureDetector(
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
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
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

  Future<void> _approveProvider(Map<String, dynamic> provider) async {
    try {
      final providerId = provider['id'] as String;
      await SupabaseService.instance.approveProvider(providerId);
      setState(() => provider['status'] = 'approved');
      _showSnack('${provider['full_name']} approved!', AppTheme.success);
    } catch (e) {
      _showSnack('Failed to approve provider.', AppTheme.error);
    }
  }

  Future<void> _rejectProvider(Map<String, dynamic> provider) async {
    try {
      final providerId = provider['id'] as String;
      await SupabaseService.instance.adminUpdateProviderStatus(
        providerId: providerId,
        status: 'rejected',
      );
      setState(() => provider['status'] = 'rejected');
      _showSnack('${provider['full_name']} rejected.', AppTheme.error);
    } catch (e) {
      _showSnack('Failed to reject provider.', AppTheme.error);
    }
  }

  Future<void> _suspendProvider(Map<String, dynamic> provider) async {
    try {
      final providerId = provider['id'] as String;
      await SupabaseService.instance.adminUpdateProviderStatus(
        providerId: providerId,
        status: 'suspended',
      );
      setState(() => provider['status'] = 'suspended');
      _showSnack('${provider['full_name']} suspended.', AppTheme.warning);
    } catch (e) {
      _showSnack('Failed to suspend provider.', AppTheme.error);
    }
  }

  Future<void> _reactivateProvider(Map<String, dynamic> provider) async {
    try {
      final providerId = provider['id'] as String;
      await SupabaseService.instance.approveProvider(providerId);
      setState(() => provider['status'] = 'approved');
      _showSnack('${provider['full_name']} reactivated!', AppTheme.success);
    } catch (e) {
      _showSnack('Failed to reactivate provider.', AppTheme.error);
    }
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
            onPressed: () async {
              Navigator.pop(ctx);
              final providerId = (provider['id'] ?? '').toString();
              if (providerId.isNotEmpty) {
                await SupabaseService.instance.adminDeleteServiceProvider(providerId);
              }
              setState(() {
                _providers.remove(provider);
                _filteredProviders.remove(provider);
              });
              _showSnack('Provider deleted successfully.', AppTheme.error);
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

  Future<List<Map<String, dynamic>>> _loadProviderDocs(String providerId) async {
    try {
      return await SupabaseService.instance.getMyKycDocuments(providerId);
    } catch (_) {
      return [];
    }
  }

  void _viewDocumentImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url.startsWith('http'))
              Image.network(
                url,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                ),
              )
            else
              Text(
                'Invalid URL: $url',
                style: GoogleFonts.plusJakartaSans(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Provider Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit Profile'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditProviderDialog(provider);
                        },
                      ),
                    ],
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
                      FutureBuilder<String>(
                        future: SupabaseService.instance.adminGetUserPassword(
                          userId: (provider['user_id'] ?? provider['id'] ?? '').toString(),
                          email: provider['email']?.toString(),
                          phone: provider['phone']?.toString(),
                        ),
                        builder: (context, snapshot) {
                          final pwd = snapshot.data ?? '••••••••';
                          return _detailPasswordRow(pwd);
                        },
                      ),
                      _detailRow('Status', provider['status'] ?? ''),
                      _detailRow('Rating', '${provider['rating'] ?? 0} ⭐'),
                      _detailRow('Total Orders', '${provider['total_orders'] ?? 0}'),
                      _detailRow('Earnings', '₹${provider['earnings'] ?? 0}'),
                      _detailRow('Subscription', provider['subscription'] ?? 'None'),
                      _detailRow('Joined', provider['joined'] ?? ''),
                      const SizedBox(height: 16),
                      Text(
                        'KYC Documents',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Divider(),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loadProviderDocs(provider['id'] as String),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final docs = snapshot.data ?? [];
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No KYC documents uploaded.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: docs.map((doc) {
                              final type = doc['document_type'] as String? ?? 'document';
                              final status = doc['status'] as String? ?? 'pending';
                              final url = doc['document_url'] as String? ?? '';
                              return ListTile(
                                leading: const Icon(Icons.description_rounded, color: AppTheme.primary),
                                title: Text(
                                  type.toUpperCase().replaceAll('_', ' '),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: status == 'approved'
                                        ? Colors.green
                                        : (status == 'rejected' ? Colors.red : Colors.orange),
                                  ),
                                ),
                                trailing: url.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primary),
                                        onPressed: () => _viewDocumentImage(context, url),
                                      )
                                    : null,
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          if (provider['status'] == 'pending') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Approve'),
                                onPressed: () async {
                                  await _approveProvider(provider);
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Reject'),
                                onPressed: () async {
                                  await _rejectProvider(provider);
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ] else if (provider['status'] == 'approved') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.warning,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.block_rounded),
                                label: const Text('Suspend'),
                                onPressed: () async {
                                  await _suspendProvider(provider);
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ] else if (provider['status'] == 'suspended') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reactivate'),
                                onPressed: () async {
                                  await _reactivateProvider(provider);
                                  setModalState(() {});
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
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

  Widget _detailPasswordRow(String password) {
    bool show = false;
    return StatefulBuilder(
      builder: (context, setPwdState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Password',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFFE65100),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  show ? password : '•' * (password.isNotEmpty ? password.length : 8),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: show ? 0.5 : 2.0,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                  color: const Color(0xFFE65100),
                ),
                tooltip: show ? 'Hide Password' : 'Show Password',
                onPressed: () => setPwdState(() => show = !show),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFFE65100)),
                tooltip: 'Copy Password',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password copied to clipboard'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
              Icons.edit_note_rounded,
              'Edit Profile & Contact Details',
              AppTheme.primary,
              () {
                Navigator.pop(ctx);
                _showEditProviderDialog(provider);
              },
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

  // ─── ADMIN: ADD & EDIT SERVICE PROVIDER ─────────────────────────────────────

  static const Map<String, List<String>> _categorySubcategoryMap = {
    'Home Maintenance': [
      'Plumber',
      'Electrician',
      'Painter',
      'Carpenter',
      'AC & Appliance Repair',
      'Cleaning & Pest Control',
      'Mason / Construction',
      'House Maid / Daily Wage',
      'Other / Custom',
    ],
    'Transport': [
      'Taxi / Cab',
      'Auto Rickshaw',
      'Mini Truck / Tempo',
      'Heavy Truck',
      'JCB & Excavator',
      'Ambulance',
      'Driver on Demand',
      'Other / Custom',
    ],
    'Events': [
      'Event Planner',
      'Photographer & Videographer',
      'Catering Service',
      'DJ & Sound System',
      'Decoration & Lighting',
      'Makeup Artist',
      'Venue / Hall',
      'Other / Custom',
    ],
    'Shop': [
      'Grocery & Supermarket',
      'Electronics & Mobile',
      'Hardware & Sanitary',
      'Clothing & Fashion',
      'Medical & Pharmacy',
      'Furniture',
      'Stationery',
      'Other / Custom',
    ],
    'Rent': [
      'Flat / Apartment',
      'Independent House',
      'Room / PG',
      'Commercial Space / Shop',
      'Office',
      'Warehouse',
      'Other / Custom',
    ],
    'Delivery': [
      'Courier & Parcel',
      'Food Delivery',
      'Grocery Delivery',
      'Medicine Delivery',
      'Express Logistics',
      'Other / Custom',
    ],
    'Healthcare': [
      'Clinic & Doctor',
      'Nursing & Caretaker',
      'Diagnostic Lab',
      'Physiotherapy',
      'Other / Custom',
    ],
    'Education': [
      'Tutor / Coaching',
      'Music & Dance Classes',
      'Skill Training',
      'Other / Custom',
    ],
    'Automobile': [
      'Two-Wheeler Service',
      'Car Repair & Garage',
      'Tyre & Puncture',
      'Towing Service',
      'Other / Custom',
    ],
    'Other': [
      'General Service',
      'Specialist',
      'Other / Custom',
    ],
  };

  static const Map<String, String> _defaultCategoryImages = {
    'Home Maintenance': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    'Transport': 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=500',
    'Events': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=500',
    'Shop': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500',
    'Rent': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=500',
    'Delivery': 'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=500',
    'Healthcare': 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=500',
    'Education': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500',
    'Automobile': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=500',
    'Other': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=500',
  };

  void _showAddProviderDialog() {
    _showProviderFormDialog();
  }

  void _showEditProviderDialog(Map<String, dynamic> provider) {
    _showProviderFormDialog(provider: provider);
  }

  void _showProviderFormDialog({Map<String, dynamic>? provider}) {
    final isEditing = provider != null;
    final formKey = GlobalKey<FormState>();

    final bizNameCtrl = TextEditingController(
      text: provider?['business_name'] ?? provider?['full_name'] ?? '',
    );
    final ownerNameCtrl = TextEditingController(
      text: provider?['owner_name'] ?? provider?['full_name'] ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: provider?['phone'] ?? '',
    );
    final waCtrl = TextEditingController(
      text: provider?['whatsapp'] ?? provider?['whatsapp_number'] ?? provider?['phone'] ?? '',
    );
    final emailCtrl = TextEditingController(
      text: provider?['email'] ?? '',
    );
    final passwordCtrl = TextEditingController(
      text: isEditing ? '' : 'LocalConnect@123',
    );
    final customSubcatCtrl = TextEditingController();
    final cityCtrl = TextEditingController(
      text: provider?['city'] ?? (SupabaseService.instance.currentAdminArea != 'ALL' ? SupabaseService.instance.currentAdminArea : 'Roha'),
    );
    final addressCtrl = TextEditingController(
      text: provider?['address'] ?? provider?['business_address'] ?? '',
    );
    final expCtrl = TextEditingController(
      text: (provider?['years_experience'] ?? provider?['experience_years'] ?? 1).toString(),
    );

    bool obscurePassword = true;
    bool hasLoadedPassword = !isEditing;

    String selectedCategory = (provider?['category'] ?? 'Home Maintenance').toString();
    final validCategories = [
      'Home Maintenance',
      'Transport',
      'Events',
      'Shop',
      'Rent',
      'Delivery',
      'Healthcare',
      'Education',
      'Automobile',
      'Other',
    ];
    if (!validCategories.contains(selectedCategory)) {
      selectedCategory = validCategories.first;
    }

    final existingSubcat = (provider?['subcategory'] ?? '').toString().trim();
    final currentSubList = _categorySubcategoryMap[selectedCategory] ?? ['Other / Custom'];
    String selectedSubcategory = 'Other / Custom';
    if (existingSubcat.isNotEmpty) {
      if (currentSubList.contains(existingSubcat)) {
        selectedSubcategory = existingSubcat;
      } else {
        selectedSubcategory = 'Other / Custom';
        customSubcatCtrl.text = existingSubcat;
      }
    } else {
      selectedSubcategory = currentSubList.first;
    }

    final imageUrlCtrl = TextEditingController(
      text: provider?['image_url'] ?? provider?['cover_image_url'] ?? _defaultCategoryImages[selectedCategory] ?? '',
    );

    String selectedStatus = (provider?['status'] ?? provider?['registration_status'] ?? 'approved').toString().toLowerCase();
    final validStatuses = ['approved', 'pending', 'suspended', 'rejected'];
    if (!validStatuses.contains(selectedStatus)) {
      selectedStatus = 'approved';
    }

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!hasLoadedPassword) {
            hasLoadedPassword = true;
            SupabaseService.instance.adminGetUserPassword(
              userId: (provider?['user_id'] ?? provider?['id'] ?? '').toString(),
              email: provider?['email']?.toString(),
              phone: provider?['phone']?.toString(),
            ).then((pwd) {
              if (context.mounted) {
                setDialogState(() {
                  passwordCtrl.text = pwd;
                });
              }
            });
          }

          final availableSubcategories = _categorySubcategoryMap[selectedCategory] ?? ['Other / Custom'];
          if (!availableSubcategories.contains(selectedSubcategory)) {
            selectedSubcategory = availableSubcategories.first;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            actionsPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
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
                        isEditing ? 'Edit Provider Profile' : 'Register New Provider',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Update password, category, photo & details'
                            : 'Add service provider directly from admin panel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Contact Number Highlight Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2E7D32), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Primary Contact Number *',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'e.g. 9876543210',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF2E7D32)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFA5D6A7)),
                                ),
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Contact number is required';
                                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.length < 10) return 'Enter a valid 10-digit phone number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Account Password Box (View & Edit)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: Color(0xFFF57F17), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  isEditing ? 'Account Password (View & Change) *' : 'Set Account Password *',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                                const Spacer(),
                                if (passwordCtrl.text.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: passwordCtrl.text));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE65100)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFE65100),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: passwordCtrl,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: isEditing ? 'Loading password...' : 'Enter minimum 6 characters',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFFF57F17)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                                ),
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: obscurePassword ? 2.0 : 0.5,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Business Name & Owner Name
                      TextFormField(
                        controller: bizNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Business / Shop / Service Name *',
                          hintText: 'e.g. Roha Quick Plumbing Works',
                          prefixIcon: const Icon(Icons.storefront_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: ownerNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Owner / Contact Person Full Name *',
                          hintText: 'e.g. Ramesh Kumar',
                          prefixIcon: const Icon(Icons.person_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Owner name is required' : null,
                      ),
                      const SizedBox(height: 10),

                      // WhatsApp with "Copy phone" button
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: waCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'WhatsApp Number',
                                hintText: 'e.g. 9876543210',
                                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                waCtrl.text = phoneCtrl.text.trim();
                              });
                            },
                            child: Text(
                              'Same as\nPhone',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Email Address
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Provider Login ID)',
                          hintText: 'e.g. partner@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Service Category *',
                          prefixIcon: const Icon(Icons.category_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: validCategories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedCategory = v;
                              final subList = _categorySubcategoryMap[v] ?? ['Other / Custom'];
                              selectedSubcategory = subList.first;
                              // Update image if currently default or empty
                              if (imageUrlCtrl.text.isEmpty ||
                                  _defaultCategoryImages.values.contains(imageUrlCtrl.text)) {
                                imageUrlCtrl.text = _defaultCategoryImages[v] ?? '';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Dynamic Subcategory Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubcategory,
                        decoration: InputDecoration(
                          labelText: 'Subcategory / Specialization *',
                          prefixIcon: const Icon(Icons.build_circle_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: availableSubcategories.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedSubcategory = v);
                        },
                      ),
                      const SizedBox(height: 10),

                      // If 'Other / Custom' chosen, show custom subcategory input
                      if (selectedSubcategory == 'Other / Custom') ...[
                        TextFormField(
                          controller: customSubcatCtrl,
                          decoration: InputDecoration(
                            labelText: 'Enter Custom Subcategory / Trade *',
                            hintText: 'e.g. Solar Technician, Welder, CCTV Expert',
                            prefixIcon: const Icon(Icons.handyman_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) => (selectedSubcategory == 'Other / Custom' && (v == null || v.trim().isEmpty))
                              ? 'Please enter subcategory name'
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Business Photo / Image URL Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.add_photo_alternate_rounded, size: 16, color: Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  'Business & Work Photo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Thumbnail Preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey[200],
                                    child: imageUrlCtrl.text.isNotEmpty
                                        ? Image.network(
                                            imageUrlCtrl.text,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.broken_image_rounded,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.image_outlined,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: imageUrlCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Image URL',
                                      hintText: 'https://...',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      imageUrlCtrl.text = _defaultCategoryImages[selectedCategory] ?? '';
                                    });
                                  },
                                  child: Chip(
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    avatar: const Icon(Icons.auto_fix_high_rounded, size: 14),
                                    label: Text(
                                      'Auto Category Image',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // City / Operating Area & Experience
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: cityCtrl,
                              decoration: InputDecoration(
                                labelText: 'City / Service Area *',
                                hintText: 'e.g. Roha, Alibag, Pen',
                                prefixIcon: const Icon(Icons.location_city_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Area/City is required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: expCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Experience (Yrs)',
                                hintText: '1',
                                prefixIcon: const Icon(Icons.history_edu_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Shop / Full Address
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Shop / Full Address',
                          hintText: 'e.g. Shop No. 4, Market Road, Roha',
                          prefixIcon: const Icon(Icons.map_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Registration Status
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Account Status',
                          prefixIcon: const Icon(Icons.verified_user_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'approved', child: Text('Approved (Active)')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                          DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedStatus = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSubmitting = true);

                  final phone = phoneCtrl.text.trim();
                  final owner = ownerNameCtrl.text.trim();
                  final biz = bizNameCtrl.text.trim();
                  final wa = waCtrl.text.trim().isNotEmpty ? waCtrl.text.trim() : phone;
                  final email = emailCtrl.text.trim();
                  final effectiveSubcat = (selectedSubcategory == 'Other / Custom')
                      ? customSubcatCtrl.text.trim()
                      : selectedSubcategory;
                  final city = cityCtrl.text.trim();
                  final address = addressCtrl.text.trim();
                  final exp = int.tryParse(expCtrl.text.trim()) ?? 1;
                  final pwd = passwordCtrl.text.trim();
                  final imgUrl = imageUrlCtrl.text.trim();

                  if (isEditing) {
                    final providerId = (provider['id'] ?? '').toString();
                    final userId = (provider['user_id'] ?? '').toString();
                    final ok = await SupabaseService.instance.adminUpdateServiceProviderProfile(
                      providerId: providerId,
                      userId: userId,
                      businessName: biz,
                      ownerName: owner,
                      phone: phone,
                      whatsapp: wa,
                      email: email,
                      category: selectedCategory,
                      subcategory: effectiveSubcat,
                      city: city,
                      address: address,
                      imageUrl: imgUrl,
                      status: selectedStatus,
                      isActive: selectedStatus == 'approved',
                      isVerified: selectedStatus == 'approved',
                      experienceYears: exp,
                      password: pwd,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      if (ok) {
                        setState(() {
                          provider['business_name'] = biz;
                          provider['owner_name'] = owner;
                          provider['full_name'] = owner;
                          provider['phone'] = phone;
                          provider['whatsapp'] = wa;
                          provider['whatsapp_number'] = wa;
                          provider['email'] = email;
                          provider['category'] = selectedCategory;
                          provider['subcategory'] = effectiveSubcat;
                          provider['city'] = city;
                          provider['address'] = address;
                          provider['image_url'] = imgUrl;
                          provider['cover_image_url'] = imgUrl;
                          provider['business_logo_url'] = imgUrl;
                          provider['status'] = selectedStatus;
                          provider['registration_status'] = selectedStatus;
                          provider['experience_years'] = exp;
                          provider['years_experience'] = exp;
                          _applyFilters();
                        });
                        _showSnack('Provider profile & contact updated successfully!', AppTheme.success);
                        _loadProviders();
                      } else {
                        _showSnack('Failed to update provider profile', AppTheme.error);
                      }
                    }
                  } else {
                    final newProv = await SupabaseService.instance.adminCreateServiceProvider(
                      businessName: biz,
                      ownerName: owner,
                      phone: phone,
                      whatsapp: wa,
                      email: email,
                      category: selectedCategory,
                      subcategory: effectiveSubcat,
                      city: city,
                      address: address,
                      imageUrl: imgUrl,
                      experienceYears: exp,
                      status: selectedStatus,
                      isActive: selectedStatus == 'approved',
                      password: pwd,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      if (newProv != null) {
                        setState(() {
                          _providers.insert(0, newProv);
                          _applyFilters();
                        });

                        // Show Popup Confirmation Dialog to Admin
                        showDialog(
                          context: context,
                          builder: (popupCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Provider Registered!',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Provider has been registered under $selectedCategory and is now live on LocalConnect.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[800]),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _infoRow('Business', biz),
                                      _infoRow('Category', '$selectedCategory ($effectiveSubcat)'),
                                      _infoRow('Owner', owner),
                                      _infoRow('Phone', phone),
                                      _infoRow('Login Email', newProv['email'] ?? email),
                                      _infoRow('Password', pwd),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '💡 Provider can log in using these credentials to add services, update prices, and upload business photos.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy Credentials'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: 'LocalConnect Partner Login:\nBusiness: $biz\nCategory: $selectedCategory ($effectiveSubcat)\nEmail: ${newProv['email'] ?? email}\nPassword: $pwd',
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Login credentials copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(popupCtx),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        );

                        _loadProviders();
                      } else {
                        _showSnack('Failed to register provider', AppTheme.error);
                      }
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Register Provider',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
