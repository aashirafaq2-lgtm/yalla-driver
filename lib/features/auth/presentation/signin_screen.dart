import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/iq_widgets.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_service.dart';
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

  Future<void> _requestOtp() async {
    _dismissKeyboard();
    final phone = '+964${_phoneController.text.trim()}';
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')));
      return;
    }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: AuthScreenLayout(
        title: 'Sign in',
        onBack: () => Navigator.pop(context),
        bottomButton: IQButton(
          label: _isLoading ? 'Loading...' : 'Next',
          onTap: _isLoading ? () {} : _requestOtp,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            IQPhoneInput(controller: _phoneController),
            const SizedBox(height: 16),
            // Keyboard dismiss hint
            GestureDetector(
              onTap: _dismissKeyboard,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_hide_rounded,
                      size: 17, color: Colors.black38),
                  SizedBox(width: 5),
                  Text(
                    'Tap anywhere to hide keyboard',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have account? ",
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/signup_personal'),
                  child: const Text('Sign up',
                      style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
