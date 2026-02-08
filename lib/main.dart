import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:details_app/models/product.dart';
import 'package:details_app/screens/home_page.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/screens/product_details_screen.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/screens/wishlist_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => WishlistProvider()..fetchWishlist(),
    child: const DetailsStoreApp(),
  ),
);

class DetailsStoreApp extends StatefulWidget {
  const DetailsStoreApp({super.key});

  @override
  State<DetailsStoreApp> createState() => _DetailsStoreAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _DetailsStoreAppState? state = context
        .findAncestorStateOfType<_DetailsStoreAppState>();
    state?.setLocale(newLocale);
  }
}

class _DetailsStoreAppState extends State<DetailsStoreApp> {
  Locale _locale = const Locale('ar', '');

  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StoreHomePage()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'];
          final product = state.extra as Product?;
          return ProductDetailsScreen(productId: productId, product: product);
        },
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
    ],
  );

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Details Store',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
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
      locale: _locale,
    );
  }
}
