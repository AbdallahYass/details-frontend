import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/providers/notification_provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/constants/app_theme.dart';
import 'package:details_app/providers/router.dart';
import 'package:flutter/foundation.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) => wishlist!..updateToken(auth.token),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, orders) => orders!..updateToken(auth.token),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة تغييرات الإعدادات (مثل اللغة)
    final settings = context.watch<SettingsProvider>();

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
      locale: settings.locale,
    );
  }
}
