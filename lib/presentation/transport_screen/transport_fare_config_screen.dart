import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

/// Transport Provider Fare Configuration Screen
/// Full fare chart editor for all transport types
class TransportFareConfigScreen extends StatefulWidget {
  const TransportFareConfigScreen({super.key});

  @override
  State<TransportFareConfigScreen> createState() =>
      _TransportFareConfigScreenState();
}

class _TransportFareConfigScreenState extends State<TransportFareConfigScreen> {
  static const _primary = Color(0xFF1E88E5);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _providerId;
  String? _fareConfigId;
  String _vehicleType = 'rickshaw';

  // Fare fields
  final _baseFareCtrl = TextEditingController();
  final _perKmCtrl = TextEditingController();
  final _waitingCtrl = TextEditingController();
  final _nightChargeCtrl = TextEditingController();
  final _minimumFareCtrl = TextEditingController();
  final _hourlyPackageCtrl = TextEditingController();
  final _dailyPackageCtrl = TextEditingController();
  final _outstationFareCtrl = TextEditingController();
  final _extraChargesCtrl = TextEditingController();
  final _tollChargesCtrl = TextEditingController();
  final _parkingChargesCtrl = TextEditingController();
  bool _acAvailable = false;

  // Vehicle details
  final _vehicleNumberCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _seatingCapacityCtrl = TextEditingController();
  final _loadingCapacityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _vehicleType = args['vehicleType'] as String? ?? 'rickshaw';
    }
  }

  @override
  void dispose() {
    _baseFareCtrl.dispose();
    _perKmCtrl.dispose();
    _waitingCtrl.dispose();
    _nightChargeCtrl.dispose();
    _minimumFareCtrl.dispose();
    _hourlyPackageCtrl.dispose();
    _dailyPackageCtrl.dispose();
    _outstationFareCtrl.dispose();
    _extraChargesCtrl.dispose();
    _tollChargesCtrl.dispose();
    _parkingChargesCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _seatingCapacityCtrl.dispose();
    _loadingCapacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final provider = await Supabase.instance.client
            .from('service_providers')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (provider != null) {
          _providerId = provider['id'] as String?;
          await _loadFareConfig();
          await _loadVehicleDetails();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFareConfig() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('transport_fare_config')
          .select()
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (data != null && mounted) {
        _fareConfigId = data['id'] as String?;
        _baseFareCtrl.text =
            (data['base_fare'] as num?)?.toStringAsFixed(0) ?? '30';
        _perKmCtrl.text =
            (data['per_km_charge'] as num?)?.toStringAsFixed(0) ?? '12';
        _waitingCtrl.text =
            (data['waiting_charge_per_min'] as num?)?.toStringAsFixed(0) ?? '2';
        _nightChargeCtrl.text =
            (data['night_charge'] as num?)?.toStringAsFixed(0) ?? '0';
        _minimumFareCtrl.text =
            (data['minimum_fare'] as num?)?.toStringAsFixed(0) ?? '50';
        _hourlyPackageCtrl.text =
            (data['hourly_package'] as num?)?.toStringAsFixed(0) ?? '0';
        _dailyPackageCtrl.text =
            (data['daily_package'] as num?)?.toStringAsFixed(0) ?? '0';
        _outstationFareCtrl.text =
            (data['outstation_fare'] as num?)?.toStringAsFixed(0) ?? '0';
        _extraChargesCtrl.text = data['extra_charges'] as String? ?? '';
        _tollChargesCtrl.text =
            data['toll_charges'] as String? ?? 'As applicable';
        _parkingChargesCtrl.text =
            data['parking_charges'] as String? ?? 'As applicable';
        _acAvailable = data['ac_available'] as bool? ?? false;
      } else {
        // Set defaults
        _baseFareCtrl.text = '30';
        _perKmCtrl.text = '12';
        _waitingCtrl.text = '2';
        _minimumFareCtrl.text = '50';
        _tollChargesCtrl.text = 'As applicable';
        _parkingChargesCtrl.text = 'As applicable';
      }
    } catch (_) {}
  }

  Future<void> _loadVehicleDetails() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_vehicles')
          .select()
          .eq('provider_id', _providerId!)
          .maybeSingle();
      if (data != null && mounted) {
        _vehicleNumberCtrl.text = data['vehicle_number'] as String? ?? '';
        _vehicleModelCtrl.text = data['vehicle_model'] as String? ?? '';
        _seatingCapacityCtrl.text =
            (data['seating_capacity'] as int?)?.toString() ?? '3';
        _loadingCapacityCtrl.text = data['loading_capacity'] as String? ?? '';
      }
    } catch (_) {}
  }

  Future<void> _saveFareConfig() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);
    try {
      final fareData = {
        'provider_id': _providerId,
        'vehicle_type': _vehicleType,
        'fare_type': 'per_km',
        'base_fare': double.tryParse(_baseFareCtrl.text) ?? 0,
        'per_km_charge': double.tryParse(_perKmCtrl.text) ?? 0,
        'waiting_charge_per_min': double.tryParse(_waitingCtrl.text) ?? 0,
        'night_charge': double.tryParse(_nightChargeCtrl.text) ?? 0,
        'minimum_fare': double.tryParse(_minimumFareCtrl.text) ?? 0,
        'hourly_package': double.tryParse(_hourlyPackageCtrl.text) ?? 0,
        'daily_package': double.tryParse(_dailyPackageCtrl.text) ?? 0,
        'outstation_fare': double.tryParse(_outstationFareCtrl.text) ?? 0,
        'extra_charges': _extraChargesCtrl.text.trim(),
        'toll_charges': _tollChargesCtrl.text.trim(),
        'parking_charges': _parkingChargesCtrl.text.trim(),
        'ac_available': _acAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_fareConfigId != null) {
        await Supabase.instance.client
            .from('transport_fare_config')
            .update(fareData)
            .eq('id', _fareConfigId!);
      } else {
        await Supabase.instance.client
            .from('transport_fare_config')
            .insert(fareData);
      }

      // Save vehicle details
      final vehicleData = {
        'provider_id': _providerId,
        'vehicle_type': _vehicleType,
        'vehicle_number': _vehicleNumberCtrl.text.trim(),
        'vehicle_model': _vehicleModelCtrl.text.trim(),
        'seating_capacity': int.tryParse(_seatingCapacityCtrl.text) ?? 3,
        'loading_capacity': _loadingCapacityCtrl.text.trim(),
      };

      await Supabase.instance.client
          .from('provider_vehicles')
          .upsert(vehicleData, onConflict: 'provider_id,vehicle_type');

      _showSnack('Fare configuration saved!', isSuccess: true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: isSuccess ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Fare Configuration',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveFareConfig,
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Fare chart preview banner
                _buildFareChartPreview(),
                const SizedBox(height: 16),
                _buildSection('Vehicle Details', Icons.directions_car_rounded, [
                  _buildFareRow(
                    'Vehicle Number',
                    _vehicleNumberCtrl,
                    hint: 'MH 12 AB 1234',
                  ),
                  _buildFareRow(
                    'Vehicle Model',
                    _vehicleModelCtrl,
                    hint: 'e.g. Bajaj RE, Maruti Swift',
                  ),
                  _buildFareRow(
                    'Seating Capacity',
                    _seatingCapacityCtrl,
                    isNumber: true,
                    hint: '3',
                  ),
                  _buildFareRow(
                    'Loading Capacity (if applicable)',
                    _loadingCapacityCtrl,
                    hint: 'e.g. 500 kg',
                  ),
                  _buildToggleRow(
                    'AC Available',
                    _acAvailable,
                    (v) => setState(() => _acAvailable = v),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection(
                  'Base Fare Settings',
                  Icons.currency_rupee_rounded,
                  [
                    _buildFareRow(
                      'Base Fare (₹)',
                      _baseFareCtrl,
                      isNumber: true,
                      hint: '30',
                    ),
                    _buildFareRow(
                      'Per Kilometer Charge (₹)',
                      _perKmCtrl,
                      isNumber: true,
                      hint: '12',
                    ),
                    _buildFareRow(
                      'Minimum Fare (₹)',
                      _minimumFareCtrl,
                      isNumber: true,
                      hint: '50',
                    ),
                    _buildFareRow(
                      'Waiting Charge (₹/min)',
                      _waitingCtrl,
                      isNumber: true,
                      hint: '2',
                    ),
                    _buildFareRow(
                      'Night Charge (₹ extra)',
                      _nightChargeCtrl,
                      isNumber: true,
                      hint: '0',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection('Package Rates', Icons.inventory_2_rounded, [
                  _buildFareRow(
                    'Hourly Package (₹/hr)',
                    _hourlyPackageCtrl,
                    isNumber: true,
                    hint: '0',
                  ),
                  _buildFareRow(
                    'Daily Package (₹/day)',
                    _dailyPackageCtrl,
                    isNumber: true,
                    hint: '0',
                  ),
                  _buildFareRow(
                    'Outstation Fare (₹/km)',
                    _outstationFareCtrl,
                    isNumber: true,
                    hint: '0',
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection(
                  'Additional Charges',
                  Icons.add_circle_outline_rounded,
                  [
                    _buildFareRow(
                      'Toll Charges',
                      _tollChargesCtrl,
                      hint: 'As applicable',
                    ),
                    _buildFareRow(
                      'Parking Charges',
                      _parkingChargesCtrl,
                      hint: 'As applicable',
                    ),
                    _buildFareRow(
                      'Extra Charges (describe)',
                      _extraChargesCtrl,
                      hint: 'e.g. Airport surcharge ₹100',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveFareConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Fare Configuration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildFareChartPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fare Chart Preview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Live Preview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _fareChip(
                'Base',
                '₹${_baseFareCtrl.text.isEmpty ? '0' : _baseFareCtrl.text}',
              ),
              _fareChip(
                'Per KM',
                '₹${_perKmCtrl.text.isEmpty ? '0' : _perKmCtrl.text}',
              ),
              _fareChip(
                'Min Fare',
                '₹${_minimumFareCtrl.text.isEmpty ? '0' : _minimumFareCtrl.text}',
              ),
              _fareChip(
                'Waiting',
                '₹${_waitingCtrl.text.isEmpty ? '0' : _waitingCtrl.text}/min',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customers see this fare chart before booking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Icon(icon, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFareRow(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: ctrl,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: _primary),
        ],
      ),
    );
  }
}

