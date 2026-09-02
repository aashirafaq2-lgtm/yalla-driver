import 'package:flutter/material.dart';
import '../network/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  SocketService? _socketService;

  bool _isLoading = false;
  bool _isOnline = true;
  Map<String, dynamic>? _userProfile;
  double _walletBalance = 0.0;
  int _totalTrips = 0;
  double _rating = 5.0;

  AuthProvider(this._apiService, this._storageService);

  void setSocketService(SocketService socket) {
    _socketService = socket;
  }

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  Map<String, dynamic>? get userProfile => _userProfile;
  double get walletBalance => _walletBalance;
  int get totalTrips => _totalTrips;
  double get rating => _rating;

  String get driverName {
    if (_userProfile != null) {
      final first = _userProfile!['firstName'] ?? '';
      final last = _userProfile!['lastName'] ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
    }
    return 'Driver';
  }

  Future<void> loadProfile() async {
    final token = await _storageService.getToken();
    if (token == null) return;

    try {
      final response = await _apiService.getProfile(token);
      if (response.statusCode == 200) {
        _userProfile = response.data['user'];
        _isOnline = _userProfile?['isOnline'] ?? true;
        _walletBalance = (_userProfile?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        _totalTrips = (_userProfile?['totalTrips'] as num?)?.toInt() ?? 0;
        _rating = (_userProfile?['rating'] as num?)?.toDouble() ?? 5.0;
        
        final userId = _userProfile?['id'];
        if (userId != null && _socketService != null) {
          _socketService!.authenticate(userId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load Profile Error: $e');
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.verifyOtp(phone, otp);
      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];
        final userId = user['id'];
        final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        
        await _storageService.saveAuth(token, userId, name: name, phone: phone);
        _userProfile = user;
        _isOnline = user['isOnline'] ?? true;
        
        if (_socketService != null) {
          _socketService!.connect();
          _socketService!.authenticate(userId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> toggleStatus() async {
    final token = await _storageService.getToken();
    if (token == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final newStatus = !_isOnline;
      final response = await _apiService.updateStatus(newStatus, token);
      if (response.statusCode == 200) {
        _isOnline = newStatus;
        _socketService?.toggleDriverStatus(newStatus);
      }
    } catch (e) {
      debugPrint('Status Toggle Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerVehicle({
    required String carName,
    required int seats,
    required String carNumber,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.registerDriver({
        'make': carName,
        'model': carName,
        'seats': seats,
        'licensePlate': carNumber,
      }, token);

      if (response.statusCode == 200) {
        await _storageService.saveVehicleInfo(carName, carNumber);
        await loadProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Register Vehicle Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteAccount() async {
    final token = await _storageService.getToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.deleteAccount(token);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _storageService.clear();
        _userProfile = null;
        _socketService?.disconnect();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Delete Account Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storageService.clear();
    _userProfile = null;
    _socketService?.disconnect();
    notifyListeners();
  }
}


