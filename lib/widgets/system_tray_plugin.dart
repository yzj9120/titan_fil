import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/app_controller.dart';
import '../controllers/locale_controller.dart';
import '../plugins/native_app.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();
  List<MenuItemBase> menus = [];
  final localeController = Get.find<LocaleController>();
  final appController = Get.find<AppController>();

  Future<void> initSystemTray() async {
    final Menu menuMain = Menu();
    await _systemTray.initSystemTray(iconPath: getTrayImagePath());
    _systemTray.setToolTip("appTitle".tr);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });

    menus = [
      MenuItemLabel(
        label: "${"ver".tr} V${appController.localVersion}",
        enabled: false,
      ),
      MenuItemLabel(
          label: "show".tr, onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(
          label: "checkUpdate".tr,
          onClicked: (menuItem) => appController.onCheckVer(false)),
      MenuItemLabel(
          label: "exit".tr,
          onClicked: (menuItem) async {
            await NativeApp.onExit();
            windowManager.destroy();
          }),
    ];

    await menuMain.buildFrom(menus);
    _systemTray.setContextMenu(menuMain);

    // 监听语言变化
    ever(localeController.currentLocale, (Locale? locale) {
      debugPrint("监听语言变化:${locale}");
      updateSystemTray();
    });
  }

  Future<void> updateSystemTray() async {
    // 更新图标和提示
    await _systemTray.initSystemTray(iconPath: getTrayImagePath());
    _systemTray.setToolTip("appTitle".tr);

    // ✅ 重新构建菜单项（更新语言）
    final Menu updatedMenu = Menu();
    menus = [
      MenuItemLabel(
        label: "${"ver".tr} V${appController.localVersion}",
        enabled: false,
      ),
      MenuItemLabel(
          label: "show".tr, onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(
          label: "checkUpdate".tr,
          onClicked: (menuItem) => appController.onCheckVer(false)),
      MenuItemLabel(
          label: "exit".tr,
          onClicked: (menuItem) async {
            await NativeApp.onExit();
            windowManager.destroy();
          }),
    ];

    await updatedMenu.buildFrom(menus);
    _systemTray.setContextMenu(updatedMenu);
  }

  String getTrayImagePath() {
    return Platform.isWindows
        ? 'assets/images/app_icon.ico'
        : 'assets/images/app_icon.png';
  }
}
