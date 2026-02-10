import 'package:details_app/providers/cart_provider.dart';

class OrderModel {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;
  final String status;

  OrderModel({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
    required this.status,
  });
}
