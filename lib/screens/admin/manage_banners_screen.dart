import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:details_app/screens/home/cloudinary_service.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/screens/home/notifications_screen.dart';
import 'package:details_app/l10n/app_localizations.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/categories'),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _categories = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/banners'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _banners = data is List ? data : [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBanner(
    String titleAr,
    String titleEn,
    String imageUrl,
    String? categoryId,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/banners'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'title': {'ar': titleAr, 'en': titleEn},
          'imageUrl': imageUrl,
          'location': 'home', // افتراضياً للصفحة الرئيسية
          'isActive': true,
          if (categoryId != null) 'category': categoryId,
        }),
      );

      if (response.statusCode == 201) {
        _fetchBanners();
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('banner_added_success'),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('banner_add_failed'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('banner_add_failed'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteBanner(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/banners/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() {
        _banners.removeWhere((b) => b['_id'] == id);
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('banner_deleted_success'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('banner_delete_failed'),
            ),
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    final titleArController = TextEditingController();
    final titleEnController = TextEditingController();
    final imageController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isUploading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              setState(() => isUploading = true);
              final url = await CloudinaryService().pickAndUploadImage();
              setState(() => isUploading = false);
              if (url != null) {
                imageController.text = url;
              }
            }

            return Stack(
              children: [
                AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.translate('add_new_banner'),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleArController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('title_ar'),
                          ),
                        ),
                        TextField(
                          controller: titleEnController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('title_en'),
                          ),
                        ),
                        TextField(
                          controller: imageController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.translate('image_url'),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.cloud_upload),
                              onPressed: isUploading ? null : pickImage,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_categories.isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.translate('link_category_optional'),
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map<DropdownMenuItem<String>>((
                              c,
                            ) {
                              final name = c['name'] is Map
                                  ? c['name']['ar']
                                  : c['name'];
                              return DropdownMenuItem(
                                value: c['_id'],
                                child: Text(name ?? ''),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => selectedCategory = v),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isUploading ? null : () => Navigator.pop(ctx),
                      child: Text(
                        AppLocalizations.of(context)!.translate('cancel'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () => _addBanner(
                              titleArController.text,
                              titleEnController.text,
                              imageController.text,
                              selectedCategory,
                            ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('add'),
                      ),
                    ),
                  ],
                ),
                if (isUploading) const CustomLoadingOverlay(isOverlay: true),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Image.asset('assets/images/logo2.png', height: 100),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchBanners,
            child: _banners.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_banners'),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _banners.length,
                    itemBuilder: (ctx, i) {
                      final banner = _banners[i];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: banner['imageUrl'] ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.grey200),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            ListTile(
                              title: Text(
                                banner['title'] is Map
                                    ? (banner['title']['ar'] ??
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('banner_default_title'))
                                    : AppLocalizations.of(
                                        context,
                                      )!.translate('banner_default_title'),
                              ),
                              subtitle: Text(
                                '${AppLocalizations.of(context)!.translate('location_label')} ${banner['location'] ?? 'home'}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.adminDelete,
                                ),
                                onPressed: () => _deleteBanner(banner['_id']),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const CustomLoadingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.adminAdd,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
