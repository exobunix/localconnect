import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Transport Provider Chat Screen
/// Allows transport providers to chat with customers in real-time.
/// Supports booking-specific conversations and general inquiries.
class TransportProviderChatScreen extends StatefulWidget {
  const TransportProviderChatScreen({super.key});

  @override
  State<TransportProviderChatScreen> createState() =>
      _TransportProviderChatScreenState();
}

class _TransportProviderChatScreenState
    extends State<TransportProviderChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _subscription;

  String _conversationId = '';
  String _otherUserId = '';
  String _otherUserName = 'Customer';
  String _bookingId = '';
  String _vehicleType = '';
  Color _vehicleColor = const Color(0xFF1E88E5);

  final List<String> _quickReplies = [
    'I am on my way',
    'Reached pickup location',
    'Trip started',
    'Will arrive in 10 mins',
    'Please share exact location',
    'Trip completed successfully',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _conversationId = args?['conversationId'] as String? ?? '';
    _otherUserId = args?['otherUserId'] as String? ?? '';
    _otherUserName = args?['otherUserName'] as String? ?? 'Customer';
    _bookingId = args?['bookingId'] as String? ?? '';
    _vehicleType = args?['vehicleType'] as String? ?? 'rickshaw';
    _vehicleColor = _getVehicleColor(_vehicleType);

    if (_conversationId.isNotEmpty) {
      _loadMessages();
      _subscribeToMessages();
    } else {
      // Create or find conversation
      _initConversation();
    }
  }

  Color _getVehicleColor(String vt) {
    switch (vt) {
      case 'car':
        return const Color(0xFF00838F);
      case 'tempo':
        return const Color(0xFF7B1FA2);
      case 'pickup_van':
        return const Color(0xFFE65100);
      case 'truck':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1E88E5);
    }
  }

  Future<void> _initConversation() async {
    if (_otherUserId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final conv = await SupabaseService.instance.getOrCreateConversation(
        providerUserId: _otherUserId,
      );
      if (conv != null && mounted) {
        setState(() => _conversationId = conv['id'] as String? ?? '');
        if (_conversationId.isNotEmpty) {
          _loadMessages();
          _subscribeToMessages();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId.isEmpty) return;
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getMessages(_conversationId);
    if (mounted) {
      setState(() {
        _messages = data;
        _isLoading = false;
      });
      _scrollToBottom();
      SupabaseService.instance.markMessagesRead(_conversationId);
    }
  }

  void _subscribeToMessages() {
    if (_conversationId.isEmpty) return;
    _subscription = SupabaseService.instance.subscribeToMessages(
      conversationId: _conversationId,
      onMessage: (message) {
        if (mounted) {
          setState(() => _messages.add(message));
          _scrollToBottom();
          final senderId = message['sender_id'] as String? ?? '';
          final myId = SupabaseService.instance.currentUser?.id ?? '';
          if (senderId != myId) {
            SupabaseService.instance.markMessagesRead(_conversationId);
          }
        }
      },
    );
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

  Future<void> _sendMessage([String? quickReply]) async {
    final text = quickReply ?? _messageController.text.trim();
    if (text.isEmpty || _isSending || _conversationId.isEmpty) return;

    setState(() => _isSending = true);
    if (quickReply == null) _messageController.clear();

    final result = await SupabaseService.instance.sendMessage(
      conversationId: _conversationId,
      content: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (result != null) {
        final alreadyAdded = _messages.any((m) => m['id'] == result['id']);
        if (!alreadyAdded) {
          setState(() => _messages.add(result));
          _scrollToBottom();
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  bool _isSameDay(String? a, String? b) {
    if (a == null || b == null) return false;
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) {
      return false;
    }
  }

  String _formatDateLabel(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Yesterday';
      }
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = SupabaseService.instance.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_bookingId.isNotEmpty) _buildBookingBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessageList(myId),
          ),
          _buildQuickReplies(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _vehicleColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _otherUserName.isNotEmpty ? _otherUserName[0].toUpperCase() : 'C',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Customer',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Calling customer...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _vehicleColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: _vehicleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Booking #${_bookingId.length > 8 ? _bookingId.substring(0, 8) : _bookingId}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _vehicleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: const Color(0xFF74777F).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with your customer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF74777F).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(String myId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = (msg['sender_id'] as String? ?? '') == myId;
        final createdAt = msg['created_at'] as String?;
        final prevCreatedAt = index > 0
            ? _messages[index - 1]['created_at'] as String?
            : null;
        final showDateLabel =
            index == 0 || !_isSameDay(prevCreatedAt, createdAt);

        return Column(
          children: [
            if (showDateLabel) _buildDateLabel(createdAt),
            _buildMessageBubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateLabel(String? isoString) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
          ),
          child: Text(
            _formatDateLabel(isoString),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF74777F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final content = msg['content'] as String? ?? '';
    final time = _formatTime(msg['created_at'] as String?);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 6,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? _vehicleColor : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickReplies[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _vehicleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _vehicleColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _quickReplies[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: _vehicleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF1A1C1E),
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF74777F),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending ? AppTheme.outline : _vehicleColor,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
