// ignore_for_file: use_build_context_synchronously, empty_catches

import 'package:details_app/app_imports.dart'; // تأكد من استيراد SearchService هنا
import 'package:details_app/services/search_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  Timer? _debounce;

  List<String> _recentSearches = [];
  List<Product> _recentlyViewed = [];
  List<String> _suggestions = [];
  bool _showingSuggestions = false;

  // Trending Searches State
  List<String> _trendingTags = [];
  bool _isLoadingTrending = true;

  // Pagination & Sorting
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _sortOption = 'newest';

  // Voice Search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadRecentlyViewed();
    _loadTrendingTags();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _speech.stop();
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 🛡️ حماية لمنع الـ Crash
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading &&
        !_hasError) {
      _performSearch(_searchController.text, isPagination: true);
    }
  }

  Future<void> _loadTrendingTags() async {
    try {
      final tags = await SearchService.fetchTrendingTags();
      if (mounted) {
        setState(() {
          _trendingTags = tags;
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trendingTags = [
            'ساعات',
            'عطور',
            'حقائب',
            'أحذية',
            'فساتين',
            'هدايا',
          ];
          _isLoadingTrending = false;
        });
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  Future<void> _addToRecentSearches(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches.remove(query);
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.sublist(0, 10);
        }
      });
      await prefs.setStringList('recent_searches', _recentSearches);
    }
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _recentSearches.clear());
      await prefs.remove('recent_searches');
    }
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _recentSearches.remove(query));
      await prefs.setStringList('recent_searches', _recentSearches);
    }
  }

  Future<void> _loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final String? saved = prefs.getString('recently_viewed_products');
    if (saved != null) {
      try {
        final List<dynamic> decoded = json.decode(saved);
        setState(() {
          _recentlyViewed = decoded.map((e) => Product.fromJson(e)).toList();
        });
      } catch (e) {}
    }
  }

  Future<void> _addToRecentlyViewed(Product p) async {
    setState(() {
      _recentlyViewed.removeWhere((item) => item.id == p.id);
      _recentlyViewed.insert(0, p);
      if (_recentlyViewed.length > 5) {
        _recentlyViewed = _recentlyViewed.sublist(0, 5);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(
        'recently_viewed_products',
        json.encode(_recentlyViewed.map((e) => e.toJson()).toList()),
      );
    } catch (e) {}
  }

  Future<void> _performSearch(
    String query, {
    bool saveToHistory = false,
    bool isPagination = false,
  }) async {
    if (query.trim().isEmpty && !isPagination) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _hasError = false;
      });
      return;
    }

    if (saveToHistory) _addToRecentSearches(query);

    if (!isPagination) {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
        _showingSuggestions = false;
        _hasError = false;
        _page = 1;
        _hasMore = true;
        _searchResults.clear();
      });
    } else {
      if (!_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      // استخدام السيرفيس الجديد الذي يدعم الكاش! 🔥
      final result = await SearchService.searchProducts(
        query: query,
        page: _page,
        sortOption: _sortOption,
      );

      if (mounted) {
        setState(() {
          final List<Product> newProducts = result['products'];

          if (isPagination) {
            _searchResults.addAll(newProducts);
          } else {
            _searchResults = newProducts;
          }

          _hasMore = result['hasMore'];
          if (newProducts.isNotEmpty) _page++;

          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isPagination) _hasError = true;
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (isPagination) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('error_occurred'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchSuggestionsForUI(String query) async {
    try {
      final langCode = Localizations.localeOf(context).languageCode;
      final tags = await SearchService.fetchSuggestions(query, langCode);
      if (mounted) {
        setState(() {
          _suggestions = tags;
          _showingSuggestions = true;
        });
      }
    } catch (e) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // تم تعديل وقت الانتظار لـ 400ms للحفاظ على أداء السيرفر 🛠️
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isEmpty) {
        setState(() => _showingSuggestions = false);
        return;
      }
      _fetchSuggestionsForUI(query);
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        final currentLocale = Localizations.localeOf(context);
        final localeId = currentLocale.languageCode == 'ar' ? 'ar_SA' : 'en_US';

        _speech.listen(
          localeId: localeId,
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
                _performSearch(val.recognizedWords, saveToHistory: true);
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showSortOptions(AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.translate('sort_by'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSortOption(loc, 'newest', loc.translate('newest')),
              _buildSortOption(
                loc,
                'price_asc',
                loc.translate('price_low_high'),
              ),
              _buildSortOption(
                loc,
                'price_desc',
                loc.translate('price_high_low'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(AppLocalizations loc, String value, String label) {
    final isSelected = _sortOption == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFFD4AF37))
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() => _sortOption = value);
        _performSearch(_searchController.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: 1080,
            ),
          ),
          Column(
            children: [
              _buildSearchHeader(loc),
              Expanded(child: _buildBody(loc)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFF452512)),
            onPressed: () => _showSortOptions(loc),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF452512).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: Color(0xFF452512),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: loc.translate('search_hint'),
                  hintStyle: TextStyle(
                    color: const Color(0xFF452512).withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFD4AF37),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _showingSuggestions = false);
                                    _performSearch('');
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.red
                              : const Color(0xFFD4AF37),
                        ),
                        onPressed: _listen,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _performSearch(val, saveToHistory: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    const bottomPadding = EdgeInsets.only(bottom: 120);

    if (_showingSuggestions && _suggestions.isNotEmpty) {
      return _buildSuggestionsList(bottomPadding);
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              loc.translate('error_occurred'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
              ),
              child: Text(loc.translate('retry')),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16).add(bottomPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _buildShimmerProductCard(),
      );
    }

    if (!_hasSearched) {
      return SingleChildScrollView(
        padding: bottomPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrendingSearches(loc),
            if (_recentSearches.isNotEmpty) _buildRecentSearchesList(loc),
            if (_recentlyViewed.isNotEmpty) _buildRecentlyViewedSection(loc),
            if (_recentSearches.isEmpty &&
                _recentlyViewed.isEmpty &&
                _searchController.text.isEmpty &&
                !_isLoadingTrending)
              _buildEmptyState(loc),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('no_results'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF452512),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16).add(bottomPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_searchResults[index], loc);
            },
          ),
        ),
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ).add(bottomPadding),
            child: Row(
              children: List.generate(
                2,
                (index) => Expanded(child: _buildShimmerProductCard()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsList(EdgeInsets padding) {
    return ListView.builder(
      padding: padding,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final query = _searchController.text;

        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          // ↗ إضافة أيقونة السهم الجانبي الاحترافية
          trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF452512), fontSize: 16),
              children: _highlightOccurrences(suggestion, query),
            ),
          ),
          onTap: () {
            _searchController.text = _suggestions[index];
            _performSearch(_suggestions[index], saveToHistory: true);
            FocusScope.of(context).unfocus();
          },
        );
      },
    );
  }

  List<TextSpan> _highlightOccurrences(String source, String query) {
    if (query.isEmpty || !source.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: source)];
    }
    final matches = query.toLowerCase().allMatches(source.toLowerCase());
    int lastMatchEnd = 0;
    final List<TextSpan> children = [];
    for (var match in matches) {
      if (match.start != lastMatchEnd) {
        children.add(
          TextSpan(text: source.substring(lastMatchEnd, match.start)),
        );
      }
      children.add(
        TextSpan(
          text: source.substring(match.start, match.end),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd != source.length) {
      children.add(TextSpan(text: source.substring(lastMatchEnd)));
    }
    return children;
  }

  Widget _buildShimmerProductCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 12,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(height: 12, width: 60, color: Colors.white),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 60,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.translate('start_typing'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF452512),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('search_favorites_hint'),
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF452512).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSearches(AppLocalizations loc) {
    if (_isLoadingTrending) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }
    if (_trendingTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                loc.translate('most_popular'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF452512),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingTags.map((tag) {
              return ActionChip(
                label: Text(tag),
                backgroundColor: Colors.white,
                surfaceTintColor: const Color(0xFFFDFBF7),
                elevation: 1,
                onPressed: () {
                  _searchController.text = tag;
                  _performSearch(tag, saveToHistory: true);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesList(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('recent_searches'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF452512),
                ),
              ),
              if (_recentSearches.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFFDFBF7),
                        title: Text(
                          loc.translate('confirm_deletion'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF452512),
                          ),
                        ),
                        content: Text(
                          loc.translate('clear_history_confirm'),
                          style: const TextStyle(color: Color(0xFF452512)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              loc.translate('cancel'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearRecentSearches();
                            },
                            child: Text(
                              loc.translate('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    loc.translate('clear_all'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _recentSearches.length,
          itemBuilder: (context, index) {
            final term = _recentSearches[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(term),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onPressed: () => _removeRecentSearch(term),
              ),
              onTap: () {
                _searchController.text = term;
                _performSearch(term, saveToHistory: true);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            loc.translate('recently_viewed'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF452512),
            ),
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentlyViewed.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: _buildProductCard(_recentlyViewed[index], loc),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductCard(Product p, AppLocalizations loc) {
    return Selector<WishlistProvider, bool>(
      selector: (context, wishlistProvider) =>
          wishlistProvider.isInWishlist(p.id),
      builder: (context, isFav, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _addToRecentlyViewed(p);
                            context.push('/product/${p.id}', extra: p);
                          },
                          child: Hero(
                            tag: 'search_${p.id}',
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFEEEEEE),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (p.isSoldOut)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            loc.translate('sold_out'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (!auth.isAuthenticated) {
                            context.push('/login');
                            return;
                          }
                          final wishlistProvider =
                              Provider.of<WishlistProvider>(
                                context,
                                listen: false,
                              );
                          bool added = await wishlistProvider.toggleWishlist(p);
                          if (!mounted) return;
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? (loc.translate('added_to_wishlist'))
                                    : (loc.translate('removed_from_wishlist')),
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF9E773A),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      p.getName(context),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF452512),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.price} ${loc.translate('currency')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9E773A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
