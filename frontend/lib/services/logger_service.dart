import 'package:flutter/foundation.dart';

class LoggerService {
  static void debug(String message) {
    if (kDebugMode) {
      print('🔍 DEBUG: $message');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }
} 