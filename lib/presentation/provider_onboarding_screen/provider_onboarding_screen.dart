import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../data/app_categories.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  State<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Step 1 - Shop Name
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();

  // Step 2 - Category
  String? _selectedCategory;
  String? _selectedSubcategory;

  // Step 3 - Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Step 4 - Phone
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Step 5 - Documents
  final List<Map<String, String>> _documents = [];
  final _docNameController = TextEditingController();
  final _docTypeController = TextEditingController();

  final List<String> _docTypes = [
    'Aadhar Card',
    'PAN Card',
    'Shop License',
    'GST Certificate',
    'Bank Passbook',
    'Other',
  ];
  String _selectedDocType = 'Aadhar Card';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Pre-fill owner name from user profile
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      final fullName = user.userMetadata?['full_name'] as String? ?? '';
      _ownerNameController.text = fullName;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _docNameController.dispose();
    _docTypeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    } else {
      _submitOnboarding();
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
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_shopNameController.text.trim().isEmpty) {
          setState(
            () => _errorMessage = 'Please enter your shop/business name.',
          );
          return false;
        }
        if (_ownerNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter the owner name.');
          return false;
        }
        break;
      case 1:
        if (_selectedCategory == null) {
          setState(() => _errorMessage = 'Please select a category.');
          return false;
        }
        break;
      case 2:
        if (_addressController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your address.');
          return false;
        }
        if (_cityController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your city.');
          return false;
        }
        break;
      case 3:
        if (_phoneController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your phone number.');
          return false;
        }
        if (_phoneController.text.trim().length < 10) {
          setState(() => _errorMessage = 'Please enter a valid phone number.');
          return false;
        }
        break;
      case 4:
        // Documents are optional but at least one encouraged
        break;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> _submitOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) throw Exception('User not found.');

      await SupabaseService.instance.createProviderProfile(
        userId: userId,
        businessName: _shopNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        category: _selectedCategory!,
        subcategory: _selectedSubcategory ?? '',
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        documents: _documents,
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeScreen,
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addDocument() {
    if (_docNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a document name/number.');
      return;
    }
    setState(() {
      _documents.add({
        'type': _selectedDocType,
        'name': _docNameController.text.trim(),
        'url': '',
      });
      _docNameController.clear();
      _errorMessage = null;
    });
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
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
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stepTitles = [
      'Business Info',
      'Category',
      'Location',
      'Contact',
      'Documents',
    ];
    final stepSubtitles = [
      'Tell us about your business',
      'What services do you offer?',
      'Where are you located?',
      'How can customers reach you?',
      'Upload verification documents',
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
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handyman_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[_currentStep],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  stepSubtitles[_currentStep],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Step ${_currentStep + 1}/5',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(width: 3.w),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await SupabaseService.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: List.generate(5, (index) {
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
                if (index < 4) SizedBox(width: 1.w),
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
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return _buildCard(
      icon: Icons.storefront_rounded,
      title: 'Business Details',
      child: Column(
        children: [
          _buildTextField(
            controller: _shopNameController,
            label: 'Shop / Business Name',
            hint: 'e.g. Sharma Electricals',
            icon: Icons.storefront_rounded,
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: _ownerNameController,
            label: 'Owner Name',
            hint: 'Your full name',
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 2.h),
          _buildInfoTip(
            'Your business name will be visible to customers searching for services in your area.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildCard(
      icon: Icons.category_rounded,
      title: 'Service Category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: AppCategories.all.map((cat) {
              final isSelected = _selectedCategory == cat.name;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = cat.name;
                  _selectedSubcategory = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? AppTheme.primary : cat.color,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        cat.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF44474E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedCategory != null) ...[
            SizedBox(height: 2.h),
            Text(
              'Select Subcategory (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF44474E),
              ),
            ),
            SizedBox(height: 1.h),
            Builder(
              builder: (context) {
                final cat = AppCategories.all.firstWhere(
                  (c) => c.name == _selectedCategory,
                  orElse: () => AppCategories.all.first,
                );
                return Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: cat.subcategories.map((sub) {
                    final isSelected = _selectedSubcategory == sub.name;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedSubcategory = sub.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.secondary.withValues(alpha: 0.1)
                              : const Color(0xFFF5F7FF),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.secondary
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          sub.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.secondary
                                : const Color(0xFF44474E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildCard(
      icon: Icons.location_on_rounded,
      title: 'Business Location',
      child: Column(
        children: [
          _buildTextField(
            controller: _addressController,
            label: 'Full Address',
            hint: 'Street, Area, Landmark',
            icon: Icons.home_rounded,
            maxLines: 3,
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'e.g. Pune',
            icon: Icons.location_city_rounded,
          ),
          SizedBox(height: 2.h),
          _buildInfoTip(
            'Customers nearby will discover your business based on your location.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return _buildCard(
      icon: Icons.phone_rounded,
      title: 'Contact Details',
      child: Column(
        children: [
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'e.g. 9876543210',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: _whatsappController,
            label: 'WhatsApp Number (Optional)',
            hint: 'Same as phone or different',
            icon: Icons.chat_rounded,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 2.h),
          _buildInfoTip(
            'Customers will use this number to contact you for bookings and inquiries.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.upload_file_rounded,
          title: 'Verification Documents',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoTip(
                'Upload documents to get verified. Verified providers get more bookings.',
              ),
              SizedBox(height: 2.h),
              Text(
                'Document Type',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDocType,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: const Color(0xFF1A1C1E),
                    ),
                    items: _docTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(
                      () => _selectedDocType = val ?? _selectedDocType,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              _buildTextField(
                controller: _docNameController,
                label: 'Document Number / Name',
                hint: 'e.g. XXXX-XXXX-XXXX',
                icon: Icons.badge_rounded,
              ),
              SizedBox(height: 1.5.h),
              GestureDetector(
                onTap: _addDocument,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppTheme.secondary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Add Document',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_documents.isNotEmpty) ...[
          SizedBox(height: 2.h),
          _buildCard(
            icon: Icons.checklist_rounded,
            title: 'Added Documents (${_documents.length})',
            child: Column(
              children: _documents.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFFBBD6F5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['type'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            Text(
                              doc['name'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5.sp,
                                color: const Color(0xFF74777F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        onPressed: () => _removeDocument(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF57F17),
                size: 18,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Documents are optional. You can add them later from your profile settings.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5.sp,
                    color: const Color(0xFFF57F17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              SizedBox(width: 3.w),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          color: const Color(0xFF74777F),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          color: const Color(0xFFB0B0B0),
        ),
      ),
    );
  }

  Widget _buildInfoTip(String text) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFBBD6F5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5.sp,
                color: const Color(0xFF44474E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              margin: EdgeInsets.only(bottom: 1.5.h),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF44474E),
                            size: 18,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Back',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF44474E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
              ],
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _isLoading ? null : _nextStep,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentStep == 4
                                      ? 'Complete Setup'
                                      : 'Continue',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(
                                  _currentStep == 4
                                      ? Icons.check_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_currentStep == 4) ...[
            SizedBox(height: 1.h),
            GestureDetector(
              onTap: _isLoading ? null : _submitOnboarding,
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  color: const Color(0xFF74777F),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
