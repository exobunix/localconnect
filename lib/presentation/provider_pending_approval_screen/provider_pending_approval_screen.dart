import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';

class ProviderPendingApprovalScreen extends StatefulWidget {
  const ProviderPendingApprovalScreen({super.key});

  @override
  State<ProviderPendingApprovalScreen> createState() =>
      _ProviderPendingApprovalScreenState();
}

class _ProviderPendingApprovalScreenState
    extends State<ProviderPendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  bool _isChecking = false;
  String _registrationStatus = 'pending_approval';
  String _adminNote = '';
  Map<String, dynamic>? _approvalRequest;

  RealtimeChannel? _providerChannel;
  RealtimeChannel? _approvalChannel;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _loadStatus();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _providerChannel?.unsubscribe();
    _approvalChannel?.unsubscribe();
    _animController.dispose();
    super.dispose();
  }

  void _subscribeToUpdates() {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    // Subscribe to service_providers table for registration_status changes
    _providerChannel = SupabaseService.instance.client
        .channel('provider_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_providers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final newStatus =
                newRecord['registration_status'] as String? ??
                'pending_approval';
            if (mounted) {
              setState(() => _registrationStatus = newStatus);
              if (newStatus == 'approved') {
                _showStatusSnackBar(
                  '🎉 Your registration has been approved!',
                  AppTheme.secondary,
                );
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.providerDashboardScreen,
                      (route) => false,
                    );
                  }
                });
              } else if (newStatus == 'rejected') {
                _showStatusSnackBar(
                  'Your registration was not approved.',
                  AppTheme.error,
                );
              }
            }
          },
        )
        .subscribe();

    // Subscribe to category_approval_requests for admin_note changes
    _approvalChannel = SupabaseService.instance.client
        .channel('approval_request_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'category_approval_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (mounted) {
              setState(() {
                _approvalRequest = {...?_approvalRequest, ...newRecord};
                _adminNote = newRecord['admin_note'] as String? ?? _adminNote;
              });
            }
          },
        )
        .subscribe();
  }

  void _showStatusSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadStatus() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return;

    setState(() => _isChecking = true);
    try {
      final status = await SupabaseService.instance
          .getProviderRegistrationStatus(userId);
      final request = await SupabaseService.instance.getCategoryApprovalRequest(
        userId,
      );

      if (mounted) {
        setState(() {
          _registrationStatus = status ?? 'pending_approval';
          _approvalRequest = request;
          _adminNote = request?['admin_note'] as String? ?? '';
        });

        // If approved, navigate to provider dashboard
        if (_registrationStatus == 'approved') {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.providerDashboardScreen,
                (route) => false,
              );
            }
          });
        }
      }
    } catch (e) {
      // silent
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF26C6A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.handyman_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'LocalConnect Provider',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_registrationStatus) {
      case 'approved':
        return _buildApprovedState();
      case 'rejected':
        return _buildRejectedState();
      default:
        return _buildPendingState();
    }
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        SizedBox(height: 2.h),
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFFF6F00),
              size: 52,
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Under Review',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Your provider registration is being reviewed by our team.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF90A4AE),
            height: 1.5,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Auto-updates when admin acts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  color: const Color(0xFF388E3C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        _buildStatusCard(),
        SizedBox(height: 2.h),
        _buildStepsCard(),
        SizedBox(height: 2.h),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildApprovedState() {
    return Column(
      children: [
        SizedBox(height: 2.h),
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppTheme.secondary,
            size: 52,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Approved! 🎉',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Your registration has been approved. Redirecting to your dashboard...',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF90A4AE),
            height: 1.5,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.secondary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Welcome aboard! You can now access your Provider Dashboard and start receiving orders.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: AppTheme.secondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerDashboardScreen,
              (route) => false,
            ),
            icon: const Icon(Icons.dashboard_rounded, size: 18),
            label: Text(
              'Go to Dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedState() {
    return Column(
      children: [
        SizedBox(height: 2.h),
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 52),
        ),
        SizedBox(height: 3.h),
        Text(
          'Not Approved',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Your category approval request was not approved at this time.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            color: const Color(0xFF90A4AE),
            height: 1.5,
          ),
        ),
        if (_adminNote.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Reason from Admin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  _adminNote,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 3.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.providerRegistrationScreen,
              (route) => false,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Re-apply with Different Category',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        TextButton(
          onPressed: _signOut,
          child: Text(
            'Sign Out',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              color: const Color(0xFF90A4AE),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final category = _approvalRequest?['category'] as String? ?? '—';
    final subcategory = _approvalRequest?['subcategory'] as String? ?? '';
    final createdAt = _approvalRequest?['created_at'] as String?;
    String dateStr = '—';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFFF6F00),
                  size: 18,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Approval Request Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildDetailRow(Icons.category_rounded, 'Category', category),
          if (subcategory.isNotEmpty)
            _buildDetailRow(
              Icons.subdirectory_arrow_right_rounded,
              'Subcategory',
              subcategory,
            ),
          _buildDetailRow(Icons.calendar_today_rounded, 'Submitted', dateStr),
          _buildDetailRow(
            Icons.info_rounded,
            'Status',
            'Pending Review',
            valueColor: const Color(0xFFFF6F00),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF90A4AE)),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF44474E),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.sp,
                color: valueColor ?? const Color(0xFF90A4AE),
                fontWeight: valueColor != null
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    final steps = [
      ('Account Created', true, Icons.check_circle_rounded),
      ('Profile Submitted', true, Icons.check_circle_rounded),
      ('Category Request Sent', true, Icons.check_circle_rounded),
      ('Admin Review', false, Icons.hourglass_top_rounded),
      ('Dashboard Access', false, Icons.lock_rounded),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
          Text(
            'Registration Progress',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          SizedBox(height: 2.h),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        color: step.$2
                            ? AppTheme.secondary.withValues(alpha: 0.15)
                            : const Color(0xFFF5F7FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.$2
                              ? AppTheme.secondary
                              : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        step.$3,
                        size: 14,
                        color: step.$2
                            ? AppTheme.secondary
                            : const Color(0xFFB0BEC5),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 4.h,
                        color: step.$2
                            ? AppTheme.secondary.withValues(alpha: 0.3)
                            : const Color(0xFFE0E0E0),
                      ),
                  ],
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 0.5.h,
                      bottom: isLast ? 0 : 2.h,
                    ),
                    child: Text(
                      step.$1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: step.$2 ? FontWeight.w700 : FontWeight.w500,
                        color: step.$2
                            ? const Color(0xFF44474E)
                            : const Color(0xFFB0BEC5),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isChecking ? null : _loadStatus,
        icon: _isChecking
            ? SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 18),
        label: Text(
          _isChecking ? 'Checking...' : 'Check Status',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          side: BorderSide(color: AppTheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}

