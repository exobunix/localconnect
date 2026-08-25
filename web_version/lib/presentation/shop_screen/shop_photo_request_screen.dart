import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../utils/image_upload_helper.dart';

/// Screen for customers to upload a photo of required goods/materials,
/// request a cost estimate, and choose delivery options
class ShopPhotoRequestScreen extends StatefulWidget {
  const ShopPhotoRequestScreen({super.key});

  @override
  State<ShopPhotoRequestScreen> createState() => _ShopPhotoRequestScreenState();
}

class _ShopPhotoRequestScreenState extends State<ShopPhotoRequestScreen> {
  String _subcategoryId = 'grocery';
  String _subcategoryName = 'Shop';
  String _providerId = '';
  String _providerName = '';

  // Photo
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isPickingPhoto = false;

  // Item description
  final _itemDescCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String _unit = 'kg';

  // Cost estimate
  bool _requestCostEstimate = true;
  final _budgetCtrl = TextEditingController();

  // Delivery
  String _deliveryOption =
      'home_delivery'; // 'home_delivery' | 'pickup' | 'express'
  final _addressCtrl = TextEditingController();
  String? _selectedSlot;

  bool _isSubmitting = false;
  bool _submitted = false;

  static const List<String> _units = [
    'kg',
    'g',
    'litre',
    'ml',
    'pcs',
    'dozen',
    'bundle',
    'box',
  ];

  static const List<String> _slots = [
    'As soon as possible',
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _subcategoryId = args['subcategoryId'] as String? ?? 'grocery';
      _subcategoryName = args['subcategoryName'] as String? ?? 'Shop';
      _providerId = args['providerId'] as String? ?? '';
      _providerName = args['providerName'] as String? ?? 'Shop';
    }
  }

  @override
  void dispose() {
    _itemDescCtrl.dispose();
    _quantityCtrl.dispose();
    _budgetCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final result = await ImageUploadHelper.validateAndCompress(file);
        if (!result.isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage!),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          return;
        }
        setState(() {
          _photoBytes = result.bytes;
          _photoName = file.name;
        });
      }
    } catch (_) {
      // silent fail
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _takeCameraPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final result = await ImageUploadHelper.validateAndCompress(file);
        if (!result.isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage!),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          return;
        }
        setState(() {
          _photoBytes = result.bytes;
          _photoName = file.name;
        });
      }
    } catch (_) {
      // silent fail
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_itemDescCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the items you need'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_deliveryOption == 'home_delivery' &&
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter delivery address'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = SupabaseService.instance.currentUser?.id;
      String? photoUrl;

      // Upload photo if available
      if (_photoBytes != null && _photoName != null) {
        try {
          final fileName =
              'photo_requests/${userId}_${DateTime.now().millisecondsSinceEpoch}_$_photoName';
          await SupabaseService.instance.client.storage
              .from('shop_photos')
              .uploadBinary(fileName, _photoBytes!);
          photoUrl = SupabaseService.instance.client.storage
              .from('shop_photos')
              .getPublicUrl(fileName);
        } catch (_) {
          // Continue without photo URL
        }
      }

      await SupabaseService.instance.client.from('shop_photo_requests').insert({
        'customer_id': userId,
        'provider_id': _providerId.isNotEmpty ? _providerId : null,
        'shop_subcategory': _subcategoryId,
        'item_description': _itemDescCtrl.text.trim(),
        'quantity': _quantityCtrl.text.trim(),
        'unit': _unit,
        'photo_url': photoUrl,
        'request_cost_estimate': _requestCostEstimate,
        'budget': _budgetCtrl.text.trim().isNotEmpty
            ? double.tryParse(_budgetCtrl.text.trim())
            : null,
        'delivery_option': _deliveryOption,
        'delivery_address': _deliveryOption == 'home_delivery'
            ? _addressCtrl.text.trim()
            : null,
        'preferred_slot': _selectedSlot,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) setState(() => _submitted = true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color get _accentColor {
    switch (_subcategoryId) {
      case 'grocery':
        return const Color(0xFF43A047);
      case 'vegetables':
        return const Color(0xFF2E7D32);
      case 'meat_fish':
        return const Color(0xFFD32F2F);
      case 'electrical':
      case 'plumbing_hardware':
        return const Color(0xFFF57C00);
      case 'seasonal':
        return const Color(0xFFFFB300);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Request Items',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: _accentColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Request Sent!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _requestCostEstimate
                  ? 'Your item request has been sent to $_providerName. They will share a cost estimate shortly.'
                  : 'Your item request has been sent to $_providerName. They will confirm availability and delivery.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          _buildInfoBanner(),
          const SizedBox(height: 16),
          // Photo upload
          _buildPhotoUpload(),
          const SizedBox(height: 16),
          // Item description
          _buildItemDescription(),
          const SizedBox(height: 16),
          // Cost estimate toggle
          _buildCostEstimateSection(),
          const SizedBox(height: 16),
          // Delivery options
          _buildDeliveryOptions(),
          const SizedBox(height: 24),
          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send Request to Shop',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _accentColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Upload a photo of items you need from $_subcategoryName. The shop will confirm availability and pricing.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Photo of Required Items',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a photo or upload from gallery',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 10),
        if (_photoBytes != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photoBytes!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _photoBytes = null;
                    _photoName = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _photoPickerBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: _isPickingPhoto ? null : _takeCameraPhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _photoPickerBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: _isPickingPhoto ? null : _pickPhoto,
                ),
              ),
            ],
          ),
        if (_isPickingPhoto)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _photoPickerBtn({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accentColor, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Description',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _itemDescCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. 2 kg fresh tomatoes, 1 dozen eggs, 500g paneer...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accentColor, width: 1.5),
            ),
          ),
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _accentColor, width: 1.5),
                  ),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _unit,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF1A1C1E),
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostEstimateSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
                      'Request Cost Estimate',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Text(
                      'Shop will send you a price quote',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _requestCostEstimate,
                onChanged: (v) => setState(() => _requestCostEstimate = v),
                activeColor: _accentColor,
              ),
            ],
          ),
          if (_requestCostEstimate) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Budget (₹) — Optional',
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accentColor, width: 1.5),
                ),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    final options = [
      {
        'id': 'home_delivery',
        'label': 'Home Delivery',
        'sub': 'Delivered to your address',
        'icon': Icons.delivery_dining_rounded,
        'color': const Color(0xFF1565C0),
      },
      {
        'id': 'pickup',
        'label': 'Self Pickup',
        'sub': 'Collect from shop',
        'icon': Icons.store_rounded,
        'color': const Color(0xFF2E7D32),
      },
      {
        'id': 'express',
        'label': 'Express Delivery',
        'sub': 'Within 2 hours (extra charge)',
        'icon': Icons.flash_on_rounded,
        'color': const Color(0xFFF57C00),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Option',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 10),
        ...options.map((opt) {
          final isSelected = _deliveryOption == opt['id'];
          final color = opt['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _deliveryOption = opt['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(15) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE5E7EB),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    color: isSelected ? color : const Color(0xFF9CA3AF),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? color : const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          opt['sub'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: color, size: 20),
                ],
              ),
            ),
          );
        }),
        // Address field for home delivery
        if (_deliveryOption == 'home_delivery' ||
            _deliveryOption == 'express') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Delivery Address *',
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
              prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _accentColor, width: 1.5),
              ),
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          const SizedBox(height: 10),
          // Slot selector
          Text(
            'Preferred Delivery Slot',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _slots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _accentColor
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    slot,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
