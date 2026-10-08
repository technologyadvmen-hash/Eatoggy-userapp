import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../constants/app_keys.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationSubscribeRequest {
  final String fcmToken;
  final String deviceType;
  final String appVersion;

  NotificationSubscribeRequest({
    required this.fcmToken,
    required this.deviceType,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'fcmToken': fcmToken,
        'deviceType': deviceType,
        'appVersion': appVersion,
      };
}

class NotificationSubscribeResponse {
  final bool success;
  final String message;

  NotificationSubscribeResponse({
    required this.success,
    required this.message,
  });

  factory NotificationSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return NotificationSubscribeResponse(
      success: json['success'] == true || json['status'] == 'success' || json['status'] == 200,
      message: (json['message'] ?? 'Notification token registered').toString(),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Registers or refreshes the customer's FCM notification device token on the backend
  /// API: POST /api/notifications/subscribe
  Future<NotificationSubscribeResponse?> registerDeviceToken({
    required String fcmToken,
    String? deviceType,
    String? appVersion,
  }) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final userToken = prefs.getString(AppKeys.accessToken);

      // Only attempt server registration if user is authenticated (token exists)
      if (userToken == null || userToken.isEmpty) {
        debugPrint('ℹ️ Skip FCM Token registration: User not authenticated yet.');
        // Cache token locally so it can be synced immediately after login
        await prefs.setString(AppKeys.fcmToken, fcmToken);
        return null;
      }

      final String resolvedDeviceType = deviceType ??
          (kIsWeb
              ? 'web'
              : Platform.isIOS
                  ? 'ios'
                  : 'android');
      final String resolvedAppVersion = appVersion ?? '1.0.0';

      final request = NotificationSubscribeRequest(
        fcmToken: fcmToken,
        deviceType: resolvedDeviceType,
        appVersion: resolvedAppVersion,
      );

      final response = await ApiService.dio.post(
        ApiConstants.subscribeNotificationToken,
        data: request.toJson(),
      );

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final subscribeResponse = NotificationSubscribeResponse.fromJson(responseData);
      await prefs.setString(AppKeys.fcmToken, fcmToken);
      debugPrint('✅ FCM Token subscribed successfully: ${subscribeResponse.message}');
      return subscribeResponse;
    } on DioException catch (e) {
      debugPrint('⚠️ Dio error subscribing notification token: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error subscribing notification token: $e');
      return null;
    }
  }

  /// Syncs cached FCM token if present after user logs in
  Future<void> syncCachedTokenOnLogin() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final cachedToken = prefs.getString(AppKeys.fcmToken);
      if (cachedToken != null && cachedToken.isNotEmpty) {
        await registerDeviceToken(fcmToken: cachedToken);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync cached FCM token on login: $e');
    }
  }

  /// Returns current cached device token
  Future<String?> getSavedFcmToken() async {
    final prefs = await SharedPreferencesService.getInstance();
    return prefs.getString(AppKeys.fcmToken);
  }
}
