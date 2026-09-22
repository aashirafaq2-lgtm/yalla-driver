import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/providers/driver_locale_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<DriverLocaleProvider>(context);
    final currentCode = localeProvider.locale.languageCode;

    final List<Map<String, String>> languages = [
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸', 'sub': 'English'},
      {'name': 'العربية', 'code': 'ar', 'flag': '🇮🇶', 'sub': 'Arabic'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          localeProvider.tr('language'), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
          final isSelected = currentCode == lang['code'];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            onTap: () {
              localeProvider.setLocale(Locale(lang['code']!));
            },
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
            title: Text(
              lang['name']!, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.black,
              )
            ),
            subtitle: Text(lang['sub']!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primaryOrange, size: 26)
                : const Icon(Icons.circle_outlined, color: Colors.grey, size: 26),
          );
        },
      ),
    );
  }
}
