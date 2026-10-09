import 'package:dio/dio.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://api-yalla.aaaj.shop/api',
      connectTimeout: const Duration(seconds: 20), validateStatus: (status) => true,
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

  /// Helper: returns Options with Bearer token header
  Options authOptions(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  // Auth
  Future<Response> login(String phone) async {
    return await dio.post('/auth/login', data: {
      'phone': phone,
      'role': 'DRIVER', 
    });
  }

  Future<Response> registerDriverAccount(String phone, String name, {int? age}) async {
    return await dio.post('/auth/register-driver', data: {
      'phone': phone,
      'name': name,
      if (age != null) 'age': age,
    });
  }

  Future<Response> verifyOtp(String phone, String otp) async {
    return await dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
  }

  // Driver Registration
  Future<Response> registerDriver(Map<String, dynamic> data, String token) async {
    return await dio.post('/driver/register',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> submitDriverDocuments({
    required String cardIdImage,
    required String carImage,
    required String driverFaceImage,
    required String token,
  }) async {
    return await dio.post('/driver/documents',
      data: {
        'cardIdImage': cardIdImage,
        'carImage': carImage,
        'driverFaceImage': driverFaceImage,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getDriverVerificationStatus(String token) async {
    return await dio.get('/driver/verification-status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Driver Status
  Future<Response> updateStatus(bool isOnline, String token) async {
    return await dio.patch('/driver/status', 
      data: {'isOnline': isOnline},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Earnings
  Future<Response> getEarnings(String token, {String period = 'daily'}) async {
    return await dio.get('/driver/earnings', 
      queryParameters: {'period': period},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Profile
  Future<Response> getProfile(String token) async {
    return await dio.get('/user/profile', 
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> updateProfile(Map<String, dynamic> data, String token) async {
    return await dio.patch('/user/profile', 
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> deleteAccount(String token) async {
    return await dio.delete('/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Wallet
  Future<Response> getWallet(String token) async {
    return await dio.get('/user/wallet', 
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // History
  Future<Response> getHistory(String token) async {
    return await dio.get('/user/history', 
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Rides
  Future<Response> acceptRide(String rideId, String token) async {
    return await dio.patch('/ride/accept', 
      data: {'rideId': rideId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> updateRideStatus(String rideId, String status, String token, {double? finalPrice}) async {
    return await dio.patch('/ride/status', 
      data: {
        'rideId': rideId,
        'status': status,
        if (finalPrice != null) 'finalPrice': finalPrice,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> verifyOtpForRide(String rideId, String otp, String token) async {
    return await dio.post('/ride/verify-otp',
      data: {'rideId': rideId, 'otp': otp},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getActiveRide(String token) async {
    return await dio.get('/ride/active',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getRide(String rideId, String token) async {
    return await dio.get('/ride/$rideId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getRideRequest(String rideId, String token) async {
    return await dio.get('/ride/requests/$rideId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getParcelRequest(String parcelId, String token) async {
    return await dio.get('/parcels/requests/$parcelId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> acceptParcel(String parcelId, String token) async {
    return await dio.patch('/parcels/accept',
      data: {'parcelId': parcelId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getChatMessages(String rideId, String token) async {
    return await dio.get('/chat/$rideId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> cancelRide(String rideId, String reason, String token) async {
    return await dio.patch('/ride/cancel',
      data: {'rideId': rideId, 'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Trips
  Future<Response> getAvailableTrips({String? from, String? to, String? date}) async {
    return await dio.get('/trips/available', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (date != null) 'date': date,
    });
  }

  Future<Response> createScheduledTrip(Map<String, dynamic> tripData, String token) async {
    return await dio.post('/trips/create', 
      data: tripData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getMyTrips(String token) async {
    return await dio.get('/trips/my',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> updateTripStatus(String tripId, String status, String token) async {
    return await dio.patch('/trips/status',
      data: {'tripId': tripId, 'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> cancelTripById(String tripId, String token) async {
    return await dio.patch('/trips/cancel',
      data: {'tripId': tripId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getTripBookings(String tripId, String token) async {
    return await dio.get('/bookings/trip/$tripId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> getGovernorates() async {
    return await dio.get('/trips/governorates');
  }

  Future<Response> updateFcmToken(String fcmToken, String token) async {
    return await dio.patch('/user/device-token', 
      data: {'deviceToken': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Map & Spatial APIs
  Future<Response> searchLocation(String query, {double? lat, double? lng}) async {
    return await dio.get('/map/search', queryParameters: {
      'q': query,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }

  Future<Response> reverseGeocode(double lat, double lng) async {
    return await dio.get('/map/reverse-geocode', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
  }

  Future<Response> getDirections({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    return await dio.get('/map/route', queryParameters: {
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
    });
  }

  Future<Response> getNotifications(String token) async {
    return await dio.get('/user/notifications', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<Response> markNotificationsRead(String token) async {
    return await dio.patch('/user/notifications/mark-read', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }
}


