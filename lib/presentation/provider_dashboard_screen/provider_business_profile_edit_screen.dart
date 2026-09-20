import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/image_upload_helper.dart';
import '../../widgets/location_map_picker_dialog.dart';

/// Universal Provider Business Profile Edit Screen
/// Allows any provider to edit their full business profile
class ProviderBusinessProfileEditScreen extends StatefulWidget {
  const ProviderBusinessProfileEditScreen({super.key});

  @override
  State<ProviderBusinessProfileEditScreen> createState() =>
      _ProviderBusinessProfileEditScreenState();
}

class _ProviderBusinessProfileEditScreenState
    extends State<ProviderBusinessProfileEditScreen> {
  static const _primary = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _providerId;

  // Location coordinates
  double? _latitude;
  double? _longitude;
  String _district = '';
  String _pincode = '';

  // Controllers
  final _businessNameCtrl = TextEditingController();
  final _providerNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _yearsExpCtrl = TextEditingController();
  final _workingHoursCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();

  String? _profilePhotoUrl;
  String? _coverImageUrl;
  bool _isUploadingProfile = false;
  bool _isUploadingCover = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _providerNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _yearsExpCtrl.dispose();
    _workingHoursCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _mapUrlCtrl.dispose();
    _emergencyCtrl.dispose();
    _languagesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final provider = await SupabaseService.instance.getMyProviderProfile();
      if (provider != null && mounted) {
        _providerId = provider['id'] as String?;
        _businessNameCtrl.text = provider['business_name'] as String? ?? '';
        _providerNameCtrl.text = provider['owner_name'] as String? ?? '';
        _descriptionCtrl.text =
            provider['business_description'] as String? ?? '';
        _yearsExpCtrl.text = (provider['years_experience'] as int? ?? 0)
            .toString();
        _workingHoursCtrl.text =
            provider['working_hours'] as String? ?? '9:00 AM - 6:00 PM';
        _serviceAreaCtrl.text = provider['service_area'] as String? ?? '';
        _phoneCtrl.text = provider['phone'] as String? ?? '';
        _whatsappCtrl.text = provider['whatsapp_number'] as String? ?? '';
        _emailCtrl.text = provider['email'] as String? ?? '';
        _addressCtrl.text = provider['address'] as String? ?? '';
        _mapUrlCtrl.text = provider['google_map_url'] as String? ?? '';
        _emergencyCtrl.text = provider['emergency_contact'] as String? ?? '';
        final langs = provider['languages_spoken'];
        if (langs is List) {
          _languagesCtrl.text = langs.join(', ');
        }
        _profilePhotoUrl = provider['image_url'] as String?;
        _coverImageUrl = provider['cover_image_url'] as String?;
        _latitude = (provider['business_latitude'] ?? provider['latitude']) as double?;
        _longitude = (provider['business_longitude'] ?? provider['longitude']) as double?;
        _district = provider['district'] as String? ?? '';
        _pincode = provider['pincode'] as String? ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openMapPicker() async {
    final result = await LocationMapPickerDialog.show(
      context,
      initialLat: _latitude,
      initialLng: _longitude,
      initialAddress: _addressCtrl.text.trim(),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (result.district.isNotEmpty) _district = result.district;
        if (result.pincode.isNotEmpty) _pincode = result.pincode;
        if (_addressCtrl.text.trim().isEmpty && result.fullAddress.isNotEmpty) {
          _addressCtrl.text = result.fullAddress;
        }
      });
    }
  }

  Future<void> _detectGpsLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        final loc = await LocationService.instance.reverseGeocode(
          pos.latitude,
          pos.longitude,
        );
        if (mounted) {
          setState(() {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
            if (loc != null) {
              if (loc.district.isNotEmpty) _district = loc.district;
              if (loc.pincode.isNotEmpty) _pincode = loc.pincode;
              if (_addressCtrl.text.trim().isEmpty && loc.fullAddress.isNotEmpty) {
                _addressCtrl.text = loc.fullAddress;
              }
            }
          });
          _showSnack('GPS location detected successfully!', isSuccess: true);
        }
      } else if (mounted) {
        _showSnack('Could not access GPS. Please check location permissions.');
      }
    } catch (e) {
      if (mounted) _showSnack('GPS error: $e');
    }
  }

  Future<void> _pickAndUploadImage({required bool isCover}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null || _providerId == null) return;

      // Validate format and compress
      final result = await ImageUploadHelper.validateAndCompress(image);
      if (!result.isValid) {
        _showSnack(result.errorMessage!);
        return;
      }

      if (isCover) {
        setState(() => _isUploadingCover = true);
      } else {
        setState(() => _isUploadingProfile = true);
      }

      final ext = image.name.split('.').last.toLowerCase();
      final fileName =
          '${isCover ? 'cover' : 'profile'}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final path = '$_providerId/$fileName';
      await Supabase.instance.client.storage
          .from('provider-photos')
          .uploadBinary(
            path,
            result.bytes!,
            fileOptions: FileOptions(
              contentType: result.mimeType!,
              upsert: true,
            ),
          );

      final url = Supabase.instance.client.storage
          .from('provider-photos')
          .getPublicUrl(path);

      if (isCover) {
        await Supabase.instance.client
            .from('service_providers')
            .update({'cover_image_url': url})
            .eq('id', _providerId!);
        if (mounted) setState(() => _coverImageUrl = url);
      } else {
        await Supabase.instance.client
            .from('service_providers')
            .update({'image_url': url})
            .eq('id', _providerId!);
        if (mounted) setState(() => _profilePhotoUrl = url);
      }

      _showSnack('Photo updated successfully!', isSuccess: true);
    } catch (e) {
      _showSnack('Failed to upload photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfile = false;
          _isUploadingCover = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _providerId == null) return;
    setState(() => _isSaving = true);

    try {
      final langs = _languagesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await Supabase.instance.client
          .from('service_providers')
          .update({
            'business_name': _businessNameCtrl.text.trim(),
            'owner_name': _providerNameCtrl.text.trim(),
            'business_description': _descriptionCtrl.text.trim(),
            'years_experience': int.tryParse(_yearsExpCtrl.text) ?? 0,
            'working_hours': _workingHoursCtrl.text.trim(),
            'service_area': _serviceAreaCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'whatsapp_number': _whatsappCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'google_map_url': _mapUrlCtrl.text.trim(),
            'emergency_contact': _emergencyCtrl.text.trim(),
            'languages_spoken': langs,
            'business_latitude': _latitude,
            'business_longitude': _longitude,
            'latitude': _latitude,
            'longitude': _longitude,
            'district': _district,
            'pincode': _pincode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _providerId!);

      _showSnack('Profile saved successfully!', isSuccess: true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save profile. Please try again.');
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
          'Edit Business Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveProfile,
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
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPhotosSection(),
                  const SizedBox(height: 16),
                  _buildSection('Business Information', Icons.business_rounded, [
                    _buildField(
                      'Business Name',
                      _businessNameCtrl,
                      required: true,
                      hint: 'e.g. Sharma Plumbing Services',
                    ),
                    _buildField(
                      'Provider / Owner Name',
                      _providerNameCtrl,
                      required: true,
                      hint: 'Your full name',
                    ),
                    _buildField(
                      'Business Description',
                      _descriptionCtrl,
                      maxLines: 4,
                      hint:
                          'Describe your services, expertise, and what makes you unique...',
                    ),
                    _buildField(
                      'Years of Experience',
                      _yearsExpCtrl,
                      keyboardType: TextInputType.number,
                      hint: 'e.g. 5',
                    ),
                    _buildField(
                      'Working Hours',
                      _workingHoursCtrl,
                      hint: 'e.g. 8:00 AM – 8:00 PM',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Contact Information',
                    Icons.contact_phone_rounded,
                    [
                      _buildField(
                        'Phone Number',
                        _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        required: true,
                        hint: '+91 98765 43210',
                      ),
                      _buildField(
                        'WhatsApp Number',
                        _whatsappCtrl,
                        keyboardType: TextInputType.phone,
                        hint: '+91 98765 43210',
                      ),
                      _buildField(
                        'Email Address',
                        _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'business@email.com',
                      ),
                      _buildField(
                        'Emergency Contact (Optional)',
                        _emergencyCtrl,
                        keyboardType: TextInputType.phone,
                        hint: 'Emergency contact number',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Location & Service Area',
                    Icons.location_on_rounded,
                    [
                      _buildField(
                        'Address',
                        _addressCtrl,
                        maxLines: 2,
                        hint: 'Full business address',
                      ),
                      _buildField(
                        'Service Area',
                        _serviceAreaCtrl,
                        hint: 'e.g. Pune, Nashik, Mumbai',
                      ),
                      _buildField(
                        'Google Maps Link (Optional)',
                        _mapUrlCtrl,
                        hint: 'Paste your Google Maps URL',
                      ),
                      _buildMapPinWidget(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    'Additional Details',
                    Icons.info_outline_rounded,
                    [
                      _buildField(
                        'Languages Spoken',
                        _languagesCtrl,
                        hint: 'e.g. Hindi, English, Marathi',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
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
                            'Save Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotosSection() {
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
              Icon(Icons.photo_camera_rounded, color: _primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profile & Cover Photos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Profile photo
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickAndUploadImage(isCover: false),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profilePhotoUrl != null
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _profilePhotoUrl == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        if (_isUploadingProfile)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Profile Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Cover image
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadImage(isCover: true),
                      child: Stack(
                        children: [
                          Container(
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              image: _coverImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_coverImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _coverImageUrl == null
                                ? Center(
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploadingCover)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cover / Banner Image',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Max 2 MB each • JPG, PNG, WEBP supported',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey[500],
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
              children: required
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
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
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMapPinWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Location on Map',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _latitude != null
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _latitude != null
                    ? const Color(0xFF4CAF50)
                    : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _latitude != null
                          ? Icons.check_circle_rounded
                          : Icons.location_off_rounded,
                      color: _latitude != null
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[500],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Location Pinned (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                            : 'Location Not Pinned',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _latitude != null
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: Text(
                          _latitude != null ? 'Change Pin' : 'Select on Map',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _detectGpsLocation,
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: Text(
                          'Use GPS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
}

