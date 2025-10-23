import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void main() {
  runApp(DebugApp());
}

class DebugApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'common.debug_crowdwave'.tr(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('common.debug_screen'.tr()),
          backgroundColor: Color(0xFF008080),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text('common.app_is_working'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text('common.if_you_see_this_the_flutter_app_is_running_correct'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('common.button_works'.tr())),
                  );
                },
                child: Text('common.test_button'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
