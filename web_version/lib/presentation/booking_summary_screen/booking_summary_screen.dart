import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    final orderNumber = args['orderNumber'] as String? ?? 'ORD-000001';
    final service = args['service'] as String? ?? 'Service';
    final providerName = args['providerName'] as String? ?? 'Provider';
    final amount = args['amount'] as String? ?? '₹0';
    final scheduledDate = args['scheduledDate'] as String? ?? '';
    final scheduledTime = args['scheduledTime'] as String? ?? '';
    final paymentMethod = args['paymentMethod'] as String? ?? 'cash';
    final paymentStatus = args['paymentStatus'] as String? ?? 'Pending';
    final address = args['address'] as String? ?? '';
    final category = args['category'] as String? ?? '';
    final invoiceDate =
        args['invoiceDate'] as String? ?? _formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Booking Summary',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share',
            onPressed: () => _shareBooking(
              context,
              orderNumber: orderNumber,
              service: service,
              providerName: providerName,
              amount: amount,
              scheduledDate: scheduledDate,
              scheduledTime: scheduledTime,
              paymentStatus: paymentStatus,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: () => _downloadInvoice(
              context,
              orderNumber: orderNumber,
              service: service,
              providerName: providerName,
              amount: amount,
              scheduledDate: scheduledDate,
              scheduledTime: scheduledTime,
              paymentMethod: paymentMethod,
              paymentStatus: paymentStatus,
              address: address,
              category: category,
              invoiceDate: invoiceDate,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InvoiceReceiptCard(
              orderNumber: orderNumber,
              service: service,
              providerName: providerName,
              amount: amount,
              scheduledDate: scheduledDate,
              scheduledTime: scheduledTime,
              paymentMethod: paymentMethod,
              paymentStatus: paymentStatus,
              address: address,
              category: category,
              invoiceDate: invoiceDate,
            ),
            const SizedBox(height: 16),
            _ActionButtonsRow(
              onShare: () => _shareBooking(
                context,
                orderNumber: orderNumber,
                service: service,
                providerName: providerName,
                amount: amount,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                paymentStatus: paymentStatus,
              ),
              onDownload: () => _downloadInvoice(
                context,
                orderNumber: orderNumber,
                service: service,
                providerName: providerName,
                amount: amount,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                address: address,
                category: category,
                invoiceDate: invoiceDate,
              ),
            ),
            const SizedBox(height: 16),
            _NavigationCard(paymentStatus: paymentStatus),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  void _shareBooking(
    BuildContext context, {
    required String orderNumber,
    required String service,
    required String providerName,
    required String amount,
    required String scheduledDate,
    required String scheduledTime,
    required String paymentStatus,
  }) {
    final text =
        '''
📋 Booking Summary — LocalConnect

Order #: $orderNumber
Service: $service
Provider: $providerName
Date: $scheduledDate${scheduledTime.isNotEmpty ? ' at $scheduledTime' : ''}
Amount: $amount
Payment Status: $paymentStatus

Booked via LocalConnect App
''';

    if (kIsWeb) {
      // Web: copy to clipboard
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking details copied to clipboard!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking details copied to clipboard!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _downloadInvoice(
    BuildContext context, {
    required String orderNumber,
    required String service,
    required String providerName,
    required String amount,
    required String scheduledDate,
    required String scheduledTime,
    required String paymentMethod,
    required String paymentStatus,
    required String address,
    required String category,
    required String invoiceDate,
  }) {
    final invoiceContent = _buildInvoiceText(
      orderNumber: orderNumber,
      service: service,
      providerName: providerName,
      amount: amount,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      address: address,
      category: category,
      invoiceDate: invoiceDate,
    );

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(invoiceContent);
        final blob = html.Blob([bytes], 'text/plain');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'invoice_$orderNumber.txt')
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice downloaded!',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download not supported in this browser.',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mobile: copy to clipboard as fallback
      Clipboard.setData(ClipboardData(text: invoiceContent));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice copied to clipboard!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _buildInvoiceText({
    required String orderNumber,
    required String service,
    required String providerName,
    required String amount,
    required String scheduledDate,
    required String scheduledTime,
    required String paymentMethod,
    required String paymentStatus,
    required String address,
    required String category,
    required String invoiceDate,
  }) {
    return '''
============================================
           LOCALCONNECT INVOICE
============================================
Invoice Date : $invoiceDate
Order Number : $orderNumber
--------------------------------------------
SERVICE DETAILS
--------------------------------------------
Service      : $service
${category.isNotEmpty ? 'Category     : $category\n' : ''}Provider     : $providerName
${scheduledDate.isNotEmpty ? 'Date         : $scheduledDate\n' : ''}${scheduledTime.isNotEmpty ? 'Time         : $scheduledTime\n' : ''}${address.isNotEmpty ? 'Address      : $address\n' : ''}--------------------------------------------
PAYMENT DETAILS
--------------------------------------------
Amount       : $amount
Method       : ${_paymentLabel(paymentMethod)}
Status       : $paymentStatus
--------------------------------------------
Thank you for using LocalConnect!
============================================
''';
  }

  String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'razorpay':
        return 'Razorpay (Online)';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Card Payment';
      case 'cash':
        return 'Cash on Service';
      default:
        return method;
    }
  }
}

// ── Invoice Receipt Card ──────────────────────────────────────────────────────

class _InvoiceReceiptCard extends StatelessWidget {
  final String orderNumber;
  final String service;
  final String providerName;
  final String amount;
  final String scheduledDate;
  final String scheduledTime;
  final String paymentMethod;
  final String paymentStatus;
  final String address;
  final String category;
  final String invoiceDate;

  const _InvoiceReceiptCard({
    required this.orderNumber,
    required this.service,
    required this.providerName,
    required this.amount,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.address,
    required this.category,
    required this.invoiceDate,
  });

  Color get _statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'failed':
        return AppTheme.error;
      default:
        return AppTheme.info;
    }
  }

  IconData get _statusIcon {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'razorpay':
        return 'Razorpay (Online)';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Card Payment';
      case 'cash':
        return 'Cash on Service';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Order #$orderNumber',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    invoiceDate,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Payment Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: _statusColor.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_statusIcon, color: _statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Payment Status: $paymentStatus',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DashedDivider(),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ReceiptRow(
                  label: 'Service',
                  value: service,
                  icon: Icons.home_repair_service_rounded,
                  iconColor: AppTheme.primary,
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReceiptRow(
                    label: 'Category',
                    value: category,
                    icon: Icons.category_rounded,
                    iconColor: AppTheme.secondary,
                  ),
                ],
                const SizedBox(height: 14),
                _ReceiptRow(
                  label: 'Provider',
                  value: providerName,
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF6A1B9A),
                ),
                if (scheduledDate.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReceiptRow(
                    label: 'Date',
                    value: scheduledDate,
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppTheme.warning,
                  ),
                ],
                if (scheduledTime.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReceiptRow(
                    label: 'Time',
                    value: scheduledTime,
                    icon: Icons.access_time_rounded,
                    iconColor: AppTheme.info,
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReceiptRow(
                    label: 'Address',
                    value: address,
                    icon: Icons.location_on_rounded,
                    iconColor: AppTheme.error,
                  ),
                ],
                const SizedBox(height: 14),
                _ReceiptRow(
                  label: 'Payment Method',
                  value: _paymentLabel(paymentMethod),
                  icon: Icons.payment_rounded,
                  iconColor: const Color(0xFF00695C),
                ),
              ],
            ),
          ),

          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DashedDivider(),
          ),

          // Amount Total
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'LocalConnect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thank you for your booking!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF90A4AE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons Row ────────────────────────────────────────────────────────

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const _ActionButtonsRow({required this.onShare, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              'Share',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              'Download',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Navigation Card ───────────────────────────────────────────────────────────

class _NavigationCard extends StatelessWidget {
  final String paymentStatus;

  const _NavigationCard({required this.paymentStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Go to Home',
            color: AppTheme.primary,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.homeScreen,
              (_) => false,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF0F3)),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'View Past Bookings',
            color: AppTheme.secondary,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.customerPastBookingsScreen,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF0F3)),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat with Provider',
            color: const Color(0xFF6A1B9A),
            onTap: () => Navigator.pushNamed(context, AppRoutes.chatListScreen),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt Row ───────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF90A4AE),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dashed Divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: const Color(0xFFE0E0E0),
            ),
          ),
        );
      },
    );
  }
}
