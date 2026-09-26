import 'package:flutter/foundation.dart';

class AppLogger {
  static void printData(String str, String val) {
    if (kDebugMode) {
      print("$str :::  $val");
    }
  }
}
