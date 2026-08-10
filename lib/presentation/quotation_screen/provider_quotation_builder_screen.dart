import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ProviderQuotationBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? enquiry;
  final Map<String, dynamic>? existingQuotation;
  final bool isTemplate;

  const ProviderQuotationBuilderScreen({
    super.key,
    this.enquiry,
    this.existingQuotation,
    this.isTemplate = false,
  });

  @override
  State<ProviderQuotationBuilderScreen> createState() =>
      _ProviderQuotationBuilderScreenState();
}

class _ProviderQuotationBuilderScreenState
    extends State<ProviderQuotationBuilderScreen> {
  bool _isSaving = false;
  bool _isLoadingTemplates = false;
  List<Map<String, dynamic>> _templates = [];

  // Line items
  final List<Map<String, dynamic>> _lineItems = [];

  // Charge controllers
  final _labourController = TextEditingController(text: '0');
  final _materialController = TextEditingController(text: '0');
  final _visitingController = TextEditingController(text: '0');
  final _transportController = TextEditingController(text: '0');
  final _equipmentController = TextEditingController(text: '0');
  final _extraController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');

  // Meta
  final _completionTimeController = TextEditingController();
  final _validityController = TextEditingController(text: '7');
  final _notesController = TextEditingController();
  final _templateNameController = TextEditingController();

  // Category-specific
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.enquiry?['category'] as String?;
    if (widget.existingQuotation != null) {
      _loadExistingQuotation();
    }
    _loadTemplates();
  }

  @override
  void dispose() {
    _labourController.dispose();
    _materialController.dispose();
    _visitingController.dispose();
    _transportController.dispose();
    _equipmentController.dispose();
    _extraController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _completionTimeController.dispose();
    _validityController.dispose();
    _notesController.dispose();
    _templateNameController.dispose();
    super.dispose();
  }

  void _loadExistingQuotation() {
    final q = widget.existingQuotation!;
    _labourController.text = (q['labour_charges'] ?? 0).toString();
    _materialController.text = (q['material_charges'] ?? 0).toString();
    _visitingController.text = (q['visiting_charges'] ?? 0).toString();
    _transportController.text = (q['transportation_charges'] ?? 0).toString();
    _equipmentController.text = (q['equipment_charges'] ?? 0).toString();
    _extraController.text = (q['extra_charges'] ?? 0).toString();
    _discountController.text = (q['discount'] ?? 0).toString();
    _taxController.text = (q['tax_percentage'] ?? 0).toString();
    _completionTimeController.text = q['expected_completion_time'] ?? '';
    _validityController.text = (q['validity_days'] ?? 7).toString();
    _notesController.text = q['additional_notes'] ?? '';
    final items = q['line_items'];
    if (items is List) {
      _lineItems.addAll(items.map((e) => Map<String, dynamic>.from(e as Map)));
    }
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoadingTemplates = true);
    try {
      final templates = await SupabaseService.instance.getQuotationTemplates();
      if (mounted) setState(() => _templates = templates);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingTemplates = false);
  }

  double get _subtotal {
    final items = _lineItems.fold<double>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 1) * (item['unit_rate'] ?? 0)),
    );
    return items +
        _parseDouble(_labourController.text) +
        _parseDouble(_materialController.text) +
        _parseDouble(_visitingController.text) +
        _parseDouble(_transportController.text) +
        _parseDouble(_equipmentController.text) +
        _parseDouble(_extraController.text);
  }

  double get _taxAmount =>
      _subtotal * (_parseDouble(_taxController.text) / 100);

  double get _total =>
      _subtotal + _taxAmount - _parseDouble(_discountController.text);

  double _parseDouble(String val) => double.tryParse(val) ?? 0;

  void _addLineItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        final qtyCtrl = TextEditingController(text: '1');
        final rateCtrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Add Service Item',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Service Name *', 'e.g. Pipe Repair'),
                SizedBox(height: 1.5.h),
                _dialogField(descCtrl, 'Description', 'Brief description'),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      child: _dialogField(qtyCtrl, 'Qty', '1', isNumber: true),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _dialogField(
                        rateCtrl,
                        'Unit Rate (₹)',
                        '0',
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _lineItems.add({
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                      'unit_rate': double.tryParse(rateCtrl.text) ?? 0,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
          ),
        ),
      ],
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _labourController.text = (template['labour_charges'] ?? 0).toString();
      _materialController.text = (template['material_charges'] ?? 0).toString();
      _visitingController.text = (template['visiting_charges'] ?? 0).toString();
      _transportController.text = (template['transportation_charges'] ?? 0)
          .toString();
      _equipmentController.text = (template['equipment_charges'] ?? 0)
          .toString();
      _extraController.text = (template['extra_charges'] ?? 0).toString();
      _discountController.text = (template['discount'] ?? 0).toString();
      _taxController.text = (template['tax_percentage'] ?? 0).toString();
      _notesController.text = template['additional_notes'] ?? '';
      _completionTimeController.text =
          template['expected_completion_time'] ?? '';
      final items = template['line_items'];
      if (items is List) {
        _lineItems.clear();
        _lineItems.addAll(
          items.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    });
    Navigator.pop(context);
  }

  Future<void> _saveQuotation({bool isDraft = false}) async {
    setState(() => _isSaving = true);
    try {
      final enquiryId = widget.enquiry?['id'] as String?;
      final customerId = widget.enquiry?['customer_id'] as String?;

      await SupabaseService.instance.createOrUpdateQuotation(
        quotationId: widget.existingQuotation?['id'] as String?,
        enquiryId: enquiryId,
        customerId: customerId,
        lineItems: _lineItems,
        labourCharges: _parseDouble(_labourController.text),
        materialCharges: _parseDouble(_materialController.text),
        visitingCharges: _parseDouble(_visitingController.text),
        transportationCharges: _parseDouble(_transportController.text),
        equipmentCharges: _parseDouble(_equipmentController.text),
        extraCharges: _parseDouble(_extraController.text),
        discount: _parseDouble(_discountController.text),
        taxPercentage: _parseDouble(_taxController.text),
        taxAmount: _taxAmount,
        subtotal: _subtotal,
        totalAmount: _total,
        expectedCompletionTime: _completionTimeController.text.trim(),
        validityDays: int.tryParse(_validityController.text) ?? 7,
        additionalNotes: _notesController.text.trim(),
        status: isDraft ? 'draft' : 'sent',
        isTemplate: widget.isTemplate,
        templateName: widget.isTemplate
            ? _templateNameController.text.trim()
            : '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft
                  ? 'Quotation saved as draft.'
                  : 'Quotation sent to customer!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: isDraft ? Colors.orange : AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save quotation. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAsTemplate() async {
    if (_templateNameController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Save as Template',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a name for this template:',
                style: GoogleFonts.plusJakartaSans(),
              ),
              SizedBox(height: 1.5.h),
              TextFormField(
                controller: _templateNameController,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. Standard Plumbing Quote',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.h,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveQuotation(isDraft: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Template'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isTemplate ? 'Create Template' : 'Build Quotation',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_templates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.file_copy_rounded),
              tooltip: 'Use Template',
              onPressed: _showTemplatesSheet,
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded),
            tooltip: 'Save as Template',
            onPressed: _saveAsTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            // Enquiry info
            if (widget.enquiry != null) _buildEnquiryCard(),
            SizedBox(height: 2.h),

            // Category-specific quick fields
            if (_selectedCategory != null) _buildCategorySpecificFields(),

            // Line items
            _buildSectionCard(
              icon: Icons.list_alt_rounded,
              title: 'Service Items',
              child: Column(
                children: [
                  ..._lineItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final itemTotal =
                        (item['quantity'] ?? 1) * (item['unit_rate'] ?? 0);
                    return Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if ((item['description'] ?? '').isNotEmpty)
                                  Text(
                                    item['description'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Text(
                                  '${item['quantity']} × ₹${item['unit_rate']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5.sp,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${itemTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          GestureDetector(
                            onTap: () => setState(() => _lineItems.removeAt(i)),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.error,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 1.h),
                  OutlinedButton.icon(
                    onPressed: _addLineItem,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Add Service Item',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Charges breakdown
            _buildSectionCard(
              icon: Icons.receipt_long_rounded,
              title: 'Charges Breakdown',
              child: Column(
                children: [
                  _buildChargeRow(
                    'Labour Charges',
                    _labourController,
                    Icons.engineering_rounded,
                  ),
                  _buildChargeRow(
                    'Material Charges',
                    _materialController,
                    Icons.inventory_2_rounded,
                  ),
                  _buildChargeRow(
                    'Visiting Charges',
                    _visitingController,
                    Icons.directions_car_rounded,
                  ),
                  _buildChargeRow(
                    'Transportation',
                    _transportController,
                    Icons.local_shipping_rounded,
                  ),
                  _buildChargeRow(
                    'Equipment Charges',
                    _equipmentController,
                    Icons.build_rounded,
                  ),
                  _buildChargeRow(
                    'Extra Charges',
                    _extraController,
                    Icons.add_circle_outline_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Discount & Tax
            _buildSectionCard(
              icon: Icons.calculate_rounded,
              title: 'Discount & Tax',
              child: Column(
                children: [
                  _buildChargeRow(
                    'Discount (₹)',
                    _discountController,
                    Icons.discount_rounded,
                    color: Colors.green,
                  ),
                  _buildChargeRow(
                    'Tax (%)',
                    _taxController,
                    Icons.percent_rounded,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),

            // Total summary
            _buildTotalCard(),
            SizedBox(height: 2.h),

            // Meta info
            _buildSectionCard(
              icon: Icons.info_outline_rounded,
              title: 'Quotation Details',
              child: Column(
                children: [
                  _buildMetaField(
                    _completionTimeController,
                    'Expected Completion Time',
                    'e.g. 2-3 days',
                    Icons.schedule_rounded,
                  ),
                  SizedBox(height: 2.h),
                  _buildMetaField(
                    _validityController,
                    'Validity (days)',
                    '7',
                    Icons.event_available_rounded,
                    isNumber: true,
                  ),
                  SizedBox(height: 2.h),
                  _buildMetaField(
                    _notesController,
                    'Additional Notes',
                    'Any special instructions or conditions...',
                    Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveQuotation(isDraft: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text(
                      'Save Draft',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveQuotation(),
                    icon: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Send Quotation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryCard() {
    final enquiry = widget.enquiry!;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 2.w),
              Text(
                'Customer Enquiry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            enquiry['title'] ?? 'Service Request',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          if ((enquiry['description'] ?? '').isNotEmpty)
            Text(
              enquiry['description'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _chip(enquiry['category'] ?? '', Colors.blue),
              SizedBox(width: 2.w),
              if ((enquiry['subcategory'] ?? '').isNotEmpty)
                _chip(enquiry['subcategory'], Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategorySpecificFields() {
    final cat = (_selectedCategory ?? '').toLowerCase();
    List<String> quickFields = [];

    if (cat.contains('transport')) {
      quickFields = [
        'Local Trip',
        'Outstation Trip',
        'Airport Pickup',
        'Hourly Booking',
        'Daily Booking',
        'Waiting Charges',
        'Toll Charges',
        'Parking Charges',
        'Night Charges',
      ];
    } else if (cat.contains('home') ||
        cat.contains('maintenance') ||
        cat.contains('plumb') ||
        cat.contains('electric') ||
        cat.contains('paint') ||
        cat.contains('carpenter')) {
      quickFields = [
        'Inspection Charges',
        'Visiting Charges',
        'Labour Charges',
        'Material Charges',
        'Per Hour Charges',
        'Per Job Charges',
        'Emergency Service Charges',
      ];
    } else if (cat.contains('event') ||
        cat.contains('wedding') ||
        cat.contains('photo')) {
      quickFields = [
        'Package Selection',
        'Number of Guests',
        'Event Duration',
        'Equipment Charges',
        'Decoration Charges',
        'Photography/Videography',
        'Travel Charges',
      ];
    }

    if (quickFields.isEmpty) return const SizedBox();

    return Column(
      children: [
        _buildSectionCard(
          icon: Icons.category_rounded,
          title: 'Quick Add (${_selectedCategory ?? 'Category'} Specific)',
          child: Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: quickFields
                .map(
                  (field) => GestureDetector(
                    onTap: () {
                      if (!_lineItems.any((item) => item['name'] == field)) {
                        setState(() {
                          _lineItems.add({
                            'name': field,
                            'description': '',
                            'quantity': 1,
                            'unit_rate': 0.0,
                          });
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            field,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildChargeRow(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primary, size: 16),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          SizedBox(
            width: 25.w,
            child: TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF1A237E),
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: label.contains('%') ? '' : '₹',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  color: color ?? AppTheme.primary,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 2.w,
                  vertical: 1.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF26C6A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', _subtotal, isWhite: true),
          if (_parseDouble(_taxController.text) > 0)
            _totalRow(
              'Tax (${_taxController.text}%)',
              _taxAmount,
              isWhite: true,
            ),
          if (_parseDouble(_discountController.text) > 0)
            _totalRow(
              'Discount',
              -_parseDouble(_discountController.text),
              isWhite: true,
            ),
          const Divider(color: Colors.white38, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL AMOUNT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isWhite = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: isWhite ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isWhite ? Colors.white : const Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    bool isNumber = false,
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
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
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

  Widget _buildSectionCard({
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

  void _showTemplatesSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Templates',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            ..._templates.map(
              (t) => ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  t['template_name'] ?? 'Template',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  t['category'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    color: Colors.grey,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: () => _applyTemplate(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
