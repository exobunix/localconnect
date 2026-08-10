import 'package:google_fonts/google_fonts.dart';
import 'package:localconnect/core/supabase_mock.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToUpdates();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.getConversations();
    if (mounted) {
      setState(() {
        _conversations = data;
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    _subscription = SupabaseService.instance.subscribeToConversations(
      onUpdate: () {
        if (mounted) _loadConversations();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  String _getOtherPartyName(Map<String, dynamic> conv) {
    final currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    final customerId = conv['customer_id'] as String? ?? '';
    if (currentUserId == customerId) {
      // I'm the customer, show provider name
      final sp = conv['service_provider'];
      if (sp != null && sp is Map) {
        return sp['business_name'] as String? ?? 'Provider';
      }
      final provider = conv['provider'];
      if (provider != null && provider is Map) {
        return provider['full_name'] as String? ?? 'Provider';
      }
      return 'Provider';
    } else {
      // I'm the provider, show customer name
      final customer = conv['customer'];
      if (customer != null && customer is Map) {
        return customer['full_name'] as String? ?? 'Customer';
      }
      return 'Customer';
    }
  }

  String _getOtherPartyAvatar(Map<String, dynamic> conv) {
    final currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    final customerId = conv['customer_id'] as String? ?? '';
    if (currentUserId == customerId) {
      final sp = conv['service_provider'];
      if (sp != null && sp is Map) {
        return sp['image_url'] as String? ?? '';
      }
      final provider = conv['provider'];
      if (provider != null && provider is Map) {
        return provider['avatar_url'] as String? ?? '';
      }
      return '';
    } else {
      final customer = conv['customer'];
      if (customer != null && customer is Map) {
        return customer['avatar_url'] as String? ?? '';
      }
      return '';
    }
  }

  String _getOtherPartyId(Map<String, dynamic> conv) {
    final currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    final customerId = conv['customer_id'] as String? ?? '';
    if (currentUserId == customerId) {
      return conv['provider_id'] as String? ?? '';
    } else {
      return conv['customer_id'] as String? ?? '';
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
              itemCount: 6,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    LoadingSkeletonWidget(
                      width: 48,
                      height: 48,
                      borderRadius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeletonWidget(
                            width: double.infinity,
                            height: 14,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 6),
                          LoadingSkeletonWidget(
                            width: 160,
                            height: 12,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadConversations,
              color: AppTheme.primary,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 18.w,
                  color: AppTheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  return _ConversationTile(
                    name: _getOtherPartyName(conv),
                    avatarUrl: _getOtherPartyAvatar(conv),
                    lastMessage: conv['last_message'] as String? ?? '',
                    time: _formatTime(conv['last_message_at'] as String?),
                    conversationId: conv['id'] as String,
                    otherUserId: _getOtherPartyId(conv),
                    otherUserName: _getOtherPartyName(conv),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.chatDetailScreen,
                        arguments: {
                          'conversationId': conv['id'] as String,
                          'otherUserId': _getOtherPartyId(conv),
                          'otherUserName': _getOtherPartyName(conv),
                          'otherUserAvatar': _getOtherPartyAvatar(conv),
                        },
                      );
                      _loadConversations();
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 10.w,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No conversations yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Start a chat by visiting a provider profile and tapping the message button.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.sp,
                color: const Color(0xFF74777F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            _Avatar(url: avatarUrl, name: name),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.sp,
                          color: const Color(0xFF90A4AE),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: const Color(0xFF74777F),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;

  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 6.w,
      backgroundColor: AppTheme.primaryContainer,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            )
          : null,
    );
  }
}
