import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/razorpay_payment_widget.dart';
import './widgets/customer_availability_widget.dart';
import './widgets/saved_payment_methods_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _promoController = TextEditingController();

  // Manual address fallback controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  int _quantity = 1;
  String _selectedPayment = 'cash';
  bool _isSubmitting = false;
  bool _useManualAddress = false;

  // Pending order ID created before Razorpay checkout opens
  String? _pendingOrderId;
  String? _pendingOrderNumber;

  // Saved addresses
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;

  // Promo code
  bool _promoLoading = false;
  double _promoDiscount = 0.0;
  String? _promoError;
  String? _promoSuccess;
  String? _appliedPromoCode;

  // Availability selection
  Map<String, dynamic>? _selectedSlot;

  // Saved cards
  List<SavedCard> _savedCards = [];
  String? _selectedCardId;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'razorpay',
      'label': 'Razorpay (Cards, UPI, Wallets)',
      'icon': Icons.payment_rounded,
      'color': Color(0xFF3395FF),
    },
    {
      'id': 'cash',
      'label': 'Cash on Delivery',
      'icon': Icons.money_rounded,
      'color': Color(0xFF2E7D32),
    },
    {
      'id': 'upi',
      'label': 'UPI / QR Code',
      'icon': Icons.qr_code_rounded,
      'color': Color(0xFF6A1B9A),
    },
    {
      'id': 'card',
      'label': 'Credit / Debit Card',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF1565C0),
    },
    {
      'id': 'netbanking',
      'label': 'Net Banking',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFFF57C00),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    // Load from local state (in a real app, fetch from Supabase/secure storage)
    // Pre-populate with empty list; user can add cards via the bottom sheet
    if (mounted) {
      setState(() {
        _savedCards = [];
      });
    }
  }

  void _onCardAdded(SavedCard card) {
    setState(() {
      // If set as default, clear default from others
      if (card.isDefault) {
        _savedCards = _savedCards
            .map((c) => c.copyWith(isDefault: false))
            .toList();
      }
      _savedCards.add(card);
      _selectedCardId = card.id;
      // Auto-select card payment method when a card is added
      _selectedPayment = 'card';
    });
  }

  void _onSetDefaultCard(String cardId) {
    setState(() {
      _savedCards = _savedCards.map((c) {
        return c.copyWith(isDefault: c.id == cardId);
      }).toList();
    });
  }

  void _onDeleteCard(String cardId) {
    setState(() {
      _savedCards.removeWhere((c) => c.id == cardId);
      if (_selectedCardId == cardId) {
        _selectedCardId = _savedCards.isNotEmpty ? _savedCards.first.id : null;
        if (_savedCards.isEmpty && _selectedPayment == 'card') {
          _selectedPayment = 'cash';
        }
      }
    });
  }

  void _onCardSelected(String? cardId) {
    setState(() {
      _selectedCardId = cardId;
      if (cardId != null) {
        _selectedPayment = 'card';
      }
    });
  }

  Future<void> _loadSavedAddresses() async {
    final addresses = await SupabaseService.instance.getSavedAddresses();
    if (mounted) {
      setState(() {
        _savedAddresses = addresses;
        _loadingAddresses = false;
        // Auto-select default address
        final defaultAddr = addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : {},
        );
        if (defaultAddr.isNotEmpty) {
          _selectedAddressId = defaultAddr['id'] as String?;
        } else {
          _useManualAddress = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getArgs(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>? ??
        {};
  }

  double _getUnitPrice(Map<String, dynamic> args) {
    final raw = args['amount'] as String? ?? '₹0';
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '₹${amount.toInt()}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _buildFullAddress() {
    if (!_useManualAddress && _selectedAddressId != null) {
      final addr = _savedAddresses.firstWhere(
        (a) => a['id'] == _selectedAddressId,
        orElse: () => {},
      );
      if (addr.isNotEmpty) {
        final line1 = addr['address_line1'] as String? ?? '';
        final line2 = addr['address_line2'] as String? ?? '';
        final city = addr['city'] as String? ?? '';
        final state = addr['state'] as String? ?? '';
        final pincode = addr['pincode'] as String? ?? '';
        return [
          line1,
          if (line2.isNotEmpty) line2,
          city,
          state,
          pincode,
        ].where((s) => s.isNotEmpty).join(', ');
      }
    }
    return '${_addressController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}';
  }

  Future<void> _applyPromoCode(Map<String, dynamic> args) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final providerId = args['providerId'] as String?;
    if (providerId == null || providerId.isEmpty) {
      setState(() {
        _promoError = 'Promo codes are provider-specific';
        _promoSuccess = null;
      });
      return;
    }

    setState(() {
      _promoLoading = true;
      _promoError = null;
      _promoSuccess = null;
    });

    final unitPrice = _getUnitPrice(args);
    final subtotal = unitPrice * _quantity;

    final result = await SupabaseService.instance.validatePromoCode(
      promoCode: code,
      providerId: providerId,
      orderAmount: subtotal,
    );

    if (mounted) {
      setState(() {
        _promoLoading = false;
        if (result == null) {
          _promoError = 'Invalid promo code';
          _promoDiscount = 0.0;
          _appliedPromoCode = null;
        } else if (result.containsKey('error')) {
          _promoError = result['error'] as String;
          _promoDiscount = 0.0;
          _appliedPromoCode = null;
        } else {
          _promoDiscount = (result['discount'] as num?)?.toDouble() ?? 0.0;
          _promoSuccess =
              '${result['title']} applied! You save ${_formatAmount(_promoDiscount)}';
          _appliedPromoCode = code;
          _promoError = null;
        }
      });
    }
  }

  void _removePromo() {
    setState(() {
      _promoDiscount = 0.0;
      _promoError = null;
      _promoSuccess = null;
      _appliedPromoCode = null;
      _promoController.clear();
    });
  }

  Future<void> _submitOrder(Map<String, dynamic> args) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate address selection
    if (!_useManualAddress && _selectedAddressId == null) {
      Fluttertoast.showToast(
        msg: 'Please select a delivery address',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final unitPrice = _getUnitPrice(args);
      final subtotal = unitPrice * _quantity;
      final totalAmount = subtotal - _promoDiscount;
      final fullAddress = _buildFullAddress();

      final scheduledDate =
          _selectedSlot?['date'] as String? ??
          args['scheduledDate'] as String? ??
          DateTime.now().toIso8601String().split('T').first;
      final scheduledTime = _selectedSlot != null
          ? '${_selectedSlot!['dateDisplay']} at ${_selectedSlot!['display']}'
          : args['scheduledTime'] as String? ?? 'Flexible';

      final notesParts = <String>[
        'Qty: $_quantity',
        'Payment: $_selectedPayment',
        'Address: $fullAddress',
        if (_appliedPromoCode != null) 'Promo: $_appliedPromoCode',
        if (_notesController.text.trim().isNotEmpty)
          'Notes: ${_notesController.text.trim()}',
      ];

      final result = await SupabaseService.instance.createOrder(
        providerName: args['providerName'] as String? ?? '',
        service: args['service'] as String? ?? '',
        category: args['category'] as String? ?? '',
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        amount: _formatAmount(totalAmount > 0 ? totalAmount : subtotal),
        providerId: args['providerId'] as String?,
        promoCode: _appliedPromoCode,
        discountAmount: _promoDiscount,
        paymentMethod: _selectedPayment,
      );

      if (result != null) {
        final orderId = result['id'] as String?;
        if (orderId != null) {
          await SupabaseService.instance.client
              .from('orders')
              .update({'notes': notesParts.join(' | ')})
              .eq('id', orderId);
        }

        final providerId = args['providerId'] as String?;
        if (_selectedSlot != null && providerId != null && orderId != null) {
          final slotDateStr = _selectedSlot!['date'] as String?;
          final slotTime = _selectedSlot!['time'] as String?;
          if (slotDateStr != null && slotTime != null) {
            try {
              final slotDate = DateTime.parse(slotDateStr);
              await SupabaseService.instance.bookSlot(
                providerId: providerId,
                date: slotDate,
                slotTime: slotTime,
                orderId: orderId,
              );
            } catch (_) {}
          }
        }
      }

      if (!mounted) return;

      if (result != null) {
        _showSuccessSheet(context, result);
      } else {
        final errorMsg = SupabaseService.instance.lastOrderError != null
            ? 'Failed to place order: ${SupabaseService.instance.lastOrderError}'
            : 'Failed to place order. Please try again.';
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: AppTheme.error,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Something went wrong: $e',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Creates the order in Supabase with payment_status='pending' BEFORE
  /// opening Razorpay checkout. Returns the created order map or null on failure.
  Future<Map<String, dynamic>?> _createOrderForRazorpay(
    Map<String, dynamic> args,
  ) async {
    if (!_formKey.currentState!.validate()) return null;

    if (!_useManualAddress && _selectedAddressId == null) {
      Fluttertoast.showToast(
        msg: 'Please select a delivery address',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
      return null;
    }

    setState(() => _isSubmitting = true);

    try {
      final unitPrice = _getUnitPrice(args);
      final subtotal = unitPrice * _quantity;
      final totalAmount = subtotal - _promoDiscount;
      final fullAddress = _buildFullAddress();

      final scheduledDate =
          _selectedSlot?['date'] as String? ??
          args['scheduledDate'] as String? ??
          DateTime.now().toIso8601String().split('T').first;
      final scheduledTime = _selectedSlot != null
          ? '${_selectedSlot!['dateDisplay']} at ${_selectedSlot!['display']}'
          : args['scheduledTime'] as String? ?? 'Flexible';

      final notesParts = <String>[
        'Qty: $_quantity',
        'Payment: razorpay',
        'Address: $fullAddress',
        if (_appliedPromoCode != null) 'Promo: $_appliedPromoCode',
        if (_notesController.text.trim().isNotEmpty)
          'Notes: ${_notesController.text.trim()}',
      ];

      final result = await SupabaseService.instance.createOrder(
        providerName: args['providerName'] as String? ?? '',
        service: args['service'] as String? ?? '',
        category: args['category'] as String? ?? '',
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        amount: _formatAmount(totalAmount > 0 ? totalAmount : subtotal),
        providerId: args['providerId'] as String?,
        promoCode: _appliedPromoCode,
        discountAmount: _promoDiscount,
        paymentMethod: 'razorpay',
      );

      if (result != null) {
        final orderId = result['id'] as String?;
        if (orderId != null) {
          // Store pending order ID so Razorpay widget can update it on success
          setState(() {
            _pendingOrderId = orderId;
            _pendingOrderNumber = result['order_number'] as String?;
          });

          await SupabaseService.instance.client
              .from('orders')
              .update({'notes': notesParts.join(' | ')})
              .eq('id', orderId);

          final providerId = args['providerId'] as String?;
          if (_selectedSlot != null && providerId != null) {
            final slotDateStr = _selectedSlot!['date'] as String?;
            final slotTime = _selectedSlot!['time'] as String?;
            if (slotDateStr != null && slotTime != null) {
              try {
                final slotDate = DateTime.parse(slotDateStr);
                await SupabaseService.instance.bookSlot(
                  providerId: providerId,
                  date: slotDate,
                  slotTime: slotTime,
                  orderId: orderId,
                );
              } catch (_) {}
            }
          }
        }
      }

      if (result == null) {
        final errorMsg = SupabaseService.instance.lastOrderError != null
            ? 'Failed to create booking: ${SupabaseService.instance.lastOrderError}'
            : 'Failed to create booking. Please try again.';
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: AppTheme.error,
          textColor: Colors.white,
        );
      }

      return result;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to create booking: $e',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
      return null;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSheet(BuildContext context, Map<String, dynamic> order) {
    final args = _getArgs(context);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.bookingConfirmationScreen,
      (route) => route.settings.name == AppRoutes.homeScreen,
      arguments: {
        'orderNumber': order['order_number'] as String? ?? '',
        'service': args['service'] as String? ?? 'Service',
        'providerName': args['providerName'] as String? ?? '',
        'amount': _formatAmount(
          (_getUnitPrice(args) * _quantity) - _promoDiscount,
        ),
        'scheduledDate':
            _selectedSlot?['dateDisplay'] as String? ??
            args['scheduledDate'] as String? ??
            '',
        'scheduledTime':
            _selectedSlot?['display'] as String? ??
            args['scheduledTime'] as String? ??
            'Flexible',
        'paymentMethod': _selectedPayment,
        'address': _buildFullAddress(),
        'orderId': order['id'] as String? ?? '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _getArgs(context);
    final unitPrice = _getUnitPrice(args);
    final subtotal = unitPrice * _quantity;
    final total = subtotal - _promoDiscount;
    final providerId = args['providerId'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _ServiceSummaryCard(args: args),
            const SizedBox(height: 16),
            _QuantitySelector(
              quantity: _quantity,
              unitPrice: unitPrice,
              onChanged: (val) {
                setState(() {
                  _quantity = val;
                  // Reset promo if quantity changes
                  if (_appliedPromoCode != null) {
                    _promoDiscount = 0.0;
                    _promoSuccess = null;
                    _appliedPromoCode = null;
                    _promoController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            // Availability picker
            if (providerId != null && providerId.isNotEmpty) ...[
              CustomerAvailabilityWidget(
                providerId: providerId,
                onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
                initialSelection: _selectedSlot,
              ),
              const SizedBox(height: 16),
            ],
            // Address Section
            _AddressSelectionSection(
              savedAddresses: _savedAddresses,
              selectedAddressId: _selectedAddressId,
              loadingAddresses: _loadingAddresses,
              useManualAddress: _useManualAddress,
              addressController: _addressController,
              cityController: _cityController,
              pincodeController: _pincodeController,
              onAddressSelected: (id) =>
                  setState(() => _selectedAddressId = id),
              onToggleManual: (val) => setState(() {
                _useManualAddress = val;
                if (!val && _savedAddresses.isNotEmpty) {
                  _selectedAddressId = _savedAddresses.first['id'] as String?;
                }
              }),
              onAddNewAddress: () => _showAddAddressSheet(context),
            ),
            const SizedBox(height: 16),
            // Promo Code Section
            _PromoCodeSection(
              controller: _promoController,
              isLoading: _promoLoading,
              promoError: _promoError,
              promoSuccess: _promoSuccess,
              appliedCode: _appliedPromoCode,
              onApply: () => _applyPromoCode(args),
              onRemove: _removePromo,
            ),
            const SizedBox(height: 16),
            _PaymentMethodSection(
              methods: _paymentMethods,
              selected: _selectedPayment,
              onSelect: (id) => setState(() {
                _selectedPayment = id;
                // Deselect card if switching away from card payment
                if (id != 'card') _selectedCardId = null;
              }),
            ),
            // Show saved cards section when card payment is selected
            if (_selectedPayment == 'card') ...[
              const SizedBox(height: 12),
              SavedPaymentMethodsWidget(
                savedCards: _savedCards,
                selectedCardId: _selectedCardId,
                onCardSelected: _onCardSelected,
                onCardAdded: _onCardAdded,
                onSetDefault: _onSetDefaultCard,
                onDeleteCard: _onDeleteCard,
              ),
            ],
            const SizedBox(height: 16),
            _NotesField(controller: _notesController),
            const SizedBox(height: 16),
            _OrderSummaryCard(
              quantity: _quantity,
              unitPrice: unitPrice,
              subtotal: subtotal,
              promoDiscount: _promoDiscount,
              total: total,
              serviceName: args['service'] as String? ?? 'Service',
              selectedSlot: _selectedSlot,
              paymentMethod: _selectedPayment,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        args,
        total > 0 ? total : subtotal,
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    final labelCtrl = TextEditingController(text: 'Home');
    final line1Ctrl = TextEditingController();
    final line2Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_location_alt_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSheetField(
                    labelCtrl,
                    'Label (e.g. Home, Work)',
                    Icons.label_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildSheetField(
                    line1Ctrl,
                    'Address Line 1 *',
                    Icons.home_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  _buildSheetField(
                    line2Ctrl,
                    'Address Line 2 (Optional)',
                    Icons.add_road_rounded,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildSheetField(
                          cityCtrl,
                          'City *',
                          Icons.location_city_rounded,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildSheetField(
                          pincodeCtrl,
                          'Pincode *',
                          Icons.pin_drop_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (v.trim().length != 6) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              await SupabaseService.instance.addAddress(
                                label: labelCtrl.text.trim().isEmpty
                                    ? 'Home'
                                    : labelCtrl.text.trim(),
                                addressLine1: line1Ctrl.text.trim(),
                                addressLine2: line2Ctrl.text.trim(),
                                city: cityCtrl.text.trim(),
                                pincode: pincodeCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadSavedAddresses();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Address',
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
        ),
      ),
    );
  }

  Widget _buildSheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      validator: validator,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Checkout',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Map<String, dynamic> args,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _selectedPayment == 'razorpay' && total > 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Step 1: Create order in Supabase (payment_status='pending'),
                // then open Razorpay with the real orderId.
                // Step 2: On Razorpay success, widget updates payment_status='paid'
                // and stores razorpay_payment_id in the orders row.
                _isSubmitting
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : RazorpayPaymentWidget(
                        amount: total,
                        description:
                            '${args['service'] ?? 'Service'} - ${args['providerName'] ?? ''}',
                        paymentType: 'one_time',
                        // Pass the pre-created orderId so payment_status is
                        // updated on the correct orders row after success.
                        orderId: _pendingOrderId,
                        providerId: args['providerId'] as String?,
                        notes: {
                          'service': args['service'] ?? '',
                          'provider': args['providerName'] ?? '',
                          'category': args['category'] ?? '',
                          if (_pendingOrderId != null)
                            'order_id': _pendingOrderId!,
                        },
                        onPaymentSuccess: () async {
                          // Order already created and payment_status updated
                          // by the widget — navigate to confirmation screen.
                          if (!mounted) return;
                          final orderId = _pendingOrderId;
                          final orderNumber = _pendingOrderNumber;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.bookingConfirmationScreen,
                            (route) =>
                                route.settings.name == AppRoutes.homeScreen,
                            arguments: {
                              'orderNumber': orderNumber ?? '',
                              'service':
                                  args['service'] as String? ?? 'Service',
                              'providerName':
                                  args['providerName'] as String? ?? '',
                              'amount': _formatAmount(total),
                              'scheduledDate':
                                  _selectedSlot?['dateDisplay'] as String? ??
                                  args['scheduledDate'] as String? ??
                                  '',
                              'scheduledTime':
                                  _selectedSlot?['display'] as String? ??
                                  args['scheduledTime'] as String? ??
                                  'Flexible',
                              'paymentMethod': 'razorpay',
                              'address': _buildFullAddress(),
                              'orderId': orderId ?? '',
                            },
                          );
                        },
                        onPaymentFailed: (error) {
                          // Cancel the pending order if payment fails
                          if (_pendingOrderId != null) {
                            SupabaseService.instance.client
                                .from('orders')
                                .update({
                                  'status': 'cancelled',
                                  'payment_status': 'failed',
                                })
                                .eq('id', _pendingOrderId!)
                                .then((_) {});
                            setState(() {
                              _pendingOrderId = null;
                              _pendingOrderNumber = null;
                            });
                          }
                          Fluttertoast.showToast(
                            msg: 'Payment failed: $error',
                            backgroundColor: AppTheme.error,
                            textColor: Colors.white,
                          );
                        },
                      ),
                const SizedBox(height: 8),
                // "Confirm & Pay" button — creates order then opens Razorpay
                if (_pendingOrderId == null)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final order = await _createOrderForRazorpay(args);
                              if (order == null && mounted) {
                                Fluttertoast.showToast(
                                  msg:
                                      'Could not create booking. Please try again.',
                                  backgroundColor: AppTheme.error,
                                  textColor: Colors.white,
                                );
                              }
                            },
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: Text(
                        'Confirm Booking & Pay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.success,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Booking #${_pendingOrderNumber ?? ''} created — tap Pay to complete',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Razorpay is available on the mobile app',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF74777F),
                      ),
                    ),
                    Text(
                      total > 0
                          ? '₹${(total).toStringAsFixed(0)}'
                          : 'Negotiable',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitOrder(args),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Place Order',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Service Summary Card ──────────────────────────────────────────────────

class _ServiceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> args;

  const _ServiceSummaryCard({required this.args});

  @override
  Widget build(BuildContext context) {
    final providerName = args['providerName'] as String? ?? 'Provider';
    final service = args['service'] as String? ?? 'Service';
    final category = args['category'] as String? ?? '';
    final amount = args['amount'] as String? ?? 'Negotiable';
    final imageUrl = args['imageUrl'] as String? ?? '';

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Service Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF44474E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF74777F),
                    ),
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.home_repair_service_rounded,
        color: AppTheme.primary,
        size: 32,
      ),
    );
  }
}

// ─── Quantity Selector ─────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final double unitPrice;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.quantity,
    required this.unitPrice,
    required this.onChanged,
  });

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
      child: Row(
        children: [
          const Icon(Icons.layers_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quantity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1C1E),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: quantity < 20 ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primary : AppTheme.outlineVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppTheme.outline,
          size: 18,
        ),
      ),
    );
  }
}

// ─── Address Selection Section ─────────────────────────────────────────────

class _AddressSelectionSection extends StatelessWidget {
  final List<Map<String, dynamic>> savedAddresses;
  final String? selectedAddressId;
  final bool loadingAddresses;
  final bool useManualAddress;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController pincodeController;
  final ValueChanged<String> onAddressSelected;
  final ValueChanged<bool> onToggleManual;
  final VoidCallback onAddNewAddress;

  const _AddressSelectionSection({
    required this.savedAddresses,
    required this.selectedAddressId,
    required this.loadingAddresses,
    required this.useManualAddress,
    required this.addressController,
    required this.cityController,
    required this.pincodeController,
    required this.onAddressSelected,
    required this.onToggleManual,
    required this.onAddNewAddress,
  });

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
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              if (!loadingAddresses && savedAddresses.isNotEmpty)
                GestureDetector(
                  onTap: () => onToggleManual(!useManualAddress),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      useManualAddress ? 'Use Saved' : 'Enter Manually',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (loadingAddresses)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (!useManualAddress && savedAddresses.isNotEmpty) ...[
            // Saved address cards
            ...savedAddresses.map((addr) {
              final isSelected = addr['id'] == selectedAddressId;
              final label = addr['label'] as String? ?? 'Address';
              final line1 = addr['address_line1'] as String? ?? '';
              final line2 = addr['address_line2'] as String? ?? '';
              final city = addr['city'] as String? ?? '';
              final pincode = addr['pincode'] as String? ?? '';
              final isDefault = addr['is_default'] as bool? ?? false;

              return GestureDetector(
                onTap: () => onAddressSelected(addr['id'] as String),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          label.toLowerCase().contains('work')
                              ? Icons.work_rounded
                              : Icons.home_rounded,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outline,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : const Color(0xFF1A1C1E),
                                  ),
                                ),
                                if (isDefault) ...[
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
                              [
                                line1,
                                if (line2.isNotEmpty) line2,
                                '$city - $pincode',
                              ].join(', '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF74777F),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.outline,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
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
                ),
              );
            }),
            // Add new address button
            GestureDetector(
              onTap: onAddNewAddress,
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
                      Icons.add_location_alt_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Address',
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
          ] else ...[
            // Manual address entry
            TextFormField(
              controller: addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'House / Flat No., Street, Landmark',
                prefixIcon: const Icon(
                  Icons.home_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Address is required'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(
                      hintText: 'City',
                      prefixIcon: const Icon(
                        Icons.location_city_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'Pincode',
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.pin_drop_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      if (val.trim().length != 6) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (savedAddresses.isEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onAddNewAddress,
                child: Row(
                  children: [
                    const Icon(
                      Icons.save_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Save this address for future orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Promo Code Section ────────────────────────────────────────────────────

class _PromoCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? promoError;
  final String? promoSuccess;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _PromoCodeSection({
    required this.controller,
    required this.isLoading,
    required this.promoError,
    required this.promoSuccess,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isApplied = appliedCode != null;

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
          Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: AppTheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Promo Code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: !isApplied,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    prefixIcon: const Icon(
                      Icons.discount_rounded,
                      color: AppTheme.secondary,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: isApplied
                        ? AppTheme.successContainer
                        : AppTheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isApplied ? AppTheme.success : null,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: isApplied
                    ? ElevatedButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          'Remove',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorContainer,
                          foregroundColor: AppTheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isLoading ? null : onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Apply',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
              ),
            ],
          ),
          if (promoSuccess != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    promoSuccess!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (promoError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    promoError!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Payment Method Section ────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  final List<Map<String, dynamic>> methods;
  final String selected;
  final ValueChanged<String> onSelect;

  const _PaymentMethodSection({
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

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
          Row(
            children: [
              const Icon(
                Icons.payment_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...methods.map((method) {
            final isSelected = selected == method['id'];
            final color = method['color'] as Color;
            return GestureDetector(
              onTap: () => onSelect(method['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.08)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: isSelected ? color : AppTheme.outline,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        method['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? color : const Color(0xFF44474E),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : AppTheme.outline,
                          width: 2,
                        ),
                        color: isSelected ? color : Colors.transparent,
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
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Notes Field ───────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesField({required this.controller});

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
          Row(
            children: [
              const Icon(
                Icons.notes_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Special Instructions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF74777F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Any specific requirements or notes for the provider...',
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary Card ────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double promoDiscount;
  final double total;
  final String serviceName;
  final Map<String, dynamic>? selectedSlot;
  final String paymentMethod;

  const _OrderSummaryCard({
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.promoDiscount,
    required this.total,
    required this.serviceName,
    required this.paymentMethod,
    this.selectedSlot,
  });

  String _paymentLabel(String id) {
    switch (id) {
      case 'upi':
        return 'UPI / QR Code';
      case 'card':
        return 'Credit / Debit Card';
      case 'netbanking':
        return 'Net Banking';
      default:
        return 'Cash on Delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: serviceName,
            value: unitPrice > 0 ? '₹${unitPrice.toInt()}' : 'Negotiable',
            isLight: true,
          ),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Quantity', value: '× $quantity', isLight: true),
          if (subtotal > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Subtotal',
              value: '₹${subtotal.toInt()}',
              isLight: true,
            ),
          ],
          if (promoDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Promo Discount',
              value: '- ₹${promoDiscount.toInt()}',
              isLight: true,
              isDiscount: true,
            ),
          ],
          if (selectedSlot != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Scheduled',
              value:
                  '${selectedSlot!['dateDisplay'] ?? ''} · ${selectedSlot!['display'] ?? ''}',
              isLight: true,
            ),
          ],
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Payment',
            value: _paymentLabel(paymentMethod),
            isLight: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
          _SummaryRow(
            label: 'Total',
            value: total > 0 ? '₹${total.toInt()}' : 'Negotiable',
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLight;
  final bool isBold;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLight = false,
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isLight ? Colors.white.withValues(alpha: 0.8) : Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isDiscount ? const Color(0xFF80FF80) : Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── Order Success Bottom Sheet ────────────────────────────────────────────

class _OrderSuccessSheet extends StatelessWidget {
  final String orderNumber;
  final VoidCallback onDone;
  final VoidCallback onViewOrders;

  const _OrderSuccessSheet({
    required this.orderNumber,
    required this.onDone,
    required this.onViewOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order Placed!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order has been successfully placed.\nThe provider will confirm shortly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F),
              height: 1.5,
            ),
          ),
          if (orderNumber.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order #$orderNumber',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Go Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Orders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
