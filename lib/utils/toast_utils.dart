import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastUtils {
  /// Shows a minimal bottom toast. If [title] is provided, it's concatenated
  /// with the [message] using an en dash separator.
  static void show(String message, {String? title, Duration? duration}) {
    final text = (title != null && title.trim().isNotEmpty)
        ? '${title.trim()} — ${message.trim()}'
        : message.trim();

    if (text.isEmpty) return;

    // Dismiss any existing snackbar to avoid stacking
    if (Get.isSnackbarOpen) {
      Get.back();
    }

    final context = Get.context;
    final isDark =
        context != null && Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    Get.rawSnackbar(
      messageText: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          shadows: const [
            Shadow(
                offset: Offset(0, 0.5), blurRadius: 0.5, color: Colors.black26),
          ],
        ),
      ),
      backgroundColor: Colors.transparent, // no background color
      borderRadius: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24), // slightly above bottom
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6), // minimal padding
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.down,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }
}
