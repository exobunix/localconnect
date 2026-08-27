import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/location_service.dart';

class TransportCustomerScreen extends StatefulWidget {
  const TransportCustomerScreen({super.key});

  @override
  State<TransportCustomerScreen> createState() =>
      _TransportCustomerScreenState();
}

class _TransportCustomerScreenState extends State<TransportCustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Vehicle type from args
  String _vehicleType = 'rickshaw';
  String _vehicleLabel = 'Auto Rickshaw';
  IconData _vehicleIcon = Icons.electric_rickshaw_rounded;
  Color _vehicleColor = const Color(0xFF1E88E5);

  // Filters
  String _sortBy = 'nearest';
  double _maxDistance = 51.0;
  bool _showAvailableOnly = true;

  // Providers list
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  final Set<String> _selectedProviderIds = {};

  // Booking form
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _goodsType = 'General';
  bool _needsLoading = false;
  bool _needsUnloading = false;

  final bool _showBookingForm = false;

  // ─── Ride Status Tracking ─────────────────────────────────────────────────
  /// Active ride request IDs submitted by this customer
  final List<Map<String, dynamic>> _myActiveRides = [];

  /// Notification badge count for unread ride status changes
  int _unreadStatusCount = 0;
  RealtimeChannel? _rideStatusChannel;
  String? _currentUserId;

  static const _goodsTypes = [
    'General',
    'Furniture',
    'Electronics',
    'Fragile',
    'Building Material',
    'Agricultural',
    'Other',
  ];

  static const _vehicleConfig = {
    'rickshaw': {
      'label': 'Auto Rickshaw',
      'icon': Icons.electric_rickshaw_rounded,
      'color': Color(0xFF1E88E5),
      'hasGoods': false,
      'maxSelect': 1,
      'desc': 'Quick rides within city',
    },
    'tempo': {
      'label': 'Tempo',
      'icon': Icons.airport_shuttle_rounded,
      'color': Color(0xFF7B1FA2),
      'hasGoods': true,
      'maxSelect': 5,
      'desc': 'Small goods transport',
    },
    'pickup_van': {
      'label': 'Pickup Van',
      'icon': Icons.local_shipping_rounded,
      'color': Color(0xFFE65100),
      'hasGoods': true,
      'maxSelect': 5,
      'desc': 'Medium load transport',
    },
    'truck': {
      'label': 'Truck',
      'icon': Icons.fire_truck_rounded,
      'color': Color(0xFF2E7D32),
      'hasGoods': true,
      'maxSelect': 5,
      'desc': 'Heavy goods transport',
    },
    'car': {
      'label': 'Car (Taxi)',
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFF00838F),
      'hasGoods': false,
      'maxSelect': 1,
      'desc': 'Comfortable cab rides',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _subscribeToMyRideStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final vt = args['vehicleType'] as String? ?? 'rickshaw';
      _setVehicleType(vt);
    }
    _loadProviders();
  }

  void _setVehicleType(String vt) {
    final cfg = _vehicleConfig[vt] ?? _vehicleConfig['rickshaw']!;
    setState(() {
      _vehicleType = vt;
      _vehicleLabel = cfg['label'] as String;
      _vehicleIcon = cfg['icon'] as IconData;
      _vehicleColor = cfg['color'] as Color;
      _selectedProviderIds.clear();
    });
  }

  static const Map<String, List<double>> _cityCoordsFallback = {
    'pune': [18.5204, 73.8567],
    'mumbai': [19.0760, 72.8777],
    'nashik': [19.9975, 73.7898],
    'aurangabad': [19.8762, 75.3433],
    'nagpur': [21.1458, 79.0882],
    'kolhapur': [16.7050, 74.2433],
    'alibag': [18.6414, 72.8722],
    'roha': [18.4400, 73.1200],
    'nagothane': [18.5500, 73.1500],
    'pen': [18.7400, 73.0900],
    'mangaon': [18.2300, 73.2800],
    'mahad': [18.0800, 73.4200],
    'poladpur': [17.9800, 73.5200],
    'shrivardhan': [18.0400, 73.0200],
    'murud': [18.3200, 72.9600],
    'panvel': [18.9894, 73.1175],
    'khopoli': [18.7900, 73.3400],
    'karjat': [18.9100, 73.3200],
    'noida': [28.5355, 77.3910],
    'delhi': [28.6139, 77.2090],
    'gurgaon': [28.4595, 77.0266],
    'ghaziabad': [28.6692, 77.4538],
  };

  String _getDbSubcategory(String vt) {
    switch (vt) {
      case 'rickshaw':
        return 'Auto Rickshaw';
      case 'tempo':
        return 'Tempo';
      case 'pickup_van':
        return 'Pickup Van';
      case 'truck':
        return 'Truck';
      case 'car':
        return 'Car (Taxi)';
      default:
        return vt;
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      // Get the customer's selected/current location
      final LocationData? customerLoc = await LocationService.instance.getCustomerLocation();
      
      final dbSubcategory = _getDbSubcategory(_vehicleType);
      
      final data = await supabase
          .from('service_providers')
          .select('*, charges:provider_service_charges(*)')
          .or('category.ilike.%transport%,category.ilike.%Transport%')
          .eq('is_active', true);
          
      final List<Map<String, dynamic>> processed = [];
      final targetSub = _getDbSubcategory(_vehicleType).toLowerCase();
      final targetType = _vehicleType.toLowerCase();
      
      for (var p in List<Map<String, dynamic>>.from(data)) {
        final sub = (p['subcategory'] as String? ?? '').toLowerCase();
        if (targetSub.isNotEmpty) {
          bool matches = sub.contains(targetType) || sub.contains(targetSub);
          if (!matches) {
            if (targetType == 'rickshaw' && (sub.contains('auto') || sub.contains('rickshaw'))) matches = true;
            else if (targetType == 'tempo' && sub.contains('tempo')) matches = true;
            else if (targetType == 'pickup_van' && (sub.contains('pickup') || sub.contains('bolero') || sub.contains('van'))) matches = true;
            else if (targetType == 'truck' && (sub.contains('truck') || sub.contains('tata') || sub.contains('heavy'))) matches = true;
            else if (targetType == 'car' && (sub.contains('car') || sub.contains('cab') || sub.contains('taxi'))) matches = true;
          }
          if (!matches) {
            final subList = (p['subcategories'] as List? ?? []).map((e) => e.toString().toLowerCase()).toList();
            if (subList.any((s) => s.contains(targetType) || s.contains(targetSub))) {
              matches = true;
            }
          }
          if (!matches) continue;
        }

        double distanceKm = 9999.0;
        
        double? pLat = (p['business_latitude'] as num?)?.toDouble() ?? (p['lat'] as num?)?.toDouble();
        double? pLng = (p['business_longitude'] as num?)?.toDouble() ?? (p['lng'] as num?)?.toDouble();
        
        final providerCity = (p['city'] as String? ?? '').trim().toLowerCase();
        final isDefaultPune = pLat != null && (pLat - 18.5204).abs() < 0.001 && pLng != null && (pLng - 73.8567).abs() < 0.001;
        
        if (pLat == null || pLng == null || pLat == 0 || (isDefaultPune && providerCity != 'pune')) {
          final fallback = _cityCoordsFallback[providerCity];
          if (fallback != null) {
            pLat = fallback[0];
            pLng = fallback[1];
          }
        }
        
        if (customerLoc != null && customerLoc.latitude != 0 && pLat != null && pLng != null && pLat != 0) {
          distanceKm = LocationService.instance.calculateDistance(
            customerLoc.latitude,
            customerLoc.longitude,
            pLat,
            pLng,
          );
        }
        
        p['distance'] = distanceKm < 9999.0 
            ? LocationService.instance.formatDistance(distanceKm) 
            : '';
        p['distance_value'] = distanceKm;
        processed.add(p);
      }
      
      if (mounted) {
        setState(() {
          _providers = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Use mock data for demo
      if (mounted) {
        setState(() {
          _providers = _mockProviders();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _mockProviders() {
    return [
      {
        'id': 'p1',
        'user_id': 'u1',
        'business_name': 'Rajesh $_vehicleLabel Service',
        'address': 'Nashik Road, Nashik',
        'rating': 4.8,
        'review_count': 124,
        'image_url': '',
        'is_open': true,
        'price_range': '₹50–₹200',
        'distance': '1.2 km',
        'trips': 340,
        'vehicle_no': 'MH15 AB 1234',
      },
      {
        'id': 'p2',
        'user_id': 'u2',
        'business_name': 'Suresh Transport',
        'address': 'College Road, Nashik',
        'rating': 4.5,
        'review_count': 89,
        'image_url': '',
        'is_open': true,
        'price_range': '₹60–₹250',
        'distance': '2.1 km',
        'trips': 210,
        'vehicle_no': 'MH15 CD 5678',
      },
      {
        'id': 'p3',
        'user_id': 'u3',
        'business_name': 'Ganesh $_vehicleLabel',
        'address': 'Gangapur Road, Nashik',
        'rating': 4.3,
        'review_count': 56,
        'image_url': '',
        'is_open': false,
        'price_range': '₹40–₹180',
        'distance': '3.5 km',
        'trips': 150,
        'vehicle_no': 'MH15 EF 9012',
      },
      {
        'id': 'p4',
        'user_id': 'u4',
        'business_name': 'Mahesh Travels',
        'address': 'Panchavati, Nashik',
        'rating': 4.6,
        'review_count': 201,
        'image_url': '',
        'is_open': true,
        'price_range': '₹55–₹220',
        'distance': '0.8 km',
        'trips': 480,
        'vehicle_no': 'MH15 GH 3456',
      },
      {
        'id': 'p5',
        'user_id': 'u5',
        'business_name': 'Shivam $_vehicleLabel Co.',
        'address': 'Satpur, Nashik',
        'rating': 4.2,
        'review_count': 43,
        'image_url': '',
        'is_open': true,
        'price_range': '₹45–₹190',
        'distance': '4.2 km',
        'trips': 98,
        'vehicle_no': 'MH15 IJ 7890',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredProviders {
    var list = List<Map<String, dynamic>>.from(_providers);
    if (_showAvailableOnly) {
      list = list.where((p) => p['is_open'] == true).toList();
    }
    if (_maxDistance < 51.0) {
      list = list.where((p) {
        final dist = (p['distance_value'] as num?)?.toDouble() ?? 9999.0;
        return dist <= _maxDistance;
      }).toList();
    }
    switch (_sortBy) {
      case 'nearest':
        list.sort((a, b) {
          final da = (a['distance_value'] as num?)?.toDouble() ?? 9999.0;
          final db = (b['distance_value'] as num?)?.toDouble() ?? 9999.0;
          return da.compareTo(db);
        });
        break;
      case 'rating':
        list.sort(
          (a, b) => ((b['rating'] as num?) ?? 0).compareTo(
            (a['rating'] as num?) ?? 0,
          ),
        );
        break;
      case 'fare_low':
        list.sort((a, b) {
          final fa =
              int.tryParse(
                (a['price_range'] as String? ?? '₹999')
                    .replaceAll('₹', '')
                    .split('–')
                    .first,
              ) ??
              999;
          final fb =
              int.tryParse(
                (b['price_range'] as String? ?? '₹999')
                    .replaceAll('₹', '')
                    .split('–')
                    .first,
              ) ??
              999;
          return fa.compareTo(fb);
        });
        break;
    }
    return list;
  }

  int get _maxSelect =>
      (_vehicleConfig[_vehicleType]?['maxSelect'] as int?) ?? 1;
  bool get _hasGoods =>
      (_vehicleConfig[_vehicleType]?['hasGoods'] as bool?) ?? false;

  void _toggleProvider(String id) {
    setState(() {
      if (_selectedProviderIds.contains(id)) {
        _selectedProviderIds.remove(id);
      } else {
        if (_selectedProviderIds.length < _maxSelect) {
          _selectedProviderIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to $_maxSelect provider${_maxSelect > 1 ? "s" : ""}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  void _submitRequest() {
    if (_selectedProviderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one provider'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_pickupController.text.isEmpty || _dropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and drop locations'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedProviders = _providers
        .where((p) => _selectedProviderIds.contains(p['id']))
        .toList();

    Navigator.pushNamed(
      context,
      AppRoutes.transportQuotationScreen,
      arguments: {
        'vehicleType': _vehicleType,
        'vehicleLabel': _vehicleLabel,
        'vehicleColor': _vehicleColor.value,
        'pickup': _pickupController.text,
        'drop': _dropController.text,
        'date': _selectedDate?.toIso8601String(),
        'time': _selectedTime != null
            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'goodsType': _hasGoods ? _goodsType : null,
        'weight': _hasGoods ? _weightController.text : null,
        'needsLoading': _needsLoading,
        'needsUnloading': _needsUnloading,
        'instructions': _instructionsController.text,
        'selectedProviders': selectedProviders,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _instructionsController.dispose();
    _weightController.dispose();
    _rideStatusChannel?.unsubscribe();
    super.dispose();
  }

  /// Subscribe to ride_requests for this customer to get real-time status updates
  void _subscribeToMyRideStatuses() {
    if (_currentUserId == null) return;
    _rideStatusChannel?.unsubscribe();
    _rideStatusChannel = Supabase.instance.client
        .channel('customer_ride_status_$_currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _currentUserId!,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newRecord = payload.newRecord;
            final status = newRecord['status'] as String?;
            final rideId = newRecord['id'] as String?;
            final providerName = newRecord['provider_name'] as String?;
            if (status != null && rideId != null) {
              _onRideStatusChanged(
                rideId: rideId,
                status: status,
                providerName: providerName,
              );
            }
          },
        )
        .subscribe();
  }

  void _onRideStatusChanged({
    required String rideId,
    required String status,
    String? providerName,
  }) {
    // Show in-app toast
    NotificationService.instance.showRideStatusToast(
      status: status,
      providerName: providerName,
      isProvider: false,
    );

    // Show system notification
    NotificationService.instance.showRideStatusNotification(
      rideId: rideId,
      status: status,
      providerName: providerName,
      isProvider: false,
    );

    // Increment badge for actionable statuses
    if ([
      'accepted',
      'rejected',
      'in_progress',
      'completed',
      'cancelled',
    ].contains(status)) {
      if (mounted) {
        setState(() => _unreadStatusCount++);
      }
    }

    // Update local ride list status
    if (mounted) {
      setState(() {
        final idx = _myActiveRides.indexWhere((r) => r['id'] == rideId);
        if (idx >= 0) {
          _myActiveRides[idx] = {..._myActiveRides[idx], 'status': status};
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _vehicleColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Notification badge for ride status updates
              if (_unreadStatusCount > 0)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _unreadStatusCount = 0);
                        _showRideStatusSheet();
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _unreadStatusCount > 9
                                ? '9+'
                                : '$_unreadStatusCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                onPressed: _showFilterSheet,
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
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 96),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _vehicleIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _vehicleLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _vehicleConfig[_vehicleType]?['desc']
                                        as String? ??
                                    '',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedProviderIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedProviderIds.length} selected',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _vehicleColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Column(
                children: [
                  // Vehicle type switcher
                  Container(
                    height: 40,
                    color: Colors.black.withValues(alpha: 0.15),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      children: _vehicleConfig.entries.map((e) {
                        final isActive = _vehicleType == e.key;
                        return GestureDetector(
                          onTap: () {
                            _setVehicleType(e.key);
                            _loadProviders();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.value['icon'] as IconData,
                                  size: 12,
                                  color: isActive
                                      ? _vehicleColor
                                      : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.value['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? _vehicleColor
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Find Providers'),
                      Tab(text: 'Book Now'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildProvidersTab(), _buildBookingFormTab()],
        ),
      ),
      bottomNavigationBar: _selectedProviderIds.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildProvidersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final providers = _filteredProviders;
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_vehicleIcon, size: 64, color: AppTheme.outline),
            const SizedBox(height: 16),
            Text(
              'No $_vehicleLabel providers nearby',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    final isDesktop = MediaQuery.of(context).size.width > 800;
    Widget listWidget;
    if (isDesktop) {
      listWidget = GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.8,
        ),
        itemCount: providers.length,
        itemBuilder: (context, i) => _buildProviderCard(providers[i]),
      );
    } else {
      listWidget = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: providers.length,
        itemBuilder: (context, i) => _buildProviderCard(providers[i]),
      );
    }

    Widget content = Column(
      children: [
        _buildSortBar(),
        Expanded(child: listWidget),
      ],
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '${_filteredProviders.length} providers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.outline,
            ),
          ),
          const Spacer(),
          ...[
            ('nearest', 'Nearest', Icons.near_me_rounded),
            ('rating', 'Top Rated', Icons.star_rounded),
            ('fare_low', 'Low Fare', Icons.payments_rounded),
          ].map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _sortBy = s.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _sortBy == s.$1
                        ? _vehicleColor
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.$3,
                        size: 11,
                        color: _sortBy == s.$1
                            ? Colors.white
                            : const Color(0xFF44474E),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        s.$2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _sortBy == s.$1
                              ? Colors.white
                              : const Color(0xFF44474E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final id = provider['id'] as String;
    final isSelected = _selectedProviderIds.contains(id);
    final isOpen = provider['is_open'] as bool? ?? true;
    // Use transport_status if available, fallback to is_open
    final transportStatus =
        provider['transport_status'] as String? ??
        (isOpen ? 'available' : 'offline');
    final isAvailable = transportStatus == 'available';
    final isBusy = transportStatus == 'busy';
    final rating = (provider['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = provider['review_count'] as int? ?? 0;
    final name = provider['business_name'] as String? ?? 'Provider';
    final address = provider['address'] as String? ?? '';
    final priceRange = provider['price_range'] as String? ?? '';
    final distance = provider['distance'] as String? ?? '';
    final trips = provider['trips'] as int? ?? 0;
    final vehicleNo = provider['vehicle_no'] as String? ?? '';
    final phone = provider['phone'] as String? ?? '';

    return GestureDetector(
      onTap: () => _toggleProvider(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _vehicleColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _vehicleColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _vehicleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_vehicleIcon, color: _vehicleColor, size: 26),
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
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1C1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Real-time availability badge (replaces slot booking)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppTheme.successContainer
                                    : isBusy
                                    ? const Color(0xFFFFF3E0)
                                    : AppTheme.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? AppTheme.success
                                          : isBusy
                                          ? const Color(0xFFE65100)
                                          : AppTheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAvailable
                                        ? 'Available'
                                        : isBusy
                                        ? 'Busy'
                                        : 'Offline',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isAvailable
                                          ? AppTheme.success
                                          : isBusy
                                          ? const Color(0xFFE65100)
                                          : AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
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
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ' ($reviewCount reviews)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF74777F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (trips > 0)
                              Text(
                                '$trips trips',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF74777F),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _vehicleColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (distance.isNotEmpty) ...[
                    const Icon(
                      Icons.near_me_rounded,
                      size: 13,
                      color: Color(0xFF74777F),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      distance,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(
                    Icons.payments_rounded,
                    size: 13,
                    color: Color(0xFF74777F),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    priceRange,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                  const Spacer(),
                  if (vehicleNo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicleNo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF44474E),
                        ),
                      ),
                    ),
                ],
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 12,
                      color: Color(0xFF90A4AE),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF90A4AE),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Contact & Track row
              Row(
                children: [
                  Expanded(
                    child: _buildContactButton(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chat',
                      color: _vehicleColor,
                      onTap: () => _openInAppChat(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildContactButton(
                      icon: Icons.message_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => _openWhatsApp(phone, name),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildContactButton(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      color: const Color(0xFF1976D2),
                      onTap: () => _makeCall(phone, name),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildContactButton(
                      icon: Icons.gps_fixed_rounded,
                      label: 'Track',
                      color: const Color(0xFFE65100),
                      onTap: () => _trackVehicle(provider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInAppChat(Map<String, dynamic> provider) {
    final providerId =
        provider['user_id'] as String? ?? provider['id'] as String;
    final providerName = provider['business_name'] as String? ?? 'Provider';
    Navigator.pushNamed(
      context,
      AppRoutes.chatDetailScreen,
      arguments: {
        'providerId': providerId,
        'providerName': providerName,
        'vehicleType': _vehicleType,
        'vehicleLabel': _vehicleLabel,
      },
    );
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final number = phone.isNotEmpty
        ? phone.replaceAll(RegExp(r'[^0-9+]'), '')
        : '';
    final message = Uri.encodeComponent(
      'Hi $name, I found you on LocalConnect. I need a $_vehicleLabel service. Can you help?',
    );
    final whatsappUrl = number.isNotEmpty
        ? 'https://wa.me/$number?text=$message'
        : 'https://wa.me/?text=$message';
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on this device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _makeCall(String phone, String name) async {
    final number = phone.isNotEmpty
        ? phone.replaceAll(RegExp(r'[^0-9+]'), '')
        : '';
    if (number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number not available for $name'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make a call from this device'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _trackVehicle(Map<String, dynamic> provider) {
    final providerId =
        provider['user_id'] as String? ?? provider['id'] as String;
    final providerName = provider['business_name'] as String? ?? 'Provider';
    final vehicleNo = provider['vehicle_no'] as String? ?? '';
    Navigator.pushNamed(
      context,
      AppRoutes.transportLiveMapScreen,
      arguments: {
        'vehicleType': _vehicleType,
        'vehicleLabel': _vehicleLabel,
        'providerId': providerId,
        'providerName': providerName,
        'vehicleNo': vehicleNo,
        'isCustomerView': true,
      },
    );
  }

  Widget _buildBookingFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Trip Details', Icons.route_rounded),
          const SizedBox(height: 12),
          _buildLocationField(
            controller: _pickupController,
            label: 'Pickup Location',
            icon: Icons.my_location_rounded,
            iconColor: AppTheme.success,
          ),
          const SizedBox(height: 10),
          _buildLocationField(
            controller: _dropController,
            label: 'Drop Location',
            icon: Icons.location_on_rounded,
            iconColor: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeTile(
                  label: _selectedDate == null
                      ? 'Select Date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateTimeTile(
                  label: _selectedTime == null
                      ? 'Select Time'
                      : _selectedTime!.format(context),
                  icon: Icons.access_time_rounded,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          if (_hasGoods) ...[
            const SizedBox(height: 20),
            _sectionHeader('Goods Details', Icons.inventory_2_rounded),
            const SizedBox(height: 12),
            _buildGoodsTypeSelector(),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Estimated Weight (kg)',
                prefixIcon: const Icon(Icons.scale_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToggleTile(
                    label: 'Loading Help',
                    icon: Icons.upload_rounded,
                    value: _needsLoading,
                    onChanged: (v) => setState(() => _needsLoading = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildToggleTile(
                    label: 'Unloading Help',
                    icon: Icons.download_rounded,
                    value: _needsUnloading,
                    onChanged: (v) => setState(() => _needsUnloading = v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _sectionHeader('Additional Info', Icons.notes_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Special Instructions (optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedProviderIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Go to "Find Providers" tab and select up to $_maxSelect provider${_maxSelect > 1 ? "s" : ""} first',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _hasGoods
                      ? 'Request Quotations from ${_selectedProviderIds.length} Provider${_selectedProviderIds.length > 1 ? "s" : ""}'
                      : 'Book Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vehicleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: const Icon(Icons.gps_fixed_rounded, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _vehicleColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF44474E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoodsTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goods Type',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF44474E),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goodsTypes
              .map(
                (g) => GestureDetector(
                  onTap: () => setState(() => _goodsType = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _goodsType == g
                          ? _vehicleColor
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      g,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _goodsType == g
                            ? Colors.white
                            : const Color(0xFF44474E),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? _vehicleColor.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: value ? _vehicleColor : AppTheme.outlineVariant,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? _vehicleColor : AppTheme.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? _vehicleColor : const Color(0xFF44474E),
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: value ? _vehicleColor : AppTheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _vehicleColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedProviderIds.length} of $_maxSelect selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.outline,
                  ),
                ),
                Text(
                  _hasGoods ? 'Request quotations' : 'Proceed to book',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _vehicleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue →',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRideStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ride Status Updates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_myActiveRides.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No active ride requests',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ),
              )
            else
              ...(_myActiveRides.take(5).map((ride) {
                final status = ride['status'] as String? ?? 'pending';
                final providerName =
                    ride['provider_name'] as String? ?? 'Provider';
                final pickup = ride['pickup_location'] as String? ?? '';
                final drop = ride['drop_location'] as String? ?? '';
                Color statusColor;
                IconData statusIcon;
                String statusLabel;
                switch (status) {
                  case 'accepted':
                    statusColor = const Color(0xFF2E7D32);
                    statusIcon = Icons.check_circle_rounded;
                    statusLabel = 'Accepted';
                    break;
                  case 'rejected':
                    statusColor = const Color(0xFFC62828);
                    statusIcon = Icons.cancel_rounded;
                    statusLabel = 'Rejected';
                    break;
                  case 'in_progress':
                    statusColor = const Color(0xFF1565C0);
                    statusIcon = Icons.directions_car_rounded;
                    statusLabel = 'In Progress';
                    break;
                  case 'completed':
                    statusColor = const Color(0xFF2E7D32);
                    statusIcon = Icons.celebration_rounded;
                    statusLabel = 'Completed';
                    break;
                  case 'cancelled':
                    statusColor = const Color(0xFFC62828);
                    statusIcon = Icons.cancel_rounded;
                    statusLabel = 'Cancelled';
                    break;
                  default:
                    statusColor = const Color(0xFF1565C0);
                    statusIcon = Icons.hourglass_empty_rounded;
                    statusLabel = 'Pending';
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (pickup.isNotEmpty)
                              Text(
                                '$pickup → $drop',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF74777F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Filter & Sort',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Only',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _showAvailableOnly,
                    onChanged: (v) {
                      setSheetState(() => _showAvailableOnly = v);
                      setState(() => _showAvailableOnly = v);
                    },
                    activeThumbColor: _vehicleColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _maxDistance == 51.0 ? 'Max Distance: See All' : 'Max Distance: ${_maxDistance.toInt()} km',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 51,
                divisions: 50,
                activeColor: _vehicleColor,
                onChanged: (v) {
                  setSheetState(() => _maxDistance = v);
                  setState(() => _maxDistance = v);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vehicleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

