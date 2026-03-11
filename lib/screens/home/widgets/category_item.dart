import 'dart:ui';
import 'package:details_app/app_imports.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          // تم تقليل الـ blur لتحسين الأداء
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected
                    ? [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      memCacheWidth: 250,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) =>
                          Container(color: AppColors.imagePlaceholder),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.category_outlined,
                          color: AppColors.homeCategoryIcon,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        category.getName(context),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF452512),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
