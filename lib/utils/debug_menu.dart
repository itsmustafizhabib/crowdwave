import 'package:flutter/material.dart';
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
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text('Debug Menu'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Test Screen'),
            subtitle: const Text('Test email verification & password reset'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.emailTest);
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('Debug Menu'),
            subtitle: Text('Available only in debug mode'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
