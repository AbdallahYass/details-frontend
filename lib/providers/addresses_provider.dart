import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/address_model.dart';
import 'package:details_app/providers/auth_provider.dart';

class AddressesProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;
  AuthProvider? _auth; // لربط الـ Provider بالـ AuthProvider

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // دالة لتحديث الـ AuthProvider عند تسجيل الدخول/الخروج
  void updateAuth(AuthProvider? auth) {
    _auth = auth;
    if (_auth?.isAuthenticated == false) {
      _addresses = []; // مسح العناوين عند تسجيل الخروج
      notifyListeners();
    }
  }

  Future<void> fetchAddresses() async {
    if (_auth == null || !_auth!.isAuthenticated) {
      _addresses = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://api.details-store.com/api/addresses');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth!.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _addresses = data.map((json) => AddressModel.fromJson(json)).toList();
      } else {
        _errorMessage =
            json.decode(response.body)['message'] ??
            'Failed to fetch addresses';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('https://api.details-store.com/api/addresses');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth!.token}',
        },
        body: json.encode(address.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchAddresses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/addresses/${address.id}',
      );
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth!.token}',
        },
        body: json.encode(address.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchAddresses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    if (_auth == null || !_auth!.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/addresses/$addressId',
      );
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth!.token}',
        },
      );

      if (response.statusCode == 200) {
        await fetchAddresses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setAsDefault(String addressId) async {
    try {
      final address = _addresses.firstWhere((a) => a.id == addressId);
      final updated = AddressModel(
        id: address.id,
        name: address.name,
        phone: address.phone,
        city: address.city,
        street: address.street,
        isDefault: true,
      );
      return await updateAddress(updated);
    } catch (e) {
      return false;
    }
  }
}
