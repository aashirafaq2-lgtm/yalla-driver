import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriverLocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'driver_language_code';
  final _storage = const FlutterSecureStorage();
  Locale _locale = const Locale('ar');

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

  void toggleLocale() {
    setLocale(_locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation & General
      'home': 'Home',
      'rides': 'Rides',
      'profile': 'Profile',
      'welcome': 'Welcome, Captain',
      'driver': 'Driver',
      'app_name': 'Yalla',

      // Status
      'you_are_online': 'YOU ARE ONLINE',
      'ready_for_rides': 'Ready for rides',
      'you_are_offline': 'YOU ARE OFFLINE',
      'go_online': 'Go Online',
      'active_ride': 'ACTIVE RIDE',
      'driving_to_passenger': 'Driving to passenger',
      'arrived_at_pickup': 'Arrived at pickup',
      'trip_in_progress': 'Trip in progress',
      'return_to_ride': 'Return to Active Ride',
      'no_trip_requests': 'No Trip Requests Yet',
      'waiting_for_requests': 'Stay online to receive ride requests from passengers near you.',

      // Menu Cards
      'available_trips': 'Available Trips',
      'schedule_trip': 'Schedule Trip',
      'mail_parcel': 'Mail & Parcel',
      'booking': 'Booking',
      'outside_governorate': 'Outside Governorate',
      'intercity_booking': 'Intercity Booking',

      // Profile
      'hours': 'Hours',
      'trips': 'Trips',
      'wallet': 'Wallet',
      'payment_method': 'Payment Method & Wallet',
      'trip_history': 'Trip History & Earnings',
      'my_scheduled_trips': 'My Scheduled Trips',
      'language': 'Language Preferences',
      'support_help': 'Support & Help',
      'privacy_policy': 'Privacy Policy',
      'account_management': 'ACCOUNT MANAGEMENT',
      'log_out': 'Log Out',
      'delete_account': 'Delete Account',
      'english': 'English',
      'arabic': 'العربية (Arabic)',
      'select_language': 'Select Language',
      'notifications': 'Notifications',

      // Wallet & Payment
      'current_balance': 'Current Balance',
      'add_funds': '+ Add Funds',
      'yalla_card': 'Yalla Gift Card',
      'zain_cash': 'ZainCash Mobile Wallet',
      'asia_hawala': 'AsiaHawala Wallet',
      'commission': 'Yalla Commission (15%)',
      'net_earning': 'Driver Net Earning',
      'total_fare': 'Total Ride Fare',

      // Trip History
      'no_trips': 'No trip history found',
      'no_scheduled': 'No scheduled intercity trips found',
      'create_schedule': 'Schedule New Intercity Trip',
      'from': 'From',
      'to': 'To',
      'date': 'Date',
      'price': 'Price',
      'seats': 'Seats',
      'per_seat': 'per seat',
      'status': 'Status',
      'bookings': 'Bookings',
      'passengers': 'Passengers',
      'no_bookings': 'No passengers booked yet',

      // Common Actions
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'ok': 'OK',
      'save': 'Save',
      'back': 'Back',
      'close': 'Close',
      'retry': 'Retry',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'yes': 'Yes',
      'no': 'No',

      // Auth
      'sign_in': 'Sign In',
      'sign_up': 'Create Account',
      'enter_phone': 'Enter your phone number to continue',
      'send_otp': 'Send Verification Code',
      'verify_phone': 'Verify Phone Number',
      'enter_otp': 'Enter the verification code sent to your number',
      'confirm_code': 'Confirm Code',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'email': 'Email Address',
      'car_type': 'Car Type',
      'car_model': 'Car Model',
      'car_color': 'Car Color',
      'plate_number': 'Plate Number',
      'car_year': 'Car Year',
      'vehicle_info': 'Vehicle Information',
      'personal_info': 'Personal Information',
      'next': 'Next',
      'submit': 'Submit',
      'resend_code': 'Resend Code',

      // Ride Actions
      'arrived_pickup': 'Arrived at Pickup',
      'verify_pin_start': 'Verify PIN & Start Trip',
      'finish_trip': 'Finish Trip',
      'trip_completed': 'Trip Completed',
      'cancel_trip': 'Cancel Trip',
      'call_passenger': 'Call Passenger',
      'copy_number': 'Copy Number',
      'dismiss': 'Dismiss',
      'distance_alert': 'Distance Alert',
      'confirm_arrival': 'Confirm Arrival',
      'verify_passenger_pin': 'Verify Passenger Security PIN',
      'enter_4digit_pin': 'Enter the 4-digit code from the passenger',
      'verify_start': 'Verify & Start',
      'invalid_pin': 'Invalid PIN code. Please confirm with passenger.',
      'pin_must_4digits': 'Code must be 4 digits',
      'pin_verified': 'PIN Verified! Trip started.',
      'trip_cancelled': 'Ride Cancelled',
      'passenger_cancelled': 'The passenger has cancelled this ride.',
      'total_earnings': 'Total Fare',
      'platform_fee': 'Platform Fee (15%)',
      'your_net': 'Your Net Earnings',
      'back_dashboard': 'Back to Dashboard',
      'select_cancel_reason': 'Please select cancellation reason:',
      'phone_copied': 'Copied phone number',
      'iqd': 'IQD',
      'min': 'min',
      'km': 'km',

      // Parcels
      'no_parcels': 'No parcel orders found',
      'parcel_orders': 'Parcel Orders',
      'sender': 'Sender',
      'receiver': 'Receiver',
      'parcel_type': 'Parcel Type',
      'delivery_address': 'Delivery Address',
      'accept_order': 'Accept Order',
      'delivering': 'Delivering',
      'delivered': 'Delivered',

      // Schedule Trip
      'schedule_new_trip': 'Schedule New Trip',
      'departure_time': 'Departure Time',
      'available_seats': 'Available Seats',
      'price_per_seat': 'Price Per Seat',
      'select_from': 'Select Departure City',
      'select_to': 'Select Destination City',
      'create_trip': 'Create Trip',
      'trip_created': 'Trip created successfully!',
      'scheduled': 'Scheduled',
      'completed': 'Completed',
      'cancelled': 'Cancelled',

      // Verification
      'pending_verification': 'Pending Verification',
      'account_under_review': 'Your account is under review. We will notify you once it is approved.',
      'contact_support': 'Contact Support',
      'delete_permanently': 'Delete Permanently',
    },
    'ar': {
      // Navigation & General
      'home': 'الرئيسية',
      'rides': 'الرحلات',
      'profile': 'الملف الشخصي',
      'welcome': 'أهلاً بك كابتن',
      'driver': 'السائق',
      'app_name': 'يَلَّا',

      // Status
      'you_are_online': 'أنت متصل الآن',
      'ready_for_rides': 'جاهز لاستقبال الرحلات',
      'you_are_offline': 'أنت غير متصل',
      'go_online': 'الاتصال بالتطبيق',
      'active_ride': 'رحلة جارية',
      'driving_to_passenger': 'في الطريق إلى الراكب',
      'arrived_at_pickup': 'وصلت إلى نقطة الانطلاق',
      'trip_in_progress': 'الرحلة جارية',
      'return_to_ride': 'العودة للرحلة الحالية',
      'no_trip_requests': 'لا توجد طلبات رحلات حالياً',
      'waiting_for_requests': 'ابقَ متصلاً لاستقبال طلبات الرحلات من الركاب القريبين منك.',

      // Menu Cards
      'available_trips': 'الرحلات المتاحة',
      'schedule_trip': 'رحلة مجدولة',
      'mail_parcel': 'البريد والطرود',
      'booking': 'حجز',
      'outside_governorate': 'خارج المحافظة',
      'intercity_booking': 'حجز بين المحافظات',

      // Profile
      'hours': 'ساعات العمل',
      'trips': 'إجمالي الرحلات',
      'wallet': 'المحفظة المالية',
      'payment_method': 'طرق الدفع والمحفظة',
      'trip_history': 'سجل الرحلات والأرباح',
      'my_scheduled_trips': 'رحلاتي المجدولة',
      'language': 'اللغة والتفضيلات',
      'support_help': 'الدعم والمساعدة',
      'privacy_policy': 'سياسة الخصوصية',
      'account_management': 'إدارة الحساب',
      'log_out': 'تسجيل الخروج',
      'delete_account': 'حذف الحساب',
      'english': 'English (الإنجليزية)',
      'arabic': 'العربية',
      'select_language': 'اختر اللغة',
      'notifications': 'الإشعارات',

      // Wallet & Payment
      'current_balance': 'الرصيد الحالي',
      'add_funds': '+ إضـافة رصـيد',
      'yalla_card': 'بطـاقة كرت يلّـا',
      'zain_cash': 'محفـظة زين كاش الرقمية',
      'asia_hawala': 'محفظة آسيا حوالة',
      'commission': 'عمولة التطبيق (15%)',
      'net_earning': 'صافي أرباح السائق',
      'total_fare': 'إجمالي أجرة الرحلة',

      // Trip History
      'no_trips': 'لا يوجد سجل رحلات حالياً',
      'no_scheduled': 'لا توجد رحلات مجدولة حالياً',
      'create_schedule': 'إنشاء رحلة مجدولة بين المحافظات',
      'from': 'من',
      'to': 'إلى',
      'date': 'التاريخ',
      'price': 'السعر',
      'seats': 'المقاعد',
      'per_seat': 'لكل مقعد',
      'status': 'الحالة',
      'bookings': 'الحجوزات',
      'passengers': 'الركاب',
      'no_bookings': 'لم يحجز أحد بعد',

      // Common Actions
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'ok': 'موافق',
      'save': 'حفظ',
      'back': 'رجوع',
      'close': 'إغلاق',
      'retry': 'إعادة المحاولة',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'warning': 'تنبيه',
      'yes': 'نعم',
      'no': 'لا',

      // Auth
      'sign_in': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'enter_phone': 'أدخل رقم هاتفك للمتابعة',
      'send_otp': 'إرسال رمز التحقق',
      'verify_phone': 'تأكيد رقم الهاتف',
      'enter_otp': 'أدخل رمز التحقق المرسل إلى رقمك',
      'confirm_code': 'تأكيد الرمز',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'email': 'البريد الإلكتروني',
      'car_type': 'نوع السيارة',
      'car_model': 'موديل السيارة',
      'car_color': 'لون السيارة',
      'plate_number': 'رقم اللوحة',
      'car_year': 'سنة الصنع',
      'vehicle_info': 'معلومات المركبة',
      'personal_info': 'المعلومات الشخصية',
      'next': 'التالي',
      'submit': 'إرسال',
      'resend_code': 'إعادة إرسال الرمز',

      // Ride Actions
      'arrived_pickup': 'وصلت لنقطة الانطلاق',
      'verify_pin_start': 'تأكيد الرمز وبدء الرحلة',
      'finish_trip': 'إنهاء الرحلة',
      'trip_completed': 'اكتملت الرحلة',
      'cancel_trip': 'إلغاء الرحلة',
      'call_passenger': 'الاتصال بالراكب',
      'copy_number': 'نسخ الرقم',
      'dismiss': 'رجوع',
      'distance_alert': 'تنبيه المسافة',
      'confirm_arrival': 'تأكيد الوصول',
      'verify_passenger_pin': 'تأكيد رمز أمان الراكب',
      'enter_4digit_pin': 'أدخل الرمز المكون من 4 أرقام من الراكب',
      'verify_start': 'تحقق وابدأ',
      'invalid_pin': 'رمز التحقق غير صحيح، يرجى التأكد من الراكب',
      'pin_must_4digits': 'الرمز يجب أن يتكون من 4 أرقام',
      'pin_verified': 'تم تأكيد الرمز وبدأت الرحلة!',
      'trip_cancelled': 'تم إلغاء الرحلة',
      'passenger_cancelled': 'قام الراكب بإلغاء هذه الرحلة.',
      'total_earnings': 'إجمالي الأجرة',
      'platform_fee': 'عمولة المنصة (15%)',
      'your_net': 'صافي أرباحك',
      'back_dashboard': 'العودة للرئيسية',
      'select_cancel_reason': 'يرجى اختيار سبب الإلغاء:',
      'phone_copied': 'تم نسخ رقم الهاتف',
      'iqd': 'د.ع',
      'min': 'دقيقة',
      'km': 'كم',

      // Parcels
      'no_parcels': 'لا توجد طلبات طرود حالياً',
      'parcel_orders': 'طلبات الطرود',
      'sender': 'المرسل',
      'receiver': 'المستلم',
      'parcel_type': 'نوع الطرد',
      'delivery_address': 'عنوان التسليم',
      'accept_order': 'قبول الطلب',
      'delivering': 'جاري التوصيل',
      'delivered': 'تم التسليم',

      // Schedule Trip
      'schedule_new_trip': 'إنشاء رحلة مجدولة',
      'departure_time': 'وقت الانطلاق',
      'available_seats': 'المقاعد المتاحة',
      'price_per_seat': 'السعر لكل مقعد',
      'select_from': 'اختر مدينة الانطلاق',
      'select_to': 'اختر مدينة الوصول',
      'create_trip': 'إنشاء الرحلة',
      'trip_created': 'تم إنشاء الرحلة بنجاح!',
      'scheduled': 'مجدولة',
      'completed': 'مكتملة',
      'cancelled': 'ملغية',

      // Verification
      'pending_verification': 'في انتظار المراجعة',
      'account_under_review': 'حسابك قيد المراجعة. سنُخطرك فور الموافقة عليه.',
      'contact_support': 'تواصل مع الدعم',
      'delete_permanently': 'حذف نهائياً',
    },
  };

  String tr(String key) {
    final lang = _locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
