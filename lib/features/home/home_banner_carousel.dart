import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// One promotional banner on the home screen. EDIT THIS LIST to change the
/// sliding banners — their colours, icon, title and text. (Live editing from an
/// admin dashboard will arrive with the Firebase backend; the carousel is
/// already built to swap this list out for a backend-driven one.)
class HomeBanner {
  const HomeBanner({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    this.image,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;

  /// Full banner image (preferred). Falls back to the gradient + text card if
  /// the file is missing, so the app always builds.
  final String? image;
}

const List<HomeBanner> kHomeBanners = [
  HomeBanner(
    image: 'assets/images/home_banner_1.png',
    title: '90 Days, One New You',
    subtitle: 'Follow your daily routine and track every parameter.',
    gradient: [AppColors.primary, AppColors.secondary],
    icon: Icons.local_fire_department_rounded,
  ),
  HomeBanner(
    image: 'assets/images/home_banner_2.png',
    title: 'Eat Smart, the Indian Way',
    subtitle: 'Log your meals and know your calories & protein.',
    gradient: [AppColors.orange, AppColors.orangeDark],
    icon: Icons.restaurant_rounded,
  ),
  HomeBanner(
    image: 'assets/images/home_banner_3.png',
    title: 'Experts in Your Pocket',
    subtitle: 'Book Coach Sonali or consult Dr. Prachita anytime.',
    gradient: [AppColors.info, AppColors.primary],
    icon: Icons.health_and_safety_rounded,
  ),
  HomeBanner(
    image: 'assets/images/home_banner_4.png',
    title: 'Keep Your Streak Alive',
    subtitle: 'Earn points every day and climb the leaderboard.',
    gradient: [AppColors.orange, AppColors.primary],
    icon: Icons.emoji_events_rounded,
  ),
  HomeBanner(
    image: 'assets/images/home_banner_5.png',
    title: 'Stay Hydrated Every Day',
    subtitle: 'Hit 12 glasses of water and earn your points.',
    gradient: [AppColors.info, AppColors.taskSteps],
    icon: Icons.water_drop_rounded,
  ),
  HomeBanner(
    image: 'assets/images/home_banner_6.png',
    title: 'Your Rewards Await',
    subtitle: 'Unlock milestones as your points grow.',
    gradient: [AppColors.primary, AppColors.orange],
    icon: Icons.stars_rounded,
  ),
];

/// Auto-advancing, swipeable banner strip shown at the top of the home screen.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.banners = kHomeBanners});

  final List<HomeBanner> banners;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final int next = (_index + 1) % widget.banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Banner image aspect ratio (recommended source images are 1000 × 420 px).
  static const double _bannerAspect = 1000 / 420;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Size the window to the banner's own aspect ratio so the full image
        // shows edge-to-edge (no cropping) and scales up on larger screens.
        final double cardWidth = constraints.maxWidth - 4; // minus card margins
        final double height =
            (cardWidth / _bannerAspect).clamp(120.0, 240.0);
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) =>
                    _BannerCard(banner: widget.banners[i]),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // The gradient sits behind; a present image covers it fully. If the
        // image is missing, the gradient + text card shows through instead.
        gradient: LinearGradient(
          colors: banner.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: banner.gradient.last.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: banner.image != null
          ? Image.asset(
              banner.image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _textContent(),
            )
          : _textContent(),
    );
  }

  Widget _textContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(banner.icon, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}
