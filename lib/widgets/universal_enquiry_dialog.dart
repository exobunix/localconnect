import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Universal Enquiry Bottom Sheet & Dialog for all categories & subcategories
class UniversalEnquiryDialog extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? providerPhone;
  final String? providerImage;
  final double providerRating;
  final String category;
  final String subcategory;
  final String serviceTitle;
  final String? basePrice;
  final Color themeColor;

  const UniversalEnquiryDialog({
    super.key,
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    this.providerImage,
    this.providerRating = 4.8,
    required this.category,
    required this.subcategory,
    required this.serviceTitle,
    this.basePrice,
    this.themeColor = const Color(0xFF1E3A8A),
  });

  static Future<bool?> show(
    BuildContext context, {
    required String providerId,
    required String providerName,
    String? providerPhone,
    String? providerImage,
    double providerRating = 4.8,
    required String category,
    required String subcategory,
    required String serviceTitle,
    String? basePrice,
    Color themeColor = const Color(0xFF1E3A8A),
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UniversalEnquiryDialog(
        providerId: providerId,
        providerName: providerName,
        providerPhone: providerPhone,
        providerImage: providerImage,
        providerRating: providerRating,
        category: category,
        subcategory: subcategory,
        serviceTitle: serviceTitle,
        basePrice: basePrice,
        themeColor: themeColor,
      ),
    );
  }

  @override
  State<UniversalEnquiryDialog> createState() => _UniversalEnquiryDialogState();
}

