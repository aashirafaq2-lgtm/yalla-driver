import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/driver_locale_provider.dart';
import '../../home/presentation/driver_notifications_screen.dart';
import '../../home/presentation/driver_earnings_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;
    final driverName = auth.driverName;
    final trips = auth.totalTrips;
    final hours = (trips * 0.8).round().clamp(1, 999);
    final walletStr = '${auth.walletBalance.toStringAsFixed(0)} ${locale.tr('iqd')}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          locale.tr('profile'),
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: isArabic ? 'ar' : 'en',
                isDense: true,
                icon: const Icon(Icons.language, size: 16, color: AppColors.primaryOrange),
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                ],
                onChanged: (lang) {
                  if (lang != null) locale.setLocale(Locale(lang));
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () => auth.loadProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Avatar + Welcome ──────────────────────────────────────
              FadeInDown(
                child: Row(
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 44, color: AppColors.primaryOrange),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.tr('welcome'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                          ),
                        ),
                        Text(
                          '$driverName!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Stats Card ────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.timer_outlined, '$hours', locale.tr('hours'), isArabic),
                      Container(height: 45, width: 1, color: Colors.black12),
                      _buildStatItem(Icons.directions_car_outlined, '$trips', locale.tr('trips'), isArabic),
                      Container(height: 45, width: 1, color: Colors.black12),
                      _buildStatItem(Icons.account_balance_wallet_outlined, walletStr, locale.tr('wallet'), isArabic),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Menu Items ────────────────────────────────────────────
              _buildMenuItem(context, Icons.account_balance_wallet_outlined, isArabic ? 'أرباح الكابتن والسجل' : 'Driver Earnings & Income', null, 0, isArabic: isArabic, customTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()));
              }),
              _buildMenuItem(context, Icons.notifications_none_rounded, locale.tr('notifications'), '/notifications', 50, isArabic: isArabic, customTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverNotificationsScreen()));
              }),
              _buildMenuItem(context, Icons.credit_card_outlined, locale.tr('payment_method'), '/payment', 100, isArabic: isArabic),
              _buildMenuItem(context, Icons.person_pin_outlined, locale.tr('trip_history'), '/trips', 150, isArabic: isArabic),
              _buildMenuItem(context, Icons.calendar_month_outlined, locale.tr('my_scheduled_trips'), '/my_trips', 200, isArabic: isArabic),
              _buildMenuItem(context, Icons.language, locale.tr('language'), '/language', 250, isArabic: isArabic),
              _buildMenuItem(context, Icons.inventory_2_outlined, locale.tr('mail_parcel'), '/mail_parcels', 300, isArabic: isArabic),
              _buildMenuItem(context, Icons.support_agent_outlined, locale.tr('support_help'), '/support', 350, isArabic: isArabic),
              _buildMenuItem(context, Icons.privacy_tip_outlined, locale.tr('privacy_policy'), null, 400, isArabic: isArabic, customTap: () => _showPrivacyPolicyDialog(context, locale)),


              const SizedBox(height: 24),
              // ── Account Management Header ──
              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: isArabic ? 0 : 4, right: isArabic ? 4 : 0, bottom: 10),
                  child: Text(
                    locale.tr('account_management'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: isArabic ? 0 : 1.2,
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    ),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ),

              _buildActionItem(
                context,
                Icons.logout,
                locale.tr('log_out'),
                Colors.black87,
                () => _showLogoutDialog(context, auth, locale),
                700,
                isArabic: isArabic,
              ),
              _buildActionItem(
                context,
                Icons.delete_forever_rounded,
                locale.tr('delete_account'),
                Colors.red.shade700,
                () => _showDeleteAccountDialog(context, auth, locale),
                800,
                isDelete: true,
                isArabic: isArabic,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, bool isArabic) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 26),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        Text(
          label,
          style: TextStyle(
            color: Colors.black45,
            fontSize: 11,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String? route, int delayMs, {VoidCallback? customTap, bool isArabic = false}) {
    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: ListTile(
          onTap: customTap ?? (route != null ? () => Navigator.pushNamed(context, route) : null),
          leading: Icon(icon, color: Colors.black87, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.black,
              fontFamily: isArabic ? 'NotoKufiArabic' : null,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          trailing: Icon(
            isArabic ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.black45,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
    int delayMs,
    {bool isDelete = false, bool isArabic = false}
  ) {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDelete ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDelete ? Colors.red.withOpacity(0.35) : Colors.black.withOpacity(0.08),
            width: isDelete ? 1.5 : 1.0,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isDelete ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
              color: color,
              fontFamily: isArabic ? 'NotoKufiArabic' : null,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          subtitle: isDelete
              ? Text(
                  isArabic ? 'حذف الحساب وجميع البيانات نهائياً' : 'Permanently delete account and all data',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                  ),
                )
              : null,
          trailing: Icon(
            isArabic ? Icons.chevron_left : Icons.chevron_right,
            color: color.withOpacity(0.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, DriverLocaleProvider locale) {
    final isArabic = locale.isArabic;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Text(
              locale.tr('privacy_policy'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            isArabic
                ? 'تحترم يَلَّا خصوصيتك وتلتزم بحماية بياناتك الشخصية.\n\n'
                  '1. بيانات الموقع: نجمع بيانات الموقع الدقيقة لتوصيلك بالركاب القريبين وتوفير التنقل أثناء الرحلات.\n\n'
                  '2. معلومات الملف الشخصي: نجمع اسمك ورقم هاتفك وتفاصيل مركبتك للتحقق من السائق.\n\n'
                  '3. حذف البيانات: يمكنك حذف حسابك وجميع البيانات المرتبطة به في أي وقت من هذه الشاشة.'
                : 'Yalla Driver respects your privacy and is committed to protecting your personal data.\n\n'
                  '1. Location Data: We collect precise location data in foreground and background to connect you with nearby passengers and provide navigation during trips.\n\n'
                  '2. Profile Information: We collect your name, phone number, vehicle details, and documents for driver verification.\n\n'
                  '3. Data Deletion: You can permanently delete your account and all associated data at any time from this screen.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
              fontFamily: isArabic ? 'NotoKufiArabic' : null,
            ),
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              locale.tr('close'),
              style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, DriverLocaleProvider locale) {
    final isArabic = locale.isArabic;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          locale.tr('log_out'),
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: isArabic ? 'NotoKufiArabic' : null),
        ),
        content: Text(
          isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك كسائق؟' : 'Are you sure you want to log out of your driver account?',
          style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              locale.tr('cancel'),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
              }
            },
            child: Text(
              locale.tr('log_out'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth, DriverLocaleProvider locale) {
    final isArabic = locale.isArabic;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              locale.tr('delete_account'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟\n\n'
                '• سيتم حذف ملفك الشخصي ووثائقك وبيانات مركبتك نهائياً.\n'
                '• سيتم حذف سجل رحلاتك وبيانات محفظتك.\n'
                '• هذا الإجراء دائم ولا يمكن التراجع عنه.'
              : 'Are you sure you want to permanently delete your account?\n\n'
                '• Your profile, documents, and vehicle details will be permanently removed.\n'
                '• Your trip history and wallet data will be deleted.\n'
                '• This action is permanent and cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.tr('cancel'), style: const TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
              final success = await auth.deleteAccount();
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic ? 'تم حذف حسابك بنجاح.' : 'Your account has been deleted successfully.',
                        style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic ? 'فشل حذف الحساب. حاول مرة أخرى أو تواصل مع الدعم.' : 'Failed to delete account. Please try again or contact support.',
                        style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              locale.tr('delete_permanently') ?? (isArabic ? 'حذف نهائياً' : 'Delete Permanently'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
