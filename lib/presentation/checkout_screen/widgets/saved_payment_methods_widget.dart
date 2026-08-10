import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

// ─── Data Model ────────────────────────────────────────────────────────────

class SavedCard {
  final String id;
  final String cardholderName;
  final String maskedNumber;
  final String expiry;
  final String brand; // visa, mastercard, rupay, amex
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.cardholderName,
    required this.maskedNumber,
    required this.expiry,
    required this.brand,
    this.isDefault = false,
  });

  SavedCard copyWith({bool? isDefault}) => SavedCard(
    id: id,
    cardholderName: cardholderName,
    maskedNumber: maskedNumber,
    expiry: expiry,
    brand: brand,
    isDefault: isDefault ?? this.isDefault,
  );
}

// ─── Saved Payment Methods Widget ─────────────────────────────────────────

class SavedPaymentMethodsWidget extends StatefulWidget {
  final List<SavedCard> savedCards;
  final String? selectedCardId;
  final ValueChanged<String?> onCardSelected;
  final ValueChanged<SavedCard> onCardAdded;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onDeleteCard;

  const SavedPaymentMethodsWidget({
    super.key,
    required this.savedCards,
    required this.selectedCardId,
    required this.onCardSelected,
    required this.onCardAdded,
    required this.onSetDefault,
    required this.onDeleteCard,
  });

  @override
  State<SavedPaymentMethodsWidget> createState() =>
      _SavedPaymentMethodsWidgetState();
}