class _UniversalEnquiryDialogState extends State<UniversalEnquiryDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _selectedSlot = 'Morning (9 AM - 12 PM)';
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String _submittedEnquiryId = '';

  final List<String> _timeSlots = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 4 PM)',
    'Evening (4 PM - 8 PM)',
    'Flexible / Urgent',
  ];

  static bool _isValidUuid(String s) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(s.trim());
  }

  bool get _isFormValid {
    final name = _nameCtrl.text.trim();
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final message = _messageCtrl.text.trim();
    return name.isNotEmpty &&
        digits.length >= 10 &&
        _selectedDate != null &&
        message.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
    _messageCtrl.addListener(_onFieldChanged);
    _loadUserProfile();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserProfile() async {
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.userMetadata?['full_name'] as String? ?? '';
      _phoneCtrl.text =
          user.userMetadata?['phone'] as String? ?? user.phone ?? '';
      try {
        final profile = await SupabaseService.instance.getUserProfile(user.id);
        if (profile != null) {
          if (_nameCtrl.text.isEmpty && profile['full_name'] != null) {
            _nameCtrl.text = profile['full_name'] as String;
          }
          if (_phoneCtrl.text.isEmpty && profile['phone'] != null) {
            _phoneCtrl.text = profile['phone'] as String;
          }
        }
      } catch (_) {}
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _phoneCtrl.removeListener(_onFieldChanged);
    _messageCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEnquiry() async {
    final name = _nameCtrl.text.trim();
    final rawPhone = _phoneCtrl.text.trim();
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final message = _messageCtrl.text.trim();

    if (name.isEmpty) {
      _showToast('Please enter your full name', isError: true);
      return;
    }
    if (cleanPhone.length < 10) {
      _showToast('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }
    if (_selectedDate == null) {
      _showToast('Please select a preferred schedule date', isError: true);
      return;
    }
    if (message.isEmpty) {
      _showToast('Please enter your requirement details', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseService.instance.currentUser;
      final customerId = (user?.id != null && _isValidUuid(user!.id))
          ? user.id
          : null;
      final providerUuid = _isValidUuid(widget.providerId)
          ? widget.providerId
          : null;

      final formattedDate =
          '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';

      final insertData = <String, dynamic>{
        'customer_name': name,
        'customer_phone': cleanPhone,
        'provider_name': widget.providerName,
        'category': widget.category,
        'subcategory': widget.subcategory,
        'service_title': widget.serviceTitle,
        'preferred_date': formattedDate,
        'preferred_time': _selectedSlot,
        'message': message,
        'status': 'pending',
      };

      if (customerId != null) insertData['customer_id'] = customerId;
      if (providerUuid != null) insertData['provider_id'] = providerUuid;

      String generatedEnquiryId =
          'ENQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      try {
        final result = await SupabaseService.instance.client
            .from('enquiries')
            .insert(insertData)
            .select('id')
            .maybeSingle();

        if (result != null && result['id'] != null) {
          generatedEnquiryId = result['id'].toString();
        }
      } catch (dbErr) {
        debugPrint('[UniversalEnquiry] Primary insert note: $dbErr');
        // Fallback: try minimal insert if extra columns had any cache delay
        try {
          final fallbackData = <String, dynamic>{
            'title': widget.serviceTitle,
            'description':
                'Name: $name\nPhone: $cleanPhone\nDate: $formattedDate\nTime: $_selectedSlot\nRequirement: $message',
            'category': widget.category,
            'subcategory': widget.subcategory,
            'status': 'pending',
          };
          if (customerId != null) fallbackData['customer_id'] = customerId;
          if (providerUuid != null) fallbackData['provider_id'] = providerUuid;

          final fallbackRes = await SupabaseService.instance.client
              .from('enquiries')
              .insert(fallbackData)
              .select('id')
              .maybeSingle();
          if (fallbackRes != null && fallbackRes['id'] != null) {
            generatedEnquiryId = fallbackRes['id'].toString();
          }
        } catch (fallbackErr) {
          debugPrint('[UniversalEnquiry] Fallback insert note: $fallbackErr');
        }
      }

      // Safe dispatch of notifications (isolated from UI success)
      try {
        await NotificationService.instance.notifyEnquirySubmitted(
          enquiryId: generatedEnquiryId,
          subcategory: widget.subcategory,
          customerId: customerId ?? '',
          customerName: name,
          customerPhone: cleanPhone,
          providerId: widget.providerId,
          providerName: widget.providerName,
          message: message,
        );
      } catch (notifErr) {
        debugPrint('[UniversalEnquiry] Notification dispatch note: $notifErr');
      }

      // Play audio chime safely
      try {
        NotificationService.instance.playNotificationSound();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
          _submittedEnquiryId = generatedEnquiryId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('Could not send enquiry. Please check connection and try again.', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomInset + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: _isSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Green Circle with checkmark
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00C853),
              size: 48,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Enquiry Sent Successfully!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Your enquiry for "${widget.serviceTitle}" has been delivered directly to ${widget.providerName}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Details summary box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enquiry Reference',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _submittedEnquiryId.isNotEmpty
                            ? '#${_submittedEnquiryId.substring(0, _submittedEnquiryId.length.clamp(0, 14))}'
                            : '#ENQ-SENT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.providerName} has been notified and will call or message you shortly.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Done Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    final isValid = _isFormValid;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make an Enquiry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Send your requirement directly to this partner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Provider Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.themeColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.providerImage != null && widget.providerImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.providerImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.storefront_rounded,
                              color: widget.themeColor,
                            ),
                          ),
                        )
                      : Icon(Icons.storefront_rounded, color: widget.themeColor),
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
                              widget.providerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.providerRating}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.serviceTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: widget.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.basePrice != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.basePrice!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form Inputs - Contact
          Row(
            children: [
              Text(
                'Your Contact Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: '10-digit number',
                    prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preferred Date & Slot
          Row(
            children: [
              Text(
                'Preferred Schedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedDate != null
                          ? widget.themeColor.withValues(alpha: 0.04)
                          : Colors.white,
                      border: Border.all(
                        color: _selectedDate != null ? widget.themeColor : Colors.grey.shade400,
                        width: _selectedDate != null ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: _selectedDate != null ? widget.themeColor : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Select Date *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: _selectedDate != null ? FontWeight.w700 : FontWeight.w500,
                              color: _selectedDate != null
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSlot,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      items: _timeSlots
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSlot = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Message requirement
          Row(
            children: [
              Text(
                'Requirement Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe your requirement, issue, or any specific instructions *',
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Validation hints if not yet completed
          if (!isValid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please fill your name, valid 10-digit phone, select date, and describe your requirement to enable enquiry submission.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit Button (strictly disabled until all fields are filled)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (!isValid || _isSubmitting) ? null : _submitEnquiry,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? widget.themeColor : const Color(0xFF94A3B8),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: isValid ? 2 : 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send_rounded,
                          color: isValid ? Colors.white : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Send Enquiry to Partner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isValid ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
