import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../services/log_service.dart';

class LocaleController extends GetxController {
  // var currentLocale = const Locale('en', 'US').obs;
// 默认语言设为中文
  var currentLocale = const Locale('zh', 'CN').obs;
  static final logUtils = LoggerFactory.createLogger(LoggerName.t3);

  // 构造函数
  LocaleController() {
    _loadLocale();
  }

  // 加载本地存储的语言设置
  void _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString(Constants.langCode) ?? 'en';
      final countryCode = prefs.getString(Constants.countryCode) ?? 'US';
      final locale = Locale(langCode, countryCode);
      currentLocale.value = locale;
      Get.updateLocale(locale);
    } catch (e, stackTrace) {
      // fallback to default
      final fallbackLocale = const Locale('en', 'US');
      currentLocale.value = fallbackLocale;
      Get.updateLocale(fallbackLocale);
      _log('[Locale] Fallback to default locale: en-US');
    }
  }

  // 改变语言
  Future<void> changeLocale(String langCode, String countryCode) async {
    final locale = Locale(langCode, countryCode);
    currentLocale.value = locale;
    (await SharedPreferences.getInstance())
        .setString(Constants.langCode, langCode);
    (await SharedPreferences.getInstance())
        .setString(Constants.countryCode, countryCode);
    Get.updateLocale(locale);
  }

  void langEntryClick() {
    if (!isChineseLocale()) {
      changeLocale('zh', 'CN');
    } else {
      changeLocale('en', 'US');
    }
  }

  int locale() => currentLocale.value == const Locale('en', 'US') ? 0 : 1;

  bool isChineseLocale() {
    return currentLocale.value.languageCode == 'zh';
  }

  static void _log(String message) {
    logUtils.info("[LocaleController]$message");
  }
}
