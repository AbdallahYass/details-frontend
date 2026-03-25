import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Address {
  final String id;
  final String city;
  final String street;
  final String phone;

  Address({
    required this.id,
    required this.city,
    required this.street,
    required this.phone,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? json['_id'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class AddressesProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;

  final String baseUrl = 'https://api.details-store.com/api';

  Future<void> fetchAddresses(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _addresses = data.map((json) => Address.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAddress(
    String token,
    String city,
    String street,
    String phone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'city': city, 'street': street, 'phone': phone}),
      );

      if (response.statusCode == 201) {
        final newAddress = Address.fromJson(json.decode(response.body));
        _addresses.insert(0, newAddress); // Add to the beginning of the list
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding address: $e');
    }
    return false;
  }

  Future<bool> deleteAddress(String token, String addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _addresses.removeWhere((addr) => addr.id == addressId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
    }
    return false;
  }
}
