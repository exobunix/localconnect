import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/app_categories.dart';
import '../../routes/app_routes.dart';
import '../../services/category_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

// twilio_otp_service removed — phone OTP no longer used

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Step 0 - Account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 1 - Business Info
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();

  // Step 2 - Category
  String? _selectedCategory;
  String? _selectedSubcategory;
  final _approvalReasonController = TextEditingController();
  List<DynamicCategory> _activeCategories = [];
  bool _categoriesLoaded = false;

  // Step 3 - Location & Contact
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Step 4 - Phone OTP Verification
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _phoneVerified = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;
  bool _otpSent = false;

  // Step 5 - Document Upload
  XFile? _identityDocFile;
  String _identityDocType = 'Aadhar Card';
  final _identityDocNumberController = TextEditingController();
  XFile? _businessLicenseFile;
  String _businessLicenseType = 'Shop License';
  final _businessLicenseNumberController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _identityDocTypes = [
    'Aadhar Card',
    'PAN Card',
    'Voter ID',
    'Passport',
    'Driving License',
  ];
  final List<String> _businessLicenseTypes = [
    'Shop License',
    'GST Certificate',
    'Trade License',
    'FSSAI License',
    'Bank Passbook',
    'Other',
  ];

  // Step 5 legacy doc list (kept for submission compatibility)
  final List<Map<String, String>> _documents = [];
  final _docNameController = TextEditingController();
  final String _selectedDocType = 'Aadhar Card';
  final List<String> _docTypes = [
    'Aadhar Card',
    'PAN Card',
    'Shop License',
    'GST Certificate',
    'Bank Passbook',
    'Other',
  ];

  final int _totalSteps = 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadActiveCategories();
  }

  Future<void> _loadActiveCategories() async {
    try {
      final categories = await CategoryService.instance.getActiveCategories();
      if (mounted) {
        setState(() {
          _activeCategories = categories;
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('[ProviderRegistration] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _activeCategories = [];
          _categoriesLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _approvalReasonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _docNameController.dispose();
    _identityDocNumberController.dispose();
    _businessLicenseNumberController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep == 3) {
      // Moving from Location to Document step — let's sign up the user (create user account) here!
      _goToDocumentStep();
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    } else {
      _submitRegistration();
    }
  }

  Future<void> _goToDocumentStep() async {
    setState(() {
      _currentStep = 4; // Step 4 is now Document Upload
      _errorMessage = null;
    });
    _animController.reset();
    _animController.forward();
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    GoogleSignInAccount? googleUser;
    try {
      if (kIsWeb) {
        await SupabaseService.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.toString(),
          queryParams: {
            'role': 'provider',
          },
        );
        return;
      }

      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? (webClientId.isEmpty ? '78703580798-ga1vsmbjl90te533l9imt84ub1l12p4d.apps.googleusercontent.com' : webClientId) : null,
        serverClientId: kIsWeb ? null : (webClientId.isEmpty ? '78703580798-ga1vsmbjl90te533l9imt84ub1l12p4d.apps.googleusercontent.com' : webClientId),
      );
      googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleUser.id;
      final accessToken = googleAuth.accessToken;

      await SupabaseService.instance.signInWithGoogleIdToken(
        idToken: idToken,
        accessToken: accessToken,
        email: googleUser.email,
        name: googleUser.displayName,
      );

      if (!mounted) return;

      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final existingRole = user.userMetadata?['role'] as String?;
        if (existingRole == null || existingRole.isEmpty) {
          await SupabaseService.instance.client.auth.updateUser(
            UserAttributes(data: {'role': 'provider'}),
          );
        }
      }

      final userId = user?.id;
      if (userId != null) {
        final onboardingDone = await SupabaseService.instance
            .isProviderOnboardingComplete(userId);
        if (!mounted) return;
        if (onboardingDone) {
          final regStatus = await SupabaseService.instance
              .getProviderRegistrationStatus(userId);
          if (!mounted) return;
          if (regStatus == 'approved') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerDashboardScreen,
              (route) => false,
            );
          } else if (regStatus == 'pending_approval' || regStatus == 'rejected') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerPendingApprovalScreen,
              (route) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (route) => false,
            );
          }
          return;
        }
      }

      // Prefill fields and advance to Step 1
      setState(() {
        _emailController.text = googleUser?.email ?? '';
        _ownerNameController.text = googleUser?.displayName ?? '';
        _isGoogleLoading = false;
        _currentStep = 1;
      });
      _animController.reset();
      _animController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In failed: $e';
          _isGoogleLoading = false;
        });
      }
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (SupabaseService.instance.currentUser == null) {
          setState(() => _errorMessage = 'Please sign in with Google to continue.');
          return false;
        }
        break;
      case 1:
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
      case 2:
        if (_selectedCategory == null) {
          setState(() => _errorMessage = 'Please select a service category.');
          return false;
        }
        if (_approvalReasonController.text.trim().isEmpty) {
          setState(
            () => _errorMessage =
                'Please briefly describe your experience in this category.',
          );
          return false;
        }
        break;
      case 3:
        if (_addressController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your business address.');
          return false;
        }
        if (_cityController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter your city.');
          return false;
        }
        if (_phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length <
            10) {
          setState(() => _errorMessage = 'Please enter a valid phone number.');
          return false;
        }
        break;
      case 4:
        // Document upload — at least identity doc required
        if (_identityDocFile == null &&
            _identityDocNumberController.text.trim().isEmpty) {
          setState(
            () => _errorMessage =
                'Please upload your identity document or enter the document number.',
          );
          return false;
        }
        // Sync documents list for submission
        _syncDocumentsForSubmission();
        break;
      case 5:
        // Final confirmation — no extra validation needed
        break;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  void _syncDocumentsForSubmission() {
    _documents.clear();
    if (_identityDocNumberController.text.trim().isNotEmpty ||
        _identityDocFile != null) {
      _documents.add({
        'type': _identityDocType,
        'name': _identityDocNumberController.text.trim().isNotEmpty
            ? _identityDocNumberController.text.trim()
            : 'File uploaded',
        'url': _identityDocFile?.path ?? '',
      });
    }
    if (_businessLicenseNumberController.text.trim().isNotEmpty ||
        _businessLicenseFile != null) {
      _documents.add({
        'type': _businessLicenseType,
        'name': _businessLicenseNumberController.text.trim().isNotEmpty
            ? _businessLicenseNumberController.text.trim()
            : 'File uploaded',
        'url': _businessLicenseFile?.path ?? '',
      });
    }
  }

  Future<void> _pickIdentityDoc() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() => _identityDocFile = file);
      }
    } catch (_) {
      // Silently handle picker errors
    }
  }

  Future<void> _pickBusinessLicense() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() => _businessLicenseFile = file);
      }
    } catch (_) {
      // Silently handle picker errors
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ensure documents are synced before submission
      _syncDocumentsForSubmission();

      String? userId = SupabaseService.instance.currentUser?.id;

      if (userId == null) {
        // Fallback or signup if not already signed up/logged in
        final authResponse = await SupabaseService.instance.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _ownerNameController.text.trim(),
          role: 'provider',
          phone: _phoneController.text.trim(),
        );
        userId = authResponse.user?.id;
      }

      if (userId == null) throw Exception('Account creation failed.');

      // Step 2: Create provider profile + category approval request
      await SupabaseService.instance.registerProviderWithApproval(
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
        approvalReason: _approvalReasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.providerPendingApprovalScreen,
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      print('[ProviderRegistration ERROR] Registration failed: $e');
      setState(
        () => _errorMessage =
            'Registration failed ($e). Please try again.',
      );
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

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        _buildHeader(),
        _buildStepIndicator(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );

    if (kIsWeb && MediaQuery.of(context).size.width > 800) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2FF),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: content,
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Register',
      'Business Info',
      'Service Category',
      'Location & Contact',
      'Upload Documents',
      'Confirm & Submit',
    ];
    final subtitles = [
      'Set up your provider account',
      'Tell us about your business',
      'Request category approval',
      'Where customers can find you',
      'Identity & business license',
      'Review and complete registration',
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
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            children: [
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
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[_currentStep],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitles[_currentStep],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: Colors.white.withValues(alpha: 0.85),
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
              if (SupabaseService.instance.currentUser != null) ...[
                SizedBox(width: 2.w),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Account();
      case 1:
        return _buildStep1Business();
      case 2:
        return _buildStep2Category();
      case 3:
        return _buildStep3Location();
      case 4:
        return _buildStep5DocumentUpload();
      case 5:
        return _buildStep6Confirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep0Account() {
    return _buildCard(
      icon: Icons.person_add_rounded,
      title: 'Register as a Provider',
      child: Column(
        children: [
          _buildInfoBanner(
            icon: Icons.info_outline_rounded,
            color: AppTheme.primary,
            message:
                'Register as a provider to offer your services on LocalConnect. Please sign in with Google to begin your application.',
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
            child: Container(
              width: double.infinity,
              height: 6.5.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 28,
                            color: Color(0xFF4285F4),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStep1Business() {
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
            label: 'Owner / Your Full Name',
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

  Widget _buildStep2Category() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.category_rounded,
          title: 'Service Category',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(
                icon: Icons.approval_rounded,
                color: const Color(0xFFFF6F00),
                message:
                    'Category approval is required. Our team will review your request within 24-48 hours.',
              ),
              SizedBox(height: 2.h),
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
                children:
                    (_categoriesLoaded ? _activeCategories : <AppCategory>[])
                        .map((cat) {
                          final typedCat = cat as DynamicCategory;
                          final isSelected = _selectedCategory == typedCat.name;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = typedCat.name;
                              _selectedSubcategory = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
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
                                    typedCat.icon,
                                    size: 16,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : typedCat.color,
                                  ),
                                  SizedBox(width: 1.5.w),
                                  Text(
                                    typedCat.name,
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
                        })
                        .toList(),
              ),
              if (!_categoriesLoaded) ...[
                SizedBox(height: 1.h),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
              if (_selectedCategory != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Subcategory (Optional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF44474E),
                  ),
                ),
                SizedBox(height: 1.h),
                Builder(
                  builder: (context) {
                    final cat = _activeCategories.isNotEmpty
                        ? _activeCategories.firstWhere(
                            (c) => c.name == _selectedCategory,
                            orElse: () => _activeCategories.first,
                          )
                        : null;
                    if (cat == null || cat.subcategories.isEmpty) {
                      return const SizedBox.shrink();
                    }
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
        ),
        SizedBox(height: 2.h),
        _buildCard(
          icon: Icons.description_rounded,
          title: 'Approval Request',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why should we approve you for this category?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 1.h),
              _buildTextField(
                controller: _approvalReasonController,
                label: 'Your Experience & Qualifications',
                hint:
                    'e.g. 5 years of experience as a licensed electrician, completed 200+ jobs...',
                icon: Icons.edit_note_rounded,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Location() {
    return _buildCard(
      icon: Icons.location_on_rounded,
      title: 'Location & Contact',
      child: Column(
        children: [
          _buildTextField(
            controller: _addressController,
            label: 'Business Address',
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
        ],
      ),
    );
  }

  // ─── Step 5: Document Upload ───────────────────────────────────────────────

  Widget _buildStep5DocumentUpload() {
    final emailText = _emailController.text.trim();
    return Column(
      children: [
        // Email verified banner
        _buildCard(
          icon: Icons.check_circle_rounded,
          title: 'Email Verified ✓',
          child: _buildInfoBanner(
            icon: Icons.verified_rounded,
            color: AppTheme.secondary,
            message:
                'Your email address $emailText has been successfully verified.',
          ),
        ),
        SizedBox(height: 2.h),

        // Identity Document
        _buildCard(
          icon: Icons.badge_rounded,
          title: 'Identity Document',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                color: AppTheme.primary,
                message:
                    'Upload a government-issued identity proof (Aadhar, PAN, Passport, etc.) to verify your identity.',
              ),
              SizedBox(height: 2.h),
              Text(
                'Document Type',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 0.8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _identityDocType,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: const Color(0xFF44474E),
                    ),
                    items: _identityDocTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(
                      () => _identityDocType = v ?? _identityDocType,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              _buildTextField(
                controller: _identityDocNumberController,
                label: 'Document Number',
                hint: 'e.g. XXXX-XXXX-XXXX',
                icon: Icons.numbers_rounded,
              ),
              SizedBox(height: 1.5.h),
              _buildDocUploadButton(
                label: _identityDocFile != null
                    ? '✓ File selected: ${_identityDocFile!.name}'
                    : 'Upload Document Photo',
                icon: _identityDocFile != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_rounded,
                color: _identityDocFile != null
                    ? AppTheme.secondary
                    : AppTheme.primary,
                onTap: _pickIdentityDoc,
              ),
              if (_identityDocFile != null) ...[
                SizedBox(height: 1.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: _buildXFilePreview(_identityDocFile!),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Business License
        _buildCard(
          icon: Icons.business_center_rounded,
          title: 'Business License',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFFFF6F00),
                message:
                    'Upload your business registration or trade license. This helps us verify your business legitimacy. (Optional but recommended)',
              ),
              SizedBox(height: 2.h),
              Text(
                'License Type',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 0.8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _businessLicenseType,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.sp,
                      color: const Color(0xFF44474E),
                    ),
                    items: _businessLicenseTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(
                      () => _businessLicenseType = v ?? _businessLicenseType,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              _buildTextField(
                controller: _businessLicenseNumberController,
                label: 'License / Registration Number (Optional)',
                hint: 'e.g. GST123456789',
                icon: Icons.numbers_rounded,
              ),
              SizedBox(height: 1.5.h),
              _buildDocUploadButton(
                label: _businessLicenseFile != null
                    ? '✓ File selected: ${_businessLicenseFile!.name}'
                    : 'Upload License Photo',
                icon: _businessLicenseFile != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_rounded,
                color: _businessLicenseFile != null
                    ? AppTheme.secondary
                    : const Color(0xFFFF6F00),
                onTap: _pickBusinessLicense,
              ),
              if (_businessLicenseFile != null) ...[
                SizedBox(height: 1.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: _buildXFilePreview(_businessLicenseFile!),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 2.h),
        _buildInfoTip(
          'Documents are reviewed by our team and kept confidential. Only the document type and number are stored in your profile.',
        ),
      ],
    );
  }

  Widget _buildXFilePreview(XFile file) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            height: 15.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(),
          );
        }
        return Container(
          height: 15.h,
          color: const Color(0xFFF5F7FF),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _buildDocUploadButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 6: Final Confirmation ────────────────────────────────────────────

  Widget _buildStep6Confirmation() {
    final identityUploaded =
        _identityDocFile != null ||
        _identityDocNumberController.text.trim().isNotEmpty;
    final licenseUploaded =
        _businessLicenseFile != null ||
        _businessLicenseNumberController.text.trim().isNotEmpty;

    return Column(
      children: [
        // All steps complete banner
        _buildCard(
          icon: Icons.task_alt_rounded,
          title: 'Almost Done!',
          child: _buildInfoBanner(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFFF6F00),
            message:
                'After submission, our team will review your profile and category request. You will be notified once approved (typically within 24–48 hours).',
          ),
        ),
        SizedBox(height: 2.h),

        // Registration summary
        _buildCard(
          icon: Icons.summarize_rounded,
          title: 'Registration Summary',
          child: Column(
            children: [
              _buildSummaryRow(
                Icons.person_rounded,
                'Owner',
                _ownerNameController.text.isNotEmpty
                    ? _ownerNameController.text
                    : '—',
              ),
              _buildSummaryRow(
                Icons.storefront_rounded,
                'Business',
                _shopNameController.text.isNotEmpty
                    ? _shopNameController.text
                    : '—',
              ),
              _buildSummaryRow(
                Icons.category_rounded,
                'Category',
                _selectedCategory != null
                    ? '${_selectedCategory!}${_selectedSubcategory != null ? ' › ${_selectedSubcategory!}' : ''}'
                    : '—',
              ),
              _buildSummaryRow(
                Icons.location_city_rounded,
                'City',
                _cityController.text.isNotEmpty ? _cityController.text : '—',
              ),
              _buildSummaryRow(
                Icons.phone_rounded,
                'Phone',
                _phoneController.text.trim(),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Documents summary
        _buildCard(
          icon: Icons.folder_copy_rounded,
          title: 'Documents Summary',
          child: Column(
            children: [
              _buildDocSummaryRow(
                icon: Icons.badge_rounded,
                label: 'Identity Document',
                docType: _identityDocType,
                docNumber: _identityDocNumberController.text.trim(),
                fileUploaded: _identityDocFile != null,
                isUploaded: identityUploaded,
                required: true,
              ),
              SizedBox(height: 1.h),
              _buildDocSummaryRow(
                icon: Icons.business_center_rounded,
                label: 'Business License',
                docType: _businessLicenseType,
                docNumber: _businessLicenseNumberController.text.trim(),
                fileUploaded: _businessLicenseFile != null,
                isUploaded: licenseUploaded,
                required: false,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Terms note
        _buildCard(
          icon: Icons.gavel_rounded,
          title: 'Terms & Conditions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By submitting this registration, you agree to:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF44474E),
                ),
              ),
              SizedBox(height: 1.h),
              _buildTermsItem(
                'Provide accurate and truthful information about your business.',
              ),
              _buildTermsItem(
                'Comply with LocalConnect\'s provider guidelines and code of conduct.',
              ),
              _buildTermsItem(
                'Allow our team to verify your documents and business details.',
              ),
              _buildTermsItem(
                'Maintain service quality standards as required by the platform.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocSummaryRow({
    required IconData icon,
    required String label,
    required String docType,
    required String docNumber,
    required bool fileUploaded,
    required bool isUploaded,
    required bool required,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isUploaded
            ? AppTheme.secondary.withValues(alpha: 0.07)
            : required
            ? Colors.red.withValues(alpha: 0.05)
            : const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isUploaded
              ? AppTheme.secondary.withValues(alpha: 0.3)
              : required
              ? Colors.red.withValues(alpha: 0.2)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppTheme.secondary.withValues(alpha: 0.15)
                  : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? AppTheme.secondary : const Color(0xFF90A4AE),
              size: 18,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF44474E),
                      ),
                    ),
                    if (required) ...[
                      SizedBox(width: 1.w),
                      Text(
                        '*',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isUploaded
                      ? '$docType${docNumber.isNotEmpty ? ' · $docNumber' : ''}${fileUploaded ? ' · Photo uploaded' : ''}'
                      : required
                      ? 'Not provided — required'
                      : 'Not provided — optional',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: isUploaded
                        ? AppTheme.secondary
                        : required
                        ? Colors.red
                        : const Color(0xFF90A4AE),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: AppTheme.secondary,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5.sp,
                color: const Color(0xFF74777F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: const Color(0xFF90A4AE),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final buttonLabel = isLastStep ? 'Submit Registration' : 'Continue';

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
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                           _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastStep
                        ? const Color(0xFF2E7D32)
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 5.w,
                          height: 5.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLastStep) ...[
                              const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 2.w),
                            ],
                            Text(
                              buttonLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
                  borderRadius: BorderRadius.circular(8.0),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
          obscureText: obscureText,
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
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
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

  Widget _buildInfoTip(String message) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5.sp,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(10.0),
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

