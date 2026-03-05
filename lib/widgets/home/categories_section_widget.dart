import 'package:details_app/app_imports.dart';

class CategoriesSectionWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategory;
  final Function(CategoryModel) onCategoryTap;

  const CategoriesSectionWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.translate('categories'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.homeSectionTitle,
                ),
              ),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (c, i) {
                  final category = categories[i];
                  final isSelected = selectedCategory == category.slug;
                  return GestureDetector(
                    onTap: () => onCategoryTap(category),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                if (!isSelected)
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: category.imageUrl,
                                memCacheWidth: 150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.imagePlaceholder,
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.category_outlined,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.homeCategoryIcon,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.getName(context),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.homeCategoryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
