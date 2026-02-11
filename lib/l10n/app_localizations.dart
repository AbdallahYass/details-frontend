import 'package:flutter/material.dart';

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
      'top_announcement_1': 'Free shipping on orders over 500 NIS',
      'top_announcement_2': '20% discount on new watch collection',
      'top_announcement_3': 'Flexible exchange policy within 14 days',
      'most_popular': 'Most Popular',
      'best_seller_week': 'Best sellers this week',
      'view_all': 'View All',
      'added_to_wishlist': 'Added to wishlist',
      'removed_from_wishlist': 'Removed from wishlist',
      'sold_out': 'Sold Out',
      'currency': 'NIS',
      'categories': 'Categories',
      'language': 'Language',
      'policies': 'Policies',
      'stay_updated': 'Stay Updated',
      'copyright': 'Copyright all rights reserved © 2026 Details',
      'policy_cancel': 'Cancellation Policy',
      'policy_return': 'Return Policy',
      'policy_shipping': 'Shipping Policy',
      'footer_about_title': 'Who are we?',
      'footer_about_desc':
          'Details launched to be the premier destination for luxury bags and watches.',
      'subscribe_text': 'Subscribe to get the latest offers via email',
      'email_hint': 'Your Email',
      'nav_search': 'Search',
      'nav_account': 'Account',
      'nav_cart': 'Cart',
      'nav_wishlist': 'Wishlist',
      'nav_shop': 'Shop',
      'login_title': 'Welcome Back',
      'login_subtitle': 'Please sign in to continue',
      'email_label': 'Email',
      'password_label': 'Password',
      'login_button': 'Sign In',
      'no_account': 'Don\'t have an account?',
      'create_account_link': 'Create new account',
      'register_title': 'Create Account',
      'register_subtitle': 'Enter your details to register',
      'name_label': 'Full Name',
      'phone_label': 'Phone Number',
      'confirm_password_label': 'Confirm Password',
      'register_button': 'Sign Up',
      'have_account': 'Already have an account?',
      'login_link': 'Sign In',
      'profile_title': 'My Profile',
      'my_orders': 'My Orders',
      'logout': 'Logout',
      'please_login': 'Please login first',
      'enter_email': 'Please enter email',
      'valid_email': 'Please enter valid email',
      'enter_password': 'Please enter password',
      'short_password': 'Password too short',
      'enter_name': 'Please enter name',
      'enter_phone': 'Please enter phone number',
      'passwords_not_match': 'Passwords do not match',
      'account_created': 'Account created successfully, please login',
      'error_occurred': 'An error occurred',
      'product_desc': 'Description',
      'dimensions': 'Dimensions',
      'you_might_like': 'You might also like',
      'add_to_cart': 'Add to Cart',
      'dark_mode': 'Dark Mode',
      'search_hint': 'Search for products...',
      'no_results': 'No results found',
      'start_typing': 'Start typing to search',
      'empty_wishlist': 'Your wishlist is empty',
      'total': 'Total',
      'checkout': 'Checkout',
      'payment_soon': 'Payment will be enabled soon!',
      'cart_empty': 'Your cart is empty',
      'start_shopping': 'Start Shopping',
      'shipping_info': 'Shipping Information',
      'city': 'City',
      'street': 'Street / Address',
      'phone': 'Phone Number',
      'confirm_order': 'Confirm Order',
      'order_success': 'Order placed successfully',
      'order_failed': 'Failed to place order',
      'required_field': 'Required field',
      'payment_method': 'Payment Method',
      'cash_on_delivery': 'Cash on Delivery',
      'credit_card': 'Credit Card',
    },
    'ar': {
      'top_announcement_1': 'توصيل مجاني للطلبات فوق 500 شيكل',
      'top_announcement_2': 'خصم 20% على تشكيلة الساعات الجديدة',
      'top_announcement_3': 'سياسة استبدال مرنة خلال 14 يوماً',
      'most_popular': 'الأكثر شيوعاً',
      'best_seller_week': 'الأكثر مبيعاً هذا الأسبوع',
      'view_all': 'عرض الكل',
      'added_to_wishlist': 'تمت الإضافة للمفضلة',
      'removed_from_wishlist': 'تم الحذف من المفضلة',
      'sold_out': 'بيعت كلها',
      'currency': 'شيكل',
      'categories': 'أصنافنا',
      'language': 'اللغة',
      'policies': 'سياساتنا',
      'stay_updated': 'ابق على إطلاع',
      'copyright': 'Copyright all rights reserved © 2026 Details',
      'policy_cancel': 'سياسة إلغاء الطلب',
      'policy_return': 'سياسة الإرجاع',
      'policy_shipping': 'سياسة الشحن',
      'footer_about_title': 'من نحن ؟',
      'footer_about_desc':
          'ديتيلز انطلق ليكون الوجهة الأولى للحقائب والساعات الفاخرة، نهتم بأدق التفاصيل لنقدم لكم قطعاً تعكس ذوقكم الرفيع.',
      'subscribe_text': 'إشترك لتصل آخر العروض والمنتجات عبر بريدك الإلكتروني',
      'email_hint': 'بريدك الإلكتروني',
      'nav_search': 'بحث',
      'nav_account': 'الحساب',
      'nav_cart': 'السلة',
      'nav_wishlist': 'الأمنيات',
      'nav_shop': 'تسوق',
      'login_title': 'مرحباً بعودتك',
      'login_subtitle': 'الرجاء تسجيل الدخول للمتابعة',
      'email_label': 'البريد الإلكتروني',
      'password_label': 'كلمة المرور',
      'login_button': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب؟',
      'create_account_link': 'إنشاء حساب جديد',
      'register_title': 'إنشاء حساب جديد',
      'register_subtitle': 'أدخل بياناتك للتسجيل',
      'name_label': 'الاسم الكامل',
      'phone_label': 'رقم الهاتف',
      'confirm_password_label': 'تأكيد كلمة المرور',
      'register_button': 'تسجيل حساب جديد',
      'have_account': 'لديك حساب بالفعل؟',
      'login_link': 'تسجيل الدخول',
      'profile_title': 'ملفي الشخصي',
      'my_orders': 'طلباتي',
      'logout': 'تسجيل الخروج',
      'please_login': 'الرجاء تسجيل الدخول أولاً',
      'enter_email': 'الرجاء إدخال البريد الإلكتروني',
      'valid_email': 'الرجاء إدخال بريد إلكتروني صحيح',
      'enter_password': 'الرجاء إدخال كلمة المرور',
      'short_password': 'كلمة المرور قصيرة جداً',
      'enter_name': 'الرجاء إدخال الاسم',
      'enter_phone': 'الرجاء إدخال رقم الهاتف',
      'passwords_not_match': 'كلمات المرور غير متطابقة',
      'account_created': 'تم إنشاء الحساب بنجاح، يرجى تسجيل الدخول',
      'error_occurred': 'حدث خطأ ما',
      'product_desc': 'الوصف',
      'dimensions': 'الأبعاد',
      'you_might_like': 'قد يعجبك أيضاً',
      'add_to_cart': 'إضافة للسلة',
      'dark_mode': 'الوضع الداكن',
      'search_hint': 'ابحث عن المنتجات...',
      'no_results': 'لا توجد نتائج',
      'start_typing': 'ابدأ الكتابة للبحث',
      'empty_wishlist': 'قائمة الأمنيات فارغة',
      'total': 'المجموع',
      'checkout': 'إتمام الطلب',
      'payment_soon': 'سيتم تفعيل الدفع قريباً!',
      'cart_empty': 'السلة فارغة',
      'start_shopping': 'ابدأ التسوق',
      'shipping_info': 'معلومات الشحن',
      'city': 'المدينة',
      'street': 'الشارع / العنوان',
      'phone': 'رقم الهاتف',
      'confirm_order': 'تأكيد الطلب',
      'order_success': 'تم الطلب بنجاح',
      'order_failed': 'فشل في إتمام الطلب',
      'required_field': 'حقل مطلوب',
      'payment_method': 'طريقة الدفع',
      'cash_on_delivery': 'دفع عند الاستلام',
      'credit_card': 'بطاقة ائتمان',
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
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
