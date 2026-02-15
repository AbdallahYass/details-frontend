import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:details_app/providers/auth_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final List<String> _orderStatuses = [
    'قيد التجهيز',
    'تم الشحن',
    'تم التوصيل',
    'ملغي',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/orders'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _orders = data is List ? data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // تحديث محلي فوري لتحسين تجربة المستخدم
    setState(() {
      final index = _orders.indexWhere((o) => o['_id'] == id);
      if (index != -1) _orders[index]['status'] = newStatus;
    });

    try {
      await http.put(
        Uri.parse('https://api.details-store.com/api/admin/orders/$id/status'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );
      // لا داعي لإعادة تحميل الطلبات بالكامل إذا نجح الطلب
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      _fetchOrders(); // إعادة التحميل في حالة الخطأ فقط للتصحيح
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل تحديث الحالة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (ctx, i) {
                  final order = _orders[i];
                  final orderId = order['_id'].toString();
                  final user = order['user'];
                  final items = order['products'] as List<dynamic>? ?? [];
                  final shipping = order['shippingAddress'];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ExpansionTile(
                      title: Text(
                        'طلب #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                      ),
                      subtitle: Text(
                        '${order['totalAmount']} - ${order['status']}',
                        style: TextStyle(
                          color: order['status'] == 'تم التوصيل'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_attributes),
                          title: const Text('تغيير الحالة'),
                          trailing: DropdownButton<String>(
                            value: _orderStatuses.contains(order['status'])
                                ? order['status']
                                : null,
                            items: _orderStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) _updateStatus(orderId, val);
                            },
                          ),
                        ),
                        const Divider(),
                        if (user != null || shipping != null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'معلومات العميل:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (user != null && user['name'] != null)
                                  Text('👤 الاسم: ${user['name']}'),
                                if (shipping != null &&
                                    shipping['phone'] != null)
                                  Text('📞 الهاتف: ${shipping['phone']}'),
                                if (shipping != null)
                                  Text(
                                    '📍 العنوان: ${shipping['city'] ?? ''} - ${shipping['street'] ?? ''}',
                                  ),
                              ],
                            ),
                          ),
                        if (items.isNotEmpty) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'المنتجات:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ...items.map((item) {
                                  final productName =
                                      item['title'] ?? 'منتج غير معروف';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '- $productName (x${item['quantity']})',
                                          ),
                                        ),
                                        Text(
                                          '${item['price']} ₪',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
