import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class ProviderOffersManagementWidget extends StatefulWidget {
  final String providerId;
  final bool isOwner;

  const ProviderOffersManagementWidget({
    super.key,
    required this.providerId,
    this.isOwner = false,
  });

  @override
  State<ProviderOffersManagementWidget> createState() =>
      _ProviderOffersManagementWidgetState();
}

class _ProviderOffersManagementWidgetState
    extends State<ProviderOffersManagementWidget> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    final offers = widget.isOwner
        ? await SupabaseService.instance.getProviderOffers(widget.providerId)
        : await SupabaseService.instance.getActiveProviderOffers(
            widget.providerId,
          );
    if (mounted) {
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    }
  }

  bool _isExpired(Map<String, dynamic> offer) {
    final expiresAt = offer['expires_at'] as String?;
    if (expiresAt == null) return false;
    return DateTime.tryParse(expiresAt)?.isBefore(DateTime.now()) ?? false;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _discountLabel(Map<String, dynamic> offer) {
    final type = offer['discount_type'] as String? ?? 'percentage';
    final value = (offer['discount_value'] as num?)?.toDouble() ?? 0;
    return type == 'flat'
        ? '₹${value.toStringAsFixed(0)} OFF'
        : '${value.toStringAsFixed(0)}% OFF';
  }

  Color _offerColor(Map<String, dynamic> offer) {
    if (_isExpired(offer)) return const Color(0xFF9E9E9E);
    final type = offer['discount_type'] as String? ?? 'percentage';
    return type == 'flat' ? AppTheme.secondary : AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isOwner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Offers & Discounts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showOfferForm(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Offer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Active Offers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
        if (_offers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 48,
                    color: AppTheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isOwner
                        ? 'No offers yet. Tap "Add Offer" to create one.'
                        : 'No active offers at the moment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _offers.length,
            itemBuilder: (context, index) {
              final offer = _offers[index];
              return _OfferCard(
                offer: offer,
                isOwner: widget.isOwner,
                isExpired: _isExpired(offer),
                discountLabel: _discountLabel(offer),
                accentColor: _offerColor(offer),
                formatDate: _formatDate,
                onToggle: (isActive) async {
                  await SupabaseService.instance.toggleOfferActive(
                    offer['id'] as String,
                    isActive,
                  );
                  _loadOffers();
                },
                onEdit: () => _showOfferForm(context, offer: offer),
                onDelete: () async {
                  final confirm = await _confirmDelete(context);
                  if (confirm) {
                    await SupabaseService.instance.deleteProviderOffer(
                      offer['id'] as String,
                    );
                    _loadOffers();
                  }
                },
              );
            },
          ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Offer',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this offer?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showOfferForm(BuildContext context, {Map<String, dynamic>? offer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferFormSheet(
        providerId: widget.providerId,
        existingOffer: offer,
        onSaved: _loadOffers,
      ),
    );
  }
}

