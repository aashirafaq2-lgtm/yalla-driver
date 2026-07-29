import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';

class MailParcelDetailsScreen extends StatelessWidget {
  const MailParcelDetailsScreen({super.key});

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yalla ',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 32),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // ── Recipient Card ────────────────────────────────────────
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipient',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Name', 'Ahmed'),
                    _buildDetailRow('governorate', 'Baghdad'),
                    _buildDetailRow('Region', 'Al-Adhamiyah'),
                    _buildDetailRow('Date & time', '2026-02-17 2:00 AM'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Map Thumbnail ─────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  image: const DecorationImage(
                    image: NetworkImage('https://staticmapmaker.com/img/google.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // ── Action Buttons ────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Accept',
                      const Color(0xFF65CA28),
                      () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionButton(
                      'Reject',
                      const Color(0xFFFF1717),
                      () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
