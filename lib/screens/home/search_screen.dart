import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/products?search=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: AppColors.appBarBackground,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )!.translate('search_hint'),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: _performSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _buildBody(),
                if (_isLoading) const CustomLoadingOverlay(isOverlay: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate('start_typing'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('no_results'),
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: Image.network(
              product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.error),
            ),
            title: Text(product.getName(context)),
            subtitle: Text(
              '${product.price} ${AppLocalizations.of(context)!.translate('currency')}',
            ),
            onTap: () {
              context.push('/product/${product.id}', extra: product);
            },
          ),
        );
      },
    );
  }
}
