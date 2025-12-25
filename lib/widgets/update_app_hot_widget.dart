import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/styles/app_colors.dart';

import '../services/global_service.dart';
import '../utils/FileLogger.dart';
import '../utils/file_helper.dart';

class UpdateAppHotWidget extends StatefulWidget {
  final bool isForceUpdate;
  final String agentFileName;

  const UpdateAppHotWidget({
    super.key,
    this.isForceUpdate = false,
    this.agentFileName = "",
  });

  @override
  State<UpdateAppHotWidget> createState() => _UpdateAppHotWidgetState();
}

class _UpdateAppHotWidgetState extends State<UpdateAppHotWidget> {
  bool _isUpdating = false;

  final localeController = Get.find<GlobalService>().localeController;

  Future<void> _startUpdater() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final libsPath = await FileHelper.getCurrentPath();
      final updater = path.join(libsPath, "titanUpdater", "titan_fil.exe");
      final main = path.join(libsPath, "titan_fil.exe");
      final isEn = !localeController.isChineseLocale();

      final result = await Process.run(
        updater,
        [
          "main=$main",
          "isEn=${isEn}",
          "libsPath=$libsPath",
          "extractToPath=$libsPath",
          "agentFileName=${widget.agentFileName}",
        ],
        runInShell: true,
      );

      if (result.stderr.isNotEmpty) {
        await FileLogger.log("run updater stderr: ${result.stderr}");
      }

      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    } catch (e, stack) {
      await FileLogger.log("update failed: $e\n$stack");
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 500,
          height: 450,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.minaColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Assets.images.icLogo2.image(width: 100, height: 100),
              const SizedBox(height: 22),
              Text("hot_tip".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              Text("hot_tip2".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14)),
              const Spacer(),
              _buildUpdateButton(),
              const SizedBox(height: 10),
              if (!widget.isForceUpdate) _buildSkipButton(),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      height: 45,
      width: 300,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.themeColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: _isUpdating ? null : _startUpdater,
        child: _isUpdating
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : Text(
                "hot_tip3".tr,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      height: 45,
      width: 300,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.tcCff, width: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: Text("hot_tip4".tr,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}
