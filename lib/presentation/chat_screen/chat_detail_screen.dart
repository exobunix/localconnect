import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'package:localconnect/core/supabase_mock.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _subscription;

  late String _conversationId;
  late String _otherUserId;
  late String _otherUserName;
  late String _otherUserAvatar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _conversationId = args?['conversationId'] as String? ?? '';
    _otherUserId = args?['otherUserId'] as String? ?? '';
    _otherUserName = args?['otherUserName'] as String? ?? 'Chat';
    _otherUserAvatar = args?['otherUserAvatar'] as String? ?? '';

    if (_conversationId.isNotEmpty) {
      _loadMessages();
      _subscribeToMessages();
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
      // Mark messages as read
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
          // Mark as read if from other user
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final result = await SupabaseService.instance.sendMessage(
      conversationId: _conversationId,
      content: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (result != null) {
        // Real-time subscription will add the message, but add locally for instant feedback
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

  String _formatMessageTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
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
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 4.w,
              backgroundColor: AppTheme.primaryContainer,
              backgroundImage: _otherUserAvatar.isNotEmpty
                  ? NetworkImage(_otherUserAvatar)
                  : null,
              child: _otherUserAvatar.isEmpty
                  ? Text(
                      _otherUserName.isNotEmpty
                          ? _otherUserName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                _otherUserName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = (msg['sender_id'] as String?) == myId;
                      final showDateLabel =
                          index == 0 ||
                          !_isSameDay(
                            _messages[index - 1]['created_at'] as String?,
                            msg['created_at'] as String?,
                          );
                      return Column(
                        children: [
                          if (showDateLabel)
                            _DateLabel(
                              label: _formatDateLabel(
                                msg['created_at'] as String?,
                              ),
                            ),
                          _MessageBubble(
                            content: msg['content'] as String? ?? '',
                            time: _formatMessageTime(
                              msg['created_at'] as String?,
                            ),
                            isMe: isMe,
                            isRead: msg['is_read'] as bool? ?? false,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 12.w,
            color: AppTheme.outline,
          ),
          SizedBox(height: 1.h),
          Text(
            'Say hello!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              color: const Color(0xFF74777F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 2.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.sp,
                    color: const Color(0xFF90A4AE),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.2.h,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 11.w,
              height: 11.w,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool isMe;
  final bool isRead;

  const _MessageBubble({
    required this.content,
    required this.time,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 0.4.h,
          bottom: 0.4.h,
          left: isMe ? 12.w : 0,
          right: isMe ? 0 : 12.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: isMe ? Colors.white : const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 0.3.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF90A4AE),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String label;

  const _DateLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: AppTheme.outlineVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF74777F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
