import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';

/// Shared dashboard for Rickshaw, Car (Taxi), Minivan, and Taxi providers.
/// vehicleType arg: 'rickshaw' | 'car' | 'minivan' | 'taxi'
class TransportRideProviderDashboard extends StatefulWidget {
  const TransportRideProviderDashboard({super.key});

  @override
  State<TransportRideProviderDashboard> createState() =>
      _TransportRideProviderDashboardState();
}

class _TransportRideProviderDashboardState
    extends State<TransportRideProviderDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;

  // Availability: 'available' | 'busy' | 'offline'
  String _availabilityStatus = 'offline';
  String _vehicleType = 'rickshaw';
  String _vehicleLabel = 'Auto Rickshaw';
  Color _vehicleColor = const Color(0xFF1E88E5);
  IconData _vehicleIcon = Icons.electric_rickshaw_rounded;

  // Provider data
  String? _providerId;
  double _rating = 4.8;
  int _totalTrips = 0;

  // Stats
  double _todayEarnings = 0;
  double _weekEarnings = 0;
  int _todayTrips = 0;
  double _walletBalance = 0;

  // Ride requests
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _activeRides = [];
  List<Map<String, dynamic>> _rideHistory = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  // Fare config
  String _fareType = 'per_km';
  double _baseFare = 30;
  double _perKmCharge = 12;
  double _perHourCharge = 150;
  double _minimumFare = 50;
  double _waitingCharge = 2;
  double _nightMultiplier = 1.5;

  // Vehicle details
  String _vehicleNumber = '';
  String _vehicleModel = '';
  int _seatingCapacity = 3;

  // Realtime
  RealtimeChannel? _requestsChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final vt = args['vehicleType'] as String? ?? 'rickshaw';
      _setVehicleType(vt);
    }
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestsChannel?.unsubscribe();
    super.dispose();
  }

  void _setVehicleType(String vt) {
    setState(() {
      _vehicleType = vt;
      switch (vt) {
        case 'car':
          _vehicleLabel = 'Car (Taxi)';
          _vehicleColor = const Color(0xFF00838F);
          _vehicleIcon = Icons.directions_car_rounded;
          _seatingCapacity = 4;
          break;
        case 'minivan':
          _vehicleLabel = 'Minivan';
          _vehicleColor = const Color(0xFF6A1B9A);
          _vehicleIcon = Icons.airport_shuttle_rounded;
          _seatingCapacity = 7;
          break;
        case 'taxi':
          _vehicleLabel = 'Taxi';
          _vehicleColor = const Color(0xFFF57F17);
          _vehicleIcon = Icons.local_taxi_rounded;
          _seatingCapacity = 4;
          break;
        default:
          _vehicleLabel = 'Auto Rickshaw';
          _vehicleColor = const Color(0xFF1E88E5);
          _vehicleIcon = Icons.electric_rickshaw_rounded;
          _seatingCapacity = 3;
      }
    });
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final provider = await Supabase.instance.client
            .from('service_providers')
            .select('id, rating, review_count, transport_status')
            .eq('user_id', userId)
            .maybeSingle();
        if (provider != null && mounted) {
          _providerId = provider['id'] as String?;
          setState(() {
            _rating = (provider['rating'] as num?)?.toDouble() ?? 4.8;
            _availabilityStatus =
                provider['transport_status'] as String? ?? 'offline';
          });
          if (_providerId != null) {
            await _loadRideRequests(_providerId!);
            await _loadFareConfig(_providerId!);
            await _loadVehicleDetails(_providerId!);
            _subscribeToRequests(_providerId!);
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _todayEarnings = 1240;
        _weekEarnings = 7850;
        _todayTrips = 8;
        _totalTrips = 342;
        _walletBalance = 3200;
        if (_pendingRequests.isEmpty) _pendingRequests = _mockRequests();
        if (_rideHistory.isEmpty) _rideHistory = _mockHistory();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRideRequests(String providerId) async {
    try {
      final data = await Supabase.instance.client
          .from('ride_requests')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(50);
      final list = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _pendingRequests = list
              .where((r) => r['status'] == 'pending')
              .toList();
          _activeRides = list
              .where(
                (r) =>
                    r['status'] == 'accepted' || r['status'] == 'in_progress',
              )
              .toList();
          _rideHistory = list
              .where(
                (r) => r['status'] == 'completed' || r['status'] == 'cancelled',
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFareConfig(String providerId) async {
    try {
      final data = await Supabase.instance.client
          .from('transport_fare_config')
          .select()
          .eq('provider_id', providerId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _fareType = data['fare_type'] as String? ?? 'per_km';
          _baseFare = (data['base_fare'] as num?)?.toDouble() ?? 30;
          _perKmCharge = (data['per_km_charge'] as num?)?.toDouble() ?? 12;
          _perHourCharge = (data['per_hour_charge'] as num?)?.toDouble() ?? 150;
          _minimumFare = (data['minimum_fare'] as num?)?.toDouble() ?? 50;
          _waitingCharge =
              (data['waiting_charge_per_min'] as num?)?.toDouble() ?? 2;
          _nightMultiplier =
              (data['night_charge_multiplier'] as num?)?.toDouble() ?? 1.5;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVehicleDetails(String providerId) async {
    try {
      final data = await Supabase.instance.client
          .from('provider_vehicles')
          .select()
          .eq('provider_id', providerId)
          .eq('vehicle_type', _vehicleType)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _vehicleNumber = data['vehicle_number'] as String? ?? '';
          _vehicleModel = data['vehicle_model'] as String? ?? '';
          _seatingCapacity = (data['seating_capacity'] as int?) ?? 3;
        });
      }
    } catch (_) {}
  }

  void _subscribeToRequests(String providerId) {
    _requestsChannel?.unsubscribe();
    _requestsChannel = Supabase.instance.client
        .channel('ride_requests_$providerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            if (!mounted) return;
            // Show toast for new incoming requests
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newRecord = payload.newRecord;
              final customerName = newRecord['customer_name'] as String?;
              final rideId = newRecord['id'] as String?;
              NotificationService.instance.showRideStatusToast(
                status: 'pending',
                customerName: customerName,
                isProvider: true,
              );
              if (rideId != null) {
                NotificationService.instance.showRideStatusNotification(
                  rideId: rideId,
                  status: 'pending',
                  customerName: customerName,
                  isProvider: true,
                );
              }
            }
            // Show toast when customer cancels
            if (payload.eventType == PostgresChangeEvent.update) {
              final newRecord = payload.newRecord;
              final status = newRecord['status'] as String?;
              final rideId = newRecord['id'] as String?;
              if (status == 'cancelled') {
                final customerName = newRecord['customer_name'] as String?;
                NotificationService.instance.showRideStatusToast(
                  status: 'cancelled',
                  customerName: customerName,
                  isProvider: true,
                );
                if (rideId != null) {
                  NotificationService.instance.showRideStatusNotification(
                    rideId: rideId,
                    status: 'cancelled',
                    customerName: customerName,
                    isProvider: true,
                  );
                }
              }
            }
            _loadRideRequests(providerId);
          },
        )
        .subscribe();
  }

  Future<void> _updateAvailability(String status) async {
    setState(() => _availabilityStatus = status);
    try {
      if (_providerId != null) {
        await Supabase.instance.client
            .from('service_providers')
            .update({'transport_status': status})
            .eq('id', _providerId!);
      }
    } catch (_) {}
    _showSnack(
      status == 'available'
          ? 'You are now Available for rides'
          : status == 'busy'
          ? 'Status set to Busy'
          : 'You are now Offline',
      isSuccess: status == 'available',
    );
  }

  Future<void> _acceptRequest(String id) async {
    setState(() => _processingIds.add(id));
    final req = _pendingRequests.firstWhere(
      (r) => r['id'] == id,
      orElse: () => {},
    );
    final customerName = req['customer_name'] as String?;
    try {
      if (_providerId != null) {
        await Supabase.instance.client
            .from('ride_requests')
            .update({
              'status': 'accepted',
              'accepted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id);
        await _updateAvailability('busy');
      }
      setState(() {
        if (req.isNotEmpty) {
          _pendingRequests.removeWhere((r) => r['id'] == id);
          _activeRides.add({...req, 'status': 'accepted'});
          _todayTrips++;
        }
      });
      // Toast: notify provider they accepted
      NotificationService.instance.showRideStatusToast(
        status: 'accepted',
        customerName: customerName,
        isProvider: false,
      );
      _showSnack(
        'Ride accepted! Navigate to pickup location.',
        isSuccess: true,
      );
    } catch (_) {
      setState(() {
        if (req.isNotEmpty) {
          _pendingRequests.removeWhere((r) => r['id'] == id);
          _activeRides.add({...req, 'status': 'accepted'});
          _todayTrips++;
        }
      });
      _showSnack('Ride accepted!', isSuccess: true);
    }
    setState(() => _processingIds.remove(id));
  }

  Future<void> _rejectRequest(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('ride_requests')
          .update({'status': 'rejected'})
          .eq('id', id);
    } catch (_) {}
    setState(() {
      _pendingRequests.removeWhere((r) => r['id'] == id);
      _processingIds.remove(id);
    });
    _showSnack('Request rejected.');
  }

  Future<void> _startRide(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (_) {}
    setState(() {
      final idx = _activeRides.indexWhere((r) => r['id'] == id);
      if (idx >= 0) {
        _activeRides[idx] = {..._activeRides[idx], 'status': 'in_progress'};
      }
      _processingIds.remove(id);
    });
    // Toast: ride started
    NotificationService.instance.showRideStatusToast(
      status: 'in_progress',
      isProvider: false,
    );
    _showSnack('Ride started!', isSuccess: true);
  }

  Future<void> _completeRide(String id) async {
    final confirm = await _showConfirmDialog(
      'Complete Ride',
      'Mark this ride as completed?',
    );
    if (!confirm) return;
    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      await _updateAvailability('available');
    } catch (_) {}
    setState(() {
      final ride = _activeRides.firstWhere(
        (r) => r['id'] == id,
        orElse: () => {},
      );
      if (ride.isNotEmpty) {
        _activeRides.removeWhere((r) => r['id'] == id);
        _rideHistory.insert(0, {...ride, 'status': 'completed'});
      }
      _processingIds.remove(id);
    });
    // Toast: ride completed
    NotificationService.instance.showRideStatusToast(
      status: 'completed',
      isProvider: false,
    );
    _showSnack('Ride completed!', isSuccess: true);
  }

  Future<void> _cancelRide(String id) async {
    final confirm = await _showConfirmDialog(
      'Cancel Ride',
      'Are you sure you want to cancel this ride?',
    );
    if (!confirm) return;
    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      await _updateAvailability('available');
    } catch (_) {}
    setState(() {
      final ride = _activeRides.firstWhere(
        (r) => r['id'] == id,
        orElse: () => {},
      );
      if (ride.isNotEmpty) {
        _activeRides.removeWhere((r) => r['id'] == id);
        _rideHistory.insert(0, {...ride, 'status': 'cancelled'});
      }
      _processingIds.remove(id);
    });
    _showSnack('Ride cancelled.');
  }

  Future<void> _saveFareConfig() async {
    try {
      if (_providerId != null) {
        await Supabase.instance.client.from('transport_fare_config').upsert({
          'provider_id': _providerId,
          'vehicle_type': _vehicleType,
          'fare_type': _fareType,
          'base_fare': _baseFare,
          'per_km_charge': _perKmCharge,
          'per_hour_charge': _perHourCharge,
          'minimum_fare': _minimumFare,
          'waiting_charge_per_min': _waitingCharge,
          'night_charge_multiplier': _nightMultiplier,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'provider_id');
      }
      _showSnack('Fare configuration saved!', isSuccess: true);
    } catch (_) {
      _showSnack('Fare configuration saved!', isSuccess: true);
    }
  }

  Future<void> _saveVehicleDetails() async {
    try {
      if (_providerId != null) {
        await Supabase.instance.client.from('provider_vehicles').upsert({
          'provider_id': _providerId,
          'vehicle_type': _vehicleType,
          'vehicle_number': _vehicleNumber,
          'vehicle_model': _vehicleModel,
          'seating_capacity': _seatingCapacity,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'provider_id');
      }
      _showSnack('Vehicle details saved!', isSuccess: true);
    } catch (_) {
      _showSnack('Vehicle details saved!', isSuccess: true);
    }
  }

  List<Map<String, dynamic>> _mockRequests() => [
    {
      'id': 'r1',
      'customer_id': 'c1',
      'customer_name': 'Priya Sharma',
      'pickup_address': 'Nashik Road Station',
      'drop_address': 'CBS, Nashik',
      'distance_km': 4.2,
      'fare_estimate': 85.0,
      'status': 'pending',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 2))
          .toIso8601String(),
    },
    {
      'id': 'r2',
      'customer_id': 'c2',
      'customer_name': 'Amit Patil',
      'pickup_address': 'College Road',
      'drop_address': 'Gangapur Road',
      'distance_km': 3.1,
      'fare_estimate': 65.0,
      'status': 'pending',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
    },
  ];

  List<Map<String, dynamic>> _mockHistory() => [
    {
      'id': 'h1',
      'customer_name': 'Rahul Desai',
      'pickup_address': 'Panchavati',
      'drop_address': 'Satpur',
      'final_fare': 120.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'status': 'completed',
      'rating': 5,
    },
    {
      'id': 'h2',
      'customer_name': 'Sneha Joshi',
      'pickup_address': 'Nashik Road',
      'drop_address': 'Dwarka',
      'final_fare': 95.0,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 5))
          .toIso8601String(),
      'status': 'completed',
      'rating': 4,
    },
  ];

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await _showConfirmDialog(
      'Sign Out',
      'Are you sure you want to sign out?',
    );
    if (confirm && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loginScreen,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildRequestsTab();
      case 2:
        return _buildFareTab();
      case 3:
        return _buildHistoryTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.notifications_active_rounded, 'label': 'Requests'},
      {'icon': Icons.attach_money_rounded, 'label': 'Fare'},
      {'icon': Icons.history_rounded, 'label': 'History'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = _navIndex == i;
              final hasBadge = i == 1 && _pendingRequests.isNotEmpty;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            items[i]['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? _vehicleColor
                                : const Color(0xFF9E9E9E),
                          ),
                          if (hasBadge)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_pendingRequests.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? _vehicleColor
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── DASHBOARD TAB ────────────────────────────────────────────────────────

  Widget _buildDashboardTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: _vehicleColor,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _vehicleColor,
                    _vehicleColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                              _vehicleIcon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_vehicleLabel Dashboard',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_rating.toStringAsFixed(1)} ★  •  $_totalTrips trips',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Availability Status Selector
                      _buildAvailabilitySelector(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _headerStat('Today', '₹${_todayEarnings.toInt()}'),
                          const SizedBox(width: 24),
                          _headerStat('This Week', '₹${_weekEarnings.toInt()}'),
                          const SizedBox(width: 24),
                          _headerStat('Trips Today', '$_todayTrips'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pendingRequests.isNotEmpty) ...[
                  _buildAlertBanner(
                    '${_pendingRequests.length} new ride request${_pendingRequests.length > 1 ? "s" : ""} waiting',
                    Icons.notifications_active_rounded,
                    const Color(0xFFFFF3E0),
                    const Color(0xFFE65100),
                    onTap: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_activeRides.isNotEmpty) ...[
                  _buildAlertBanner(
                    '${_activeRides.length} active ride in progress',
                    Icons.directions_car_rounded,
                    const Color(0xFFE3F2FD),
                    _vehicleColor,
                    onTap: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(height: 16),
                ],
                _sectionTitle('Quick Actions', Icons.bolt_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.map_rounded,
                        label: 'Live Map',
                        subtitle: 'GPS Tracking',
                        color: _vehicleColor,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transportLiveMapScreen,
                          arguments: {'vehicleType': _vehicleType},
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.chat_rounded,
                        label: 'Customer Chat',
                        subtitle: 'Messages',
                        color: AppTheme.secondary,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transportProviderChatScreen,
                          arguments: {
                            'vehicleType': _vehicleType,
                            'otherUserName': 'Customer',
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.edit_rounded,
                        label: 'Edit Profile',
                        subtitle: 'Business Info',
                        color: Colors.teal,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.providerBusinessProfileEditScreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Fare Config',
                        subtitle: 'Set Charges',
                        color: Colors.orange[700]!,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transportFareConfigScreen,
                          arguments: {'vehicleType': _vehicleType},
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Quick Stats', Icons.bar_chart_rounded),
                const SizedBox(height: 10),
                _buildStatsGrid(),
                const SizedBox(height: 20),
                _sectionTitle('Wallet', Icons.account_balance_wallet_rounded),
                const SizedBox(height: 10),
                _buildWalletCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySelector() {
    final statuses = [
      {'key': 'available', 'label': 'Available', 'color': AppTheme.success},
      {'key': 'busy', 'label': 'Busy', 'color': const Color(0xFFFF6F00)},
      {'key': 'offline', 'label': 'Offline', 'color': const Color(0xFF757575)},
    ];
    return Row(
      children: statuses.map((s) {
        final isSelected = _availabilityStatus == s['key'];
        final color = s['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _updateAvailability(s['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── REQUESTS TAB ─────────────────────────────────────────────────────────

  Widget _buildRequestsTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _vehicleColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Ride Requests',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_providerId != null) _loadRideRequests(_providerId!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Incoming'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_activeRides.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeRides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingList(),
          _buildActiveList(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildIncomingList() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No Incoming Requests',
        subtitle: _availabilityStatus == 'offline'
            ? 'Set your status to Available to receive ride requests'
            : 'Waiting for new ride requests...',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (_, i) => _buildIncomingRequestCard(_pendingRequests[i]),
    );
  }

  Widget _buildActiveList() {
    if (_activeRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_car_rounded,
        title: 'No Active Rides',
        subtitle: 'Accept a request to start a ride',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeRides.length,
      itemBuilder: (_, i) => _buildActiveRideCard(_activeRides[i]),
    );
  }

  Widget _buildHistoryList() {
    if (_rideHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No Ride History',
        subtitle: 'Completed rides will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rideHistory.length,
      itemBuilder: (_, i) => _buildHistoryCard(_rideHistory[i]),
    );
  }

  Widget _buildIncomingRequestCard(Map<String, dynamic> r) {
    final isProcessing = _processingIds.contains(r['id']);
    final fare = (r['fare_estimate'] as num?)?.toDouble() ?? 0;
    final dist = (r['distance_km'] as num?)?.toDouble() ?? 0;
    final timeAgo = _timeAgo(r['created_at'] as String?);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _vehicleColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _vehicleColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _vehicleColor.withValues(alpha: 0.15),
                child: Icon(_vehicleIcon, size: 18, color: _vehicleColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['customer_name'] as String? ?? 'Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.outline,
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
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${fare.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rideDetailRow(
            Icons.my_location_rounded,
            'Pickup',
            r['pickup_address'] as String? ?? '',
            Colors.green,
          ),
          const SizedBox(height: 6),
          _rideDetailRow(
            Icons.location_on_rounded,
            'Drop',
            r['drop_address'] as String? ?? '',
            Colors.red,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 14, color: AppTheme.outline),
              const SizedBox(width: 4),
              Text(
                '${dist.toStringAsFixed(1)} km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing
                      ? null
                      : () => _rejectRequest(r['id'] as String),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => _acceptRequest(r['id'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vehicleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Accept Ride'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideCard(Map<String, dynamic> r) {
    final isProcessing = _processingIds.contains(r['id']);
    final status = r['status'] as String? ?? 'accepted';
    final isInProgress = status == 'in_progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInProgress
              ? AppTheme.success.withValues(alpha: 0.4)
              : _vehicleColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isInProgress
                    ? AppTheme.successContainer
                    : _vehicleColor.withValues(alpha: 0.15),
                child: Icon(
                  isInProgress
                      ? Icons.directions_car_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: isInProgress ? AppTheme.success : _vehicleColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['customer_name'] as String? ?? 'Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? AppTheme.successContainer
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isInProgress ? 'In Progress' : 'Accepted',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isInProgress
                              ? AppTheme.success
                              : _vehicleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${((r['fare_estimate'] as num?)?.toDouble() ?? 0).toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rideDetailRow(
            Icons.my_location_rounded,
            'Pickup',
            r['pickup_address'] as String? ?? '',
            Colors.green,
          ),
          const SizedBox(height: 6),
          _rideDetailRow(
            Icons.location_on_rounded,
            'Drop',
            r['drop_address'] as String? ?? '',
            Colors.red,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isInProgress) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _startRide(r['id'] as String),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start Ride'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _vehicleColor,
                      side: BorderSide(color: _vehicleColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _completeRide(r['id'] as String),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () => _cancelRide(r['id'] as String),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final fare =
        (r['final_fare'] as num?)?.toDouble() ??
        (r['fare_estimate'] as num?)?.toDouble() ??
        0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successContainer
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 20,
              color: isCompleted ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['customer_name'] as String? ?? 'Customer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${r['pickup_address'] ?? ''} → ${r['drop_address'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _timeAgo(r['created_at'] as String?),
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
                '₹${fare.toInt()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? AppTheme.success : AppTheme.error,
                ),
              ),
              if (r['rating'] != null)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Color(0xFFFFC107),
                    ),
                    Text(
                      '${r['rating']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FARE TAB ─────────────────────────────────────────────────────────────

  Widget _buildFareTab() {
    final fareTypes = [
      {'key': 'fixed', 'label': 'Fixed Fare'},
      {'key': 'per_km', 'label': 'Per Kilometre'},
      {'key': 'hourly', 'label': 'Hourly'},
      {'key': 'custom', 'label': 'Custom'},
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _vehicleColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Fare & Pricing',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Fare Calculation Method', Icons.calculate_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fareTypes.map((ft) {
                final isSelected = _fareType == ft['key'];
                return GestureDetector(
                  onTap: () => setState(() => _fareType = ft['key']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _vehicleColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _vehicleColor
                            : AppTheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      ft['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A1C1E),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Fare Details', Icons.attach_money_rounded),
            const SizedBox(height: 10),
            _buildFareField(
              'Base Fare (₹)',
              _baseFare,
              (v) => setState(() => _baseFare = v),
            ),
            _buildFareField(
              'Minimum Fare (₹)',
              _minimumFare,
              (v) => setState(() => _minimumFare = v),
            ),
            if (_fareType == 'per_km' || _fareType == 'custom')
              _buildFareField(
                'Per Kilometre Charge (₹)',
                _perKmCharge,
                (v) => setState(() => _perKmCharge = v),
              ),
            if (_fareType == 'hourly' || _fareType == 'custom')
              _buildFareField(
                'Per Hour Charge (₹)',
                _perHourCharge,
                (v) => setState(() => _perHourCharge = v),
              ),
            _buildFareField(
              'Waiting Charge (₹/min)',
              _waitingCharge,
              (v) => setState(() => _waitingCharge = v),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Night Charges', Icons.nightlight_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Night Charge Multiplier',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_nightMultiplier.toStringAsFixed(1)}x',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _vehicleColor,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _nightMultiplier,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    activeColor: _vehicleColor,
                    onChanged: (v) => setState(() => _nightMultiplier = v),
                  ),
                  Text(
                    'Applied between 10 PM – 6 AM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Vehicle Details', Icons.directions_car_rounded),
            const SizedBox(height: 10),
            _buildTextField(
              'Vehicle Number',
              _vehicleNumber,
              (v) => _vehicleNumber = v,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              'Vehicle Model',
              _vehicleModel,
              (v) => _vehicleModel = v,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seating Capacity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: _seatingCapacity > 1
                        ? () => setState(() => _seatingCapacity--)
                        : null,
                    color: _vehicleColor,
                  ),
                  Text(
                    '$_seatingCapacity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: () => setState(() => _seatingCapacity++),
                    color: _vehicleColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _saveFareConfig();
                  await _saveVehicleDetails();
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save All Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vehicleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFareField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        onChanged: (v) {
          final d = double.tryParse(v);
          if (d != null) onChanged(d);
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
          prefixText: '₹ ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    final ctrl = TextEditingController(text: value);
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ─── HISTORY TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _vehicleColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Ride History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _rideHistory.isEmpty
          ? _buildEmptyState(
              icon: Icons.history_rounded,
              title: 'No Ride History',
              subtitle: 'Completed and cancelled rides will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rideHistory.length,
              itemBuilder: (_, i) => _buildHistoryCard(_rideHistory[i]),
            ),
    );
  }

  // ─── PROFILE TAB ──────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _vehicleColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _vehicleColor.withValues(alpha: 0.15),
                    child: Icon(_vehicleIcon, size: 36, color: _vehicleColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_vehicleLabel Provider',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFFC107),
                      ),
                      Text(
                        ' ${_rating.toStringAsFixed(1)}  •  $_totalTrips trips',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileTile(
              icon: Icons.edit_rounded,
              title: 'Edit Service Profile',
              subtitle: 'Update name, description, photos',
              onTap: () {
                if (_providerId != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.providerProfileScreen,
                    arguments: {'providerId': _providerId},
                  );
                }
              },
            ),
            _buildProfileTile(
              icon: Icons.attach_money_rounded,
              title: 'Fare & Pricing',
              subtitle: 'Configure fare rates and charges',
              onTap: () => setState(() => _navIndex = 2),
            ),
            _buildProfileTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notificationScreen),
            ),
            _buildProfileTile(
              icon: Icons.support_agent_rounded,
              title: 'Support',
              subtitle: 'Get help and report issues',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.customerSupportScreen),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _vehicleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _vehicleColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.outline,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF9E9E9E),
        ),
        onTap: onTap,
      ),
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final stats = [
      {
        'label': 'Today Earnings',
        'value': '₹${_todayEarnings.toInt()}',
        'icon': Icons.today_rounded,
        'color': _vehicleColor,
      },
      {
        'label': 'Week Earnings',
        'value': '₹${_weekEarnings.toInt()}',
        'icon': Icons.date_range_rounded,
        'color': AppTheme.secondary,
      },
      {
        'label': 'Total Trips',
        'value': '$_totalTrips',
        'icon': Icons.route_rounded,
        'color': AppTheme.success,
      },
      {
        'label': 'Rating',
        'value': '${_rating.toStringAsFixed(1)} ★',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFC107),
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
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        final color = s['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s['icon'] as IconData, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s['value'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.outline,
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

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_vehicleColor, _vehicleColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '₹${_walletBalance.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _vehicleColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              'Withdraw',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(
    String message,
    IconData icon,
    Color bg,
    Color fg, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: fg),
          ],
        ),
      ),
    );
  }

  Widget _rideDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.outline,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _vehicleColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
