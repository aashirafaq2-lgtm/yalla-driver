import 'package:flutter/material.dart';
import '../network/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  bool _isLoading = false;
  bool _isOnline = false;

  AuthProvider(this._apiService, this._storageService);

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.verifyOtp(phone, otp);
      if (response.statusCode == 200) {
        final token = response.data['token'];
        final userId = response.data['user']['id'];
        await _storageService.saveAuth(token, userId);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {}
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
      }
    } catch (e) {
      print('Status Toggle Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
