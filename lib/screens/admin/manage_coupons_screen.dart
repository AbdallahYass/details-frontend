import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';
import 'package:details_app/widgets/custom_loading_overlay.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _valueController = TextEditingController();
  String _discountType = 'percentage'; // percentage or fixed
  bool _isLoading = false;
  List<dynamic> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoupons() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.get(
        Uri.parse('https://api.details-store.com/api/coupons'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (res.statusCode == 200) {
        setState(() => _coupons = json.decode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
    }
  }

  Future<void> _addCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/coupons'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'code': _codeController.text.toUpperCase(),
          'discountType': _discountType,
          'value': double.parse(_valueController.text),
          'expirationDate': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('coupon_added'),
              ),
            ),
          );
          _codeController.clear();
          _valueController.clear();
          _fetchCoupons(); // تحديث القائمة
        }
      } else {
        throw Exception('Failed to add coupon');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('coupon_add_error'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCoupon(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/coupons/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() => _coupons.removeWhere((c) => c['_id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('coupon_deleted'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error deleting coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('coupon_delete_error'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('add_new_coupon')),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.translate('coupon_code'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.autorenew),
                    tooltip: AppLocalizations.of(
                      context,
                    )!.translate('generate_auto_code'),
                    onPressed: () {
                      _codeController.text = _generateRandomCode();
                    },
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty
                    ? AppLocalizations.of(context)!.translate('required_field')
                    : null,
              ),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.translate('value'),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty
                    ? AppLocalizations.of(context)!.translate('required_field')
                    : null,
              ),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _discountType,
                items: [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text(
                      AppLocalizations.of(context)!.translate('percentage'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text(
                      AppLocalizations.of(context)!.translate('fixed_amount'),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _addCoupon,
            child: Text(AppLocalizations.of(context)!.translate('add')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('manage_coupons')),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _coupons.length,
            itemBuilder: (ctx, i) {
              final coupon = _coupons[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    coupon['code'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${coupon['discountType'] == 'percentage' ? '%' : '\$'}${coupon['value']} - Used: ${coupon['usedCount']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.adminDelete,
                    ),
                    onPressed: () => _deleteCoupon(coupon['_id']),
                  ),
                ),
              );
            },
          ),
          if (_isLoading) const CustomLoadingOverlay(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCouponDialog,
        backgroundColor: AppColors.adminAdd,
        child: const Icon(Icons.add, color: Colors.white),
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
