import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';
import 'auth/phone_auth_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      image: AppAssets.agentsHandshake,
      tag: '🤝 Broker Network',
      title: 'Close Deals\nFaster',
      subtitle:
          'Connect with verified brokers and builders.',
    ),
    _SlideData(
      image: AppAssets.buildingBlock,
      tag: '🏗 Builder Projects',
      title: 'Discover New\nLaunches',
      subtitle:
          'Explore exclusive new-launch projects from top builders in your city.',
    ),
    _SlideData(
      image: AppAssets.agentsHandshake,
      tag: '📋 Structured Listings',
      title: 'One More Deal\nEvery Day',
      subtitle:
          'Filtered, organized, structured listings that make finding property effortless.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToAuth({required bool isLogin}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => PhoneAuthScreen(isLogin: isLogin),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ─── Image Carousel ───────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _SlideBackground(slide: _slides[i]),
          ),

          // ─── Dark gradient overlay ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.20, 0.50, 0.70, 1.0],
                colors: [
                  Color(0xCC000000),   // strong dark at top for header readability
                  Color(0x550D1B4B),
                  Color(0x000D1B4B),
                  Color(0xBB0D1B4B),
                  Color(0xFF0D1B4B),
                ],
              ),
            ),
          ),

          // ─── Content overlay ──────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + Brand
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        // Golden icon badge
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '⚡',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Brand name — gold with shadow
                        Text(
                          AppStrings.appName,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.accentLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ─── Slide Content ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _SlideContent(
                      key: ValueKey(_currentPage),
                      slide: _slides[_currentPage],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Page dots ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _slides.length,
                    effect: ExpandingDotsEffect(
                      dotColor: AppColors.white.withOpacity(0.4),
                      activeDotColor: AppColors.accent,
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 4,
                      spacing: 6,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ─── Action Buttons ───────────────────────────────────
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PrimaryButton(
                          label: AppStrings.getStarted,
                          onTap: () => _goToAuth(isLogin: false),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => _goToAuth(isLogin: true),
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.accentLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ─── Terms ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                      left: 28, right: 28, bottom: 24, top: 12),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: AppStrings.termsText,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.termsLink,
                            style: const TextStyle(
                                color: AppColors.accentLight,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(text: AppStrings.andText),
                          TextSpan(
                            text: AppStrings.privacyLink,
                            style: const TextStyle(
                                color: AppColors.accentLight,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SlideData {
  final String image;
  final String tag;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.image,
    required this.tag,
    required this.title,
    required this.subtitle,
  });
}

class _SlideBackground extends StatelessWidget {
  final _SlideData slide;
  const _SlideBackground({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        slide.image,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _SlideData slide;
  const _SlideContent({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            slide.tag,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.accentLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide.title,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white.withOpacity(0.75),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.95,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
