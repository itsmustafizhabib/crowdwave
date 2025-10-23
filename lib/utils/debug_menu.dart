import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import '../routes/app_routes.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    // Only show in debug mode
    if (kDebugMode) {
      showDialog(
        context: context,
        builder: (context) => const DebugMenu(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.orange),
          const SizedBox(width: 8),
          Text('debug.menu_title'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: Text('debug.email_test_screen'.tr()),
            subtitle: Text('debug.email_test_description'.tr()),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.emailTest);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF008080)),
            title: Text('debug.menu_title'.tr()),
            subtitle: Text('debug.debug_mode_only'.tr()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.close'.tr()),
        ),
      ],
    );
  }
}
