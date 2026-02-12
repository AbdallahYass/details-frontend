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
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const StoreHomePage(),
            ),
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
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
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
