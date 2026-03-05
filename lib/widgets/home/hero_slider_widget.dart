import 'package:details_app/app_imports.dart';

class HeroSliderWidget extends StatelessWidget {
  final List<BannerModel> banners;
  final PageController heroController;
  final ValueNotifier<int> bannerIndexNotifier;
  final Function(BannerModel) onBannerTap;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;

  const HeroSliderWidget({
    super.key,
    required this.banners,
    required this.heroController,
    required this.bannerIndexNotifier,
    required this.onBannerTap,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox();
    return SizedBox(
      height: 200,
      child: Listener(
        onPointerDown: (_) => onPointerDown(),
        onPointerUp: (_) => onPointerUp(),
        child: PageView.builder(
          controller: heroController,
          itemCount: banners.length,
          onPageChanged: (i) => bannerIndexNotifier.value = i,
          itemBuilder: (context, index) {
            return ValueListenableBuilder<int>(
              valueListenable: bannerIndexNotifier,
              builder: (context, currentIndex, child) {
                // تأثير التصغير للصفحات الجانبية
                double scale = currentIndex == index ? 1.0 : 0.9;
                return TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 350),
                  tween: Tween(begin: scale, end: scale),
                  curve: Curves.easeOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: GestureDetector(
                        onTap: () => onBannerTap(banners[index]),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedBannerItem(banner: banners[index]),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
