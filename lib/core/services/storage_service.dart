import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _driverNameKey = 'driver_name';
  static const String _driverPhoneKey = 'driver_phone';
  static const String _carModelKey = 'car_model';
  static const String _plateKey = 'license_plate';

  Future<void> saveAuth(String token, String userId, {String? name, String? phone}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    if (name != null) await _storage.write(key: _driverNameKey, value: name);
    if (phone != null) await _storage.write(key: _driverPhoneKey, value: phone);
  }

  Future<void> saveVehicleInfo(String carModel, String plate) async {
    await _storage.write(key: _carModelKey, value: carModel);
    await _storage.write(key: _plateKey, value: plate);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getDriverName() async {
    return await _storage.read(key: _driverNameKey);
  }

  Future<String?> getDriverPhone() async {
    return await _storage.read(key: _driverPhoneKey);
  }

  Future<String?> getCarModel() async {
    return await _storage.read(key: _carModelKey);
  }

  Future<String?> getLicensePlate() async {
    return await _storage.read(key: _plateKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

