import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';

class MakeupMehendiEventPlannerDashboard extends StatefulWidget {
  final String
  subcategory; // 'makeup', 'mehendi', 'planner', 'anchor', 'band', 'orchestra', 'dance', 'generator'
  const MakeupMehendiEventPlannerDashboard({
    super.key,
    this.subcategory = 'makeup',
  });

  @override
  State<MakeupMehendiEventPlannerDashboard> createState() =>
      _MakeupMehendiEventPlannerDashboardState();
}

class _MakeupMehendiEventPlannerDashboardState
    extends State<MakeupMehendiEventPlannerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> get _config {
    switch (widget.subcategory) {
      case 'mehendi':
        return {
          'title': 'Mehendi Artist Dashboard',
          'color': const Color(0xFF4E342E),
          'icon': Icons.brush_rounded,
          'name': 'Fatima Mehendi Art',
          'speciality': 'Bridal & Arabic Mehendi',
        };
      case 'planner':
        return {
          'title': 'Event Planner Dashboard',
          'color': const Color(0xFF1A237E),
          'icon': Icons.event_note_rounded,
          'name': 'Dream Events Co.',
          'speciality': 'Complete Event Planning',
        };
      case 'anchor':
        return {
          'title': 'Anchor / Host Dashboard',
          'color': const Color(0xFF37474F),
          'icon': Icons.mic_rounded,
          'name': 'Vivek Anchoring Services',
          'speciality': 'Wedding & Corporate Hosting',
        };
      case 'band':
        return {
          'title': 'Live Band Dashboard',
          'color': const Color(0xFF4A148C),
          'icon': Icons.music_note_rounded,
          'name': 'Rhythm Live Band',
          'speciality': 'Bollywood & Folk Music',
        };
      case 'orchestra':
        return {
          'title': 'Orchestra Dashboard',
          'color': const Color(0xFF1B5E20),
          'icon': Icons.queue_music_rounded,
          'name': 'Classic Orchestra Group',
          'speciality': 'Classical & Fusion Music',
        };
      case 'dance':
        return {
          'title': 'Dance Group Dashboard',
          'color': const Color(0xFFBF360C),
          'icon': Icons.directions_run_rounded,
          'name': 'Beats Dance Academy',
          'speciality': 'Bollywood & Folk Dance',
        };
      case 'generator':
        return {
          'title': 'Generator Rental Dashboard',
          'color': const Color(0xFF263238),
          'icon': Icons.power_rounded,
          'name': 'PowerGen Rentals',
          'speciality': 'Generator & Power Backup',
        };
      default:
        return {
          'title': 'Makeup Artist Dashboard',
          'color': const Color(0xFF6A1B9A),
          'icon': Icons.face_retouching_natural_rounded,
          'name': 'Glamour by Sneha',
          'speciality': 'Bridal & Party Makeup',
        };
    }
  }

  Color get _primaryColor => _config['color'] as Color;

  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 'A001',
      'client': 'Pooja Sharma',
      'event': 'Wedding',
      'date': '18 Jul 2026',
      'time': '6:00 AM',
      'package': 'Bridal ₹15,000',
      'status': 'confirmed',
      'location': 'Nashik',
    },
    {
      'id': 'A002',
      'client': 'Neha Patil',
      'event': 'Engagement',
      'date': '22 Jul 2026',
      'time': '4:00 PM',
      'package': 'Engagement ₹8,000',
      'status': 'pending',
      'location': 'Pune',
    },
    {
      'id': 'A003',
      'client': 'Riya Joshi',
      'event': 'Birthday',
      'date': '28 Jul 2026',
      'time': '2:00 PM',
      'package': 'Party ₹5,000',
      'status': 'pending',
      'location': 'Mumbai',
    },
  ];

  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Bridal Package',
      'price': 15000,
      'duration': '4-5 hrs',
      'includes': ['HD Makeup', 'Hairstyling', 'Saree Draping', 'Touch-up Kit'],
      'popular': true,
    },
    {
      'name': 'Engagement Package',
      'price': 8000,
      'duration': '2-3 hrs',
      'includes': ['Party Makeup', 'Hairstyling', 'Accessories'],
      'popular': false,
    },
    {
      'name': 'Party Makeup',
      'price': 5000,
      'duration': '1-2 hrs',
      'includes': ['Party Makeup', 'Basic Hairstyling'],
      'popular': false,
    },
    {
      'name': 'Pre-Wedding Shoot',
      'price': 6000,
      'duration': '2 hrs',
      'includes': ['HD Makeup', 'Hairstyling', 'Multiple Looks'],
      'popular': false,
    },
  ];

  final List<String> _portfolioImages = [
    'https://images.pexels.com/photos/3373736/pexels-photo-3373736.jpeg?w=300',
    'https://images.pexels.com/photos/2681751/pexels-photo-2681751.jpeg?w=300',
    'https://images.pexels.com/photos/3014856/pexels-photo-3014856.jpeg?w=300',
    'https://images.pexels.com/photos/1024993/pexels-photo-1024993.jpeg?w=300',
    'https://images.pexels.com/photos/3379934/pexels-photo-3379934.jpeg?w=300',
    'https://images.pexels.com/photos/1444442/pexels-photo-1444442.jpeg?w=300',
  ];

  // For event planner: tasks
  final List<Map<String, dynamic>> _tasks = [
    {
      'task': 'Confirm venue booking',
      'event': 'Sharma Wedding',
      'due': '10 Jul',
      'done': true,
    },
    {
      'task': 'Finalize catering menu',
      'event': 'Sharma Wedding',
      'due': '12 Jul',
      'done': false,
    },
    {
      'task': 'Confirm photographer',
      'event': 'Sharma Wedding',
      'due': '13 Jul',
      'done': false,
    },
    {
      'task': 'Arrange transport',
      'event': 'Patil Engagement',
      'due': '15 Jul',
      'done': false,
    },
    {
      'task': 'Send invitations',
      'event': 'Patil Engagement',
      'due': '8 Jul',
      'done': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.subcategory == 'planner' ? 5 : 5,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _signOut() => Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.loginScreen,
    (_) => false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(_primaryColor, Colors.white, 0.95)!,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _config['title'] as String,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationScreen),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.chatListScreen),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            const Tab(text: 'Dashboard'),
            Tab(
              text: widget.subcategory == 'planner' ? 'Events' : 'Appointments',
            ),
            const Tab(text: 'Portfolio'),
            Tab(text: widget.subcategory == 'planner' ? 'Tasks' : 'Packages'),
            const Tab(text: 'Earnings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildAppointments(),
          _buildPortfolio(),
          widget.subcategory == 'planner' ? _buildTasks() : _buildPackages(),
          _buildEarnings(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _config['icon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _config['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _config['speciality'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber[300],
                            size: 15,
                          ),
                          Text(
                            ' 4.9  •  287 reviews',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
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
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _kpiCard(
                'This Month',
                '₹65,000',
                Icons.currency_rupee_rounded,
                Colors.green,
              ),
              _kpiCard(
                widget.subcategory == 'planner' ? 'Events' : 'Appointments',
                '14',
                Icons.event_rounded,
                _primaryColor,
              ),
              _kpiCard(
                'Pending',
                '3',
                Icons.pending_actions_rounded,
                Colors.orange,
              ),
              _kpiCard('Rating', '4.9 ★', Icons.star_rounded, Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          _buildSubscriptionCard(),
          const SizedBox(height: 16),
          Text(
            'Upcoming Appointments',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._appointments
              .where((a) => a['status'] == 'confirmed')
              .map((a) => _appointmentTile(a)),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Plan Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Renews on 30 Jul 2026',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.providerSubscriptionScreen,
            ),
            child: Text(
              'Manage',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'All Appointments',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._appointments.map((a) => _appointmentTile(a, showActions: true)),
      ],
    );
  }

  Widget _appointmentTile(Map<String, dynamic> a, {bool showActions = false}) {
    final statusColors = {
      'pending': Colors.orange,
      'confirmed': Colors.green,
      'completed': Colors.blue,
    };
    final color = statusColors[a['status']] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryColor.withValues(alpha: 0.1),
                child: Text(
                  (a['client'] as String)[0],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['client'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${a['event']} • ${a['location']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (a['status'] as String).toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 5),
              Text(
                '${a['date']} at ${a['time']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a['package'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showActions && a['status'] == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => a['status'] = 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => a['status'] = 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Portfolio',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                label: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _portfolioImages.length,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _portfolioImages[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_rounded, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Products Used',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'MAC Cosmetics',
                      'Huda Beauty',
                      'Airbrush Kit',
                      'Kryolan',
                      'Charlotte Tilbury',
                      'NARS',
                    ]
                    .map(
                      (p) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPackages() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'My Packages',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._packages.map(
          (pkg) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: (pkg['popular'] as bool)
                  ? Border.all(color: _primaryColor, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pkg['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (pkg['popular'] as bool)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Popular',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit_rounded, color: Colors.grey[400], size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${pkg['price']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${pkg['duration']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...(pkg['includes'] as List).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasks() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Event Tasks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Add Task',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._tasks.map(
          (task) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
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
                GestureDetector(
                  onTap: () =>
                      setState(() => task['done'] = !(task['done'] as bool)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (task['done'] as bool)
                          ? Colors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: (task['done'] as bool)
                            ? Colors.green
                            : Colors.grey[400]!,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: (task['done'] as bool)
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['task'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: (task['done'] as bool)
                              ? TextDecoration.lineThrough
                              : null,
                          color: (task['done'] as bool)
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        '${task['event']} • Due: ${task['due']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarnings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withValues(alpha: 0.75)],
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
                const SizedBox(height: 4),
                Text(
                  '₹4,20,000',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _earningChip('This Month', '₹65,000'),
                    const SizedBox(width: 12),
                    _earningChip('Pending', '₹13,000'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Transactions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...[
            {
              'client': 'Pooja Sharma',
              'event': 'Wedding',
              'amount': '₹15,000',
              'date': '14 Jun 2026',
            },
            {
              'client': 'Neha Patil',
              'event': 'Engagement',
              'amount': '₹8,000',
              'date': '9 Jun 2026',
            },
          ].map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['client']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${t['event']} • ${t['date']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    t['amount']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
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

  Widget _earningChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
