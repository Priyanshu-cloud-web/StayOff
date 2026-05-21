import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import '../../../core/providers/app_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;

  late AnimationController _floatCtrl;
  late Animation<double> _float;

  static const _slides = [
    _Slide(
      emoji: '🚫',
      tag: 'BLOCK',
      title: 'Stop the scroll.\nTake control.',
      subtitle:
          'Block distracting websites, Shorts, Reels and entire apps with one tap. No root needed.',
      accent: Color(0xFF7C6FED),
    ),
    _Slide(
      emoji: '🛡️',
      tag: 'PROTECT',
      title: 'SafeGuard for\nyou and family.',
      subtitle:
          'Password-locked adult content blocking. Permanent protection, no loopholes.',
      accent: Color(0xFFE84393),
    ),
    _Slide(
      emoji: '🔒',
      tag: 'COMMIT',
      title: 'Lock in.\nNo going back.',
      subtitle:
          'Set commitment locks for days, months or years. No excuses, just results.',
      accent: Color(0xFF00C9A7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(appStateProvider.notifier).completeOnboarding();
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? FGColors.bg : FGColorsLight.bg;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        // Animated gradient background blob
        AnimatedBuilder(
          animation: _float,
          builder: (_, __) => Positioned(
            top: 60 + _float.value,
            left: MediaQuery.of(context).size.width / 2 - 160,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.accent.withOpacity(0.08),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80, right: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accent.withOpacity(0.05))),
        ),

        SafeArea(
          child: Column(children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: GestureDetector(
                  onTap: _finish,
                  child: Text('Skip',
                    style: TextStyle(
                      fontFamily: 'DM Sans', fontSize: 14,
                      color: isDark ? FGColors.textThird : FGColorsLight.textThird,
                    )),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(
                  slide: _slides[i],
                  floatAnim: _float,
                  isDark: isDark,
                ),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? slide.accent
                            : slide.accent.withOpacity(0.25),
                        borderRadius: FGRadius.full,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // CTA button
                GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          slide.accent,
                          Color.lerp(slide.accent, Colors.black, 0.2)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: FGRadius.lg,
                      boxShadow: [
                        BoxShadow(
                          color: slide.accent.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _page == _slides.length - 1 ? 'Get started →' : 'Next →',
                        style: const TextStyle(
                          fontFamily: 'Syne', fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({
    required this.slide,
    required this.floatAnim,
    required this.isDark,
  });
  final _Slide slide;
  final Animation<double> floatAnim;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating emoji
          AnimatedBuilder(
            animation: floatAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, floatAnim.value),
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.accent.withOpacity(0.12),
                  border: Border.all(
                    color: slide.accent.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(slide.emoji,
                    style: const TextStyle(fontSize: 60)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: slide.accent.withOpacity(0.12),
              borderRadius: FGRadius.full,
              border: Border.all(color: slide.accent.withOpacity(0.3)),
            ),
            child: Text(slide.tag,
              style: TextStyle(
                fontFamily: 'Syne', fontSize: 11,
                fontWeight: FontWeight.w700,
                color: slide.accent, letterSpacing: 0.15,
              )),
          ),
          const SizedBox(height: 20),

          // Title
          Text(slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Syne', fontSize: 30,
              fontWeight: FontWeight.w800,
              color: tp, height: 1.15,
            )),
          const SizedBox(height: 16),

          // Subtitle
          Text(slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans', fontSize: 15,
              color: ts, height: 1.6,
            )),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.emoji,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
  final String emoji, tag, title, subtitle;
  final Color accent;
}