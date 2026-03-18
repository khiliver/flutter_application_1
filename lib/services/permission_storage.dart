import 'package:shared_preferences/shared_preferences.dart';

const _kAllowExternalLinksKey = 'allow_external_links_v1';

class PermissionStorage {
  PermissionStorage._();

  static final PermissionStorage instance = PermissionStorage._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> get allowExternalLinks async {
    final prefs = await _prefs;
    return prefs.getBool(_kAllowExternalLinksKey) ?? false;
  }

  Future<void> setAllowExternalLinks(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_kAllowExternalLinksKey, value);
  }
}
