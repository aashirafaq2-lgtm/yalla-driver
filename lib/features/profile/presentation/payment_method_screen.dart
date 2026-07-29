import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Payment method',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // ── Balance Card ─────────────────────────────────────────
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Current balance',
                      style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '10,000 IQD',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Add Funds Button ──────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/add_credit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '+ Add funds',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── IQ Card Row ───────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, '/card_code'),
                  leading: const Icon(Icons.card_giftcard_outlined, color: AppColors.primaryOrange, size: 24),
                  title: const Text(
                    'Yalla Card',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
