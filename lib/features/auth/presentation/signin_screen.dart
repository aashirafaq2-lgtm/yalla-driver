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

  Future<void> _requestOtp() async {
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
    return AuthScreenLayout(
      title: 'Sign in',
      onBack: () => Navigator.pop(context),
      bottomButton: IQButton(
        label: _isLoading ? 'Loading...' : 'Next',
        onTap: _isLoading ? () {} : _requestOtp,
      ),
      child: Column(
        children: [
          const SizedBox(height: 120),
          IQPhoneInput(controller: _phoneController),
          const SizedBox(height: 120),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have account? ", style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup_personal'),
                child: const Text('Sign up', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
