import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeferredLinkService {
  static const String _baseUrl = 'http://72.62.50.86/api';
  static const String _keyPendingReferral = 'pending_referral_code';

  /// Initialize deep link listening and deferred deep link resolution on app startup
  static Future<String?> resolveOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we already have a saved referral code
    String? existingCode = prefs.getString(_keyPendingReferral);
    if (existingCode != null && existingCode.isNotEmpty) {
      print('[DeferredLinkService] Found existing saved referral code: $existingCode');
      return existingCode;
    }

    // 1. Try Deferred Deep Link Resolution via Server (IP matching)
    try {
      final dio = Dio();
      final response = await dio.post(
        '$_baseUrl/invite/resolve-deferred',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['found'] == true && data['referralCode'] != null) {
          final code = data['referralCode'].toString().trim();
          await prefs.setString(_keyPendingReferral, code);
          print('[DeferredLinkService] Server resolved deferred referral code: $code');
          return code;
        }
      }
    } catch (e) {
      print('[DeferredLinkService] Server resolve error (non-fatal): $e');
    }

    // 2. Clipboard Fallback (Backup mechanism: Web page copied referral code on tap)
    try {
      ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        String text = clipboardData.text!.trim();
        // Regex match 6-8 alphanumeric code
        if (RegExp(r'^[A-Za-z0-9]{4,10}$').hasMatch(text)) {
          await prefs.setString(_keyPendingReferral, text);
          print('[DeferredLinkService] Clipboard resolved referral code: $text');
          return text;
        }
      }
    } catch (e) {
      print('[DeferredLinkService] Clipboard error (non-fatal): $e');
    }

    return null;
  }

  /// Get pending referral code for signup
  static Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingReferral);
  }

  /// Clear pending referral code after successful signup
  static Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingReferral);
  }

  /// Save direct deep link code
  static Future<void> saveReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingReferral, code);
  }
}
