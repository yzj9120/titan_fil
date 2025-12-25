import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final localeController = Get.find<GlobalService>().localeController;
  final imageSize = 18.0;

  void _onChangeIndex(int index) {
    widget.onItemSelected(index);
  }

  Color getBackgroundColor(int index, bool isSelected) {
    return isSelected ? AppColors.btn2 : AppColors.c1818;
  }

  Color getTextColor(int index, bool isSelected) {
    return isSelected ? AppColors.themeColor : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    List<_MenuItem> menuItems = [
      // _MenuItem('menu_storage'.tr),
      // _MenuItem('menu_storage_logs'.tr),
      _MenuItem('menu_pcdn'.tr),
      _MenuItem('settings_logs'.tr),
      _MenuItem('menu_help'.tr),
      _MenuItem('menu_about'.tr),
      // _MenuItem('测试宽带设置'.tr),
    ];

    return Container(
      // width: 200,
      height: 713,
      margin: EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.c1818,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(menuItems.length, (index) {
            bool isSelected = widget.selectedIndex == index;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _onChangeIndex(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 45,
                  width: 175,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                   // color: getBackgroundColor(index, isSelected),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.themeColor2
                          : AppColors.c1818,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        menuItems[index].title,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 12,
                          color: getTextColor(index, isSelected),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  _MenuItem(
    this.title,
  );
}
