import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/providers/auth_provider.dart';

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
            const SnackBar(content: Text('تم إضافة الكوبون بنجاح')),
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
          const SnackBar(content: Text('حدث خطأ أثناء إضافة الكوبون')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCoupon(String id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await http.delete(
        Uri.parse('https://api.details-store.com/api/coupons/$id'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      setState(() => _coupons.removeWhere((c) => c['_id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الكوبون بنجاح')));
      }
    } catch (e) {
      debugPrint('Error deleting coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل حذف الكوبون')));
      }
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
        title: const Text('إضافة كوبون جديد'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'كود الكوبون',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.autorenew),
                    tooltip: 'توليد كود تلقائي',
                    onPressed: () {
                      _codeController.text = _generateRandomCode();
                    },
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'القيمة'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _discountType,
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('نسبة مئوية %'),
                  ),
                  DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _addCoupon,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الكوبونات')),
      body: ListView.builder(
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
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCoupon(coupon['_id']),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCouponDialog,
        backgroundColor: AppColors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
