import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/address_model.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final bool wasAuthenticated = _auth?.isAuthenticated ?? false;
    _auth = auth;

    // إذا تغيرت حالة الدخول، نعيد جلب البيانات (سواء من السيرفر أو الذاكرة المحلية)
    if (wasAuthenticated != (_auth?.isAuthenticated ?? false)) {
      fetchAddresses();
    }
  }

  // دالة مساعدة لحفظ عناوين الزوار محلياً
  Future<void> _saveGuestAddressesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(_addresses.map((e) => e.toJson()).toList());
      await prefs.setString('guest_addresses_data', data);
    } catch (e) {
      debugPrint('Error saving guest addresses: $e');
    }
  }

  // دالة مساعدة لتحميل عناوين الزوار من الذاكرة
  Future<void> _loadGuestAddressesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('guest_addresses_data');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      _addresses = decoded.map((item) => AddressModel.fromJson(item)).toList();
    } else {
      _addresses = [];
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth != null && _auth!.isAuthenticated) {
        // جلب من السيرفر للمسجلين
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
              json.decode(response.body)['message'] ?? 'error_fetch_addresses';
        }
      } else {
        // جلب من الذاكرة المحلية للزوار
        await _loadGuestAddressesFromPrefs();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_auth != null && _auth!.isAuthenticated) {
        // إضافة للسيرفر
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
        } else {
          final data = json.decode(response.body);
          _errorMessage = data['message'] ?? 'error_add_address';
          return false;
        }
      } else {
        // إضافة محلياً للزوار
        final guestAddress = AddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // معرف مؤقت
          name: address.name,
          phone: address.phone,
          city: address.city,
          street: address.street,
          isDefault: address.isDefault,
        );

        if (guestAddress.isDefault) {
          // إلغاء الافتراضي عن البقية محلياً
          _addresses = _addresses
              .map(
                (a) => AddressModel(
                  id: a.id,
                  name: a.name,
                  phone: a.phone,
                  city: a.city,
                  street: a.street,
                  isDefault: false,
                ),
              )
              .toList();
        }

        _addresses.add(guestAddress);
        await _saveGuestAddressesToPrefs();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_auth != null && _auth!.isAuthenticated) {
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
      } else {
        // تحديث محلي للزوار
        final index = _addresses.indexWhere((a) => a.id == address.id);
        if (index != -1) {
          if (address.isDefault) {
            _addresses = _addresses
                .map(
                  (a) => a.id == address.id
                      ? address
                      : AddressModel(
                          id: a.id,
                          name: a.name,
                          phone: a.phone,
                          city: a.city,
                          street: a.street,
                          isDefault: false,
                        ),
                )
                .toList();
          } else {
            _addresses[index] = address;
          }
          await _saveGuestAddressesToPrefs();
          return true;
        }
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_auth != null && _auth!.isAuthenticated) {
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
      } else {
        // حذف محلي للزوار
        _addresses.removeWhere((a) => a.id == addressId);
        await _saveGuestAddressesToPrefs();
        return true;
      }
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
