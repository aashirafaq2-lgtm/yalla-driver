import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriverLocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'driver_language_code';
  final _storage = const FlutterSecureStorage();
  Locale _locale = const Locale('ar'); // Default for drivers is Arabic

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  DriverLocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final code = await _storage.read(key: _prefKey) ?? 'ar';
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
      'payment_method': 'Payment method',
      'trip_history': 'Trip History',
      'my_scheduled_trips': 'My Scheduled Trips',
      'language': 'Language',
      'mail_parcel': 'Mail & Parcel',
      'support_help': 'Support & Help',
      'privacy_policy': 'Privacy Policy',
      'account_management': 'ACCOUNT MANAGEMENT',
      'log_out': 'Log Out',
      'delete_account': 'Delete Account',
      'english': 'English',
      'arabic': 'العربية (Arabic)',
      'select_language': 'Select Language',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'welcome': 'أهلاً بك كابتن',
      'driver': 'السائق',
      'hours': 'ساعات',
      'trips': 'رحلات',
      'wallet': 'المحفظة',
      'payment_method': 'طرق الدفع',
      'trip_history': 'سجل الرحلات',
      'my_scheduled_trips': 'رحلاتي المجدولة',
      'language': 'اللغة',
      'mail_parcel': 'البريد والطرود',
      'support_help': 'الدعم والمساعدة',
      'privacy_policy': 'سياسة الخصوصية',
      'account_management': 'إدارة الحساب',
      'log_out': 'تسجيل الخروج',
      'delete_account': 'حذف الحساب',
      'english': 'English (الإنجليزية)',
      'arabic': 'العربية',
      'select_language': 'اختر اللغة',
    }
  };

  String tr(String key) {
    final lang = _locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
