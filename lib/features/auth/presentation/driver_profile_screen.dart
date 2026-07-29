import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  dynamic _user;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final api     = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token   = await storage.getToken();

    try {
      final response = await api.getProfile(token!);
      setState(() {
        _user = response.data['user'];
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
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FadeInDown(
                  child: Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryOrange, width: 2)),
                          child: const CircleAvatar(radius: 60, backgroundColor: Color(0xFF1E293B), child: Icon(Icons.person, size: 60, color: Colors.white24)),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 20)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(_user?['phone'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                
                const SizedBox(height: 40),
                
                _buildInfoSection('Vehicle Details', [
                  _buildInfoTile(Icons.directions_car, 'Model', _user?['vehicle']?['model'] ?? '--'),
                  _buildInfoTile(Icons.numbers, 'Plate', _user?['vehicle']?['plateNumber'] ?? '--'),
                  _buildInfoTile(Icons.color_lens, 'Color', _user?['vehicle']?['color'] ?? '--'),
                ]),
                
                const SizedBox(height: 24),
                
                _buildInfoSection('Stats', [
                  _buildInfoTile(Icons.star, 'Rating', '4.9 ★'),
                  _buildInfoTile(Icons.check_circle, 'Staus', 'Verified'),
                ]),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final storage = Provider.of<StorageService>(context, listen: false);
                      await storage.clear();
                      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/signin', (_) => false);
                    },
                    child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryOrange, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
