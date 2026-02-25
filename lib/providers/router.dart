import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/models/product.dart';

// Screens
import 'package:details_app/screens/home/main_screen.dart';
import 'package:details_app/screens/home/home_page.dart';
import 'package:details_app/screens/home/search_screen.dart';
import 'package:details_app/screens/home/cart_screen.dart';
import 'package:details_app/screens/home/product_details_screen.dart';
import 'package:details_app/screens/login/login_screen.dart';
import 'package:details_app/screens/login/register_screen.dart';
import 'package:details_app/screens/home/checkout_screen.dart';
import 'package:details_app/screens/home/orders_screen.dart';
import 'package:details_app/screens/home/about_screen.dart';
import 'package:details_app/screens/home/wishlist_screen.dart';
import 'package:details_app/screens/login/account_screen.dart';
import 'package:details_app/screens/splash/splash_screen.dart';
import 'package:details_app/screens/login/reset_password_screen.dart';
import 'package:details_app/screens/login/otp_verification_screen.dart';

// Admin Screens
import 'package:details_app/screens/admin/admin_dashboard_screen.dart';
import 'package:details_app/screens/admin/manage_products_screen.dart';
import 'package:details_app/screens/admin/add_edit_product_screen.dart';
import 'package:details_app/screens/admin/manage_users_screen.dart';
import 'package:details_app/screens/admin/manage_categories_screen.dart';
import 'package:details_app/screens/admin/manage_coupons_screen.dart';
import 'package:details_app/screens/admin/manage_banners_screen.dart';

import 'package:details_app/screens/admin/admin_orders_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wishlist',
              builder: (context, state) => const WishlistScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
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
      path: '/product/:id',
      builder: (context, state) {
        final product = state.extra as Product?;
        final id = state.pathParameters['id'];
        return ProductDetailsScreen(productId: id, product: product);
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final userData = state.extra as Map<String, String>;
        return OtpVerificationScreen(userData: userData);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(
      path: '/reset-password/:token',
      builder: (context, state) {
        final token = state.pathParameters['token'] ?? '';
        return ResetPasswordScreen(token: token);
      },
    ),
    // Admin Routes
    GoRoute(
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
