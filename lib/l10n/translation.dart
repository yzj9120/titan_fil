/**
 * GetX 国际化翻译
 */

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Translation extends Translations {
  static final Map<String, Map<String, String>> _translations = {};

  // 读取 JSON 并解析
  static Future<void> loadTranslations() async {
    _translations['en_US'] = await _loadJson('assets/l10n/en.json');
    _translations['zh_CN'] = await _loadJson('assets/l10n/zh.json');
  }

  static Future<Map<String, String>> _loadJson(String path) async {
    String jsonString = await rootBundle.loadString(path);
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Map<String, Map<String, String>> get keys => _translations;
}
