import 'package:flutter/foundation.dart';

class ActiveRideProvider extends ChangeNotifier {
  Map<String, dynamic>? _activeRide;

  Map<String, dynamic>? get activeRide => _activeRide;
  bool get hasActiveRide => _activeRide != null;

  void setActiveRide(Map<String, dynamic> ride) {
    _activeRide = Map<String, dynamic>.from(ride);
    notifyListeners();
  }

  void updateRideStatus(String status) {
    if (_activeRide != null) {
      _activeRide!['status'] = status;
      notifyListeners();
    }
  }

  void clearActiveRide() {
    _activeRide = null;
    notifyListeners();
  }
}
