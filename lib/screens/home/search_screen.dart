import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  RangeValues _currentPriceRange = const RangeValues(0, 1000);
  String _sortBy = 'newest'; // newest, price_asc, price_desc

  @override
  void initState() {
    super.initState();
    _fetchFilteredProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilteredProducts() async {
    setState(() => _isLoading = true);
    try {
      // بناء رابط الـ API مع الباراميترز
      String url = 'https://api.details-store.com/api/products?';

      if (_searchController.text.isNotEmpty) {
        url += 'search=${_searchController.text}&';
      }

      url +=
          'minPrice=${_currentPriceRange.start}&maxPrice=${_currentPriceRange.end}&';
      url += 'sort=$_sortBy';

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _filteredProducts = data.map((j) => Product.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching products for search: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    // نستخدم Debounce بسيط لتجنب كثرة الطلبات (اختياري، هنا نستدعي مباشرة)
    _fetchFilteredProducts();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('filter_sort'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.translate('price_range'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: _currentPriceRange,
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    labels: RangeLabels(
                      "${_currentPriceRange.start.round()} ${AppLocalizations.of(context)!.translate('currency')}",
                      "${_currentPriceRange.end.round()} ${AppLocalizations.of(context)!.translate('currency')}",
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (values) {
                      setModalState(() => _currentPriceRange = values);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.translate('sort_by'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: Text(
                          AppLocalizations.of(context)!.translate('newest'),
                        ),
                        selected: _sortBy == 'newest',
                        onSelected: (b) =>
                            setModalState(() => _sortBy = 'newest'),
                      ),
                      ChoiceChip(
                        label: Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('price_low_high'),
                        ),
                        selected: _sortBy == 'price_asc',
                        onSelected: (b) =>
                            setModalState(() => _sortBy = 'price_asc'),
                      ),
                      ChoiceChip(
                        label: Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('price_high_low'),
                        ),
                        selected: _sortBy == 'price_desc',
                        onSelected: (b) =>
                            setModalState(() => _sortBy = 'price_desc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchFilteredProducts();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.translate('apply_filters'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.translate('search_hint'),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _filterProducts,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _searchController.text.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('start_typing'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate('no_results'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Hero(
                            tag: product.id,
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          product.getName(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${product.price} ${AppLocalizations.of(context)!.translate('currency')}",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => context.push(
                          '/product/${product.id}',
                          extra: product,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
