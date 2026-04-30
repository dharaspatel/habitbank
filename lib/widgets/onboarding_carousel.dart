import 'package:flutter/cupertino.dart';

import '../config/theme.dart';

class OnboardingPage {
  const OnboardingPage({required this.headline, required this.body});
  final String headline;
  final String body;
}

/// Three-page horizontally-paged carousel with dot indicator at the bottom.
/// Used at the top of the OnboardingScreen above the email/password fields.
class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({
    super.key,
    required this.pages,
    this.height = 180,
  });

  final List<OnboardingPage> pages;
  final double height;

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final p = widget.pages[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      p.headline,
                      style: AppTheme.balanceLarge.copyWith(fontSize: 36),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.body,
                      style: AppTheme.body.copyWith(color: AppTheme.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pages.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.foreground : AppTheme.subtle,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
