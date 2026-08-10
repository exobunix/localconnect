import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _slideController;
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;

  static const String _onboardingKey = 'onboarding_completed';

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D1B4B), Color(0xFF1565C0), Color(0xFF1E88E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF42A5F5),
      icon: Icons.search_rounded,
      illustrationUrl:
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=600&q=80',
      illustrationLabel:
          'Person using smartphone to search for local services on a bright screen',
      tag: 'DISCOVER',
      title: 'Find Services\nNear You',
      description:
          'Browse hundreds of trusted local providers — from plumbers to personal trainers — all within your neighbourhood.',
      featureChips: ['Smart Search', 'Map View', 'Filters'],
    ),
    _OnboardingSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A0533), Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFFCE93D8),
      icon: Icons.calendar_today_rounded,
      illustrationUrl:
          'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?w=600&q=80',
      illustrationLabel:
          'Professional service provider arriving at a home for a scheduled appointment',
      tag: 'BOOK',
      title: 'Book in\nSeconds',
      description:
          'Pick a time that suits you, confirm your booking instantly, and get a guaranteed slot with your chosen provider.',
      featureChips: ['Instant Confirm', 'Flexible Slots', 'Reminders'],
    ),
    _OnboardingSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF003300), Color(0xFF1B5E20), Color(0xFF388E3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF81C784),
      icon: Icons.location_on_rounded,
      illustrationUrl:
          'https://images.pixabay.com/photo/2017/08/10/08/47/laptop-2620118_1280.jpg',
      illustrationLabel:
          'Live map showing real-time location tracking of a service provider en route',
      tag: 'TRACK',
      title: 'Live Order\nTracking',
      description:
          'Watch your provider travel to you in real time. Know exactly when they arrive — no more waiting and wondering.',
      featureChips: ['Live Map', 'ETA Updates', 'Status Alerts'],
    ),
    _OnboardingSlide(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A0A00), Color(0xFFBF360C), Color(0xFFFF6B35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFFFFAB91),
      icon: Icons.chat_bubble_rounded,
      illustrationUrl:
          'https://images.unsplash.com/photo-1611746872915-64382b5c76da?w=600&q=80',
      illustrationLabel:
          'Two people chatting on mobile phones, representing in-app messaging between customer and provider',
      tag: 'CONNECT',
      title: 'Chat with\nProviders',
      description:
          'Message your provider directly before, during, and after the job. Share details, photos, and feedback — all in one place.',
      featureChips: ['Direct Chat', 'Photo Share', 'Reviews'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  void _goToLogin() async {
    await _markOnboardingDone();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconController.reset();
    _iconController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: slide.gradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page counter
                    Text(
                      '${_currentPage + 1} / ${_slides.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(153),
                      ),
                    ),
                    if (!isLast)
                      GestureDetector(
                        onTap: _goToLogin,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: Colors.white.withAlpha(60),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _SlideContent(
                      slide: _slides[index],
                      iconScale: _iconScale,
                      iconFade: _iconFade,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 0.8.w),
                          width: i == _currentPage ? 6.w : 2.w,
                          height: 1.h,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withAlpha(80),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: _nextPage,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 1.8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLast ? 'Get Started' : 'Next',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: slide.gradient.colors.first,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    isLast
                                        ? Icons.rocket_launch_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: slide.gradient.colors.first,
                                    size: 18.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;
  final Animation<double> iconScale;
  final Animation<double> iconFade;
  final bool isActive;

  const _SlideContent({
    required this.slide,
    required this.iconScale,
    required this.iconFade,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          SizedBox(height: 1.h),

          // Illustration card
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image
                    Image.network(
                      slide.illustrationUrl,
                      fit: BoxFit.cover,
                      semanticLabel: slide.illustrationLabel,
                      errorBuilder: (_, __, ___) => Container(
                        color: slide.accentColor.withAlpha(40),
                        child: Icon(
                          slide.icon,
                          size: 20.w,
                          color: slide.accentColor,
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(120),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Tag chip
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.6.h,
                        ),
                        decoration: BoxDecoration(
                          color: slide.accentColor.withAlpha(220),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(slide.icon, size: 12.sp, color: Colors.white),
                            SizedBox(width: 1.w),
                            Text(
                              slide.tag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Feature chips at bottom
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Wrap(
                        spacing: 2.w,
                        runSpacing: 0.8.h,
                        children: slide.featureChips
                            .map(
                              (chip) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.5.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(60),
                                  ),
                                ),
                                child: Text(
                                  chip,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Text content
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated icon
                AnimatedBuilder(
                  animation: iconScale,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: iconFade,
                      child: ScaleTransition(scale: iconScale, child: child),
                    );
                  },
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: slide.accentColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: slide.accentColor.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      slide.icon,
                      color: slide.accentColor,
                      size: 16.sp,
                    ),
                  ),
                ),
                SizedBox(height: 1.5.h),
                Text(
                  slide.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Text(
                  slide.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(200),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final LinearGradient gradient;
  final Color accentColor;
  final IconData icon;
  final String illustrationUrl;
  final String illustrationLabel;
  final String tag;
  final String title;
  final String description;
  final List<String> featureChips;

  const _OnboardingSlide({
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.illustrationUrl,
    required this.illustrationLabel,
    required this.tag,
    required this.title,
    required this.description,
    required this.featureChips,
  });
}
