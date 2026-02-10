import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.toLowerCase(), 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // حفظ البيانات في الجهاز
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'فشل تسجيل الدخول';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      _errorMessage = 'حدث خطأ في الاتصال، يرجى المحاولة لاحقاً';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // إنشاء حساب جديد
  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.details-store.com/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email.toLowerCase(),
          'password': password,
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'فشل إنشاء الحساب';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      _errorMessage = 'حدث خطأ في الاتصال، يرجى المحاولة لاحقاً';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // محاولة الدخول التلقائي عند فتح التطبيق
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;
    if (!prefs.containsKey('userData')) return;

    final token = prefs.getString('token');
    final userDataString = prefs.getString('userData');

    if (token == null || userDataString == null) return;

    final userData = json.decode(userDataString) as Map<String, dynamic>;

    _token = token;
    _user = User.fromJson(userData);
    notifyListeners();
  }
}
