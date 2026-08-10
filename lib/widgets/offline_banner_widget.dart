import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/connectivity_service.dart';

/// A persistent banner shown at the top of a screen when offline.
class OfflineBannerWidget extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineBannerWidget({super.key, this.onRetry});

  @override
  State<OfflineBannerWidget> createState() => _OfflineBannerWidgetState();
}

class _OfflineBannerWidgetState extends State<OfflineBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _isOnline = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _isOnline = ConnectivityService.instance.isOnline;
    if (!_isOnline) _animCtrl.forward();

    _sub = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (!online) {
          _animCtrl.forward();
        } else {
          _animCtrl.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFB71C1C),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re offline — showing cached data',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.onRetry != null)
              GestureDetector(
                onTap: widget.onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white,
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
}

/// A small inline chip indicating offline / cached state.
class OfflineChipWidget extends StatelessWidget {
  final String? cacheAge;
  const OfflineChipWidget({super.key, this.cacheAge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 13, color: Color(0xFFE65100)),
          const SizedBox(width: 4),
          Text(
            cacheAge != null ? 'Cached · $cacheAge' : 'Cached data',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFFE65100),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen offline fallback widget with retry button.
class OfflineFallbackWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  final String? cacheAge;

  const OfflineFallbackWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.cacheAge,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please check your connection and try again.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF74777F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B4B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
