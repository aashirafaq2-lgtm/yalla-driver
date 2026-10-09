import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/socket_service.dart';

class MailParcelsScreen extends StatefulWidget {
  const MailParcelsScreen({super.key});

  @override
  State<MailParcelsScreen> createState() => _MailParcelsScreenState();
}

class _MailParcelsScreenState extends State<MailParcelsScreen> {
  List<dynamic> _parcels = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParcels();
    _listenForNewParcels();
  }

  void _listenForNewParcels() {
    // Listen for real-time new parcel requests
    try {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.onNewParcelRequest = (data) {
        if (!mounted) return;
        // Add to list at top if not already present
        setState(() {
          final exists = _parcels.any((p) => p['id'] == data['parcelId']);
          if (!exists) {
            _parcels.insert(0, {
              'id': data['parcelId'],
              'parcelType': data['parcelType'] ?? 'PARCEL',
              'pickupRegion': data['pickupRegion'] ?? 'Pickup',
              'dropRegion': data['dropRegion'] ?? 'Destination',
              'price': data['price'],
              'status': 'PENDING',
              'pickupLat': data['pickupLat'],
              'pickupLng': data['pickupLng'],
              'dropLat': data['dropLat'],
              'dropLng': data['dropLng'],
              'isNew': true,
            });
          }
        });
      };
    } catch (_) {}
  }

  Future<void> _loadParcels() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final api = Provider.of<ApiService>(context, listen: false);
      final token = await storage.getToken();
      if (token == null) {
        setState(() { _isLoading = false; _error = 'Not authenticated'; });
        return;
      }
      // Fetch pending parcels (for drivers to accept)
      final res = await api.dio.get(
        '/parcels/pending',
        options: api.authOptions(token),
      );
      if (res.statusCode == 200) {
        setState(() {
          _parcels = res.data['parcels'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _error = 'Failed to load parcels'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    try {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.onNewParcelRequest = null;
    } catch (_) {}
    super.dispose();
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
            onPressed: _loadParcels,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text('Could not load parcels', style: TextStyle(color: Colors.black45, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadParcels,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_parcels.isEmpty) {
      return _buildEmptyState();
    }
    return _buildOrdersList(context);
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
            'No pending parcels',
            style: TextStyle(
              color: AppColors.primaryOrange.withOpacity(0.8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New parcel requests will appear here',
            style: TextStyle(color: Colors.black38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadParcels,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _parcels.length,
        itemBuilder: (context, index) {
          final order = _parcels[index];
          final isMail = (order['parcelType'] ?? '').toString().toUpperCase() == 'MAIL';
          final isNew = order['isNew'] == true;
          final price = order['price'];
          final from = order['pickupRegion'] ?? 'Pickup';
          final to = order['dropRegion'] ?? 'Destination';
          final id = order['id']?.toString() ?? '';
          final shortId = id.length > 6 ? '#${id.substring(0, 6).toUpperCase()}' : '#$id';

          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/parcel_details', arguments: {
                ...Map<String, dynamic>.from(order),
                'isMail': isMail,
                'type': isMail ? 'Mail' : 'Parcel',
                'count': '1x ${isMail ? "Mail" : "Parcel"}',
                'from': from,
                'to': to,
                'recipientName': order['sender'] != null
                    ? '${order['sender']['firstName'] ?? ''} ${order['sender']['lastName'] ?? ''}'.trim()
                    : (order['recipientName'] ?? ''),
                'recipientPhone': order['recipientPhone'] ?? '',
              }),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNew ? AppColors.primaryOrange.withOpacity(0.5) : Colors.black.withOpacity(0.08),
                    width: isNew ? 1.5 : 1,
                  ),
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
                          isMail ? Icons.mail_outline : Icons.inventory_2_outlined,
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
                            Row(
                              children: [
                                Text(
                                  'Order $shortId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isNew) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1x ${isMail ? "Mail" : "Parcel"}',
                              style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'from $from → $to',
                              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            if (price != null)
                              Text(
                                '${price.toString()} IQD',
                                style: const TextStyle(color: AppColors.primaryOrange, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      // View Button
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/parcel_details', arguments: {
                          ...Map<String, dynamic>.from(order),
                          'isMail': isMail,
                          'type': isMail ? 'Mail' : 'Parcel',
                          'count': '1x ${isMail ? "Mail" : "Parcel"}',
                          'from': from,
                          'to': to,
                        }),
                        child: const Text(
                          'VIEW',
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
      ),
    );
  }
}
