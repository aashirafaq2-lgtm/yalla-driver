import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class IQHeader extends StatelessWidget {
  final bool showBack;
  const IQHeader({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Yalla ',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'يَلَّا',
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryOrange,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
