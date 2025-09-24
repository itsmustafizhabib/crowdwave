import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../services/presence_service.dart';

class AppLifecycleController extends GetxController
    with WidgetsBindingObserver {
  final PresenceService _presenceService = Get.find<PresenceService>();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print('App lifecycle state changed: $state');
    }

    // Handle presence updates based on app lifecycle
    _presenceService.handleAppLifecycleChange(state);
  }
}
