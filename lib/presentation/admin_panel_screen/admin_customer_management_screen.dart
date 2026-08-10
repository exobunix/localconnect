import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class AdminCustomerManagementScreen extends StatefulWidget {
  const AdminCustomerManagementScreen({super.key});

  @override
  State<AdminCustomerManagementScreen> createState() =>
      _AdminCustomerManagementScreenState();
}

class _AdminCustomerManagementScreenState
    extends State<AdminCustomerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  String _searchQuery = '';
  String _statusFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  // Mock data
  final List<Map<String, dynamic>> _mockCustomers = [
    {
      'id': 'c1',
      'full_name': 'Amit Sharma',
      'email': 'amit.sharma@example.com',
      'phone': '+91 98765 43210',
      'city': 'Roha',
      'status': 'active',
      'joined': '2026-01-15',
      'total_bookings': 12,
      'total_deliveries': 5,
      'total_spent': 8450.0,
      'wallet_balance': 320.0,
      'complaints': 1,
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    },
    {
      'id': 'c2',
      'full_name': 'Priya Patil',
      'email': 'priya.patil@example.com',
      'phone': '+91 87654 32109',
      'city': 'Alibag',
      'status': 'active',
      'joined': '2026-02-20',
      'total_bookings': 8,
      'total_deliveries': 14,
      'total_spent': 12300.0,
      'wallet_balance': 750.0,
      'complaints': 0,
      'avatar':
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?w=100&h=100&fit=crop',
    },
    {
      'id': 'c3',
      'full_name': 'Rahul Desai',
      'email': 'rahul.desai@example.com',
      'phone': '+91 76543 21098',
      'city': 'Nagothane',
      'status': 'suspended',
      'joined': '2026-03-10',
      'total_bookings': 3,
      'total_deliveries': 2,
      'total_spent': 2100.0,
      'wallet_balance': 0.0,
      'complaints': 3,
      'avatar':
          'https://images.pixabay.com/photo/2016/11/21/12/42/beard-1845166_960_720.jpg',
    },
    {
      'id': 'c4',
      'full_name': 'Sunita Jadhav',
      'email': 'sunita.jadhav@example.com',
      'phone': '+91 65432 10987',
      'city': 'Pen',
      'status': 'active',
      'joined': '2026-04-05',
      'total_bookings': 20,
      'total_deliveries': 9,
      'total_spent': 18900.0,
      'wallet_balance': 1200.0,
      'complaints': 0,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_10b6710ab-1770236998594.png',
    },
    {
      'id': 'c5',
      'full_name': 'Vijay More',
      'email': 'vijay.more@example.com',
      'phone': '+91 54321 09876',
      'city': 'Mumbai',
      'status': 'active',
      'joined': '2026-05-12',
      'total_bookings': 6,
      'total_deliveries': 22,
      'total_spent': 9800.0,
      'wallet_balance': 450.0,
      'complaints': 1,
      'avatar':
          'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?w=100&h=100&fit=crop',
    },
    {
      'id': 'c6',
      'full_name': 'Kavita Kulkarni',
      'email': 'kavita.kulkarni@example.com',
      'phone': '+91 43210 98765',
      'city': 'Pune',
      'status': 'inactive',
      'joined': '2026-06-01',
      'total_bookings': 1,
      'total_deliveries': 0,
      'total_spent': 500.0,
      'wallet_balance': 100.0,
      'complaints': 0,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_119e61325-1779003286076.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAdminAllUsers();
      final customers = data.where((u) => u['role'] == 'customer').toList();
      if (mounted) {
        setState(() {
          _customers = customers.isNotEmpty ? customers : _mockCustomers;
          _filteredCustomers = _customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customers = _mockCustomers;
          _filteredCustomers = _mockCustomers;
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final name = (c['full_name'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final status = (c['status'] ?? 'active').toString();
        final matchesSearch =
            _searchQuery.isEmpty ||
            name.contains(_searchQuery.toLowerCase()) ||
            email.contains(_searchQuery.toLowerCase()) ||
            phone.contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.success;
      case 'suspended':
        return AppTheme.error;
      case 'inactive':
        return AppTheme.outline;
      default:
        return AppTheme.outline;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successContainer;
      case 'suspended':
        return AppTheme.errorContainer;
      case 'inactive':
        return AppTheme.surfaceVariant;
      default:
        return AppTheme.surfaceVariant;
    }
  }

  void _showCustomerDetail(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: customer),
    );
  }

  Future<void> _suspendCustomer(Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Suspend Customer',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to suspend ${customer['full_name']}? They will lose access to the platform.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Suspend',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SupabaseService.instance.adminToggleUserStatus(
          userId: customer['id'],
          isActive: false,
        );
      } catch (_) {}
      setState(() {
        final idx = _customers.indexWhere((c) => c['id'] == customer['id']);
        if (idx != -1) _customers[idx]['status'] = 'suspended';
        _applyFilters();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${customer['full_name']} has been suspended.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _reactivateCustomer(Map<String, dynamic> customer) async {
    try {
      await SupabaseService.instance.adminToggleUserStatus(
        userId: customer['id'],
        isActive: true,
      );
    } catch (_) {}
    setState(() {
      final idx = _customers.indexWhere((c) => c['id'] == customer['id']);
      if (idx != -1) _customers[idx]['status'] = 'active';
      _applyFilters();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${customer['full_name']} has been reactivated.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Customer',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete ${customer['full_name']}\'s account and all associated data. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _customers.removeWhere((c) => c['id'] == customer['id']);
        _applyFilters();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${customer['full_name']} has been deleted.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _sendNotification(Map<String, dynamic> customer) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Notification',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To: ${customer['full_name']}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notification message...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.outline,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notification sent to ${customer['full_name']}.',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Send',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _customers
        .where((c) => (c['status'] ?? 'active') == 'active')
        .length;
    final suspendedCount = _customers
        .where((c) => (c['status'] ?? 'active') == 'suspended')
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Customer Management',
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
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
          tabs: const [
            Tab(text: 'All Customers'),
            Tab(text: 'Active'),
            Tab(text: 'Suspended'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StatPill(
                  label: 'Total',
                  value: '${_customers.length}',
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Active',
                  value: '$activeCount',
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Suspended',
                  value: '$suspendedCount',
                  color: AppTheme.error,
                ),
                const Spacer(),
                Text(
                  '${_filteredCustomers.length} shown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          // Search + filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or phone...',
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspended', 'suspended'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive', 'inactive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerList(_filteredCustomers),
                _buildCustomerList(
                  _filteredCustomers
                      .where((c) => (c['status'] ?? 'active') == 'active')
                      .toList(),
                ),
                _buildCustomerList(
                  _filteredCustomers
                      .where((c) => (c['status'] ?? 'active') == 'suspended')
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        _statusFilter = value;
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
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

  Widget _buildCustomerList(List<Map<String, dynamic>> list) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: AppTheme.outline.withAlpha(128),
            ),
            const SizedBox(height: 12),
            Text(
              'No customers found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CustomerCard(
        customer: list[i],
        statusColor: _statusColor(list[i]['status'] ?? 'active'),
        statusBg: _statusBg(list[i]['status'] ?? 'active'),
        onTap: () => _showCustomerDetail(list[i]),
        onSuspend: () => _suspendCustomer(list[i]),
        onReactivate: () => _reactivateCustomer(list[i]),
        onDelete: () => _deleteCustomer(list[i]),
        onNotify: () => _sendNotification(list[i]),
      ),
    );
  }
}

// ── Customer Card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onTap;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final VoidCallback onNotify;

  const _CustomerCard({
    required this.customer,
    required this.statusColor,
    required this.statusBg,
    required this.onTap,
    required this.onSuspend,
    required this.onReactivate,
    required this.onDelete,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    final status = customer['status'] ?? 'active';
    final isSuspended = status == 'suspended';
    final complaints = (customer['complaints'] ?? 0) as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryContainer,
                    backgroundImage: customer['avatar'] != null
                        ? NetworkImage(customer['avatar'])
                        : null,
                    child: customer['avatar'] == null
                        ? Text(
                            (customer['full_name'] ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer['full_name'] ?? 'Unknown',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1C1E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer['email'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppTheme.outline,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              customer['city'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: AppTheme.outline,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              customer['phone'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  _MiniStat(
                    icon: Icons.calendar_today_rounded,
                    label: '${customer['total_bookings'] ?? 0} Bookings',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    icon: Icons.delivery_dining_rounded,
                    label: '${customer['total_deliveries'] ?? 0} Deliveries',
                    color: AppTheme.catDelivery,
                  ),
                  const SizedBox(width: 12),
                  if (complaints > 0)
                    _MiniStat(
                      icon: Icons.report_problem_rounded,
                      label: '$complaints Complaints',
                      color: AppTheme.error,
                    ),
                  const Spacer(),
                  // Action buttons
                  _ActionIconBtn(
                    icon: Icons.notifications_rounded,
                    color: AppTheme.primary,
                    tooltip: 'Send Notification',
                    onTap: onNotify,
                  ),
                  const SizedBox(width: 4),
                  if (isSuspended)
                    _ActionIconBtn(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                      tooltip: 'Reactivate',
                      onTap: onReactivate,
                    )
                  else
                    _ActionIconBtn(
                      icon: Icons.block_rounded,
                      color: AppTheme.warning,
                      tooltip: 'Suspend',
                      onTap: onSuspend,
                    ),
                  const SizedBox(width: 4),
                  _ActionIconBtn(
                    icon: Icons.delete_rounded,
                    color: AppTheme.error,
                    tooltip: 'Delete',
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer Detail Bottom Sheet ──────────────────────────────────────────────
class _CustomerDetailSheet extends StatefulWidget {
  final Map<String, dynamic> customer;
  const _CustomerDetailSheet({required this.customer});

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Mock booking history
  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'BK001',
      'service': 'Plumbing Repair',
      'provider': 'Ravi Kumar',
      'date': '2026-06-20',
      'amount': 850.0,
      'status': 'completed',
    },
    {
      'id': 'BK002',
      'service': 'Electrical Work',
      'provider': 'Mohan Electricals',
      'date': '2026-06-10',
      'amount': 1200.0,
      'status': 'completed',
    },
    {
      'id': 'BK003',
      'service': 'House Painting',
      'provider': 'Painter Pro',
      'date': '2026-05-28',
      'amount': 4500.0,
      'status': 'cancelled',
    },
  ];

  // Mock delivery history
  final List<Map<String, dynamic>> _deliveries = [
    {
      'id': 'DL001',
      'item': 'Grocery Package',
      'from': 'Roha Market',
      'to': 'Home',
      'date': '2026-06-22',
      'amount': 80.0,
      'status': 'delivered',
    },
    {
      'id': 'DL002',
      'item': 'Medicine',
      'from': 'City Pharmacy',
      'to': 'Office',
      'date': '2026-06-15',
      'amount': 50.0,
      'status': 'delivered',
    },
  ];

  // Mock complaints
  final List<Map<String, dynamic>> _complaints = [
    {
      'id': 'CP001',
      'subject': 'Late service delivery',
      'provider': 'Ravi Kumar',
      'date': '2026-06-21',
      'status': 'resolved',
    },
  ];

  // Mock wallet/payment records
  final List<Map<String, dynamic>> _payments = [
    {
      'id': 'TXN001',
      'type': 'credit',
      'description': 'Wallet Top-up',
      'amount': 500.0,
      'date': '2026-06-18',
      'method': 'UPI',
    },
    {
      'id': 'TXN002',
      'type': 'debit',
      'description': 'Plumbing Repair Payment',
      'amount': 850.0,
      'date': '2026-06-20',
      'method': 'Wallet',
    },
    {
      'id': 'TXN003',
      'type': 'credit',
      'description': 'Refund - Cancelled Booking',
      'amount': 200.0,
      'date': '2026-05-29',
      'method': 'Refund',
    },
    {
      'id': 'TXN004',
      'type': 'debit',
      'description': 'Delivery Charge',
      'amount': 80.0,
      'date': '2026-06-22',
      'method': 'UPI',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final status = customer['status'] ?? 'active';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryContainer,
                    backgroundImage: customer['avatar'] != null
                        ? NetworkImage(customer['avatar'])
                        : null,
                    child: customer['avatar'] == null
                        ? Text(
                            (customer['full_name'] ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['full_name'] ?? 'Unknown',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          customer['email'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.outline,
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
                      color: status == 'active'
                          ? AppTheme.successContainer
                          : status == 'suspended'
                          ? AppTheme.errorContainer
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: status == 'active'
                            ? AppTheme.success
                            : status == 'suspended'
                            ? AppTheme.error
                            : AppTheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // KPI row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _KpiCard(
                    label: 'Bookings',
                    value: '${customer['total_bookings'] ?? 0}',
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'Deliveries',
                    value: '${customer['total_deliveries'] ?? 0}',
                    icon: Icons.delivery_dining_rounded,
                    color: AppTheme.catDelivery,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'Spent',
                    value:
                        '₹${(customer['total_spent'] ?? 0.0).toStringAsFixed(0)}',
                    icon: Icons.currency_rupee_rounded,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _KpiCard(
                    label: 'Wallet',
                    value:
                        '₹${(customer['wallet_balance'] ?? 0.0).toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.outlineVariant),
                ),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.outline,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Bookings'),
                  Tab(text: 'Deliveries'),
                  Tab(text: 'Complaints'),
                  Tab(text: 'Payments'),
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildBookingHistory(),
                  _buildDeliveryHistory(),
                  _buildComplaints(),
                  _buildPayments(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHistory() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final b = _bookings[i];
        final isCompleted = b['status'] == 'completed';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.successContainer
                      : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 18,
                  color: isCompleted ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['service'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${b['provider']} • ${b['date']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${b['amount'].toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    b['id'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHistory() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _deliveries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final d = _deliveries[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  size: 18,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['item'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${d['from']} → ${d['to']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                    Text(
                      d['date'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${d['amount'].toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.catDelivery,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d['status'].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaints() {
    if (_complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppTheme.success,
            ),
            const SizedBox(height: 8),
            Text(
              'No complaints filed',
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
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _complaints[i];
        final isResolved = c['status'] == 'resolved';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isResolved
                  ? AppTheme.successContainer
                  : AppTheme.errorContainer,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppTheme.successContainer
                      : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  size: 18,
                  color: isResolved ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['subject'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Against: ${c['provider']} • ${c['date']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppTheme.successContainer
                      : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c['status'].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isResolved ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayments() {
    final totalCredit = _payments
        .where((p) => p['type'] == 'credit')
        .fold(0.0, (sum, p) => sum + (p['amount'] as double));
    final totalDebit = _payments
        .where((p) => p['type'] == 'debit')
        .fold(0.0, (sum, p) => sum + (p['amount'] as double));

    return Column(
      children: [
        // Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Credits',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₹${totalCredit.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Total Debits',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₹${totalDebit.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Wallet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '₹${(widget.customer['wallet_balance'] ?? 0.0).toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Transaction list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = _payments[i];
              final isCredit = p['type'] == 'credit';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? AppTheme.successContainer
                            : AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCredit
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 16,
                        color: isCredit ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['description'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${p['method']} • ${p['date']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}₹${(p['amount'] as double).toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCredit ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
