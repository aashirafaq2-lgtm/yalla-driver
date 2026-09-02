import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';

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
    final driverName = auth.driverName;
    final trips = auth.totalTrips;
    final hours = (trips * 0.8).round().clamp(1, 999);
    final walletStr = '${auth.walletBalance.toStringAsFixed(0)} IQD';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
                        const Text(
                          'Welcome',
                          style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w400),
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
                      _buildStatItem(Icons.timer_outlined, '$hours', 'Hours'),
                      Container(height: 45, width: 1, color: Colors.black12),
                      _buildStatItem(Icons.directions_car_outlined, '$trips', 'Trips'),
                      Container(height: 45, width: 1, color: Colors.black12),
                      _buildStatItem(Icons.account_balance_wallet_outlined, walletStr, 'Wallet'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Menu Items ────────────────────────────────────────────
              _buildMenuItem(context, Icons.credit_card_outlined, 'Payment method', '/payment', 0),
              _buildMenuItem(context, Icons.person_pin_outlined, 'Trip History', '/trips', 100),
              _buildMenuItem(context, Icons.person_pin_circle_outlined, 'My Scheduled Trips', '/schedule', 200),
              _buildMenuItem(context, Icons.language, 'Language', '/language', 300),
              _buildMenuItem(context, Icons.inventory_2_outlined, 'Mail & Parcel', '/mail_parcels', 400),
              _buildMenuItem(context, Icons.support_agent_outlined, 'Support & Help', '/support', 500),
              _buildActionItem(
                context, 
                Icons.privacy_tip_outlined, 
                'Privacy Policy', 
                Colors.black87, 
                () => _showPrivacyPolicyDialog(context),
                600,
              ),
              _buildActionItem(
                context, 
                Icons.logout, 
                'Log Out', 
                Colors.black87, 
                () => _showLogoutDialog(context, auth),
                700,
              ),
              _buildActionItem(
                context, 
                Icons.delete_forever_outlined, 
                'Delete Account', 
                Colors.red.shade700, 
                () => _showDeleteAccountDialog(context, auth),
                800,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 26),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String? route, int delayMs) {
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
          onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
          leading: Icon(icon, color: Colors.black87, size: 22),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap, int delayMs) {
    return FadeInUp(
      delay: Duration(milliseconds: delayMs),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color == Colors.black87 ? Colors.black.withOpacity(0.08) : Colors.red.withOpacity(0.2)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color, size: 22),
          title: Text(
            title, 
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: color),
          ),
          trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Yalla Driver respects your privacy and is committed to protecting your personal data.\n\n'
            '1. Location Data: We collect precise location data in foreground and background to connect you with nearby passengers and provide navigation during trips.\n\n'
            '2. Profile Information: We collect your name, phone number, vehicle details, and documents for driver verification.\n\n'
            '3. Data Deletion: You can permanently delete your account and all associated data at any time from this screen.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your driver account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
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
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account?\n\n'
          '• Your profile, documents, and vehicle details will be permanently removed.\n'
          '• Your trip history and wallet data will be deleted.\n'
          '• This action is permanent and cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Dismiss confirmation dialog
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );

              final success = await auth.deleteAccount();
              
              if (context.mounted) {
                Navigator.pop(context); // Dismiss loading dialog

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account has been deleted successfully.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete account. Please try again or contact support.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
