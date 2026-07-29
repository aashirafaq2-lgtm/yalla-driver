import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  bool _isLoading = true;
  dynamic _earnings;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    final api     = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token   = await storage.getToken();

    try {
      final response = await api.getEarnings(token!);
      setState(() {
        _earnings = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Earnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryOrange, AppColors.primaryOrange.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text('${_earnings?['total'] ?? 0} IQD', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: FadeInUp(
                    child: ListView(
                      children: [
                        _buildEarningCard('Daily Earnings', '${_earnings?['daily'] ?? 0} IQD', Icons.today),
                        _buildEarningCard('Weekly Earnings', '${_earnings?['weekly'] ?? 0} IQD', Icons.calendar_view_week),
                        _buildEarningCard('Monthly Earnings', '${_earnings?['monthly'] ?? 0} IQD', Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEarningCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 14)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
