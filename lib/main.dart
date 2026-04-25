import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/home_provider.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/providers/addresses_provider.dart';
import 'package:details_app/providers/language_provider.dart';
import 'package:details_app/constants/app_theme.dart';
import 'package:details_app/providers/router.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAUMaUSPPNfVTKudn58zM0WMs5dG4umx0c",
        authDomain: "details-store-3be7c.firebaseapp.com",
        projectId: "details-store-3be7c",
        storageBucket: "details-store-3be7c.firebasestorage.app",
        messagingSenderId: "131777577750",
        appId: "1:131777577750:web:c9ce46e86de97152cfc637",
        measurementId: "G-V5XQCFK678",
      ),
    );
  } else {
    await Firebase.initializeApp(); // يقرأ من ملف google-services.json تلقائياً للموبايل
  }

  setPathUrlStrategy();

  // قراءة اللغة المحفوظة قبل بدء التطبيق لضمان تطبيقها فوراً من أول إطار (Frame)
  final prefs = await SharedPreferences.getInstance();
  final String savedLanguage = prefs.getString('language_code') ?? 'ar';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(savedLanguage)),
        ChangeNotifierProxyProvider<AuthProvider, AddressesProvider>(
          create: (_) => AddressesProvider(),
          update: (_, auth, addresses) => addresses!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) =>
              wishlist!..updateToken(auth.token, onLogout: auth.logout),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, orders) =>
              orders!..updateToken(auth.token, onLogout: auth.logout),
        ),
      ],
      child: const DetailsStoreApp(),
    ),
  );
}

class DetailsStoreApp extends StatefulWidget {
  const DetailsStoreApp({super.key});

  @override
  State<DetailsStoreApp> createState() => _DetailsStoreAppState();
}

class _DetailsStoreAppState extends State<DetailsStoreApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
        await _setupFirebaseMessaging();
      } catch (e) {
        debugPrint('Auto-login error caught safely: $e');
      }
    });
  }

  // دالة إعداد إشعارات فايربيس (طلب الصلاحية وجلب التوكن)
  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings;
      if (kIsWeb) {
        // في الويب، نطلب الصلاحية فقط، والمتصفح سيتجاهلها إذا لم تكن مرتبطة بـ Gesture
        // لكننا نضعها في try-catch لمنع تعطل التطبيق بالكامل
        settings = await messaging.getNotificationSettings();
      } else {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ المستخدم وافق على الإشعارات');

        // 2. جلب التوكن الخاص بهذا المتصفح باستخدام مفتاح VAPID
        String? token = await messaging.getToken(
          vapidKey:
              "BEZk9zT8N6SJW6-yDwdw8Z3AGyxn1N6cImzo9iDMxzd5xBfRQz_4iD2eNN_GE_Hfv8SXXKzI1SkwogZPctDE3f4",
        );

        debugPrint('🔥 FCM Token: $token');
        // سيتم لاحقاً إرسال هذا التوكن للباك إند لحفظه مع حساب المستخدم
      } else {
        debugPrint('❌ المستخدم رفض صلاحية الإشعارات');
      }

      // 3. الاستماع للإشعارات بينما الموقع مفتوح أمام المستخدم (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification!.title}\n${message.notification!.body}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('خطأ في إعداد الإشعارات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة تغييرات الإعدادات (مثل اللغة)
    // تم التعديل ليقرأ التطبيق اللغة المحفوظة في الذاكرة
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Details Store | متجر ديتيلز',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // العربية
        Locale('en', ''), // الإنجليزية
      ],
      locale: languageProvider.appLocale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (var locale in supportedLocales) {
          if (locale.languageCode == languageProvider.appLocale.languageCode) {
            return locale;
          }
        }
        return supportedLocales.first; // الافتراضي
      },
    );
  }
}
