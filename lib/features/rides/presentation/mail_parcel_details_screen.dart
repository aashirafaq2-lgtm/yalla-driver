import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import 'parcel_active_delivery_screen.dart';

class MailParcelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  const MailParcelDetailsScreen({super.key, this.orderData});

  @override
  State<MailParcelDetailsScreen> createState() => _MailParcelDetailsScreenState();
}

class _MailParcelDetailsScreenState extends State<MailParcelDetailsScreen> {
  bool _isAccepting = false;

  Future<void> _acceptParcel() async {
    if (_isAccepting) return;
    final parcelId = widget.orderData?['id']?.toString();
    if (parcelId == null || parcelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid parcel ID'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isAccepting = true);
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final api = Provider.of<ApiService>(context, listen: false);
      final token = await storage.getToken();
      if (token == null) {
        setState(() => _isAccepting = false);
        return;
      }

      final res = await api.dio.patch(
        '/parcels/accept',
        data: {'parcelId': parcelId},
        options: api.authOptions(token),
      );

      if (!mounted) return;
      setState(() => _isAccepting = false);

      if (res.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParcelActiveDeliveryScreen(
              orderData: {
                ...?widget.orderData,
                'type': widget.orderData?['isMail'] == true ? 'Mail' : 'Parcel',
                'count': '1x ${widget.orderData?['isMail'] == true ? "Mail" : "Parcel"}',
              },
            ),
          ),
        );
      } else {
        final err = res.data?['error'] ?? 'Could not accept parcel. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAccepting = false);
      debugPrint('[Parcel] Accept request failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not accept this delivery. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderData ?? {};
    final isMail = order['isMail'] == true;
    final from = order['from'] ?? order['pickupRegion'] ?? 'Pickup';
    final to = order['to'] ?? order['dropRegion'] ?? 'Destination';
    final recipient = order['recipientName'] ?? '';
    final recipientPhone = order['recipientPhone'] ?? '';
    final price = order['price'];
    final parcelType = isMail ? 'Mail' : 'Parcel';

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

            // ── Parcel Info Card ──────────────────────────────────────────────
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
                    Row(
                      children: [
                        Icon(isMail ? Icons.mail_outline : Icons.inventory_2_outlined,
                            color: AppColors.primaryOrange, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '$parcelType Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Type', parcelType),
                    _buildDetailRow('From', from),
                    _buildDetailRow('To', to),
                    if (recipient.isNotEmpty) _buildDetailRow('Recipient', recipient),
                    if (recipientPhone.isNotEmpty) _buildDetailRow('Phone', recipientPhone),
                    if (price != null)
                      _buildDetailRow('Payment', '$price IQD'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Route Display ──────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.circle, size: 12, color: AppColors.primaryOrange),
                        Container(width: 2, height: 32, color: AppColors.primaryOrange.withOpacity(0.3)),
                        const Icon(Icons.location_on, size: 16, color: Colors.red),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(from,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          Text(to,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60),

            // ── Action Buttons ─────────────────────────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Expanded(
                    child: _isAccepting
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                        : _buildActionButton(
                            context,
                            'Accept',
                            const Color(0xFF65CA28),
                            _acceptParcel,
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionButton(
                      context,
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
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, VoidCallback onTap) {
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
