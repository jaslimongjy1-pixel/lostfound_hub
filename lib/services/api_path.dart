import 'package:flutter/foundation.dart';

class ApiPath {
  // Automatically detects on a phone emulator or web
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost/lostfound/api";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2/lostfound/api";
      default:
        return "http://localhost/lostfound/api";
    }
  }

  static String get imageUrl {
    return baseUrl.replaceAll('/api', '');
  }

  static String endpoint(String fileName) {
    return "$baseUrl/$fileName";
  }
}
