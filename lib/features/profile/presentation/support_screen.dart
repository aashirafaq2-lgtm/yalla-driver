import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/driver_locale_provider.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isArabic ? 'مركز الدعم' : 'Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.chevron_right : Icons.chevron_left,
            color: AppColors.primaryOrange,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.support_agent, size: 100, color: AppColors.primaryOrange),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'كيف يمكننا مساعدتك؟' : 'How can we help you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? 'فريقنا متاح على مدار الساعة لمساعدتك في أي مشكلة أو استفسار.'
                    : 'Our team is available 24/7 to assist you with any issues or questions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                ),
              ),
              const SizedBox(height: 40),
              _buildSupportOption(
                context,
                Icons.chat_bubble_outline,
                isArabic ? 'دردشة مباشرة' : 'Live Chat',
                isArabic ? 'ابدأ محادثة الآن' : 'Start a conversation now',
                isArabic: isArabic,
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
              const SizedBox(height: 15),
              _buildSupportOption(
                context,
                Icons.phone_outlined,
                isArabic ? 'مركز الاتصال' : 'Call Center',
                isArabic ? 'تحدث مع وكيل مباشرةً' : 'Talk to an agent directly',
                isArabic: isArabic,
                onTap: () => _showCallDialog(context, isArabic),
              ),
              const SizedBox(height: 15),
              _buildSupportOption(
                context,
                Icons.email_outlined,
                isArabic ? 'دعم البريد الإلكتروني' : 'Email Support',
                isArabic ? 'أرسل لنا ملاحظاتك' : 'Send us your feedback',
                isArabic: isArabic,
                onTap: () => _showEmailDialog(context, isArabic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    required bool isArabic,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryOrange, size: 28),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
        ),
        trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showCallDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_in_talk, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text(
                isArabic ? 'جارٍ الاتصال بالدعم...' : 'Calling Support...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text('+964 770 123 4567', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(150, 45),
                ),
                child: Text(
                  isArabic ? 'إنهاء المكالمة' : 'End Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isArabic ? 'دعم البريد الإلكتروني' : 'Email Support',
            style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
          ),
          content: Text(
            isArabic
                ? 'سيتم فتح تطبيق البريد لإرسال رسالة إلى support@yallataxi.com'
                : 'Opening your email app to send a message to support@yallataxi.com',
            style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isArabic ? 'تأكيد' : 'Confirm',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
