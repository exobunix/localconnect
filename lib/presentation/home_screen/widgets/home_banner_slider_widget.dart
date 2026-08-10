import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class _BannerData {
  final String title;
  final String subtitle;
  final String badge;
  final LinearGradient gradient;
  final String imageUrl;
  final String semanticLabel;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
    required this.imageUrl,
    required this.semanticLabel,
  });
}

class HomeBannerSliderWidget extends StatefulWidget {
  const HomeBannerSliderWidget({super.key});

  @override
  State<HomeBannerSliderWidget> createState() => _HomeBannerSliderWidgetState();
}

class _HomeBannerSliderWidgetState extends State<HomeBannerSliderWidget> {
  // TODO: Replace with Riverpod/Bloc for production
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<_BannerData> _banners = const [
    _BannerData(
      title: '50% Off on Electricians',
      subtitle: 'Book today & save big on home repairs',
      badge: 'Limited Time',
      gradient: AppTheme.bannerGradient1,
      imageUrl:
          'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
      semanticLabel:
          'Electrician in blue uniform working with tools and wiring',
    ),
    _BannerData(
      title: 'ताजे भाजीपाला घरपोच!',
      subtitle: 'Fresh vegetables delivered in 30 mins',
      badge: 'New',
      gradient: AppTheme.bannerGradient3,
      imageUrl:
          'https://images.pixabay.com/photos/2017/10/09/19/29/eat-2834549_1280.jpg',
      semanticLabel:
          'Colourful fresh vegetables and fruits arranged in a market display',
    ),
    _BannerData(
      title: 'Beauty at Your Doorstep',
      subtitle: 'Salon services at home from ₹299',
      badge: '₹299 Onwards',
      gradient: AppTheme.bannerGradient2,
      imageUrl:
          'https://images.pexels.com/photos/3997379/pexels-photo-3997379.jpeg',
      semanticLabel:
          'Professional beautician applying makeup to a woman client at home',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _banners.length,
            padEnds: false,
            itemBuilder: (_, index) {
              final b = _banners[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == _banners.length - 1 ? 16 : 8,
                ),
                child: _BannerCard(banner: b),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _currentPage == i ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? AppTheme.primary
                    : AppTheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(decoration: BoxDecoration(gradient: banner.gradient)),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    banner.badge,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
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
