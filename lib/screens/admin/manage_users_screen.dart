import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/users'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _users = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.delete(
        Uri.parse('https://api.details-store.com/api/admin/users/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user['_id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('user_deleted'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('delete_failed'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo1.png', height: 40),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.homeNavBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(context, Icons.home_outlined, 0),
            _navIcon(context, Icons.search, 1),
            _navIcon(context, Icons.shopping_bag_outlined, 2),
            _navIcon(context, Icons.favorite_border, 3),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final user = _users[i];
                return Card(
                  color: AppColors.adminSurface,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                    title: Text(user['name']),
                    subtitle: Text(user['email']),
                    trailing: user['isAdmin'] == true
                        ? Chip(
                            label: Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('admin_role'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.adminDelete,
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('confirm_delete'),
                                ),
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('delete_user_confirmation'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('cancel'),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(c);
                                      _deleteUser(user['_id']);
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('delete'),
                                      style: const TextStyle(
                                        color: AppColors.adminDelete,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onNavTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.homeNavInactive, size: 24),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/wishlist');
        break;
    }
  }
}
