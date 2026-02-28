import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/constants/app_theme.dart';
import 'package:details_app/providers/router.dart';

Future<void> main() async {
  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
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
  Widget build(BuildContext context) {
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
