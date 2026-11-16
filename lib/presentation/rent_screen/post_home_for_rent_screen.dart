import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class PostHomeForRentScreen extends StatefulWidget {
  const PostHomeForRentScreen({super.key});

  @override
  State<PostHomeForRentScreen> createState() => _PostHomeForRentScreenState();
}

class _PostHomeForRentScreenState extends State<PostHomeForRentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _areaLocalityCtrl = TextEditingController();
  final _monthlyRentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  String _selectedCity = 'Pune';
  String _selectedPropertyType = 'Flat';
  String _selectedBedrooms = '2 BHK';
  String _selectedFurnishing = 'Semi-Furnished';

  bool _isSubmitting = false;
  bool _isSuccess = false;
  List<String> _availableCities = [];

  final List<String> _propertyTypes = [
    'Flat',
    'Independent House',
    'Room',
    'Villa',
    'Penthouse',
    'Studio Apartment',
  ];

  final List<String> _bedroomOptions = [
    '1 RK',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4+ BHK',
    'Single Room',
    'Shared Room',
  ];

  final List<String> _furnishingOptions = [
    'Unfurnished',
    'Semi-Furnished',
    'Fully Furnished',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndAreas();
  }

  Future<void> _loadUserAndAreas() async {
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      if (user.phone != null && user.phone!.isNotEmpty) {
        _ownerPhoneCtrl.text = user.phone!;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        _ownerEmailCtrl.text = user.email!;
      }
    }

    try {
      final cities = await SupabaseService.instance.getManagedAreas();
      if (mounted && cities.isNotEmpty) {
        setState(() {
          _availableCities = cities;
          if (!cities.contains(_selectedCity)) {
            _selectedCity = cities.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _areaLocalityCtrl.dispose();
    _monthlyRentCtrl.dispose();
    _depositCtrl.dispose();
    _descriptionCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final rent = double.tryParse(_monthlyRentCtrl.text.trim()) ?? 0.0;
    final deposit = double.tryParse(_depositCtrl.text.trim()) ?? 0.0;

    if (rent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly rent amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final photo = _photoUrlCtrl.text.trim().isNotEmpty
        ? _photoUrlCtrl.text.trim()
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=600&auto=format&fit=crop&q=80';

    final res = await SupabaseService.instance.submitHomeRentListing(
      ownerName: _ownerNameCtrl.text.trim(),
      ownerPhone: _ownerPhoneCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      city: _selectedCity,
      areaLocality: _areaLocalityCtrl.text.trim(),
      propertyType: _selectedPropertyType,
      bedrooms: _selectedBedrooms,
      monthlyRent: rent,
      deposit: deposit,
      furnishingStatus: _selectedFurnishing,
      description: _descriptionCtrl.text.trim(),
      primaryPhoto: photo,
      photos: [photo],
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (res != null) {
          _isSuccess = true;
        }
      });

      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing saved! Pending verification by Admin.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          title: Text(
            'Listing Submitted',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Home for Rent Posted Successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your property is now visible to customers and tenants searching in $_selectedCity. Interested tenants can contact you directly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back to Rentals',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Post Your Home for Rent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0288D1), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct Homeowner Rental: No service provider registration required. Post details to receive enquiries directly from tenants.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF01579B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Owner Details Section
              _buildSectionTitle('Owner Information'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ownerNameCtrl,
                      decoration: InputDecoration(
                        labelText: "Owner's Full Name *",
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter owner name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ownerPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number (For Tenant Inquiries) *',
                        prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                        if (v.trim().replaceAll(RegExp(r'\D'), '').length < 10) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ownerEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address (Optional)',
                        prefixIcon: const Icon(Icons.email_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Property Location
              _buildSectionTitle('Property Location & Area'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City / Region *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: (_availableCities.isNotEmpty
                              ? _availableCities
                              : ['Pune', 'Mumbai', 'Nashik', 'Aurangabad', 'Nagpur', 'Kolhapur'])
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCity = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaLocalityCtrl,
                      decoration: InputDecoration(
                        labelText: 'Locality / Area / Landmark *',
                        hintText: 'e.g. Kothrud, Near Metro Station, Flat 402',
                        prefixIcon: const Icon(Icons.pin_drop_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter locality/area' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Property Details
              _buildSectionTitle('Property Specifications'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
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
                                'Property Type',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedPropertyType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: _propertyTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPropertyType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bedrooms / Configuration',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedBedrooms,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: _bedroomOptions
                                    .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBedrooms = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Furnishing Status',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedFurnishing,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.chair_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _furnishingOptions
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFurnishing = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rent & Deposit
              _buildSectionTitle('Rent & Deposit Terms'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlyRentCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Rent (₹) *',
                          hintText: 'e.g. 15000',
                          prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter rent' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _depositCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Deposit (₹)',
                          hintText: 'e.g. 30000',
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description & Photo
              _buildSectionTitle('Description & Photos'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Property Description & Features',
                        hintText: 'e.g. 24/7 water supply, gated security, lift, covered parking, close to schools.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _photoUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Photo Image URL (Optional)',
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.photo_camera_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.publish_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Publish Home for Rent',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1C1E),
      ),
    );
  }
}

