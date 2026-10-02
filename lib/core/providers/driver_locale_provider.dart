import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriverLocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'driver_language_code';
  final _storage = const FlutterSecureStorage();
  Locale _locale = const Locale('en'); // Default for drivers is English (LTR)

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  DriverLocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final code = await _storage.read(key: _prefKey) ?? 'en';
      _locale = Locale(code);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['en', 'ar'].contains(newLocale.languageCode)) return;
    _locale = newLocale;
    notifyListeners();
    try {
      await _storage.write(key: _prefKey, value: newLocale.languageCode);
    } catch (_) {}
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'profile': 'Profile',
      'welcome': 'Welcome',
      'driver': 'Driver',
      'hours': 'Hours',
      'trips': 'Trips',
      'wallet': 'Wallet',
      'payment_method': 'Payment Method & Wallet',
      'trip_history': 'Trip History & Earnings',
      'my_scheduled_trips': 'My Scheduled Trips',
      'language': 'Language Preferences',
      'mail_parcel': 'Mail & Parcel',
      'support_help': 'Support & Help',
      'privacy_policy': 'Privacy Policy',
      'account_management': 'ACCOUNT MANAGEMENT',
      'log_out': 'Log Out',
      'delete_account': 'Delete Account',
      'english': 'English',
      'arabic': 'العربية (Arabic)',
      'select_language': 'Select Language',
      'current_balance': 'Current Balance',
      'add_funds': '+ Add Funds',
      'yalla_card': 'Yalla Gift Card',
      'zain_cash': 'ZainCash Mobile Wallet',
      'asia_hawala': 'AsiaHawala Wallet',
      'commission': 'Yalla Commission (15%)',
      'net_earning': 'Driver Net Earning',
      'total_fare': 'Total Ride Fare',
      'no_trips': 'No trip history found',
      'no_scheduled': 'No scheduled intercity trips found',
      'create_schedule': 'Schedule New Intercity Trip',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'welcome': 'أهلاً بك كابتن',
      'driver': 'السائق',
      'hours': 'ساعات العمل',
      'trips': 'إجمالي الرحلات',
      'wallet': 'المحفظة المالية',
      'payment_method': 'طرق الدفع والمحفظة',
      'trip_history': 'سجل الرحلات والأرباح',
      'my_scheduled_trips': 'رحلاتي المجدولة',
      'language': 'اللغة والتفضيلات',
      'mail_parcel': 'البريد والطرود',
      'support_help': 'الدعم والمساعدة',
      'privacy_policy': 'سياسة الخصوصية',
      'account_management': 'إدارة الحساب',
      'log_out': 'تسجيل الخروج',
      'delete_account': 'حذف الحساب',
      'english': 'English (الإنجليزية)',
      'arabic': 'العربية',
      'select_language': 'اختر اللغة',
      'current_balance': 'الرصيد الحالي',
      'add_funds': '+ إضـافة رصـيد',
      'yalla_card': 'بطـاقة كرت يلّـا',
      'zain_cash': 'محفـظة زين كاش الرقمية',
      'asia_hawala': 'محفظة آسيا حوالة',
      'commission': 'عمولة التطبيق (15%)',
      'net_earning': 'صافي أرباح السائق',
      'total_fare': 'إجمالي أجرة الرحلة',
      'no_trips': 'لا يوجد سجل رحلات حالياً',
      'no_scheduled': 'لا توجد رحلات مجدولة حالياً',
      'create_schedule': 'إنشاء رحلة مجدولة بين المحافظات',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
    }
  };

  String tr(String key) {
    final lang = _locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
