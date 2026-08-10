import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class ToolsProviderDashboard extends StatefulWidget {
  const ToolsProviderDashboard({super.key});

  @override
  State<ToolsProviderDashboard> createState() => _ToolsProviderDashboardState();
}

class _ToolsProviderDashboardState extends State<ToolsProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _toolsColor = Color(0xFF2E7D32);

  final List<Map<String, dynamic>> _tools = [
    {
      'id': 't1',
      'name': 'Bosch Drill Machine',
      'brand': 'Bosch',
      'model': 'GSB 550',
      'category': 'Power Tools',
      'condition': 'Excellent',
      'quantity': 3,
      'hourlyRate': 50,
      'dailyRate': 200,
      'weeklyRate': 1000,
      'monthlyRate': 3500,
      'deposit': 1000,
      'delivery': true,
      'available': true,
      'image':
          'https://images.pexels.com/photos/1249611/pexels-photo-1249611.jpeg',
    },
    {
      'id': 't2',
      'name': 'Concrete Mixer',
      'brand': 'Generic',
      'model': 'CM-200',
      'category': 'Construction',
      'condition': 'Good',
      'quantity': 1,
      'hourlyRate': 150,
      'dailyRate': 800,
      'weeklyRate': 4000,
      'monthlyRate': 12000,
      'deposit': 3000,
      'delivery': false,
      'available': true,
      'image':
          'https://images.pexels.com/photos/159306/construction-site-build-construction-work-159306.jpeg',
    },
    {
      'id': 't3',
      'name': 'Pressure Washer',
      'brand': 'Karcher',
      'model': 'K5',
      'category': 'Cleaning',
      'condition': 'Excellent',
      'quantity': 2,
      'hourlyRate': 100,
      'dailyRate': 500,
      'weeklyRate': 2500,
      'monthlyRate': 8000,
      'deposit': 2000,
      'delivery': true,
      'available': false,
      'image':
          'https://images.pexels.com/photos/4239031/pexels-photo-4239031.jpeg',
    },
  ];

  final List<Map<String, dynamic>> _rentals = [
    {
      'customer': 'Suresh Patil',
      'tool': 'Bosch Drill Machine',
      'duration': '3 days',
      'status': 'Active',
      'amount': 600,
      'returnDate': '2026-07-05',
    },
    {
      'customer': 'Ramesh Kumar',
      'tool': 'Pressure Washer',
      'duration': '1 day',
      'status': 'Pending',
      'amount': 500,
      'returnDate': '2026-07-08',
    },
    {
      'customer': 'Vijay Singh',
      'tool': 'Concrete Mixer',
      'duration': '1 week',
      'status': 'Completed',
      'amount': 4000,
      'returnDate': '2026-06-28',
    },
  ];

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Power Tools',
    'Construction',
    'Cleaning',
    'Gardening',
    'Automotive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _toolsColor,
        title: Text(
          'Tools & Equipment Rental',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
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
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.loginScreen,
              (_) => false,
            ),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'My Tools'),
            Tab(text: 'Rentals'),
            Tab(text: 'Earnings'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddToolSheet(context),
              backgroundColor: _toolsColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add Tool',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildToolsTab(),
          _buildRentalsTab(),
          _buildEarningsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final activeRentals = _rentals.where((r) => r['status'] == 'Active').length;
    final totalRevenue = _rentals.fold(0, (s, r) => s + (r['amount'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_toolsColor, _toolsColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Revenue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        '₹$totalRevenue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniChip('$activeRentals Active'),
                          const SizedBox(width: 8),
                          _miniChip('${_tools.length} Tools'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.build_rounded, color: Colors.white, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard(
                'Total Tools',
                '${_tools.length}',
                Icons.build_rounded,
                _toolsColor,
              ),
              _statCard(
                'Available',
                '${_tools.where((t) => t['available'] == true).length}',
                Icons.check_circle_rounded,
                AppTheme.success,
              ),
              _statCard(
                'Active Rentals',
                '$activeRentals',
                Icons.handshake_rounded,
                AppTheme.warning,
              ),
              _statCard(
                'Pending Returns',
                '${_rentals.where((r) => r['status'] == 'Active').length}',
                Icons.assignment_return_rounded,
                AppTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Rentals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._rentals.take(2).map((r) => _buildRentalCard(r)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Chat',
                  Icons.chat_rounded,
                  () => Navigator.pushNamed(context, AppRoutes.chatListScreen),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  'Subscription',
                  Icons.workspace_premium_rounded,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.providerSubscriptionScreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    final filtered = _selectedCategory == 'All'
        ? _tools
        : _tools.where((t) => t['category'] == _selectedCategory).toList();

    return Column(
      children: [
        Container(
          height: 48,
          color: AppTheme.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _toolsColor : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _toolsColor : AppTheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildToolCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final isAvailable = tool['available'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  tool['image'] as String,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel:
                      '${tool['name']} - ${tool['brand']} tool for rent',
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: _toolsColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.build_rounded,
                      size: 40,
                      color: _toolsColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.success : AppTheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Rented Out',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tool['category'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${tool['brand']} • ${tool['model']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${tool['dailyRate']}/day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _toolsColor,
                          ),
                        ),
                        Text(
                          '₹${tool['hourlyRate']}/hr',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(
                      'Qty: ${tool['quantity']}',
                      Icons.inventory_rounded,
                    ),
                    const SizedBox(width: 6),
                    _infoChip(tool['condition'] as String, Icons.star_rounded),
                    const SizedBox(width: 6),
                    if (tool['delivery'] == true)
                      _infoChip('Delivery', Icons.local_shipping_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditToolSheet(context, tool),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _toolsColor,
                          side: BorderSide(color: _toolsColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => tool['available'] = !isAvailable),
                        icon: Icon(
                          isAvailable
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 14,
                        ),
                        label: Text(isAvailable ? 'Pause' : 'Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable
                              ? AppTheme.warning
                              : _toolsColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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

  Widget _buildRentalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Rental History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._rentals.map((r) => _buildRentalCard(r)),
      ],
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final statusColors = {
      'Active': AppTheme.success,
      'Pending': AppTheme.warning,
      'Completed': AppTheme.primary,
    };
    final color = statusColors[rental['status']] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental['customer'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rental['tool'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rental['status'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${rental['amount']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _toolsColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_rounded, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                rental['duration'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.assignment_return_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Return: ${rental['returnDate']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_toolsColor, _toolsColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  '₹28,500',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniChip('This Month: ₹5,100'),
                    const SizedBox(width: 8),
                    _miniChip('Pending: ₹500'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Rental Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._tools.map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _toolsColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.build_rounded,
                      color: _toolsColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '₹${t['dailyRate']}/day • ${t['quantity']} units',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(t['dailyRate'] as int) * 5}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _toolsColor,
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

  Widget _infoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _toolsColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _toolsColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _toolsColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: _toolsColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _toolsColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _toolsColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _toolsColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _toolsColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToolSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final dailyRateCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Tool',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Tool Name',
                  prefixIcon: const Icon(
                    Icons.build_rounded,
                    size: 18,
                    color: _toolsColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _toolsColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: brandCtrl,
                decoration: InputDecoration(
                  hintText: 'Brand',
                  prefixIcon: const Icon(
                    Icons.branding_watermark_rounded,
                    size: 18,
                    color: _toolsColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _toolsColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dailyRateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Daily Rate (₹)',
                  prefixIcon: const Icon(
                    Icons.currency_rupee_rounded,
                    size: 18,
                    color: _toolsColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _toolsColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        _tools.add({
                          'id': 't${_tools.length + 1}',
                          'name': nameCtrl.text,
                          'brand': brandCtrl.text.isEmpty
                              ? 'Unknown'
                              : brandCtrl.text,
                          'model': '-',
                          'category': 'Power Tools',
                          'condition': 'Good',
                          'quantity': 1,
                          'hourlyRate': 50,
                          'dailyRate': int.tryParse(dailyRateCtrl.text) ?? 200,
                          'weeklyRate': 1000,
                          'monthlyRate': 3500,
                          'deposit': 500,
                          'delivery': false,
                          'available': true,
                          'image':
                              'https://images.pexels.com/photos/1249611/pexels-photo-1249611.jpeg',
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _toolsColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Tool',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditToolSheet(BuildContext context, Map<String, dynamic> tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit: ${tool['name']}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _toolsColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
