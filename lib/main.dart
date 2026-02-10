import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:details_app/models/product.dart';
import 'package:details_app/screens/home_page.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:details_app/screens/product_details_screen.dart';
import 'package:details_app/providers/wishlist_provider.dart';
import 'package:details_app/screens/wishlist_screen.dart';
import 'package:details_app/screens/login_screen.dart';
import 'package:details_app/screens/register_screen.dart';
import 'package:details_app/providers/auth_provider.dart';
import 'package:details_app/screens/profile_screen.dart';
import 'package:details_app/providers/settings_provider.dart';
import 'package:details_app/providers/cart_provider.dart';
import 'package:details_app/screens/cart_screen.dart';
import 'package:details_app/screens/search_screen.dart';
import 'package:details_app/providers/orders_provider.dart';
import 'package:details_app/screens/orders_screen.dart';
import 'package:details_app/constants/app_theme.dart';
import 'package:details_app/screens/main_screen.dart';

Future<void> main() async {
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
  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const StoreHomePage(),
              ),
            ],
          ),
          // Branch 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Branch 2: Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          // Branch 3: Wishlist
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'];
          final product = state.extra as Product?;
          return ProductDetailsScreen(productId: productId, product: product);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Details Store',
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
