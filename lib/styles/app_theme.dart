import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/**
 *主题配置
 */
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      titleLarge: AppTextStyles.heading,
      bodyMedium: AppTextStyles.body,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        textStyle: AppTextStyles.button,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.black,
  );

  static ThemeData mainTheme(BuildContext context) => ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
        ),
        primaryColor: AppColors.primaryColor,
        canvasColor: AppColors.canvasColor,
        scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
        textTheme: GoogleFonts.notoSansScTextTheme().copyWith(
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: 46,
            fontWeight: FontWeight.w800,
          ),
        ),

        // fontFamily: Platform.isWindows ? "Noto Sans SC" : "PingFang SC",
        // fontFamily: "Microsoft YaHei",
        // fontFamilyFallback: ['Microsoft YaHei','Noto Sans SC'],
        // textTheme: const TextTheme(
        //   headlineSmall: TextStyle(
        //     color: Colors.white,
        //     fontSize: 46,
        //     fontWeight: FontWeight.w800,
        //   ),
        // ),
      ).useSystemChineseFont(Brightness.dark);

  static BoxDecoration chartDecoration(bSelected) => BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(100),
        topRight: Radius.circular(100),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bSelected
            ? [
                const Color(0xFFFEF00D),
                const Color(0xFF59F942),
                const Color(0xFF000000),
              ]
            : [
                const Color(0x786DFF57),
                const Color(0x78338B26),
                const Color(0xFF000000),
              ],
      ));

  static BoxDecoration minaCircular = BoxDecoration(
    color: AppColors.minaColor,
    borderRadius: BorderRadius.circular(13), // Rounded corners with 20px radius
  );

  static BoxDecoration circular({
    Color color = Colors.blue, // 默认颜色
    double radius = 13.0, // 默认圆角半径
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration rectangle = const BoxDecoration(
    color: AppColors.tcF40,
    borderRadius: BorderRadius.all(Radius.circular(45.0)),
  );
}
