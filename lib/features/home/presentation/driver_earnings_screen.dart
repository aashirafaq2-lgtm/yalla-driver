import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/driver_locale_provider.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _daily = {};
  Map<String, dynamic> _weekly = {};
  Map<String, dynamic> _monthly = {};
  int _selectedTab = 0; // 0=daily,1=weekly,2=monthly
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _selectedTab = _tabController.index));
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();
    if (token == null) { setState(() => _isLoading = false); return; }

    try {
      final results = await Future.wait([
        api.getEarnings(token, period: 'daily'),
        api.getEarnings(token, period: 'weekly'),
        api.getEarnings(token, period: 'monthly'),
      ]);
      setState(() {
        _daily   = Map<String, dynamic>.from(results[0].data ?? {});
        _weekly  = Map<String, dynamic>.from(results[1].data ?? {});
        _monthly = Map<String, dynamic>.from(results[2].data ?? {});
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch earnings: $e');
      setState(() {
        _daily   = {'totalEarnings': 0, 'rideEarnings': 0, 'tripEarnings': 0};
        _weekly  = {'totalEarnings': 0, 'rideEarnings': 0, 'tripEarnings': 0};
        _monthly = {'totalEarnings': 0, 'rideEarnings': 0, 'tripEarnings': 0};
        _isLoading = false;
      });
    }
  }

  String _fmt(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    final tabs = [
      isArabic ? 'اليوم' : 'Today',
      isArabic ? 'الأسبوع' : 'Week',
      isArabic ? 'الشهر' : 'Month',
    ];
    final data = [_daily, _weekly, _monthly][_selectedTab];
    final total = data['totalEarnings'] ?? 0;
    final rideEarn = data['rideEarnings'] ?? 0;
    final tripEarn = data['tripEarnings'] ?? 0;
    final commission = ((total as num) * 0.15).round();
    final net = (total - commission);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Icon(
                        isArabic ? Icons.arrow_forward : Icons.arrow_back,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isArabic ? 'أرباحي' : 'My Earnings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchAll,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: AppColors.primaryOrange, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Period Tab Bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: TextStyle(
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : RefreshIndicator(
                    color: AppColors.primaryOrange,
                    onRefresh: _fetchAll,
                    child: Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          // ── Big Total Card ──
                          FadeInDown(
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    isArabic ? 'إجمالي الأرباح' : 'Total Earnings',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _fmt(total),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isArabic ? 'د.ع' : 'IQD',
                                        style: const TextStyle(
                                          color: AppColors.primaryOrange,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Net after commission
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF22C55E), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          isArabic
                                              ? 'صافي أرباحك (بعد 15%): ${_fmt(net)} د.ع'
                                              : 'Net after 15% fee: ${_fmt(net)} IQD',
                                          style: TextStyle(
                                            color: const Color(0xFF22C55E),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Breakdown Cards ──
                          _buildBreakdownCard(
                            icon: Icons.directions_car_rounded,
                            title: isArabic ? 'رحلات فورية' : 'Instant Rides',
                            amount: _fmt(rideEarn),
                            color: const Color(0xFF3B82F6),
                            isArabic: isArabic,
                          ),
                          const SizedBox(height: 12),
                          _buildBreakdownCard(
                            icon: Icons.calendar_month_rounded,
                            title: isArabic ? 'رحلات مجدولة' : 'Scheduled Trips',
                            amount: _fmt(tripEarn),
                            color: const Color(0xFF8B5CF6),
                            isArabic: isArabic,
                          ),
                          const SizedBox(height: 12),
                          _buildBreakdownCard(
                            icon: Icons.remove_circle_outline_rounded,
                            title: isArabic ? 'عمولة يلا (15%)' : 'Yalla Commission (15%)',
                            amount: '- ${_fmt(commission)}',
                            color: Colors.red,
                            isArabic: isArabic,
                          ),

                          const SizedBox(height: 20),

                          // ── Tip Banner ──
                          FadeInUp(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryOrange.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_rounded, color: AppColors.primaryOrange, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isArabic
                                          ? 'أكثر رحلات = أرباح أعلى! حافظ على تقييمك فوق 4.5 للحصول على أولوية في الطلبات.'
                                          : 'More trips = more earnings! Keep your rating above 4.5 for priority dispatch.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
    required bool isArabic,
  }) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                ),
              ),
            ),
            Text(
              '$amount ${isArabic ? "د.ع" : "IQD"}',
              style: TextStyle(
                color: amount.startsWith('-') ? Colors.red : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
