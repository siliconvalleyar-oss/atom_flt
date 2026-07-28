import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const _keyDirectory = 'default_directory';
  static const _keyTreeUri = 'tree_uri';
  static const _keyOnboardingDone = 'onboarding_done';

  static Future<String> getDefaultDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDirectory) ?? '';
  }

  static Future<String?> getTreeUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTreeUri);
  }

  static Future<void> setDirectory(String path, {String? treeUri}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDirectory, path);
    if (treeUri != null) {
      await prefs.setString(_keyTreeUri, treeUri);
    } else {
      await prefs.remove(_keyTreeUri);
    }
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }
}
