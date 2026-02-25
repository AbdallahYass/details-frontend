import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:details_app/app_imports.dart';

// نموذج مستخدم بسيط (يمكنك نقله لملف منفصل لاحقاً)
class User {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'isAdmin': isAdmin,
  };
}

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _token != null;
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('https://api.details-store.com/api/auth/login');
      final response = await http.post(
        url,
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        // حفظ البيانات محلياً
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(data['user']));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'];
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // تسجيل الخروج
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // استعادة الجلسة عند فتح التطبيق
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final extractedToken = prefs.getString('token');
    final userData = json.decode(prefs.getString('userData') ?? '{}');

    _token = extractedToken;
    _user = User.fromJson(userData);
    notifyListeners();
  }

  // تسجيل حساب جديد (يمكنك تفعيله لاحقاً)
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
      final url = Uri.parse('https://api.details-store.com/api/auth/register');
      final response = await http.post(
        url,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // طلب استعادة كلمة المرور (إرسال الإيميل)
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/auth/forgot-password',
      );
      final response = await http.post(
        url,
        body: json.encode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // إعادة تعيين كلمة المرور (باستخدام التوكن)
  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/auth/reset-password/$token',
      );
      final response = await http.post(
        url,
        body: json.encode({'password': newPassword}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage = data['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
