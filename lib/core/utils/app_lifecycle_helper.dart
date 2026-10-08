import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLifecycleHelper {
  AppLifecycleHelper._();

  static const MethodChannel _channel = MethodChannel('com.eatoggy.userapp/lifecycle');

  /// Smoothly moves the application task to the background on Android without destroying the activity.
  /// This allows instant warm startup when tapping the launcher icon again.
  static Future<void> moveToBackground() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? success = await _channel.invokeMethod<bool>('moveToBackground');
        if (success == true) return;
      } catch (e) {
        debugPrint('AppLifecycleHelper.moveToBackground error: $e');
      }
    }
    // Fallback to standard system pop
    await SystemNavigator.pop(animated: true);
  }
}