// ── Offer Card ────────────────────────────────────────────────────────────────

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final bool isOwner;
  final bool isExpired;
  final String discountLabel;
  final Color accentColor;
  final String Function(String?) formatDate;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OfferCard({
    required this.offer,
    required this.isOwner,
    required this.isExpired,
    required this.discountLabel,
    required this.accentColor,
    required this.formatDate,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = offer['title'] as String? ?? '';
    final description = offer['description'] as String?;
    final promoCode = offer['promo_code'] as String?;
    final expiresAt = offer['expires_at'] as String?;
    final isActive = offer['is_active'] as bool? ?? false;
    final minOrder = (offer['min_order_amount'] as num?)?.toDouble() ?? 0;
    final usageLimit = offer['usage_limit'] as int?;
    final usageCount = offer['usage_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: isExpired
              ? AppTheme.outlineVariant
              : accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color(0xFFF5F5F5)
                  : accentColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired ? const Color(0xFF9E9E9E) : accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    discountLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isExpired
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF1A1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOwner) ...[
                  Switch(
                    value: isActive && !isExpired,
                    onChanged: isExpired ? null : onToggle,
                    activeThumbColor: accentColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ] else if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Expired',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null && description.isNotEmpty) ...[
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF44474E),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    // Promo code chip
                    if (promoCode != null && promoCode.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: promoCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Code "$promoCode" copied!',
                                style: GoogleFonts.plusJakartaSans(),
                              ),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 11,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                promoCode,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Expiry
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Color(0xFF74777F),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Expires ${formatDate(expiresAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isExpired
                            ? AppTheme.error
                            : const Color(0xFF74777F),
                      ),
                    ),
                  ],
                ),
                if (minOrder > 0 || usageLimit != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (minOrder > 0) ...[
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 12,
                          color: Color(0xFF74777F),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Min ₹${minOrder.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (usageLimit != null) ...[
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 12,
                          color: Color(0xFF74777F),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$usageCount/$usageLimit used',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF74777F),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 13,
                                color: AppTheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offer Form Sheet ──────────────────────────────────────────────────────────

class _OfferFormSheet extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? existingOffer;
  final VoidCallback onSaved;

  const _OfferFormSheet({
    required this.providerId,
    this.existingOffer,
    required this.onSaved,
  });

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController();

  String _discountType = 'percentage';
  DateTime _startsAt = DateTime.now();
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  bool get _isEditing => widget.existingOffer != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existingOffer;
    if (o != null) {
      _titleCtrl.text = o['title'] as String? ?? '';
      _descCtrl.text = o['description'] as String? ?? '';
      _codeCtrl.text = o['promo_code'] as String? ?? '';
      _valueCtrl.text = (o['discount_value'] as num?)?.toStringAsFixed(0) ?? '';
      _minOrderCtrl.text =
          (o['min_order_amount'] as num?)?.toStringAsFixed(0) ?? '';
      _usageLimitCtrl.text = o['usage_limit']?.toString() ?? '';
      _discountType = o['discount_type'] as String? ?? 'percentage';
      _startsAt =
          DateTime.tryParse(o['starts_at'] as String? ?? '') ?? DateTime.now();
      _expiresAt =
          DateTime.tryParse(o['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _usageLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expiresAt : _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiresAt = picked;
        } else {
          _startsAt = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    final minOrder = double.tryParse(_minOrderCtrl.text.trim());
    final usageLimit = int.tryParse(_usageLimitCtrl.text.trim());

    bool success;
    if (_isEditing) {
      success = await SupabaseService.instance.updateProviderOffer(
        offerId: widget.existingOffer!['id'] as String,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        discountType: _discountType,
        discountValue: value,
        promoCode: _codeCtrl.text.trim().isEmpty
            ? null
            : _codeCtrl.text.trim().toUpperCase(),
        minOrderAmount: minOrder,
        startsAt: _startsAt,
        expiresAt: _expiresAt,
        usageLimit: usageLimit,
      );
    } else {
      final result = await SupabaseService.instance.createProviderOffer(
        providerId: widget.providerId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        discountType: _discountType,
        discountValue: value,
        promoCode: _codeCtrl.text.trim().isEmpty
            ? null
            : _codeCtrl.text.trim().toUpperCase(),
        minOrderAmount: minOrder,
        startsAt: _startsAt,
        expiresAt: _expiresAt,
        usageLimit: usageLimit,
      );
      success = result != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Offer updated!' : 'Offer created!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save offer. Please try again.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Edit Offer' : 'Create New Offer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 20),
              _FormField(
                label: 'Offer Title *',
                hint: 'e.g. Monsoon Special 20% Off',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              _FormField(
                label: 'Description',
                hint: 'Brief description of the offer',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              // Discount type toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount Type *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TypeChip(
                        label: '% Percentage',
                        isSelected: _discountType == 'percentage',
                        onTap: () =>
                            setState(() => _discountType = 'percentage'),
                      ),
                      const SizedBox(width: 10),
                      _TypeChip(
                        label: '₹ Flat Amount',
                        isSelected: _discountType == 'flat',
                        onTap: () => setState(() => _discountType = 'flat'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormField(
                label: _discountType == 'flat'
                    ? 'Discount Amount (₹) *'
                    : 'Discount Percentage (%) *',
                hint: _discountType == 'flat' ? 'e.g. 100' : 'e.g. 20',
                controller: _valueCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Value is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FormField(
                label: 'Promo Code',
                hint: 'e.g. SAVE20 (optional)',
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),
              _FormField(
                label: 'Minimum Order Amount (₹)',
                hint: 'e.g. 200 (optional)',
                controller: _minOrderCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _FormField(
                label: 'Usage Limit',
                hint: 'e.g. 50 (leave blank for unlimited)',
                controller: _usageLimitCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Start Date',
                      value: _formatDate(_startsAt),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Expiry Date *',
                      value: _formatDate(_expiresAt),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Update Offer' : 'Create Offer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF90A4AE),
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.error),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF44474E),
          ),
        ),
      ),
    );
  }
}
