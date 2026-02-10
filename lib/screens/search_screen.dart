import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:details_app/models/product.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllProducts() async {
    try {
      final res = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/products'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _allProducts = data.map((j) => Product.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching products for search: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = []);
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = product.getName(context).toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('search_hint'),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black),
          onChanged: _filterProducts,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
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
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                  title: Text(
                    product.getName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "\$${product.price}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () =>
                      context.push('/product/${product.id}', extra: product),
                );
              },
            ),
    );
  }
}
