import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/index/index_page.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_theme.dart';
import 'package:titan_fil/utils/FileLogger.dart';
import 'package:titan_fil/widgets/LoadingWidget.dart';
import 'package:titan_fil/widgets/system_tray_plugin.dart';
import 'package:window_manager/window_manager.dart';

import 'channelService/defineMethodChannel.dart';
import 'command/launch_after.dart';
import 'command/launch_before.dart';
import 'config/app_config.dart';
import 'controllers/locale_controller.dart';
import 'gen/assets.gen.dart';
import 'l10n/translation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> dialog1Key = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> dialog2Key = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const size = Size(1400, 788);
  WindowOptions windowOptions = WindowOptions(
    size: size,
    minimumSize: size,
    maximumSize: size,
    center: true,
    title: AppConfig.appTitle,
    alwaysOnTop: false,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    windowManager.setResizable(false);
  });

  try {
    await LaunchBeforeCommand.setUp();
  } catch (e) {
    FileLogger.log('setUp', tag: '$e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => StateMyApp();
}

class StateMyApp extends State<MyApp> with WindowListener {
  final _appKey = GlobalKey<StateMyApp>();
  late int langSelectedIndex;
  OverlayEntry? langEntryView;
  late SystemTrayManager _systemTrayManager = SystemTrayManager();

  @override
  void initState() {
    super.initState();
    _precacheImages();
    windowManager.addListener(this);
    _systemTrayManager.initSystemTray();
    _initWindowManager();
    DefineMethodChannel().intNative();
  }

  void _precacheImages() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      precacheImage(Assets.images.appIconPng.provider(), context);
      precacheImage(Assets.images.appIcon2.provider(), context);
    });
  }

  Future<void> _initWindowManager() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  String getTrayImagePath() {
    return Platform.isWindows
        ? 'assets/images/app_icon.ico'
        : 'assets/images/app_icon.png';
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    return Obx(() {
      return GetMaterialApp(
        navigatorKey: navigatorKey,
        key: _appKey,
        themeMode: ThemeMode.light,
        locale: localeController.currentLocale.value,
        translations: Translation(),
        title: 'appTitle'.tr,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.mainTheme(context),
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('zh', 'CN'),
        ],
        fallbackLocale: const Locale('en', 'US'),
        home: SplashScreen(),
      );
    });
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    // 设置进度回调
    LaunchAfterCommand.setProgressCallback((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
          _isDownloading = progress < 1.0;
        });
      }
    });
    LaunchAfterCommand.setUp().then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => IndexPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isDownloading
                ? Text(
                    'assert_download'.tr,
                    style: TextStyle(color: AppColors.themeColor),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 20),
            SizedBox(
              height: 100,
              width: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LoadingWidget(),
                  Visibility(
                    visible: _downloadProgress > 0,
                    child: Text(
                      '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppColors.themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
