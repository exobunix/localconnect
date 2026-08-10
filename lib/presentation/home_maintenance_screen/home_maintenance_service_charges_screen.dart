import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

/// Home Maintenance Service Charge Chart Editor
/// Allows providers to set and manage their service charges
class HomeMaintenanceServiceChargesScreen extends StatefulWidget {
  const HomeMaintenanceServiceChargesScreen({super.key});

  @override
  State<HomeMaintenanceServiceChargesScreen> createState() =>
      _HomeMaintenanceServiceChargesScreenState();
}

class _HomeMaintenanceServiceChargesScreenState
    extends State<HomeMaintenanceServiceChargesScreen> {
  static const _primary = Color(0xFF0277BD);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _providerId;
  String _subcategory = 'plumber';

  List<Map<String, dynamic>> _services = [];

  // Visiting / hourly / emergency rates
  final _visitingChargeCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  final _emergencyChargeCtrl = TextEditingController();

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
      _subcategory = args['subcategory'] as String? ?? 'plumber';
    }
  }

  @override
  void dispose() {
    _visitingChargeCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _emergencyChargeCtrl.dispose();
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
          await _loadServiceCharges();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadServiceCharges() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_service_charges')
          .select()
          .eq('provider_id', _providerId!)
          .order('sort_order');
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        if (list.isEmpty) {
          // Load defaults for subcategory
          _services = _defaultServices(_subcategory);
        } else {
          _services = list;
          // Extract visiting/hourly/emergency from special entries
          final visiting = list.firstWhere(
            (s) => s['service_name'] == '__visiting_charge',
            orElse: () => {},
          );
          final hourly = list.firstWhere(
            (s) => s['service_name'] == '__hourly_rate',
            orElse: () => {},
          );
          final emergency = list.firstWhere(
            (s) => s['service_name'] == '__emergency_charge',
            orElse: () => {},
          );
          _visitingChargeCtrl.text =
              (visiting['base_price'] as num?)?.toStringAsFixed(0) ?? '';
          _hourlyRateCtrl.text =
              (hourly['base_price'] as num?)?.toStringAsFixed(0) ?? '';
          _emergencyChargeCtrl.text =
              (emergency['base_price'] as num?)?.toStringAsFixed(0) ?? '';
          _services = list
              .where((s) => !(s['service_name'] as String).startsWith('__'))
              .toList();
        }
        setState(() {});
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _defaultServices(String sub) {
    final Map<String, List<Map<String, dynamic>>> defaults = {
      'plumber': [
        {
          'service_name': 'Pipe Leakage Repair',
          'base_price': 300.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Tap Installation',
          'base_price': 200.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Bathroom Fitting',
          'base_price': 800.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Drain Blockage Removal',
          'base_price': 400.0,
          'unit': 'per visit',
          'is_emergency': true,
          'is_enabled': true,
        },
        {
          'service_name': 'Water Tank Installation',
          'base_price': 1200.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
      ],
      'electrician': [
        {
          'service_name': 'Wiring Repair',
          'base_price': 350.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Switch/Socket Installation',
          'base_price': 150.0,
          'unit': 'per point',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Fan Installation',
          'base_price': 250.0,
          'unit': 'per fan',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'MCB/Fuse Replacement',
          'base_price': 200.0,
          'unit': 'per visit',
          'is_emergency': true,
          'is_enabled': true,
        },
      ],
      'carpenter': [
        {
          'service_name': 'Door Repair',
          'base_price': 400.0,
          'unit': 'per door',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Furniture Assembly',
          'base_price': 500.0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Wardrobe Fitting',
          'base_price': 1500.0,
          'unit': 'per unit',
          'is_emergency': false,
          'is_enabled': true,
        },
      ],
      'painter': [
        {
          'service_name': 'Wall Painting (per sqft)',
          'base_price': 15.0,
          'unit': 'per sqft',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Room Painting',
          'base_price': 2500.0,
          'unit': 'per room',
          'is_emergency': false,
          'is_enabled': true,
        },
        {
          'service_name': 'Exterior Painting',
          'base_price': 20.0,
          'unit': 'per sqft',
          'is_emergency': false,
          'is_enabled': true,
        },
      ],
    };
    return (defaults[sub] ??
            [
              {
                'service_name': 'General Service',
                'base_price': 300.0,
                'unit': 'per visit',
                'is_emergency': false,
                'is_enabled': true,
              },
            ])
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
  }

  Future<void> _saveAll() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);
    try {
      // Delete existing
      await Supabase.instance.client
          .from('provider_service_charges')
          .delete()
          .eq('provider_id', _providerId!);

      // Insert all services
      final toInsert = <Map<String, dynamic>>[];
      for (int i = 0; i < _services.length; i++) {
        final s = _services[i];
        toInsert.add({
          'provider_id': _providerId,
          'service_name': s['service_name'],
          'base_price': s['base_price'],
          'unit': s['unit'] ?? 'per visit',
          'is_emergency': s['is_emergency'] ?? false,
          'is_enabled': s['is_enabled'] ?? true,
          'sort_order': i,
        });
      }

      // Add special rate entries
      if (_visitingChargeCtrl.text.isNotEmpty) {
        toInsert.add({
          'provider_id': _providerId,
          'service_name': '__visiting_charge',
          'base_price': double.tryParse(_visitingChargeCtrl.text) ?? 0,
          'unit': 'per visit',
          'is_emergency': false,
          'is_enabled': true,
          'sort_order': 999,
        });
      }
      if (_hourlyRateCtrl.text.isNotEmpty) {
        toInsert.add({
          'provider_id': _providerId,
          'service_name': '__hourly_rate',
          'base_price': double.tryParse(_hourlyRateCtrl.text) ?? 0,
          'unit': 'per hour',
          'is_emergency': false,
          'is_enabled': true,
          'sort_order': 1000,
        });
      }
      if (_emergencyChargeCtrl.text.isNotEmpty) {
        toInsert.add({
          'provider_id': _providerId,
          'service_name': '__emergency_charge',
          'base_price': double.tryParse(_emergencyChargeCtrl.text) ?? 0,
          'unit': 'per visit',
          'is_emergency': true,
          'is_enabled': true,
          'sort_order': 1001,
        });
      }

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('provider_service_charges')
            .insert(toInsert);
      }

      _showSnack('Service charges saved!', isSuccess: true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addService() {
    setState(() {
      _services.add({
        'service_name': '',
        'base_price': 0.0,
        'unit': 'per visit',
        'is_emergency': false,
        'is_enabled': true,
      });
    });
  }

  void _removeService(int index) {
    setState(() => _services.removeAt(index));
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
          'Service Charge Chart',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveAll,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addService,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Service',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Rate summary card
                _buildRateSummaryCard(),
                const SizedBox(height: 16),
                // Services list
                Container(
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
                          Icon(
                            Icons.list_alt_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Service List & Charges',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_services.length} services',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_services.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No services added yet.\nTap "Add Service" to get started.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ...List.generate(_services.length, (i) {
                        final s = _services[i];
                        return _buildServiceRow(i, s);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveAll,
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
                          'Save All Charges',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRateSummaryCard() {
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
          Text(
            'Base Rate Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _rateField(
                  'Visiting Charge (₹)',
                  _visitingChargeCtrl,
                  hint: '150',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rateField(
                  'Hourly Rate (₹/hr)',
                  _hourlyRateCtrl,
                  hint: '300',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _rateField(
                  'Emergency (₹)',
                  _emergencyChargeCtrl,
                  hint: '600',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These base rates are shown to customers before booking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow(int index, Map<String, dynamic> service) {
    final nameCtrl = TextEditingController(
      text: service['service_name'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (service['base_price'] as num?)?.toStringAsFixed(0) ?? '0',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Service name',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => _services[index]['service_name'] = v,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) =>
                      _services[index]['base_price'] = double.tryParse(v) ?? 0,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                onPressed: () => _removeService(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Row(
            children: [
              _chipToggle(
                'Emergency',
                service['is_emergency'] as bool? ?? false,
                (v) => setState(() => _services[index]['is_emergency'] = v),
                activeColor: Colors.red[700]!,
              ),
              const SizedBox(width: 8),
              _chipToggle(
                'Enabled',
                service['is_enabled'] as bool? ?? true,
                (v) => setState(() => _services[index]['is_enabled'] = v),
                activeColor: Colors.green[700]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.12) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? activeColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: value ? activeColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
