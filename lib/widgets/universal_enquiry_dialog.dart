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

  final List<String> _timeSlots = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 4 PM)',
    'Evening (4 PM - 8 PM)',
    'Flexible / Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = SupabaseService.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.userMetadata?['full_name'] as String? ?? '';
      _phoneCtrl.text = user.userMetadata?['phone'] as String? ?? user.phone ?? '';
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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEnquiry() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (name.isEmpty) {
      _showToast('Please enter your name', isError: true);
      return;
    }
    if (phone.isEmpty || phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _showToast('Please enter a valid 10-digit phone number', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = SupabaseService.instance.currentUser;
      final customerId = user?.id ?? 'guest_customer_${DateTime.now().millisecondsSinceEpoch}';
      final enquiryId = 'ENQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final enquiryData = {
        'id': enquiryId,
        'customer_id': customerId,
        'customer_name': name,
        'customer_phone': phone,
        'provider_id': widget.providerId,
        'provider_name': widget.providerName,
        'category': widget.category,
        'subcategory': widget.subcategory,
        'service_title': widget.serviceTitle,
        'preferred_date': _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
            : 'Immediate / As per discussion',
        'preferred_time': _selectedSlot,
        'message': message.isNotEmpty ? message : 'Customer requested quotation and details.',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // 1. Save to Supabase enquiries table
      try {
        await SupabaseService.instance.client.from('enquiries').insert(enquiryData);
      } catch (e) {
        debugPrint('[UniversalEnquiry] Supabase direct insert note: $e');
      }

      // 2. Dispatch real-time notifications with audio chime
      await NotificationService.instance.notifyEnquirySubmitted(
        enquiryId: enquiryId,
        subcategory: widget.subcategory,
        customerId: customerId,
        customerName: name,
        customerPhone: phone,
        providerId: widget.providerId,
        providerName: widget.providerName,
        message: message,
      );

      // Play audio chime
      NotificationService.instance.playNotificationSound();

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessConfirmation(enquiryId, name);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('Could not send enquiry. Please try again.', isError: true);
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

  void _showSuccessConfirmation(String enquiryId, String customerName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00C853),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enquiry Sent Successfully!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your enquiry (#$enquiryId) for "${widget.serviceTitle}" has been sent directly to ${widget.providerName}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The partner has received a notification and will call or message you shortly.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
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

            // Form Inputs
            Text(
              'Your Contact Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
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
                      labelText: 'Mobile Number',
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
            Text(
              'Preferred Schedule',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
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
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: widget.themeColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select Date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                                color: _selectedDate != null ? const Color(0xFF0F172A) : Colors.grey.shade500,
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
            Text(
              'Requirement Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your requirement, problem, or any specific instructions...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEnquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                          const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Send Enquiry to Partner',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
