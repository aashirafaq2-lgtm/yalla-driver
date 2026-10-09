import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/driver_locale_provider.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.chevron_right : Icons.chevron_left,
            color: AppColors.primaryOrange,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          locale.tr('payment_method'),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // ── Premium Balance Card ─────────────────────────────────
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale.tr('current_balance'),
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'IQD',
                            style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${auth.walletBalance.toStringAsFixed(0)} IQD',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    locale.tr('add_funds'),
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              locale.tr('wallet'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // ── Method 1: Yalla Gift Card ──────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, '/card_code'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_outlined, color: AppColors.primaryOrange, size: 24),
                  ),
                  title: Text(
                    locale.tr('yalla_card'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  subtitle: Text(
                    isArabic ? 'استبدال رمز القسيمة الرسمية' : 'Redeem official voucher code',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right, color: Colors.black45),
                ),
              ),
            ),

            // ── Method 2: ZainCash ─────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, '/add_credit'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.purple, size: 24),
                  ),
                  title: Text(
                    locale.tr('zain_cash'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  subtitle: Text(
                    isArabic ? 'شحن فوري عبر المحفظة الرقمية' : 'Instant mobile wallet topup',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right, color: Colors.black45),
                ),
              ),
            ),

            // ── Method 3: AsiaHawala ───────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 450),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: ListTile(
                  onTap: () => Navigator.pushNamed(context, '/add_credit'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined, color: Colors.red, size: 24),
                  ),
                  title: Text(
                    locale.tr('asia_hawala'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  subtitle: Text(
                    isArabic ? 'إيداع سريع عبر الوكيل' : 'Fast agent deposit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                  ),
                  trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
