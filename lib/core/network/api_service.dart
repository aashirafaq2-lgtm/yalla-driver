import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kIsWeb ? 'http://76.13.3.121:4000/api' : 'http://76.13.3.121:4000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  // Auth
  Future<Response> login(String phone) async {
    return await dio.post('/auth/login', data: {
      'phone': phone,
      'role': 'DRIVER', 
    });
  }

  Future<Response> verifyOtp(String phone, String otp) async {
    return await dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
  }

  // Driver Status
  Future<Response> updateStatus(bool isOnline, String token) async {
    return await dio.patch('/driver/status', 
      data: {'isOnline': isOnline},
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }

  // Earnings
  Future<Response> getEarnings(String token) async {
    return await dio.get('/driver/earnings', 
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }

  // Profile
  Future<Response> getProfile(String token) async {
    return await dio.get('/user/profile', 
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }

  // Rides
  Future<Response> acceptRide(String rideId, String token) async {
    return await dio.patch('/ride/accept', 
      data: {'rideId': rideId},
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }

  Future<Response> updateRideStatus(String rideId, String status, String token) async {
    return await dio.patch('/ride/status', 
      data: {'rideId': rideId, 'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }

  Future<Response> updateFcmToken(String fcmToken, String token) async {
    return await dio.patch('/user/fcm-token', 
      data: {'fcmToken': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'})
    );
  }
}
