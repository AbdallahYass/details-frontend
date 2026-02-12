import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/models/product.dart';

// Screens
import 'package:details_app/screens/main_screen.dart';
import 'package:details_app/screens/home_page.dart';
import 'package:details_app/screens/search_screen.dart';
import 'package:details_app/screens/cart_screen.dart';
import 'package:details_app/screens/product_details_screen.dart';
import 'package:details_app/screens/login_screen.dart';
import 'package:details_app/screens/register_screen.dart';
import 'package:details_app/screens/checkout_screen.dart';
import 'package:details_app/screens/orders_screen.dart';
import 'package:details_app/screens/about_screen.dart';
import 'package:details_app/screens/wishlist_screen.dart';
import 'package:details_app/screens/account_screen.dart';

// Admin Screens
import 'package:details_app/screens/admin_dashboard_screen.dart';
import 'package:details_app/screens/manage_products_screen.dart';
import 'package:details_app/screens/add_edit_product_screen.dart';
import 'package:details_app/screens/manage_users_screen.dart';
import 'package:details_app/screens/manage_categories_screen.dart';
import 'package:details_app/screens/manage_coupons_screen.dart';
import 'package:details_app/screens/admin_orders_screen.dart';
import 'package:details_app/screens/manage_banners_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorHome = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final GlobalKey<NavigatorState> _shellNavigatorSearch =
    GlobalKey<NavigatorState>(debugLabel: 'shellSearch');
final GlobalKey<NavigatorState> _shellNavigatorCart = GlobalKey<NavigatorState>(
  debugLabel: 'shellCart',
);
final GlobalKey<NavigatorState> _shellNavigatorWishlist =
    GlobalKey<NavigatorState>(debugLabel: 'shellWishlist');
final GlobalKey<NavigatorState> _shellNavigatorAccount =
    GlobalKey<NavigatorState>(debugLabel: 'shellAccount');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSearch,
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCart,
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorWishlist,
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (context, state) => const WishlistScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorAccount,
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Product?;
        final id = state.pathParameters['id'];
        return ProductDetailsScreen(productId: id, product: product);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    // Admin Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'products',
          builder: (context, state) => const ManageProductsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditProductScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final product = state.extra;
                return AddEditProductScreen(product: product);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const ManageUsersScreen(),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const ManageCategoriesScreen(),
        ),
        GoRoute(
          path: 'coupons',
          builder: (context, state) => const ManageCouponsScreen(),
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: 'banners',
          builder: (context, state) => const ManageBannersScreen(),
        ),
      ],
    ),
  ],
);
