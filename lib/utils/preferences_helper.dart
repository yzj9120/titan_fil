import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 基础类型读取
  static String? getString(String key) => _prefs.getString(key);
  static int? getInt(String key) => _prefs.getInt(key);
  static bool? getBool(String key) => _prefs.getBool(key);
  static double? getDouble(String key) => _prefs.getDouble(key);
  static List<String>? getStringList(String key) => _prefs.getStringList(key);

  // 基础类型写入
  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  static Future<bool> setInt(String key, int value) =>
      _prefs.setInt(key, value);
  static Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);
  static Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  static Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // 通用写入（自动根据类型判断）
  static Future<bool> set(String key, dynamic value) {
    if (value is String) return setString(key, value);
    if (value is int) return setInt(key, value);
    if (value is bool) return setBool(key, value);
    if (value is double) return setDouble(key, value);
    if (value is List<String>) return setStringList(key, value);
    throw Exception("Unsupported value type: ${value.runtimeType}");
  }

  // 删除与清空
  static Future<bool> remove(String key) => _prefs.remove(key);
  static Future<bool> clear() => _prefs.clear();

  // 判断是否存在
  static bool containsKey(String key) => _prefs.containsKey(key);

  // 获取所有 key
  static Set<String> getKeys() => _prefs.getKeys();

  // 存储/读取 Map（以 JSON 格式）
  static Future<bool> setMap(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getMap(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    final decoded = jsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Value for "$key" is not a valid Map');
  }
}
