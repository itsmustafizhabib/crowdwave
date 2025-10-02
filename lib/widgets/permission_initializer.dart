import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_manager_service.dart';
import '../services/zego_call_service.dart';

/// Widget that handles permission requests after app initialization
/// This prevents white screen issues by ensuring permissions are requested
/// after the UI is fully loaded and stable
class PermissionInitializer extends StatefulWidget {
  final Widget child;

  const PermissionInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PermissionInitializer> createState() => _PermissionInitializerState();
}

class _PermissionInitializerState extends State<PermissionInitializer> {
  bool _hasInitializedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Small delay to ensure UI is fully rendered before requesting permissions
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _initializePermissions();
      }
    });
  }

  Future<void> _initializePermissions() async {
    if (_hasInitializedPermissions) return;

    try {
      final permissionManager = PermissionManagerService.instance;

      // Request essential permissions in a coordinated way
      await permissionManager.requestEssentialPermissions();

      // Now that permissions are granted, initialize services that need them
      final zegoService = Get.find<ZegoCallService>();
      await zegoService.initializeZego();

      _hasInitializedPermissions = true;

      print('✅ Permission initialization completed successfully');
    } catch (e) {
      print('❌ Error during permission initialization: $e');
      // Continue anyway - app should still work with limited functionality
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
