import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/driver_locale_provider.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() => _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final token = await storage.getToken();

      if (token != null) {
        final res = await api.getNotifications(token);
        if (res.statusCode == 200 && mounted) {
          setState(() {
            _notifications = res.data['notifications'] ?? [];
            _isLoading = false;
          });
          api.markNotificationsRead(token);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }

    if (mounted && _notifications.isEmpty) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'RIDE_REQUEST':
      case 'RIDE':
        return Icons.local_taxi_rounded;
      case 'EARNINGS':
      case 'PAYOUT':
        return Icons.account_balance_wallet_rounded;
      case 'DOCUMENT':
      case 'KYC':
        return Icons.verified_user_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

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
        title: Text(
          isArabic ? 'مركز الإشعارات' : 'Notifications Center',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _error != null && _notifications.isEmpty
              ? _buildErrorState(isArabic)
              : _notifications.isEmpty
                  ? _buildEmptyState(isArabic)
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final title = item['title'] ?? (isArabic ? 'تنبيه الكابتن' : 'Driver Notification');
                          final body = item['body'] ?? '';
                          final type = item['type'] ?? 'SYSTEM';
                          final isRead = item['isRead'] ?? false;
                          final dateStr = item['createdAt'] != null
                              ? DateTime.tryParse(item['createdAt'].toString())?.toLocal().toString().substring(0, 16) ?? ''
                              : '';

                          return FadeInUp(
                            duration: Duration(milliseconds: 200 + (index * 50)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? Colors.black.withOpacity(0.08) : AppColors.primaryOrange.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isRead ? Colors.grey.shade100 : AppColors.primaryOrange.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(type.toString()),
                                      color: isRead ? Colors.black54 : AppColors.primaryOrange,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (dateStr.isNotEmpty)
                                              Text(
                                                dateStr,
                                                style: GoogleFonts.inter(fontSize: 11, color: Colors.black38),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          body,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: isRead ? Colors.black54 : Colors.black87,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: const Icon(Icons.notifications_active_outlined, size: 64, color: Colors.black38),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'لا توجد إشعارات حالياً' : 'No Notifications Yet',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'ستظهر هنا طلبات الرحلات وتنبيهات الأرباح.' : 'New ride requests and earnings alerts will appear here.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 54, color: Colors.red),
          const SizedBox(height: 14),
          Text(
            isArabic ? 'تعذر تحميل الإشعارات' : 'Failed to load notifications',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _fetchNotifications,
            child: Text(isArabic ? 'إعادة المحاولة' : 'Retry', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
