import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';

class MailParcelsScreen extends StatelessWidget {
  const MailParcelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demo purposes, we can toggle this to see the empty state
    final bool isEmpty = false; 

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
      body: isEmpty ? _buildEmptyState() : _buildOrdersList(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.primaryOrange.withOpacity(0.7)),
              const SizedBox(width: 20),
              Icon(Icons.mail_outline, size: 60, color: AppColors.primaryOrange.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'No mail or parcels',
            style: TextStyle(
              color: AppColors.primaryOrange.withOpacity(0.8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {'id': '#001122', 'type': 'Mail', 'count': '1X Mail', 'from': 'Kirkuk', 'to': 'Baghdad', 'isMail': true},
      {'id': '#123456', 'type': 'Parcel', 'count': '3X Parcel', 'from': 'Erbil', 'to': 'Baghdad', 'isMail': false},
      {'id': '#221122', 'type': 'Mail', 'count': '1X Mail', 'from': 'Kirkuk', 'to': 'Baghdad', 'isMail': true},
      {'id': '#881122', 'type': 'Parcel', 'count': '3X Parcel', 'from': 'Erbil', 'to': 'Baghdad', 'isMail': false},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/parcel_details', arguments: order),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
                      ),
                      child: Icon(
                        order['isMail'] ? Icons.mail_outline : Icons.inventory_2_outlined,
                        color: AppColors.primaryOrange,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${order['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order['count'],
                            style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'from ${order['from']} to ${order['to']}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // View Button
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/parcel_details', arguments: order),
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
