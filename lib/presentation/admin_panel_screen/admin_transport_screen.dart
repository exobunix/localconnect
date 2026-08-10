import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_export.dart';

class AdminTransportScreen extends StatefulWidget {
  const AdminTransportScreen({super.key});

  @override
  State<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends State<AdminTransportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedVehicleFilter = 0;

  final List<String> _vehicleFilters = [
    'All',
    'Auto Rickshaw',
    'Tempo',
    'Pickup Van',
    'Truck',
    'Car',
  ];

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'Rajesh Kumar',
      'vehicle': 'Auto Rickshaw',
      'vehicleNo': 'MH12AB1234',
      'status': 'pending',
      'rating': 4.5,
      'trips': 0,
      'joined': '2 days ago',
      'phone': '+91 98765 43210',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'docs': ['Aadhar', 'License', 'RC Book'],
      'subscription': 'None',
    },
    {
      'name': 'Suresh Patil',
      'vehicle': 'Tempo',
      'vehicleNo': 'MH14CD5678',
      'status': 'approved',
      'rating': 4.8,
      'trips': 142,
      'joined': '6 months ago',
      'phone': '+91 87654 32109',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      'docs': ['Aadhar', 'License', 'RC Book', 'Insurance'],
      'subscription': 'Premium',
    },
    {
      'name': 'Amit Sharma',
      'vehicle': 'Truck',
      'vehicleNo': 'MH04EF9012',
      'status': 'pending',
      'rating': 0.0,
      'trips': 0,
      'joined': '1 day ago',
      'phone': '+91 76543 21098',
      'avatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      'docs': ['Aadhar', 'License'],
      'subscription': 'None',
    },
    {
      'name': 'Priya Desai',
      'vehicle': 'Car',
      'vehicleNo': 'MH01GH3456',
      'status': 'approved',
      'rating': 4.9,
      'trips': 287,
      'joined': '1 year ago',
      'phone': '+91 65432 10987',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
      'docs': ['Aadhar', 'License', 'RC Book', 'Insurance', 'Permit'],
      'subscription': 'Basic',
    },
    {
      'name': 'Vikram Singh',
      'vehicle': 'Pickup Van',
      'vehicleNo': 'MH20IJ7890',
      'status': 'rejected',
      'rating': 3.2,
      'trips': 18,
      'joined': '3 months ago',
      'phone': '+91 54321 09876',
      'avatar':
          'https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=100',
      'docs': ['Aadhar', 'License'],
      'subscription': 'None',
    },
    {
      'name': 'Mohan Yadav',
      'vehicle': 'Auto Rickshaw',
      'vehicleNo': 'MH06KL2345',
      'status': 'approved',
      'rating': 4.6,
      'trips': 523,
      'joined': '2 years ago',
      'phone': '+91 43210 98765',
      'avatar':
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100',
      'docs': ['Aadhar', 'License', 'RC Book', 'Insurance'],
      'subscription': 'Premium',
    },
  ];

  final List<Map<String, dynamic>> _quotations = [
    {
      'id': 'QT-2024-001',
      'customer': 'Anita Mehta',
      'route': 'Andheri → Bandra',
      'vehicle': 'Tempo',
      'bids': 3,
      'status': 'active',
      'time': '10 min ago',
      'amount': '₹850–₹1,200',
    },
    {
      'id': 'QT-2024-002',
      'customer': 'Ravi Joshi',
      'route': 'Thane → Navi Mumbai',
      'vehicle': 'Truck',
      'bids': 2,
      'status': 'confirmed',
      'time': '25 min ago',
      'amount': '₹3,500',
    },
    {
      'id': 'QT-2024-003',
      'customer': 'Sunita Rao',
      'route': 'Dadar → Kurla',
      'vehicle': 'Pickup Van',
      'bids': 5,
      'status': 'active',
      'time': '5 min ago',
      'amount': '₹600–₹900',
    },
    {
      'id': 'QT-2024-004',
      'customer': 'Deepak Nair',
      'route': 'Borivali → Goregaon',
      'vehicle': 'Auto Rickshaw',
      'bids': 1,
      'status': 'expired',
      'time': '2 hrs ago',
      'amount': '₹180',
    },
    {
      'id': 'QT-2024-005',
      'customer': 'Kavita Patel',
      'route': 'Malad → Kandivali',
      'vehicle': 'Car',
      'bids': 4,
      'status': 'confirmed',
      'time': '1 hr ago',
      'amount': '₹320',
    },
  ];

  final List<Map<String, dynamic>> _subscriptions = [
    {
      'provider': 'Suresh Patil',
      'vehicle': 'Tempo',
      'plan': 'Premium',
      'amount': '₹999/mo',
      'status': 'active',
      'renewal': '15 Jul 2024',
      'color': const Color(0xFF7C3AED),
    },
    {
      'provider': 'Priya Desai',
      'vehicle': 'Car',
      'plan': 'Basic',
      'amount': '₹499/mo',
      'status': 'active',
      'renewal': '22 Jul 2024',
      'color': const Color(0xFF0284C7),
    },
    {
      'provider': 'Mohan Yadav',
      'vehicle': 'Auto Rickshaw',
      'plan': 'Premium',
      'amount': '₹999/mo',
      'status': 'active',
      'renewal': '8 Jul 2024',
      'color': const Color(0xFF7C3AED),
    },
    {
      'provider': 'Amit Sharma',
      'vehicle': 'Truck',
      'plan': 'Basic',
      'amount': '₹499/mo',
      'status': 'expired',
      'renewal': '1 Jun 2024',
      'color': const Color(0xFF0284C7),
    },
    {
      'provider': 'Vikram Singh',
      'vehicle': 'Pickup Van',
      'plan': 'None',
      'amount': '—',
      'status': 'inactive',
      'renewal': '—',
      'color': const Color(0xFF64748B),
    },
  ];

  final List<Map<String, dynamic>> _performanceData = [
    {
      'name': 'Priya Desai',
      'vehicle': 'Car',
      'trips': 287,
      'rating': 4.9,
      'earnings': '₹1,24,500',
      'completion': 98,
      'cancellation': 2,
      'badge': 'Top Performer',
      'badgeColor': const Color(0xFFD97706),
    },
    {
      'name': 'Mohan Yadav',
      'vehicle': 'Auto Rickshaw',
      'trips': 523,
      'rating': 4.6,
      'earnings': '₹89,200',
      'completion': 95,
      'cancellation': 5,
      'badge': 'Reliable',
      'badgeColor': const Color(0xFF059669),
    },
    {
      'name': 'Suresh Patil',
      'vehicle': 'Tempo',
      'trips': 142,
      'rating': 4.8,
      'earnings': '₹2,18,000',
      'completion': 97,
      'cancellation': 3,
      'badge': 'Top Performer',
      'badgeColor': const Color(0xFFD97706),
    },
    {
      'name': 'Vikram Singh',
      'vehicle': 'Pickup Van',
      'trips': 18,
      'rating': 3.2,
      'earnings': '₹12,400',
      'completion': 72,
      'cancellation': 28,
      'badge': 'At Risk',
      'badgeColor': const Color(0xFFDC2626),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProvidersTab(),
                  _buildVehicleRegistrationsTab(),
                  _buildQuotationsTab(),
                  _buildSubscriptionsTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transport Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage all transport operations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          _buildStatChip(Icons.pending_rounded, '3', const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildStatChip(
            Icons.local_shipping_rounded,
            '12',
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0D1B3E),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Providers'),
          Tab(text: 'Vehicles'),
          Tab(text: 'Quotations'),
          Tab(text: 'Subscriptions'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  // ── TAB 1: Providers ──────────────────────────────────────────────────────

  Widget _buildProvidersTab() {
    final filtered = _selectedVehicleFilter == 0
        ? _providers
        : _providers
              .where(
                (p) => p['vehicle'] == _vehicleFilters[_selectedVehicleFilter],
              )
              .toList();

    return Column(
      children: [
        _buildVehicleFilterChips(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildProviderCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleFilterChips() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _vehicleFilters.length,
        itemBuilder: (context, i) {
          final selected = _selectedVehicleFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedVehicleFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF0D1B3E)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0D1B3E)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                _vehicleFilters[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final status = provider['status'] as String;
    final statusColor = status == 'approved'
        ? const Color(0xFF059669)
        : status == 'pending'
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);
    final statusBg = status == 'approved'
        ? const Color(0xFFD1FAE5)
        : status == 'pending'
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    provider['avatar'] as String,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF94A3B8),
                      ),
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
                              provider['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
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
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildVehicleIcon(provider['vehicle'] as String),
                          const SizedBox(width: 6),
                          Text(
                            '${provider['vehicle']} • ${provider['vehicleNo']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (provider['rating'] > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${provider['rating']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${provider['trips']} trips',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Joined ${provider['joined']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
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
          // Documents row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.description_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (provider['docs'] as List).join(' • '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showActionDialog(provider, 'reject'),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      label: Text(
                        'Reject',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFF1F5F9),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showActionDialog(provider, 'approve'),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFF059669),
                      ),
                      label: Text(
                        'Approve',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
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

  Widget _buildVehicleIcon(String vehicle) {
    IconData icon;
    Color color;
    switch (vehicle) {
      case 'Auto Rickshaw':
        icon = Icons.electric_rickshaw_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'Tempo':
        icon = Icons.airport_shuttle_rounded;
        color = const Color(0xFF7C3AED);
        break;
      case 'Pickup Van':
        icon = Icons.local_shipping_rounded;
        color = const Color(0xFF0284C7);
        break;
      case 'Truck':
        icon = Icons.fire_truck_rounded;
        color = const Color(0xFFDC2626);
        break;
      case 'Car':
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF059669);
        break;
      default:
        icon = Icons.commute_rounded;
        color = const Color(0xFF64748B);
    }
    return Icon(icon, size: 14, color: color);
  }

  void _showActionDialog(Map<String, dynamic> provider, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          action == 'approve' ? 'Approve Provider' : 'Reject Provider',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          action == 'approve'
              ? 'Approve ${provider['name']} as a verified transport provider?'
              : 'Reject ${provider['name']}\'s application? They will be notified.',
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
                final idx = _providers.indexOf(provider);
                if (idx != -1) {
                  _providers[idx] = {
                    ...provider,
                    'status': action == 'approve' ? 'approved' : 'rejected',
                  };
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    action == 'approve'
                        ? '${provider['name']} approved successfully'
                        : '${provider['name']} application rejected',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: action == 'approve'
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve'
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              action == 'approve' ? 'Approve' : 'Reject',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Vehicle Registrations ──────────────────────────────────────────

  Widget _buildVehicleRegistrationsTab() {
    final pendingProviders = _providers
        .where((p) => p['status'] == 'pending')
        .toList();
    final approvedProviders = _providers
        .where((p) => p['status'] == 'approved')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          'Pending Registrations',
          pendingProviders.length,
          const Color(0xFFF59E0B),
        ),
        ...pendingProviders.map(
          (p) => _buildVehicleRegCard(p, isPending: true),
        ),
        const SizedBox(height: 8),
        _buildSectionHeader(
          'Approved Vehicles',
          approvedProviders.length,
          const Color(0xFF059669),
        ),
        ...approvedProviders.map(
          (p) => _buildVehicleRegCard(p, isPending: false),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRegCard(
    Map<String, dynamic> provider, {
    required bool isPending,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPending
            ? Border.all(color: const Color(0xFFFEF3C7), width: 1.5)
            : null,
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
              _buildVehicleIcon(provider['vehicle'] as String),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider['vehicleNo'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${provider['vehicle']} • ${provider['name']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showActionDialog(provider, 'reject'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showActionDialog(provider, 'approve'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (provider['docs'] as List<String>).map((doc) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 10,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Quotations ─────────────────────────────────────────────────────

  Widget _buildQuotationsTab() {
    return Column(
      children: [
        _buildQuotationSummaryBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _quotations.length,
            itemBuilder: (context, i) => _buildQuotationCard(_quotations[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationSummaryBar() {
    final active = _quotations.where((q) => q['status'] == 'active').length;
    final confirmed = _quotations
        .where((q) => q['status'] == 'confirmed')
        .length;
    final expired = _quotations.where((q) => q['status'] == 'expired').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _buildQuotStat('Active', active, const Color(0xFF3B82F6)),
          _buildQuotStat('Confirmed', confirmed, const Color(0xFF059669)),
          _buildQuotStat('Expired', expired, const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildQuotStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> q) {
    final status = q['status'] as String;
    final statusColor = status == 'active'
        ? const Color(0xFF3B82F6)
        : status == 'confirmed'
        ? const Color(0xFF059669)
        : const Color(0xFF94A3B8);
    final statusBg = status == 'active'
        ? const Color(0xFFEFF6FF)
        : status == 'confirmed'
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                q['id'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B3E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 13,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                q['customer'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              _buildVehicleIcon(q['vehicle'] as String),
              const SizedBox(width: 4),
              Text(
                q['vehicle'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 13,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  q['route'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${q['bids']} bids',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                q['amount'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1B3E),
                ),
              ),
              const Spacer(),
              Text(
                q['time'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 4: Subscriptions ──────────────────────────────────────────────────

  Widget _buildSubscriptionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSubscriptionRevenueCard(),
        const SizedBox(height: 16),
        Text(
          'Provider Subscriptions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ..._subscriptions.map((s) => _buildSubscriptionCard(s)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSubscriptionRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Revenue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹14,970',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'This month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSubStat('Active', '3', Colors.white),
              _buildSubStat(
                'Expired',
                '1',
                Colors.white.withValues(alpha: 0.7),
              ),
              _buildSubStat(
                'Inactive',
                '1',
                Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final status = sub['status'] as String;
    final isActive = status == 'active';
    final statusColor = isActive
        ? const Color(0xFF059669)
        : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (sub['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: sub['color'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['provider'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${sub['vehicle']} • ${sub['plan']} Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (sub['renewal'] != '—')
                  Text(
                    'Renews: ${sub['renewal']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sub['amount'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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

  // ── TAB 5: Analytics ──────────────────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnalyticsKpiRow(),
        const SizedBox(height: 16),
        _buildVehicleBreakdownCard(),
        const SizedBox(height: 16),
        _buildPerformanceSection(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAnalyticsKpiRow() {
    final kpis = [
      {
        'label': 'Total Trips',
        'value': '970',
        'icon': Icons.route_rounded,
        'color': const Color(0xFF0D1B3E),
      },
      {
        'label': 'Revenue',
        'value': '₹4.4L',
        'icon': Icons.currency_rupee_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'label': 'Avg Rating',
        'value': '4.6',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Active Now',
        'value': '8',
        'icon': Icons.circle,
        'color': const Color(0xFF3B82F6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) {
        final kpi = kpis[i];
        return Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  kpi['icon'] as IconData,
                  color: kpi['color'] as Color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kpi['value'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      kpi['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleBreakdownCard() {
    final breakdown = [
      {
        'vehicle': 'Auto Rickshaw',
        'trips': 523,
        'pct': 0.54,
        'color': const Color(0xFFF59E0B),
      },
      {
        'vehicle': 'Car',
        'trips': 287,
        'pct': 0.30,
        'color': const Color(0xFF059669),
      },
      {
        'vehicle': 'Tempo',
        'trips': 142,
        'pct': 0.15,
        'color': const Color(0xFF7C3AED),
      },
      {
        'vehicle': 'Pickup Van',
        'trips': 18,
        'pct': 0.02,
        'color': const Color(0xFF0284C7),
      },
    ];

    return Container(
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
          Text(
            'Trips by Vehicle Type',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ...breakdown.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildVehicleIcon(b['vehicle'] as String),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b['vehicle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        '${b['trips']} trips',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: b['pct'] as double,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        b['color'] as Color,
                      ),
                      minHeight: 6,
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

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Performance',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ..._performanceData.map((p) => _buildPerformanceCard(p)),
      ],
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        _buildVehicleIcon(p['vehicle'] as String),
                        const SizedBox(width: 4),
                        Text(
                          p['vehicle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (p['badgeColor'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p['badge'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: p['badgeColor'] as Color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPerfStat('Trips', '${p['trips']}', const Color(0xFF0D1B3E)),
              _buildPerfStat(
                'Rating',
                '${p['rating']}',
                const Color(0xFFF59E0B),
              ),
              _buildPerfStat(
                'Earnings',
                p['earnings'] as String,
                const Color(0xFF059669),
              ),
              _buildPerfStat(
                'Completion',
                '${p['completion']}%',
                const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Rate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (p['completion'] as int) / 100,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (p['completion'] as int) >= 90
                              ? const Color(0xFF059669)
                              : (p['completion'] as int) >= 75
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFDC2626),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerfStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
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
              fontSize: 9,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
