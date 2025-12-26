import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../gen/assets.gen.dart';
import '../../network/api_service.dart';
import '../../services/global_service.dart';
import '../../styles/app_colors.dart';

class SideMenu extends StatefulWidget {
  final Function(int index) onItemSelected;
  final int selectedIndex;

  const SideMenu({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int? _hoveredIndex;
  final localeController = Get.find<GlobalService>().localeController;
  final imageSize = 18.0;
  String discordURL = "";

  @override
  void initState() {
    super.initState();
  }

  void _onChangeIndex(int index) {
    if (index == 4) {
      localeController.langEntryClick();
    } else {
      widget.onItemSelected(index);
    }
  }

  Color getBorderBackgroundColor(int index, bool isHovered, bool isSelected) {
    return index == 4
        ? isHovered
            ? AppColors.themeColor
            : AppColors.c1818
        : isSelected
            ? AppColors.themeColor
            : AppColors.c1818;
  }

  Color getBackgroundColor(int index, bool isHovered, bool isSelected) {
    return index == 4
        ? isHovered
            ? Colors.transparent
            : AppColors.c1818
        : isSelected
            ? AppColors.themeColor
            : AppColors.c1818;
  }

  Color getTextColor(int index, bool isHovered, bool isSelected) {
    return index == 4
        ? isHovered
            ? AppColors.themeColor
            : Colors.white
        : isSelected
            ? Colors.black
            : isHovered
                ? Colors.white70
                : Colors.white;
  }

  Widget getMenuItemWidget(
      int index, bool isHovered, bool isSelected, menuItems) {
    return isHovered
        ? index == 4
            ? localeController.isChineseLocale()
                ? Assets.images.tabLanguageZh
                    .image(width: imageSize, color: AppColors.themeColor)
                : Assets.images.tabLanguageEn
                    .image(width: imageSize, color: AppColors.themeColor)
            : isSelected
                ? menuItems[index].icon_on
                : menuItems[index].icon_off
        : isSelected
            ? menuItems[index].icon_on
            : menuItems[index].icon_off;
  }

  @override
  Widget build(BuildContext context) {
    List<_MenuItem> menuItems = [
      _MenuItem('tab_home'.tr, Assets.images.tabHomeOn.image(width: imageSize),
          Assets.images.tabHomeOff.image(width: imageSize)),
      _MenuItem('tag_task'.tr, Assets.images.tabTaskOn.image(width: imageSize),
          Assets.images.tabTaskOff.image(width: imageSize)),
      _MenuItem('tab_bind'.tr, Assets.images.tabBindOn.image(width: imageSize),
          Assets.images.tabBindOff.image(width: imageSize)),
      _MenuItem(
          'tab_setting'.tr,
          Assets.images.tabSettingOn.image(width: imageSize),
          Assets.images.tabSettingOff.image(width: imageSize)),
      _MenuItem(
        'tag_language'.tr,
        localeController.isChineseLocale()
            ? Assets.images.tabLanguageZh.image(width: imageSize)
            : Assets.images.tabLanguageEn.image(width: imageSize),
        localeController.isChineseLocale()
            ? Assets.images.tabLanguageZh.image(width: imageSize)
            : Assets.images.tabLanguageEn.image(width: imageSize),
      ),
    ];

    return SizedBox(
      width: 200,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(menuItems.length, (index) {
            bool isSelected = widget.selectedIndex == index;
            bool isHovered = _hoveredIndex == index;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTap: () => _onChangeIndex(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 45,
                  width: 175,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  decoration: BoxDecoration(
                    color: getBackgroundColor(index, isHovered, isSelected),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: getBorderBackgroundColor(
                          index, isHovered, isSelected), // 设置边框颜色
                      width: 1.0, // 设置边框宽度
                    ),
                  ),
                  child: Row(
                    children: [
                      getMenuItemWidget(
                          index, isHovered, isSelected, menuItems),
                      const SizedBox(width: 5),
                      Text(
                        menuItems[index].title,
                        style: TextStyle(
                          fontSize: isSelected ? 14 : 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: getTextColor(index, isHovered, isSelected),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Container(
          //   decoration: BoxDecoration(
          //     color: AppColors.c1818,
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       InkWell(
          //         onTap: () {
          //           AppHelper.openUrl(context, discordURL);
          //         },
          //         child: Assets.images.tabBottomDiscord.image(width: imageSize),
          //       ),
          //       const Spacer(),
          //       InkWell(
          //         onTap: () {
          //           AppHelper.openUrl(context, AppConfig.twitterURL);
          //         },
          //         child: Assets.images.tabBottomTwitter.image(width: imageSize),
          //       ),
          //       const Spacer(),
          //       InkWell(
          //         onTap: () {
          //           AppHelper.openUrl(context, AppConfig.tgURL);
          //         },
          //         child: Assets.images.tabBottomTg.image(width: imageSize),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final Image icon_on;
  final Image icon_off;

  _MenuItem(this.title, this.icon_on, this.icon_off);
}
