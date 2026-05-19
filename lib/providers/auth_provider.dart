import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:details_app/app_imports.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// نموذج المستخدم
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isAdmin;
  final String? avatar;
  final bool? receiveNotifications; // 🌟 إضافة الحقل الناقص
  final DateTime? createdAt; // 🌟 إضافة تاريخ إنشاء الحساب

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.isAdmin = false,
    this.avatar,
    this.receiveNotifications,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      avatar: json['avatar'],
      receiveNotifications: json['receiveNotifications'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'isAdmin': isAdmin,
    'avatar': avatar,
    'receiveNotifications': receiveNotifications,
    'createdAt': createdAt?.toIso8601String(),
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

  // دالة مساعدة لجلب توكن الإشعارات
  Future<String?> _getFcmToken() async {
    try {
      return await FirebaseMessaging.instance
          .getToken(
            vapidKey:
                "BEZk9zT8N6SJW6-yDwdw8Z3AGyxn1N6cImzo9iDMxzd5xBfRQz_4iD2eNN_GE_Hfv8SXXKzI1SkwogZPctDE3f4",
          )
          .timeout(
            const Duration(seconds: 3),
          ); // ⏱️ إضافة مهلة 3 ثوانٍ لمنع التعليق النهائي
    } catch (e) {
      return null;
    }
  }

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
      // جلب توكن الإشعارات قبل الإرسال
      final fcmToken = await _getFcmToken();
      final body = {'email': email, 'password': password};
      if (fcmToken != null) body['fcmToken'] = fcmToken;

      final url = Uri.parse('https://api.details-store.com/api/auth/login');
      final response = await http.post(
        url,
        body: json.encode(body),
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
      _errorMessage = "server_connection_failed";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 🌟 إضافة الدالة المفقودة لحذف الحساب نهائياً
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = Uri.parse('https://api.details-store.com/api/profile');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        await logout(); // تسجيل الخروج وتنظيف البيانات محلياً
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

      // جلب توكن الإشعارات
      final fcmToken = await _getFcmToken();
      final body = {'idToken': googleAuth.idToken};
      if (fcmToken != null) body['fcmToken'] = fcmToken;

      final url = Uri.parse('https://api.details-store.com/api/auth/google');
      final response = await http.post(
        url,
        body: json.encode(body),
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
      _errorMessage = "google_auth_failed";
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
    await prefs.remove(
      'token',
    ); // مسح التوكن فقط لتجنب حذف إعدادات التطبيق الأخرى
    await prefs.remove('userData'); // مسح بيانات المستخدم فقط

    try {
      // أهم سطر لمنع الدخول التلقائي بحساب محذوف
      final bool isGoogleSigned = await _googleSignIn.isSignedIn();
      if (isGoogleSigned || _googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect().catchError((_) => null);
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

    // التحميل الاستباقي من الذاكرة لضمان سرعة استجابة الواجهة وعدم الانتظار
    _token = extractedToken;
    if (prefs.containsKey('userData')) {
      debugPrint('✅ تم قراءة التوكن وبيانات المستخدم من الذاكرة بنجاح!');
      try {
        _user = User.fromJson(json.decode(prefs.getString('userData')!));
      } catch (_) {}
    }
    notifyListeners();

    // فصل التحقق من السيرفر في وظيفة خلفية حتى لا يعطل الواجهة
    _validateTokenBackground(extractedToken!, prefs);
  }

  Future<void> _validateTokenBackground(
    String extractedToken,
    SharedPreferences prefs,
  ) async {
    try {
      // نسأل السيرفر: هل هذا التوكن لا يزال صالحاً وصاحبه موجود؟
      final url = Uri.parse(
        'https://api.details-store.com/api/auth/validate-token',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $extractedToken',
            },
          )
          .timeout(const Duration(seconds: 5)); // تجنب تعليق شاشة البداية

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data['user']);
        await prefs.setString('userData', json.encode(_user!.toJson()));
        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        // السيرفر يرفض التوكن ويرجع 401 أو الرابط غير موجود 404!
        debugPrint('🚨 السيرفر يرفض التوكن! الحالة: ${response.statusCode}');
        debugPrint(
          '💡 المشكلة من الباك إند: السيرفر يعتبر التوكن المحفوظ غير صالح أو منتهي الصلاحية.',
        );
        await logout(); // تفعيل تسجيل الخروج لحذف الجلسة المنتهية فوراً
      }
    } catch (e) {
      // في حالة عدم وجود إنترنت، لا داعي لفعل شيء لأن البيانات محملة مسبقاً بنجاح
      debugPrint('Auto Login Validation Error: $e');
    }
  }

  // --- بقية الدوال (بدون تغيير في المنطق الأساسي) ---

  Future<bool> verifyEmail(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final fcmToken = await _getFcmToken();
      final body = {'email': email, 'otp': otp};
      if (fcmToken != null) body['fcmToken'] = fcmToken;

      final url = Uri.parse(
        'https://api.details-store.com/api/auth/verify-email',
      );
      final response = await http.post(
        url,
        body: json.encode(body),
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
    String? email,
    String? avatar,
    String? password,
    String? fcmToken, // 🌟 إضافة توكن الإشعارات هنا
    bool? receiveNotifications, // 🌟 إضافة حقل جديد
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = Uri.parse('https://api.details-store.com/api/profile');
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (receiveNotifications != null)
          'receiveNotifications':
              receiveNotifications, // 🌟 إرسال إعدادات الإشعارات
        if (fcmToken != null)
          'fcmToken': fcmToken, // 🌟 إرسال التوكن للسيرفر ليتم حفظه
        if (avatar != null) 'avatar': avatar,
      };
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
        // تحسين: دمج البيانات المحدثة مع البيانات الحالية لضمان عدم فقدان isAdmin أو غيرها
        final updatedUserMap = _user!.toJson();
        final responseMap = data as Map<String, dynamic>;
        updatedUserMap.addAll(responseMap);

        _user = User.fromJson(updatedUserMap);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(_user!.toJson()));
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        await logout(); // طرد المستخدم عند انتهاء الجلسة
        _errorMessage = "session_expired";
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
