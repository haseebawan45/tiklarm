import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PlatformUtils {
  /// Checks if native alarms are supported on the current platform
  static bool get isNativeAlarmsSupported {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
  
  /// Checks if permissions are available on the current platform
  static bool get arePermissionsAvailable {
    return !kIsWeb;
  }
  
  /// Checks if the current platform is Android
  static bool get isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }
  
  /// Checks if the current platform is iOS
  static bool get isIOS {
    return !kIsWeb && Platform.isIOS;
  }
  
  /// Checks if the current platform is web
  static bool get isWeb {
    return kIsWeb;
  }
} 