class _SavedPaymentMethodsWidgetState extends State<SavedPaymentMethodsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.credit_card_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Saved Cards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              if (widget.savedCards.isNotEmpty)
                GestureDetector(
                  onTap: () => _showAddCardSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: AppTheme.primaryDark,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Card list or empty state
          if (widget.savedCards.isEmpty)
            _EmptyCardsState(onAddCard: () => _showAddCardSheet(context))
          else ...[
            ...widget.savedCards.map(
              (card) => _CardTile(
                card: card,
                isSelected: widget.selectedCardId == card.id,
                onTap: () => widget.onCardSelected(card.id),
                onSetDefault: () => widget.onSetDefault(card.id),
                onDelete: () => widget.onDeleteCard(card.id),
              ),
            ),
            const SizedBox(height: 4),
            // Add new card row
            GestureDetector(
              onTap: () => _showAddCardSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_card_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Card',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNewCardBottomSheet(
        onCardAdded: (card) {
          widget.onCardAdded(card);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Card Tile ─────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final SavedCard card;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brandColor = _brandColor(card.brand);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Card brand icon
            Container(
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? brandColor.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
              ),
              child: Center(
                child: Text(
                  _brandLabel(card.brand),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: brandColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '•••• ${card.maskedNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFF1A1C1E),
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (card.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${card.cardholderName}  •  Exp: ${card.expiry}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!card.isDefault)
                  GestureDetector(
                    onTap: onSetDefault,
                    child: Tooltip(
                      message: 'Set as default',
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star_border_rounded,
                          color: AppTheme.warning,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.outline,
                      width: 2,
                    ),
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _brandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'rupay':
        return const Color(0xFF097939);
      case 'amex':
        return const Color(0xFF007BC1);
      default:
        return AppTheme.primary;
    }
  }

  String _brandLabel(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MC';
      case 'rupay':
        return 'RuPay';
      case 'amex':
        return 'AMEX';
      default:
        return 'CARD';
    }
  }
}

// ─── Empty Cards State ─────────────────────────────────────────────────────

class _EmptyCardsState extends StatelessWidget {
  final VoidCallback onAddCard;

  const _EmptyCardsState({required this.onAddCard});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.credit_card_off_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No saved cards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a card for faster checkout',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onAddCard,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: Text(
              'Add New Card',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Add New Card Bottom Sheet ─────────────────────────────────────────────

class AddNewCardBottomSheet extends StatefulWidget {
  final ValueChanged<SavedCard> onCardAdded;

  const AddNewCardBottomSheet({super.key, required this.onCardAdded});

  @override
  State<AddNewCardBottomSheet> createState() => _AddNewCardBottomSheetState();
}

class _AddNewCardBottomSheetState extends State<AddNewCardBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _cardholderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = true;
  bool _setAsDefault = false;
  bool _obscureCvv = true;
  String _detectedBrand = 'unknown';

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardholderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _detectBrand(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'visa';
    if (clean.startsWith('5') || clean.startsWith('2')) return 'mastercard';
    if (clean.startsWith('6')) return 'rupay';
    if (clean.startsWith('3')) return 'amex';
    return 'unknown';
  }

  String _formatCardNumber(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 2) {
      return '${clean.substring(0, 2)}/${clean.substring(2, clean.length.clamp(2, 4))}';
    }
    return clean;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawNumber = _cardNumberCtrl.text.replaceAll(' ', '');
    final last4 = rawNumber.substring(rawNumber.length - 4);
    final card = SavedCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardholderName: _cardholderCtrl.text.trim(),
      maskedNumber: last4,
      expiry: _expiryCtrl.text.trim(),
      brand: _detectedBrand,
      isDefault: _setAsDefault,
    );
    widget.onCardAdded(card);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_card_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add New Card',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFF74777F),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Security note
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.info,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your card details are encrypted and secure',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card number field
                _buildLabel('Card Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  onChanged: (val) {
                    final brand = _detectBrand(val);
                    if (brand != _detectedBrand) {
                      setState(() => _detectedBrand = brand);
                    }
                  },
                  decoration: _inputDecoration(
                    hint: '1234 5678 9012 3456',
                    prefixIcon: Icons.credit_card_rounded,
                    suffix: _detectedBrand != 'unknown'
                        ? _BrandBadge(brand: _detectedBrand)
                        : null,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Card number is required';
                    }
                    final clean = val.replaceAll(' ', '');
                    if (clean.length < 15) return 'Enter a valid card number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Cardholder name
                _buildLabel('Cardholder Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cardholderCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    hint: 'Name as on card',
                    prefixIcon: Icons.person_rounded,
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Cardholder name is required';
                    }
                    if (val.trim().length < 3) return 'Enter full name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Expiry + CVV row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Expiry Date'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _expiryCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryFormatter(),
                            ],
                            decoration: _inputDecoration(
                              hint: 'MM/YY',
                              prefixIcon: Icons.calendar_month_rounded,
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final parts = val.split('/');
                              if (parts.length != 2) return 'Invalid';
                              final month = int.tryParse(parts[0]) ?? 0;
                              if (month < 1 || month > 12) return 'Invalid';
                              return null;
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
                          _buildLabel('CVV'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _cvvCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: _obscureCvv,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _inputDecoration(
                              hint: '•••',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscureCvv = !_obscureCvv),
                                child: Icon(
                                  _obscureCvv
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.outline,
                                  size: 18,
                                ),
                              ),
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              letterSpacing: 2.0,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              if (val.length < 3) return 'Invalid CVV';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save card toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.save_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save card for future payments',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                Text(
                                  'Securely stored for faster checkout',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF74777F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _saveCard,
                            onChanged: (val) => setState(() {
                              _saveCard = val;
                              if (!val) _setAsDefault = false;
                            }),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                      if (_saveCard) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Set as default payment card',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                            ),
                            Switch(
                              value: _setAsDefault,
                              onChanged: (val) =>
                                  setState(() => _setAsDefault = val),
                              activeThumbColor: AppTheme.warning,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_card_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF44474E),
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primary, size: 18),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: const Color(0xFF90A4AE),
      ),
    );
  }
}

// ─── Brand Badge ───────────────────────────────────────────────────────────

class _BrandBadge extends StatelessWidget {
  final String brand;

  const _BrandBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (brand.toLowerCase()) {
      case 'visa':
        color = const Color(0xFF1A1F71);
        label = 'VISA';
        break;
      case 'mastercard':
        color = const Color(0xFFEB001B);
        label = 'MC';
        break;
      case 'rupay':
        color = const Color(0xFF097939);
        label = 'RuPay';
        break;
      case 'amex':
        color = const Color(0xFF007BC1);
        label = 'AMEX';
        break;
      default:
        color = AppTheme.outline;
        label = 'CARD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Input Formatters ──────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = newValue.text.replaceAll(RegExp(r'\D'), '');
    String text = clean;
    if (clean.length >= 2) {
      text =
          '${clean.substring(0, 2)}/${clean.substring(2, clean.length.clamp(2, 4))}';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
