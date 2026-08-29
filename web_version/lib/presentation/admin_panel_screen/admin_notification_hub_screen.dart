import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class AdminNotificationHubScreen extends StatefulWidget {
  const AdminNotificationHubScreen({super.key});

  @override
  State<AdminNotificationHubScreen> createState() =>
      _AdminNotificationHubScreenState();
}

class _AdminNotificationHubScreenState
    extends State<AdminNotificationHubScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTarget = 'all_users'; // all_users | all_customers | all_vendors | specific_customer | specific_vendor
  
  bool _isSending = false;
  bool _isLoadingUsers = false;
  List<Map<String, dynamic>> _userList = [];
  Map<String, dynamic>? _selectedSpecificUser;
  String _userSearchQuery = '';

  // Sent notifications history
  List<Map<String, dynamic>> _notificationHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final res = await SupabaseService.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      if (mounted) {
        setState(() {
          _notificationHistory = List<Map<String, dynamic>>.from(res);
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _fetchUsersForTarget(String targetRole) async {
    setState(() {
      _isLoadingUsers = true;
      _userList = [];
      _selectedSpecificUser = null;
    });

    try {
      var query = SupabaseService.instance.client.from('user_profiles').select('id, full_name, email, phone, role');
      if (targetRole == 'customer') {
        query = query.eq('role', 'customer');
      } else if (targetRole == 'provider') {
        query = query.eq('role', 'provider');
      }

      final res = await query.limit(50);
      if (mounted) {
        setState(() {
          _userList = List<Map<String, dynamic>>.from(res);
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showToast('Please enter a notification title', isError: true);
      return;
    }
    if (body.isEmpty) {
      _showToast('Please enter a notification body/message', isError: true);
      return;
    }

    if ((_selectedTarget == 'specific_customer' || _selectedTarget == 'specific_vendor') &&
        _selectedSpecificUser == null) {
      _showToast('Please select a specific recipient user', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      String targetType = _selectedTarget;
      String? targetUserId;

      if (_selectedTarget == 'specific_customer' || _selectedTarget == 'specific_vendor') {
        targetType = 'specific_user';
        targetUserId = _selectedSpecificUser!['id'] as String;
      }

      final sentCount = await NotificationService.instance.broadcastAdminPushNotification(
        targetType: targetType,
        targetUserId: targetUserId,
        title: title,
        body: body,
      );

      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _isSending = false;
        _selectedSpecificUser = null;
      });

      _showToast('Successfully broadcasted to $sentCount recipient(s)!');
      _loadNotificationHistory();
    } catch (e) {
      setState(() => _isSending = false);
      _showToast('Failed to send notification: $e', isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B4B),
        elevation: 0,
        title: Text(
          'Push Notification Hub',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFFFD54F)),
            tooltip: 'Test Sound',
            onPressed: () {
              NotificationService.instance.playNotificationSound();
              _showToast('Notification Sound Chime Tested! 🔔');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadNotificationHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B4B), Color(0xFF1E3A8A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D1B4B).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFFFFD54F),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Push Notification Dispatcher',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send real-time alerts with sound to all customers, vendors, or specific partners.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Composer Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Select Target Audience',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTargetChip('All Users (Everyone)', 'all_users', Icons.people_rounded),
                        _buildTargetChip('All Customers', 'all_customers', Icons.person_rounded),
                        _buildTargetChip('All Vendors / Partners', 'all_vendors', Icons.storefront_rounded),
                        _buildTargetChip('Specific Customer', 'specific_customer', Icons.person_pin_rounded),
                        _buildTargetChip('Specific Vendor', 'specific_vendor', Icons.business_center_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // If specific user selected -> show user picker
                    if (_selectedTarget == 'specific_customer' || _selectedTarget == 'specific_vendor') ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTarget == 'specific_customer'
                                  ? 'Select Customer Recipient'
                                  : 'Select Vendor / Partner Recipient',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingUsers)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_userList.isEmpty)
                              Text(
                                'No users found for this role in database.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            else
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedSpecificUser,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                hint: Text('Select recipient user from list', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                items: _userList.map((u) {
                                  final name = u['full_name'] ?? 'User';
                                  final phone = u['phone'] ?? '';
                                  final email = u['email'] ?? '';
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(
                                      '$name ($phone / $email)',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedSpecificUser = val);
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      '2. Compose Notification',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Notification Title',
                        hintText: 'e.g. Special Weekend Offer 50% Off / Booking Update',
                        prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _bodyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notification Message / Body',
                        hintText: 'Write your message to recipients here...',
                        prefixIcon: const Icon(Icons.message_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dispatch Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1B4B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dispatch Notification With Sound',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
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
              const SizedBox(height: 32),

              // Recent Notifications History
              Text(
                'Recent Notification Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_notificationHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No notifications sent yet.',
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notificationHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = _notificationHistory[i];
                    final title = item['title'] as String? ?? 'Notification';
                    final body = item['body'] as String? ?? '';
                    final type = item['type'] as String? ?? 'general';
                    final time = item['created_at'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        type,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                if (time.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    time.length > 19 ? time.substring(0, 19).replaceAll('T', ' ') : time,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetChip(String label, String value, IconData icon) {
    final selected = _selectedTarget == value;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF1E3A8A),
      ),
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF0D1B4B),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : const Color(0xFF0F172A),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedTarget = value);
          if (value == 'specific_customer') {
            _fetchUsersForTarget('customer');
          } else if (value == 'specific_vendor') {
            _fetchUsersForTarget('provider');
          }
        }
      },
    );
  }
}
