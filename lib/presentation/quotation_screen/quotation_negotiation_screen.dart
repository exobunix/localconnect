import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class QuotationNegotiationScreen extends StatefulWidget {
  final Map<String, dynamic> quotation;
  final String role; // 'customer' | 'provider'

  const QuotationNegotiationScreen({
    super.key,
    required this.quotation,
    required this.role,
  });

  @override
  State<QuotationNegotiationScreen> createState() =>
      _QuotationNegotiationScreenState();
}

class _QuotationNegotiationScreenState
    extends State<QuotationNegotiationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _counterAmountController =
      TextEditingController();
  final TextEditingController _counterNotesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showCounterOffer = false;
  String? _error;
  RealtimeChannel? _subscription;

  late String _quotationId;
  late String _currentUserId;
  late double _currentAmount;
  late String _serviceName;
  late String _otherPartyName;
  late String _quotationStatus;

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    _quotationId = q['id'] as String? ?? '';
    _currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    _currentAmount = (q['total_amount'] ?? q['amount'] ?? 0).toDouble();
    final enquiry = q['enquiry'] as Map<String, dynamic>? ?? {};
    _serviceName = (enquiry['title'] as String? ?? '').isNotEmpty
        ? enquiry['title'] as String
        : 'Service';
    final provider = q['provider'] as Map<String, dynamic>? ?? {};
    final customer = q['customer'] as Map<String, dynamic>? ?? {};
    _otherPartyName = widget.role == 'customer'
        ? (provider['business_name'] as String? ??
              provider['full_name'] as String? ??
              'Provider')
        : (customer['full_name'] as String? ?? 'Customer');
    _quotationStatus = q['status'] as String? ?? 'sent';

    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _messageController.dispose();
    _counterAmountController.dispose();
    _counterNotesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_quotationId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.instance.getQuotationMessages(
        _quotationId,
      );
      if (mounted) {
        setState(() {
          _messages = data;
          _isLoading = false;
        });
        _scrollToBottom();
        _markMessagesRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages.';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToMessages() {
    if (_quotationId.isEmpty) return;
    _subscription = SupabaseService.instance.client
        .channel('quotation_messages_$_quotationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'quotation_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quotation_id',
            value: _quotationId,
          ),
          callback: (payload) {
            if (mounted) {
              final newMsg = payload.newRecord as Map<String, dynamic>? ?? {};
              if (newMsg.isNotEmpty) {
                setState(() => _messages.add(newMsg));
                _scrollToBottom();
                _markMessagesRead();
              }
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesRead() async {
    try {
      await SupabaseService.instance.markQuotationMessagesRead(
        _quotationId,
        _currentUserId,
      );
    } catch (_) {}
  }

  Future<void> _sendMessage({
    String type = 'text',
    double? proposedAmount,
    String? proposedNotes,
  }) async {
    final content = _messageController.text.trim();
    if (type == 'text' && content.isEmpty) return;
    if (type == 'counter_offer' &&
        (_counterAmountController.text.trim().isEmpty)) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final msgContent = type == 'counter_offer'
          ? (content.isNotEmpty
                ? content
                : 'Counter-offer: ₹${_counterAmountController.text.trim()}')
          : content;

      await SupabaseService.instance.sendQuotationMessage(
        quotationId: _quotationId,
        senderId: _currentUserId,
        messageType: type,
        content: msgContent,
        proposedAmount: proposedAmount,
        proposedNotes: proposedNotes,
      );

      _messageController.clear();
      if (type == 'counter_offer') {
        _counterAmountController.clear();
        _counterNotesController.clear();
        setState(() => _showCounterOffer = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send message.',
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
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _acceptCounterOffer(Map<String, dynamic> msg) async {
    final proposed = (msg['proposed_amount'] as num?)?.toDouble();
    if (proposed == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Accept Counter-Offer?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Accept the revised amount of ₹${proposed.toStringAsFixed(2)}?',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Accept',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.instance.updateQuotationStatus(
        quotationId: _quotationId,
        status: 'negotiating',
      );
      await SupabaseService.instance.sendQuotationMessage(
        quotationId: _quotationId,
        senderId: _currentUserId,
        messageType: 'system',
        content:
            'Counter-offer of ₹${proposed.toStringAsFixed(2)} accepted. Quotation is now in negotiation.',
      );
      setState(() {
        _currentAmount = proposed;
        _quotationStatus = 'negotiating';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Counter-offer accepted!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  bool get _canNegotiate =>
      _quotationStatus == 'sent' || _quotationStatus == 'negotiating';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildQuotationSummaryBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : _buildMessageList(),
          ),
          if (_showCounterOffer) _buildCounterOfferPanel(),
          if (_canNegotiate) _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _otherPartyName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            _serviceName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 3.w),
          padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: _statusColor(_quotationStatus).withAlpha(51),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _statusColor(_quotationStatus).withAlpha(153),
            ),
          ),
          child: Text(
            _statusLabel(_quotationStatus),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(235),
            AppTheme.primary.withAlpha(191),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 14.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Quotation Amount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            '₹${_currentAmount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            _error!,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
          ),
          SizedBox(height: 1.h),
          TextButton(
            onPressed: _loadMessages,
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.grey[400],
              size: 22.sp,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'No messages yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              _canNegotiate
                  ? 'Start negotiating by sending a message below'
                  : 'Negotiation is closed for this quotation',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = (msg['sender_id'] as String? ?? '') == _currentUserId;
        final type = msg['message_type'] as String? ?? 'text';

        if (type == 'system') {
          return _buildSystemMessage(msg);
        }
        return _buildMessageBubble(msg, isMe);
      },
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> msg) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            msg['content'] as String? ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final type = msg['message_type'] as String? ?? 'text';
    final content = msg['content'] as String? ?? '';
    final proposedAmount = (msg['proposed_amount'] as num?)?.toDouble();
    final proposedNotes = msg['proposed_notes'] as String?;
    final createdAt = msg['created_at'] as String? ?? '';
    final time = _formatTime(createdAt);

    final isCounterOffer = type == 'counter_offer';
    final isAdjustment = type == 'adjustment';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 1.h,
          left: isMe ? 8.w : 0,
          right: isMe ? 0 : 8.w,
        ),
        constraints: BoxConstraints(maxWidth: 75.w),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: isCounterOffer || isAdjustment
                    ? (isMe
                          ? const Color(0xFFE65100).withAlpha(31)
                          : const Color(0xFF1565C0).withAlpha(20))
                    : (isMe ? AppTheme.primary.withAlpha(230) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: (isCounterOffer || isAdjustment)
                    ? Border.all(
                        color: isMe
                            ? const Color(0xFFE65100).withAlpha(102)
                            : const Color(0xFF1565C0).withAlpha(77),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCounterOffer || isAdjustment) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCounterOffer
                              ? Icons.swap_horiz_rounded
                              : Icons.tune_rounded,
                          size: 10.sp,
                          color: isMe
                              ? const Color(0xFFE65100)
                              : const Color(0xFF1565C0),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          isCounterOffer ? 'Counter-Offer' : 'Adjustment',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: isMe
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    if (proposedAmount != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFE65100).withAlpha(38)
                              : const Color(0xFF1565C0).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${proposedAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isMe
                                ? const Color(0xFFE65100)
                                : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    if (proposedNotes != null && proposedNotes.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        proposedNotes,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    SizedBox(height: 0.5.h),
                  ],
                  Text(
                    content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      color: (isCounterOffer || isAdjustment)
                          ? Colors.grey[800]
                          : (isMe ? Colors.white : Colors.grey[850]),
                    ),
                  ),
                  // Accept counter-offer button (only for the other party)
                  if (isCounterOffer &&
                      !isMe &&
                      _canNegotiate &&
                      proposedAmount != null) ...[
                    SizedBox(height: 1.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptCounterOffer(msg),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                        ),
                        label: Text(
                          'Accept ₹${proposedAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 0.8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 7.5.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterOfferPanel() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: const Color(0xFFE65100),
                size: 12.sp,
              ),
              SizedBox(width: 1.5.w),
              Text(
                'Send Counter-Offer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE65100),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showCounterOffer = false),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.grey[500],
                  size: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _counterAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                  decoration: InputDecoration(
                    labelText: 'Proposed Amount (₹)',
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      color: Colors.grey[600],
                    ),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.2.h,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _counterNotesController,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Reason / Notes (optional)',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE65100),
                  width: 1.5,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              isDense: true,
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending
                  ? null
                  : () {
                      final amt = double.tryParse(
                        _counterAmountController.text.trim(),
                      );
                      if (amt == null || amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Enter a valid amount.',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _sendMessage(
                        type: 'counter_offer',
                        proposedAmount: amt,
                        proposedNotes:
                            _counterNotesController.text.trim().isNotEmpty
                            ? _counterNotesController.text.trim()
                            : null,
                      );
                    },
              icon: _isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 14),
              label: Text(
                'Send Counter-Offer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Counter-offer toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showCounterOffer = !_showCounterOffer),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _showCounterOffer
                      ? const Color(0xFFE65100).withAlpha(31)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _showCounterOffer
                        ? const Color(0xFFE65100).withAlpha(128)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: _showCounterOffer
                      ? const Color(0xFFE65100)
                      : Colors.grey[600],
                  size: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.plusJakartaSans(fontSize: 10.sp),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.5.w,
                    vertical: 1.2.h,
                  ),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: _isSending ? null : () => _sendMessage(),
              child: Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 12.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'expired':
        return const Color(0xFF757575);
      case 'negotiating':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'negotiating':
        return 'Negotiating';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }
}
