import 'package:details_app/app_imports.dart';

class HomeHeroSlider extends StatelessWidget {
  final List<BannerModel> banners;
  final PageController controller;
  final ValueNotifier<int> notifier;
  final Function(BannerModel) onBannerTap;
  final Function(PointerDownEvent) onPointerDown;
  final Function(PointerUpEvent) onPointerUp;

  const HomeHeroSlider({
    super.key,
    required this.banners,
    required this.controller,
    required this.notifier,
    required this.onBannerTap,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox();
    return SizedBox(
      height: 260,
      child: VisibilityDetector(
        key: const Key('hero-slider'),
        onVisibilityChanged: (info) {
          // يمكن هنا إضافة منطق لإيقاف الـ Timer إذا اختفى السلايدر
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Listener(
              onPointerDown: onPointerDown,
              onPointerUp: onPointerUp,
              child: PageView.builder(
                controller: controller,
                itemCount: banners.length,
                onPageChanged: (i) {
                  notifier.value = i;
                },
                itemBuilder: (c, i) {
                  return GestureDetector(
                    onTap: () => onBannerTap(banners[i]),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedBannerItem(banner: banners[i]),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 20,
              child: ValueListenableBuilder<int>(
                valueListenable: notifier,
                builder: (context, currentIndex, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      banners.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == currentIndex ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == currentIndex
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
