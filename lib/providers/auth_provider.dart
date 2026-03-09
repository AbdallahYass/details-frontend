import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:details_app/app_imports.dart';
import 'package:google_sign_in/google_sign_in.dart';

// نموذج المستخدم
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isAdmin;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.isAdmin = false,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'isAdmin': isAdmin,
    'avatar': avatar,
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. تسجيل الدخول العادي
  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
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

        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('userData', json.encode(_user!.toJson()));
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'];
      }
    } catch (e) {
      _errorMessage = "فشل الاتصال بالسيرفر";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 2. تسجيل الدخول عبر جوجل (الحل المتكامل)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // تنظيف أي جلسة سابقة عالقة في جوجل
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final url = Uri.parse('https://api.details-store.com/api/auth/google');
      final response = await http.post(
        url,
        body: json.encode({'idToken': googleAuth.idToken}),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // إذا كان الحساب محذوف من الداتابيس (404)
        _errorMessage = data['message'];
        await _googleSignIn.disconnect(); // قطع الارتباط تماماً
      }
    } catch (e) {
      _errorMessage = "خطأ أثناء تسجيل الدخول بجوجل";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 3. تسجيل الخروج (تنظيف شامل لفك "التعليقة")
  Future<void> logout() async {
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // مسح الذاكرة المحلية

    try {
      // أهم سطر لمنع الدخول التلقائي بحساب محذوف
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      debugPrint('Google Disconnect Error: $e');
    }

    notifyListeners();
  }

  // 4. استعادة الجلسة والتحقق من وجود الحساب (المنقذ من "الحساب الشبح")
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    final extractedToken = prefs.getString('token');

    try {
      // نسأل السيرفر: هل هذا التوكن لا يزال صالحاً وصاحبه موجود؟
      final url = Uri.parse(
        'https://api.details-store.com/api/auth/validate-token',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $extractedToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = extractedToken;
        _user = User.fromJson(data['user']);
        notifyListeners();
      }
      // إذا الحساب محذوف أو التوكن منتهي (401 أو 404)
      else if (response.statusCode == 401 || response.statusCode == 404) {
        await logout(); // طرد فوري وتنظيف للذاكرة
      }
    } catch (e) {
      // في حالة عدم وجود إنترنت، نعتمد على الذاكرة مؤقتاً
      if (prefs.containsKey('userData')) {
        _token = extractedToken;
        _user = User.fromJson(json.decode(prefs.getString('userData')!));
        notifyListeners();
      }
    }
  }

  // --- بقية الدوال (بدون تغيير في المنطق الأساسي) ---

  Future<bool> verifyEmail(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = Uri.parse(
        'https://api.details-store.com/api/auth/verify-email',
      );
      final response = await http.post(
        url,
        body: json.encode({'email': email, 'otp': otp}),
        headers: {'Content-Type': 'application/json'},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userData', json.encode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

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

  Future<bool> requestRegisterOtp(
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

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = Uri.parse('https://api.details-store.com/api/profile');
      final body = <String, dynamic>{'name': name, 'phone': phone};
      if (password != null && password.isNotEmpty) body['password'] = password;

      final response = await http.put(
        url,
        body: json.encode(body),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(_user!.toJson()));
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
