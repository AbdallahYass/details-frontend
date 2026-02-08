import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'DETAILS',
      'search': 'Search',
      'cart': 'Cart',
      'menu': 'Menu',
      'top_announcement_1': 'Free shipping for orders over 500 NIS',
      'top_announcement_2': '20% off on new watch collection',
      'top_announcement_3': 'Flexible exchange policy within 14 days',
      'categories': 'Categories',
      'bags': 'Bags',
      'watches': 'Watches',
      'accessories': 'Accessories',
      'most_popular': 'Most Popular',
      'best_seller_week': 'Best sellers this week',
      'view_all': 'View All',
      'sold_out': 'Sold Out',
      'currency': 'NIS',
      'footer_about_title': 'Who are we?',
      'footer_about_desc':
          'Details launched to be the premier destination for luxury bags and watches. We care about the finest details to offer pieces that reflect your refined taste.',
      'shortcuts': 'Shortcuts',
      'women': 'Women',
      'men': 'Men',
      'wallets': 'Wallets',
      'policies': 'Our Policies',
      'policy_cancel': 'Cancellation Policy',
      'policy_return': 'Return Policy',
      'policy_shipping': 'Shipping Policy',
      'stay_updated': 'Stay Updated',
      'subscribe_text':
          'Subscribe to receive the latest offers and products via email',
      'subscribe_button': 'Subscribe',
      'email_hint': 'Your Email',
      'copyright': 'Copyright all rights reserved © 2026 Details',
      'dev_credit':
          'Designed and Developed by Rowad || Integrated Web Solutions',
      'nav_search': 'Search',
      'nav_account': 'Account',
      'nav_cart': 'Cart',
      'nav_wishlist': 'Wishlist',
      'nav_shop': 'Shop',
      'add_to_cart': 'Add to Shopping Bag',
      'product_desc': 'Product Description',
      'dimensions': 'Dimensions & Sizes',
      'no_desc': 'No description available.',
      'discover_details': 'Discover Details',
      'you_might_like': 'You might also like',
    },
    'ar': {
      'app_title': 'DETAILS',
      'search': 'بحث',
      'cart': 'السلة',
      'menu': 'القائمة',
      'top_announcement_1': 'توصيل مجاني للطلبات فوق 500 شيكل',
      'top_announcement_2': 'خصم 20% على تشكيلة الساعات الجديدة',
      'top_announcement_3': 'سياسة استبدال مرنة خلال 14 يوماً',
      'categories': 'أصنافنا',
      'bags': 'حقائب',
      'watches': 'ساعات',
      'accessories': 'إكسسوارات',
      'most_popular': 'الأكثر شيوعاً',
      'best_seller_week': 'الأكثر مبيعاً هذا الأسبوع',
      'view_all': 'عرض الكل',
      'sold_out': 'بيعت كلها',
      'currency': 'شيكل',
      'footer_about_title': 'من نحن ؟',
      'footer_about_desc':
          'ديتيلز انطلق ليكون الوجهة الأولى للحقائب والساعات الفاخرة، نهتم بأدق التفاصيل لنقدم لكم قطعاً تعكس ذوقكم الرفيع.',
      'shortcuts': 'اختصارات',
      'women': 'النساء',
      'men': 'الرجال',
      'wallets': 'المحافظ',
      'policies': 'سياساتنا',
      'policy_cancel': 'سياسة إلغاء الطلب',
      'policy_return': 'سياسة الإرجاع',
      'policy_shipping': 'سياسة الشحن',
      'stay_updated': 'ابق على إطلاع',
      'subscribe_text': 'إشترك لتصل آخر العروض والمنتجات عبر بريدك الإلكتروني',
      'subscribe_button': 'إشتراك',
      'email_hint': 'بريدك الإلكتروني',
      'copyright': 'Copyright all rights reserved © 2026 Details',
      'dev_credit': 'تصميم و تطوير رواد || لخدمات وحلول الويب المتكاملة',
      'nav_search': 'بحث',
      'nav_account': 'الحساب',
      'nav_cart': 'السلة',
      'nav_wishlist': 'الأمنيات',
      'nav_shop': 'تسوق',
      'add_to_cart': 'إضافة إلى حقيبة التسوق',
      'product_desc': 'وصف المنتج',
      'dimensions': 'الأبعاد والمقاسات',
      'no_desc': 'لا يوجد وصف متاح حالياً.',
      'discover_details': 'اكتشف ديتيلز',
      'you_might_like': 'قد يعجبك أيضاً',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
