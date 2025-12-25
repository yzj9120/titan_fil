import 'package:flutter/material.dart';

import '../../../widgets/update_app_widget.dart';

class SettingAbout extends StatelessWidget {
  const SettingAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: UpdateAppWidget(
          tag: 1,
          height: 500,
          onCallback: () async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => UpdateAppWidget(
                height: 550,
                tag: 2,
              ),
            );
          },
        ),
      ),
    );
  }
}
