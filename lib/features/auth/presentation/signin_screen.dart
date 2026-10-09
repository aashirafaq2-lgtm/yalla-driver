import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/iq_widgets.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/driver_locale_provider.dart';
import 'otp_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  Future<void> _requestOtp(bool isArabic) async {
    _dismissKeyboard();
    String raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isArabic
                  ? 'يرجى إدخال رقم الهاتف'
                  : 'Please enter your phone number')));
      return;
    }
    raw = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('964')) raw = raw.substring(3);
    if (raw.startsWith('0')) raw = raw.substring(1);
    final phone = '+964$raw';
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final response = await api.login(phone);
      if (response.statusCode == 200 && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(phone: phone),
        ));
      }
    } catch (e) {
      if (mounted) {
        String msg = isArabic
            ? 'فشل إرسال الرمز. يرجى المحاولة مجدداً.'
            : 'Failed to request OTP. Please try again.';
        if (e is DioException) {
          if (e.response?.statusCode == 403) {
            msg = isArabic
                ? 'حسابك غير مسجل. يرجى إنشاء حساب أولاً!'
                : 'Driver account not registered yet. Please sign up first!';
          } else if (e.response?.data != null &&
              e.response?.data['error'] != null) {
            msg = e.response?.data['error'].toString() ?? msg;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            action: e is DioException && e.response?.statusCode == 403
                ? SnackBarAction(
                    label: isArabic ? 'إنشاء حساب' : 'Sign Up',
                    textColor: Colors.white,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/signup_personal'),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: AuthScreenLayout(
        title: locale.tr('sign_in'),
        onBack: () => Navigator.pop(context),
        bottomButton: IQButton(
          label: _isLoading ? locale.tr('loading') : locale.tr('next'),
          onTap: _isLoading ? () {} : () => _requestOtp(isArabic),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            IQPhoneInput(controller: _phoneController),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _dismissKeyboard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_hide_rounded,
                      size: 17, color: Colors.black38),
                  const SizedBox(width: 5),
                  Text(
                    isArabic
                        ? 'اضغط في أي مكان لإخفاء لوحة المفاتيح'
                        : 'Tap anywhere to hide keyboard',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isArabic ? 'ليس لديك حساب؟ ' : "Don't have account? ",
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/signup_personal'),
                  child: Text(
                    isArabic ? 'سجّل الآن' : 'Sign up',
                    style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
