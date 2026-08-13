import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../utils/image_upload_helper.dart';

class PlumberServiceManagementWidget extends StatefulWidget {
  const PlumberServiceManagementWidget({super.key});

  @override
  State<PlumberServiceManagementWidget> createState() =>
      _PlumberServiceManagementWidgetState();
}

class _PlumberServiceManagementWidgetState
    extends State<PlumberServiceManagementWidget> {
  static const _primaryColor = Color(0xFF0277BD);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _providerId;

  List<_ServiceItem> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
          await _loadServices();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadServices() async {
    if (_providerId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('provider_service_charges')
          .select()
          .eq('provider_id', _providerId!)
          .not('service_name', 'like', '__%')
          .order('sort_order');

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(data);
        if (list.isEmpty) {
          _services = _defaultServices();
        } else {
          _services = list.map((s) => _ServiceItem.fromMap(s)).toList();
        }
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        _services = _defaultServices();
        setState(() {});
      }
    }
  }

  List<_ServiceItem> _defaultServices() {
    return [
      _ServiceItem(
        name: 'Pipe Leakage Repair',
        basePrice: 300,
        minPrice: 200,
        maxPrice: 500,
        unit: 'per visit',
        isEmergency: false,
        isEnabled: true,
        description: 'Fix leaking pipes, joints and fittings',
        photos: [],
      ),
      _ServiceItem(
        name: 'Tap Installation',
        basePrice: 200,
        minPrice: 150,
        maxPrice: 400,
        unit: 'per tap',
        isEmergency: false,
        isEnabled: true,
        description: 'Install or replace taps and faucets',
        photos: [],
      ),
      _ServiceItem(
        name: 'Bathroom Fitting',
        basePrice: 800,
        minPrice: 600,
        maxPrice: 1500,
        unit: 'per visit',
        isEmergency: false,
        isEnabled: true,
        description: 'Complete bathroom plumbing setup',
        photos: [],
      ),
      _ServiceItem(
        name: 'Drain Blockage Removal',
        basePrice: 400,
        minPrice: 300,
        maxPrice: 800,
        unit: 'per visit',
        isEmergency: true,
        isEnabled: true,
        description: 'Clear blocked drains and pipes',
        photos: [],
      ),
      _ServiceItem(
        name: 'Water Tank Installation',
        basePrice: 1200,
        minPrice: 1000,
        maxPrice: 2500,
        unit: 'per tank',
        isEmergency: false,
        isEnabled: true,
        description: 'Install overhead or underground water tanks',
        photos: [],
      ),
    ];
  }

  Future<void> _saveAll() async {
    if (_providerId == null) return;
    setState(() => _isSaving = true);
    try {
      // Delete existing non-special entries
      await Supabase.instance.client
          .from('provider_service_charges')
          .delete()
          .eq('provider_id', _providerId!)
          .not('service_name', 'like', '__%');

      final toInsert = <Map<String, dynamic>>[];
      for (int i = 0; i < _services.length; i++) {
        final s = _services[i];
        toInsert.add({
          'provider_id': _providerId,
          'service_name': s.name,
          'base_price': s.basePrice,
          'min_price': s.minPrice,
          'max_price': s.maxPrice,
          'unit': s.unit,
          'is_emergency': s.isEmergency,
          'is_enabled': s.isEnabled,
          'description': s.description,
          'photos': s.photos,
          'sort_order': i,
        });
      }

      if (toInsert.isNotEmpty) {
        await Supabase.instance.client
            .from('provider_service_charges')
            .insert(toInsert);
      }

      _showSnack('Services saved successfully!', isSuccess: true);
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

  void _addService() {
    setState(() {
      _services.add(
        _ServiceItem(
          name: '',
          basePrice: 0,
          minPrice: null,
          maxPrice: null,
          unit: 'per visit',
          isEmergency: false,
          isEnabled: true,
          description: '',
          photos: [],
        ),
      );
    });
    // Scroll to bottom after adding
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showEditDialog(_services.length - 1);
      }
    });
  }

  void _deleteService(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Service',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${_services[index].name}" from your service list?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _services.removeAt(index));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final s = _services[index];
    final nameCtrl = TextEditingController(text: s.name);
    final basePriceCtrl = TextEditingController(
      text: s.basePrice > 0 ? s.basePrice.toStringAsFixed(0) : '',
    );
    final minPriceCtrl = TextEditingController(
      text: s.minPrice != null ? s.minPrice!.toStringAsFixed(0) : '',
    );
    final maxPriceCtrl = TextEditingController(
      text: s.maxPrice != null ? s.maxPrice!.toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController(text: s.description);
    String selectedUnit = s.unit;
    bool isEmergency = s.isEmergency;
    bool isEnabled = s.isEnabled;

    final units = [
      'per visit',
      'per hour',
      'per day',
      'per sqft',
      'per unit',
      'per tap',
      'per tank',
      'per pipe',
      'fixed',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.plumbing_rounded,
                          color: _primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.name.isEmpty ? 'Add New Service' : 'Edit Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Service Name
                  _dialogLabel('Service Name *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: _inputDecoration('e.g. Pipe Leakage Repair'),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _dialogLabel('Description'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    decoration: _inputDecoration(
                      'Brief description of the service...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pricing
                  _dialogLabel('Pricing (₹)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _priceField('Base Price', basePriceCtrl, '300'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _priceField('Min Price', minPriceCtrl, '200'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _priceField('Max Price', maxPriceCtrl, '500'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Unit
                  _dialogLabel('Charge Unit'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedUnit,
                        isExpanded: true,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        items: units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedUnit = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Toggles
                  Row(
                    children: [
                      Expanded(
                        child: _toggleChip(
                          'Emergency Service',
                          isEmergency,
                          Colors.red[700]!,
                          (v) => setDialogState(() => isEmergency = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _toggleChip(
                          'Active / Enabled',
                          isEnabled,
                          Colors.green[700]!,
                          (v) => setDialogState(() => isEnabled = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) {
                              _showSnack('Service name is required');
                              return;
                            }
                            setState(() {
                              _services[index] = _ServiceItem(
                                id: s.id,
                                name: nameCtrl.text.trim(),
                                basePrice:
                                    double.tryParse(basePriceCtrl.text) ?? 0,
                                minPrice: minPriceCtrl.text.isNotEmpty
                                    ? double.tryParse(minPriceCtrl.text)
                                    : null,
                                maxPrice: maxPriceCtrl.text.isNotEmpty
                                    ? double.tryParse(maxPriceCtrl.text)
                                    : null,
                                unit: selectedUnit,
                                isEmergency: isEmergency,
                                isEnabled: isEnabled,
                                description: descCtrl.text.trim(),
                                photos: s.photos,
                              );
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Save Service',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(int serviceIndex) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;

      final result = await ImageUploadHelper.validateAndCompress(picked);
      if (!result.isValid) {
        _showSnack(result.errorMessage ?? 'Invalid image');
        return;
      }

      if (_providerId == null) {
        _showSnack('Provider not found');
        return;
      }

      setState(() => _isSaving = true);

      final fileName =
          '$_providerId/service_${serviceIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('provider-photos')
          .uploadBinary(
            fileName,
            result.bytes!,
            fileOptions: FileOptions(
              contentType: result.mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('provider-photos')
          .getPublicUrl(fileName);

      setState(() {
        _services[serviceIndex].photos.add(publicUrl);
        _isSaving = false;
      });

      _showSnack('Photo added!', isSuccess: true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Failed to upload photo. Please try again.');
      }
    }
  }

  Future<void> _deletePhoto(int serviceIndex, int photoIndex) async {
    final photoUrl = _services[serviceIndex].photos[photoIndex];
    setState(() {
      _services[serviceIndex].photos.removeAt(photoIndex);
    });

    // Try to delete from storage
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('provider-photos');
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await Supabase.instance.client.storage.from('provider-photos').remove([
          filePath,
        ]);
      }
    } catch (_) {}

    _showSnack('Photo removed', isSuccess: true);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: Colors.grey[400],
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _priceField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '₹',
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _primaryColor,
              fontWeight: FontWeight.w600,
            ),
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
              borderSide: const BorderSide(color: _primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleChip(
    String label,
    bool value,
    Color activeColor,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? activeColor : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: value ? activeColor : Colors.grey[400],
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: value ? activeColor : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          'My Services',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
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
            )
          else
            TextButton.icon(
              onPressed: _saveAll,
              icon: const Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Save All',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addService,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Service',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _services.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _services.length,
              itemBuilder: (_, i) => _buildServiceCard(i),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.plumbing_rounded,
              size: 48,
              color: _primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No services added yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Service" to create your first service',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addService,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Service',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final s = _services[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: s.isEmergency
                        ? Colors.red[50]
                        : _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    s.isEmergency
                        ? Icons.warning_amber_rounded
                        : Icons.plumbing_rounded,
                    size: 18,
                    color: s.isEmergency ? Colors.red[700] : _primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name.isEmpty ? 'Unnamed Service' : s.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: s.name.isEmpty
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.isEmergency)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                'Emergency',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (s.description.isNotEmpty)
                        Text(
                          s.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Enable toggle
                Switch(
                  value: s.isEnabled,
                  onChanged: (v) =>
                      setState(() => _services[index].isEnabled = v),
                  activeColor: _primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Price row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _priceBadge(
                  'Base',
                  '₹${s.basePrice.toStringAsFixed(0)}',
                  _primaryColor,
                ),
                if (s.minPrice != null) ...[
                  const SizedBox(width: 6),
                  _priceBadge(
                    'Min',
                    '₹${s.minPrice!.toStringAsFixed(0)}',
                    Colors.green[700]!,
                  ),
                ],
                if (s.maxPrice != null) ...[
                  const SizedBox(width: 6),
                  _priceBadge(
                    'Max',
                    '₹${s.maxPrice!.toStringAsFixed(0)}',
                    Colors.orange[700]!,
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Photos section
          if (s.photos.isNotEmpty || true) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Service Photos',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _pickAndUploadPhoto(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 13,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Add Photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  itemCount: s.photos.length,
                  itemBuilder: (_, pi) => _buildPhotoThumb(index, pi),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No photos yet — tap "Add Photo" to upload',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Divider + actions
          Divider(height: 1, color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(index),
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: _primaryColor,
                  ),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteService(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: Colors.red[700],
                  ),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: s.isEnabled ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.isEnabled ? '● Active' : '○ Inactive',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: s.isEnabled ? Colors.green[700] : Colors.grey[500],
                      fontWeight: FontWeight.w600,
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

  Widget _priceBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(int serviceIndex, int photoIndex) {
    final url = _services[serviceIndex].photos[photoIndex];
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[100],
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _deletePhoto(serviceIndex, photoIndex),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for a service item
class _ServiceItem {
  String? id;
  String name;
  double basePrice;
  double? minPrice;
  double? maxPrice;
  String unit;
  bool isEmergency;
  bool isEnabled;
  String description;
  List<String> photos;

  _ServiceItem({
    this.id,
    required this.name,
    required this.basePrice,
    this.minPrice,
    this.maxPrice,
    required this.unit,
    required this.isEmergency,
    required this.isEnabled,
    required this.description,
    required this.photos,
  });

  factory _ServiceItem.fromMap(Map<String, dynamic> map) {
    final rawPhotos = map['photos'];
    List<String> photoList = [];
    if (rawPhotos is List) {
      photoList = rawPhotos.map((e) => e.toString()).toList();
    }
    return _ServiceItem(
      id: map['id'] as String?,
      name: map['service_name'] as String? ?? '',
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
      minPrice: (map['min_price'] as num?)?.toDouble(),
      maxPrice: (map['max_price'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? 'per visit',
      isEmergency: map['is_emergency'] as bool? ?? false,
      isEnabled: map['is_enabled'] as bool? ?? true,
      description: map['description'] as String? ?? '',
      photos: photoList,
    );
  }
}

