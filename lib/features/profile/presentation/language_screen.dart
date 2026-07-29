import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'name': 'English', 'flag': '🇺🇸'},
      {'name': 'العربية', 'flag': '🇮🇶'},
      {'name': 'Kurdî', 'flag': '☀️'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: languages.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final lang = languages[index];
          return ListTile(
            onTap: () => Navigator.pop(context),
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(lang['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            trailing: index == 1 // Default Arabic
                ? Icon(Icons.check_circle, color: AppColors.primaryOrange)
                : const Icon(Icons.circle_outlined, color: Colors.grey),
          );
        },
      ),
    );
  }
}
