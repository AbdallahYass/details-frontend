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
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await http.put(
        Uri.parse('https://api.details-store.com/api/admin/orders/$id/status'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );
      _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
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
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final order = _orders[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(
                      'طلب #${order['_id'].toString().substring(0, 8)}',
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
                        title: const Text('تغيير الحالة'),
                        trailing: DropdownButton<String>(
                          value:
                              [
                                'قيد التجهيز',
                                'تم الشحن',
                                'تم التوصيل',
                                'ملغي',
                              ].contains(order['status'])
                              ? order['status']
                              : null,
                          items:
                              ['قيد التجهيز', 'تم الشحن', 'تم التوصيل', 'ملغي']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) _updateStatus(order['_id'], val);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
