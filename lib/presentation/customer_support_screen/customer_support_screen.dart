import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/offline_banner_widget.dart';
import '../../services/connectivity_service.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = true;

  // Contact form
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'Order Issue';
  bool _submitting = false;
  bool _submitted = false;

  // FAQ expand state
  final Set<int> _expandedFaqs = {};

  static const _categories = [
    'Order Issue',
    'Payment Problem',
    'Provider Complaint',
    'Account Issue',
    'App Bug',
    'Other',
  ];

  static const _faqs = [
    {
      'q': 'How do I track my order?',
      'a':
          'Go to Orders tab → tap your active order → you\'ll see a live status timeline with the provider\'s location and ETA. You\'ll also receive push notifications at each status change.',
    },
    {
      'q': 'How do I cancel an order?',
      'a':
          'Open the order from the Orders tab and tap "Cancel Order". Cancellations are free if the provider hasn\'t accepted yet. After acceptance, a small cancellation fee may apply per our policy.',
    },
    {
      'q': 'My provider didn\'t show up. What do I do?',
      'a':
          'First, try contacting the provider via the in-app chat. If unreachable, tap "Report Issue" on the order screen. Our team will investigate and process a full refund if the provider failed to deliver.',
    },
    {
      'q': 'How do I get a refund?',
      'a':
          'Refunds are processed automatically for cancelled orders within 3–5 business days. For disputes, submit a complaint via this support screen and our team will review within 24 hours.',
    },
    {
      'q': 'How do I become a service provider?',
      'a':
          'Tap the menu icon on the home screen → "Become a Provider". Fill in your details, upload documents, and submit. Our team reviews applications within 48 hours.',
    },
    {
      'q': 'Can I change my booking time?',
      'a':
          'Yes — open the order, tap "Reschedule", and pick a new time slot. Rescheduling is free up to 2 hours before the scheduled time.',
    },
    {
      'q': 'How do I update my address?',
      'a':
          'Go to Profile → Addresses → tap the edit icon on any saved address, or add a new one. Changes apply to future orders only.',
    },
    {
      'q': 'Is my payment information secure?',
      'a':
          'Yes. We never store card numbers. All payments are processed through PCI-DSS compliant gateways. UPI payments are handled directly by your UPI app.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isOnline = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOnline) {
      _showSnack(
        'You\'re offline. Please connect to submit a ticket.',
        isError: true,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = SupabaseService.instance.currentUser;
      await SupabaseService.instance.client.from('support_tickets').insert({
        'user_id': user?.id,
        'user_email': user?.email ?? '',
        'category': _selectedCategory,
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });
      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } catch (e) {
      setState(() => _submitting = false);
      _showSnack('Failed to submit. Please try again.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Column(
        children: [
          OfflineBannerWidget(onRetry: () => setState(() {})),
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFaqTab(), _buildContactTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Customer Support',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 0, 0),
                child: Text(
                  'We\'re here to help you 24/7',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickContactRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickContactRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _QuickContactChip(
            icon: Icons.phone_rounded,
            label: 'Call Us',
            onTap: () => _launchUrl('tel:+911800123456'),
          ),
          const SizedBox(width: 10),
          _QuickContactChip(
            icon: Icons.email_rounded,
            label: 'Email',
            onTap: () => _launchUrl('mailto:support@localconnect.in'),
          ),
          const SizedBox(width: 10),
          _QuickContactChip(
            icon: Icons.chat_bubble_rounded,
            label: 'Live Chat',
            onTap: () => Navigator.pushNamed(context, '/chat-list-screen'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1565C0),
        unselectedLabelColor: const Color(0xFF90A4AE),
        indicatorColor: const Color(0xFF1565C0),
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Submit Ticket'),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _faqs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildFaqHeader();
        final faq = _faqs[index - 1];
        final isExpanded = _expandedFaqs.contains(index);
        return _FaqCard(
          question: faq['q']!,
          answer: faq['a']!,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() {
              if (isExpanded) {
                _expandedFaqs.remove(index);
              } else {
                _expandedFaqs.add(index);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFaqHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Frequently Asked Questions',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1C1B1F),
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    if (_submitted) return _buildSuccessView();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(text: 'Issue Category'),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Subject'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _subjectCtrl,
              hint: 'Brief description of your issue',
              maxLines: 1,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Subject is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: 'Message'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _messageCtrl,
              hint: 'Describe your issue in detail...',
              maxLines: 5,
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Please provide at least 20 characters'
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Our support team typically responds within 2–4 hours.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF90A4AE),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit Ticket',
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
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF1565C0)
                  : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF1565C0)
                    : const Color(0xFFB0BEC5),
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF546E7A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFF1C1B1F),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: const Color(0xFFB0BEC5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE1E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC62828)),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ticket Submitted!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Our support team will get back to you within 2–4 hours via email.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                  _subjectCtrl.clear();
                  _messageCtrl.clear();
                  _selectedCategory = 'Order Issue';
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Submit Another',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFF1565C0).withValues(alpha: 0.3)
                : const Color(0xFFE1E8EF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1B1F),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  answer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF546E7A),
                    height: 1.55,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF37474F),
      ),
    );
  }
}
