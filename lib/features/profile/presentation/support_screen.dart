import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 100, color: AppColors.primaryOrange),
            const SizedBox(height: 20),
            const Text(
              'How can we help you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Our team is available 24/7 to assist you with any issues or questions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _buildSupportOption(
              context, 
              Icons.chat_bubble_outline, 
              'Live Chat', 
              'Start a conversation now',
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
            const SizedBox(height: 15),
            _buildSupportOption(
              context, 
              Icons.phone_outlined, 
              'Call Center', 
              'Talk to an agent directly',
              onTap: () => _showCallDialog(context),
            ),
            const SizedBox(height: 15),
            _buildSupportOption(
              context, 
              Icons.email_outlined, 
              'Email Support', 
              'Send us your feedback',
              onTap: () => _showEmailDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text('Calling Support...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: const Text('End Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Email Support'),
        content: const Text('Opening your email app to send a message to support@yalla.app'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirm', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
