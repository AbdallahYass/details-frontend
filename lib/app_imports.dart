// Dart & Flutter Core
export 'dart:async';
export 'package:flutter/foundation.dart' show kIsWeb;
export 'package:flutter/material.dart';

// Third Party Packages
export 'package:provider/provider.dart';
export 'package:font_awesome_flutter/font_awesome_flutter.dart';
export 'package:go_router/go_router.dart';
export 'package:url_launcher/url_launcher.dart';
export 'package:cached_network_image/cached_network_image.dart';
export 'package:share_plus/share_plus.dart';
export 'package:flutter_cache_manager/flutter_cache_manager.dart';
export 'package:intl/intl.dart' hide TextDirection;
export 'package:visibility_detector/visibility_detector.dart';

// App Constants & Localization
export 'package:details_app/constants/app_colors.dart';
export 'package:details_app/constants/app_constants.dart';
export 'package:details_app/l10n/app_localizations.dart';

// Models & Providers & Repositories
export 'package:details_app/models/product.dart';
export 'package:details_app/models/banner_model.dart';
export 'package:details_app/models/category_model.dart';
export 'package:details_app/providers/wishlist_provider.dart';
export 'package:details_app/providers/settings_provider.dart';
export 'package:details_app/providers/auth_provider.dart';
export 'package:details_app/providers/cart_provider.dart';
export 'package:details_app/providers/orders_provider.dart';
export 'package:details_app/repositories/home_repository.dart';
export 'package:details_app/screens/home/cloudinary_service.dart';

// Widgets
export 'package:details_app/widgets/reveal_on_scroll.dart';
export 'package:details_app/widgets/animated_banner_item.dart';
export 'package:details_app/widgets/animated_product_image.dart';
export 'package:details_app/widgets/common_error_widget.dart';
