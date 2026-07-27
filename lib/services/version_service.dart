import 'package:flutter/services.dart';

class VersionService {
  static String _version = '0.0.0';

  static String get version => _version;

  static Future<void> load() async {
    try {
      _version = (await rootBundle.loadString('VERSION')).trim();
    } catch (_) {
      _version = '0.0.0';
    }
  }
}
