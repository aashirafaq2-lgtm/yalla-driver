import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/iq_widgets.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/socket_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String? phone;
  const OTPVerificationScreen({super.key, this.phone});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Focus on first OTP field after screen loads
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();
  String get _phone => widget.phone ?? '07701234567';

  Future<void> _verifyOtp() async {
    if (_otp.length < 4) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final socket = Provider.of<SocketService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);

      final success = await authProvider.verifyOtp(_phone, _otp);
      
      final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['vehicleName'] != null) {
        await authProvider.registerVehicle(
          carName: args['vehicleName'],
          seats: args['seats'] ?? 4,
          carNumber: args['carNumber'] ?? 'IQ-1234',
        );
      }

      final userId = await storage.getUserId();
      if (userId != null) {
        socket.authenticate(userId);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/success');
      }
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/success');
      }
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
        label: _isLoading ? 'Verifying...' : 'Confirm',
        onTap: _verifyOtp,
      ),
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              'Enter Code verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) => Container(
                width: 70,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 3) _focusNodes[i + 1].requestFocus();
                      if (val.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                      if (_otp.length == 4) _verifyOtp();
                    },
                  ),
                ),
              )),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

