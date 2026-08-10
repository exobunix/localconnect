import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class VirtualShopSetupScreen extends StatefulWidget {
  final bool isEditing;
  const VirtualShopSetupScreen({super.key, this.isEditing = false});

  @override
  State<VirtualShopSetupScreen> createState() => _VirtualShopSetupScreenState();
}

class _VirtualShopSetupScreenState extends State<VirtualShopSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _existingProfile;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Step 0 – Shop Identity
  final _shopNameController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _profilePhotoUrl;
  String? _coverBannerUrl;
  Uint8List? _profilePhotoBytes;
  Uint8List? _coverBannerBytes;

  // Step 1 – Contact & Location
  final _contactController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _mapLocationController = TextEditingController();

  // Step 2 – Business Details
  final _workingHoursController = TextEditingController(
    text: '9:00 AM - 6:00 PM',
  );
  int _yearsExperience = 1;
  final _startingPriceController = TextEditingController();
  final List<String> _servicesOffered = [];
  final _serviceInputController = TextEditingController();

  // Step 3 – Gallery
  final List<String> _galleryPhotos = [];
  final List<Uint8List> _galleryBytes = [];

  final int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    if (widget.isEditing) _loadExistingProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    _shopNameController.dispose();
    _providerNameController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _serviceAreaController.dispose();
    _mapLocationController.dispose();
    _workingHoursController.dispose();
    _startingPriceController.dispose();
    _serviceInputController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.instance.getMyProviderProfile();
      if (profile != null && mounted) {
        _existingProfile = profile;
        _shopNameController.text = profile['business_name'] ?? '';
        _providerNameController.text = profile['owner_name'] ?? '';
        _descriptionController.text = profile['business_description'] ?? '';
        _profilePhotoUrl = profile['image_url'];
        _coverBannerUrl = profile['cover_image_url'];
        _contactController.text =
            profile['contact_number'] ?? profile['phone'] ?? '';
        _whatsappController.text =
            profile['whatsapp_number'] ?? profile['whatsapp'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _serviceAreaController.text = profile['service_area'] ?? '';
        _mapLocationController.text = profile['map_location'] ?? '';
        _workingHoursController.text =
            profile['working_hours'] ?? '9:00 AM - 6:00 PM';
        _yearsExperience = profile['years_experience'] ?? 1;
        _startingPriceController.text = (profile['starting_price'] ?? 0)
            .toString();
        final services = profile['services_offered'];
        if (services is List) {
          _servicesOffered.addAll(services.map((e) => e.toString()));
        }
        final gallery = profile['gallery_photos'];
        if (gallery is List) {
          _galleryPhotos.addAll(gallery.map((e) => e.toString()));
        }
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    } else {
      _saveShop();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    } else if (widget.isEditing) {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_shopNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Business/Shop name is required.');
          return false;
        }
        if (_providerNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Provider name is required.');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Business description is required.');
          return false;
        }
        break;
      case 1:
        if (_contactController.text.trim().length < 10) {
          setState(
            () => _errorMessage = 'Please enter a valid contact number.',
          );
          return false;
        }
        if (_whatsappController.text.trim().length < 10) {
          setState(
            () => _errorMessage = 'Please enter a valid WhatsApp number.',
          );
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Business address is required.');
          return false;
        }
        if (_serviceAreaController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Service area is required.');
          return false;
        }
        break;
      case 2:
        if (_workingHoursController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Working hours are required.');
          return false;
        }
        if (_servicesOffered.isEmpty) {
          setState(
            () => _errorMessage = 'Please add at least one service offered.',
          );
          return false;
        }
        break;
      case 3:
        if (_galleryPhotos.isEmpty && _galleryBytes.isEmpty) {
          setState(
            () => _errorMessage = 'Please add at least 1 gallery photo.',
          );
          return false;
        }
        break;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (mounted) setState(() => _profilePhotoBytes = bytes);
      }
    } catch (_) {}
  }

  Future<void> _pickCoverBanner() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (mounted) setState(() => _coverBannerBytes = bytes);
      }
    } catch (_) {}
  }

  Future<void> _pickGalleryPhoto() async {
    if (_galleryPhotos.length + _galleryBytes.length >= 10) {
      setState(() => _errorMessage = 'Maximum 10 gallery photos allowed.');
      return;
    }
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (mounted) setState(() => _galleryBytes.add(bytes));
      }
    } catch (_) {}
  }

  Future<String?> _uploadToStorage(Uint8List bytes, String path) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('provider-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return supabase.storage.from('provider-photos').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveShop() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final providerId = _existingProfile?['id'] as String?;
      final userId = SupabaseService.instance.currentUser?.id ?? 'unknown';
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload profile photo
      String? profileUrl = _profilePhotoUrl;
      if (_profilePhotoBytes != null) {
        profileUrl = await _uploadToStorage(
          _profilePhotoBytes!,
          'virtual-shop/$userId/profile_$ts.jpg',
        );
      }

      // Upload cover banner
      String? coverUrl = _coverBannerUrl;
      if (_coverBannerBytes != null) {
        coverUrl = await _uploadToStorage(
          _coverBannerBytes!,
          'virtual-shop/$userId/cover_$ts.jpg',
        );
      }

      // Upload gallery photos
      final List<String> allGallery = List.from(_galleryPhotos);
      for (int i = 0; i < _galleryBytes.length; i++) {
        final url = await _uploadToStorage(
          _galleryBytes[i],
          'virtual-shop/$userId/gallery_${ts}_$i.jpg',
        );
        if (url != null) allGallery.add(url);
      }

      await SupabaseService.instance.updateVirtualShop(
        providerId: providerId,
        businessName: _shopNameController.text.trim(),
        ownerName: _providerNameController.text.trim(),
        description: _descriptionController.text.trim(),
        profilePhotoUrl: profileUrl,
        coverBannerUrl: coverUrl,
        contactNumber: _contactController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        serviceArea: _serviceAreaController.text.trim(),
        mapLocation: _mapLocationController.text.trim(),
        workingHours: _workingHoursController.text.trim(),
        yearsExperience: _yearsExperience,
        startingPrice: double.tryParse(_startingPriceController.text) ?? 0,
        servicesOffered: _servicesOffered,
        galleryPhotos: allGallery,
      );

      if (mounted) {
        if (widget.isEditing) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Virtual Shop updated successfully!',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerPendingApprovalScreen,
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save shop. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2FF),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            if (_errorMessage != null) _buildErrorBar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Shop Identity',
      'Contact & Location',
      'Business Details',
      'Gallery',
    ];
    final subtitles = [
      'Name, photo & description',
      'How customers reach you',
      'Hours, experience & services',
      'Showcase your work',
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF26C6A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          if (widget.isEditing || _currentStep > 0)
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          if (widget.isEditing || _currentStep > 0) SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      widget.isEditing
                          ? 'Edit Virtual Shop'
                          : 'Setup Virtual Shop',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  titles[_currentStep],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  subtitles[_currentStep],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_currentStep + 1}/$_totalSteps',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.secondary
                          : isActive
                          ? AppTheme.primary
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) SizedBox(width: 1.w),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Identity();
      case 1:
        return _buildStep1Contact();
      case 2:
        return _buildStep2Business();
      case 3:
        return _buildStep3Gallery();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Shop Identity ────────────────────────────────────────────────

  Widget _buildStep0Identity() {
    return Column(
      children: [
        _buildInfoBanner(
          icon: Icons.storefront_rounded,
          color: AppTheme.primary,
          message:
              'Your Virtual Shop is your public business profile. Customers will see this before sending an enquiry.',
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.badge_rounded,
          title: 'Basic Information',
          child: Column(
            children: [
              _buildTextField(
                controller: _shopNameController,
                label: 'Business / Shop Name *',
                hint: 'e.g. Sharma Plumbing Services',
                icon: Icons.storefront_rounded,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _providerNameController,
                label: 'Provider / Owner Name *',
                hint: 'Your full name',
                icon: Icons.person_rounded,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _descriptionController,
                label: 'Business Description *',
                hint:
                    'Describe your services, expertise, and what makes you unique...',
                icon: Icons.description_rounded,
                maxLines: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.photo_camera_rounded,
          title: 'Profile Photo',
          child: _buildPhotoUploadTile(
            label: 'Profile Photo',
            hint: 'Upload your profile or business logo',
            bytes: _profilePhotoBytes,
            existingUrl: _profilePhotoUrl,
            onTap: _pickProfilePhoto,
            height: 12.h,
            isCircle: true,
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.panorama_rounded,
          title: 'Cover Banner',
          child: _buildPhotoUploadTile(
            label: 'Cover Banner',
            hint: 'Upload a wide banner image for your shop',
            bytes: _coverBannerBytes,
            existingUrl: _coverBannerUrl,
            onTap: _pickCoverBanner,
            height: 16.h,
            isCircle: false,
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  // ── Step 1: Contact & Location ───────────────────────────────────────────

  Widget _buildStep1Contact() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.contact_phone_rounded,
          title: 'Contact Details',
          child: Column(
            children: [
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number *',
                hint: '10-digit mobile number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _whatsappController,
                label: 'WhatsApp Number *',
                hint: 'WhatsApp number for enquiries',
                icon: Icons.chat_rounded,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.location_on_rounded,
          title: 'Location',
          child: Column(
            children: [
              _buildTextField(
                controller: _addressController,
                label: 'Business Address *',
                hint: 'Full address of your business',
                icon: Icons.home_rounded,
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _serviceAreaController,
                label: 'Service Area *',
                hint: 'e.g. Pune, Kothrud, Hinjewadi',
                icon: Icons.map_rounded,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _mapLocationController,
                label: 'Google Map Link (Optional)',
                hint: 'Paste Google Maps URL',
                icon: Icons.pin_drop_rounded,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  // ── Step 2: Business Details ─────────────────────────────────────────────

  Widget _buildStep2Business() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.schedule_rounded,
          title: 'Working Hours',
          child: _buildTextField(
            controller: _workingHoursController,
            label: 'Working Hours *',
            hint: 'e.g. 9:00 AM - 6:00 PM',
            icon: Icons.access_time_rounded,
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.workspace_premium_rounded,
          title: 'Experience',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Years of Experience *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_yearsExperience > 0) {
                        setState(() => _yearsExperience--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppTheme.primary,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_yearsExperience yrs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _yearsExperience++),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Pricing',
          child: _buildTextField(
            controller: _startingPriceController,
            label: 'Starting Price (Optional)',
            hint: 'e.g. 500',
            icon: Icons.currency_rupee_rounded,
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.build_rounded,
          title: 'Services Offered *',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serviceInputController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
                      decoration: InputDecoration(
                        hintText: 'e.g. Pipe Repair, Leak Fixing',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: const Color(0xFFB0BEC5),
                        ),
                        prefixIcon: Icon(
                          Icons.add_task_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: () {
                      final s = _serviceInputController.text.trim();
                      if (s.isNotEmpty && !_servicesOffered.contains(s)) {
                        setState(() {
                          _servicesOffered.add(s);
                          _serviceInputController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.5.h,
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
              if (_servicesOffered.isNotEmpty) ...[
                SizedBox(height: 1.5.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _servicesOffered
                      .map(
                        (s) => Chip(
                          label: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5.sp,
                            ),
                          ),
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          deleteIcon: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          onDeleted: () =>
                              setState(() => _servicesOffered.remove(s)),
                          side: BorderSide(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                          labelStyle: TextStyle(color: AppTheme.primary),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  // ── Step 3: Gallery ──────────────────────────────────────────────────────

  Widget _buildStep3Gallery() {
    final totalPhotos = _galleryPhotos.length + _galleryBytes.length;
    return Column(
      children: [
        _buildInfoBanner(
          icon: Icons.photo_library_rounded,
          color: const Color(0xFF7B1FA2),
          message:
              'Add at least 1 photo of your work. Gallery photos help customers trust your services.',
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.photo_library_rounded,
          title: 'Gallery Photos ($totalPhotos/10)',
          child: Column(
            children: [
              // Existing photos from URL
              if (_galleryPhotos.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _galleryPhotos.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _galleryPhotos[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE0E0E0),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _galleryPhotos.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // New photos from bytes
              if (_galleryBytes.isNotEmpty) ...[
                if (_galleryPhotos.isNotEmpty) SizedBox(height: 1.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _galleryBytes.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _galleryBytes[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _galleryBytes.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 1.5.h),
              if (totalPhotos < 10)
                GestureDetector(
                  onTap: _pickGalleryPhoto,
                  child: Container(
                    width: double.infinity,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            color: AppTheme.primary,
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
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildPhotoUploadTile({
    required String label,
    required String hint,
    required Uint8List? bytes,
    required String? existingUrl,
    required VoidCallback onTap,
    required double height,
    required bool isCircle,
  }) {
    final hasPhoto =
        bytes != null || (existingUrl != null && existingUrl.isNotEmpty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(isCircle ? 100 : 12),
          border: Border.all(
            color: hasPhoto ? AppTheme.primary : const Color(0xFFE0E0E0),
            width: hasPhoto ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : Image.network(
                      existingUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPhotoPlaceholder(hint),
                    )
            : _buildPhotoPlaceholder(hint),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String hint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          color: AppTheme.primary,
          size: 28,
        ),
        SizedBox(height: 0.5.h),
        Text(
          hint,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.sp,
            color: const Color(0xFF90A4AE),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5.sp,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0 && !widget.isEditing)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0 && !widget.isEditing) SizedBox(width: 3.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                elevation: 2,
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      isLastStep
                          ? (widget.isEditing
                                ? 'Save Changes'
                                : 'Complete Setup')
                          : 'Continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF44474E),
          ),
        ),
        SizedBox(height: 0.8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF1A237E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: const Color(0xFFB0BEC5),
            ),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5.sp,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
