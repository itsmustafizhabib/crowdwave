import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/locale/locale_detection_service.dart';

/// Language Confirmation Dialog
/// Shows when app first launches to confirm detected language
class LanguageConfirmationDialog extends StatelessWidget {
  final LocaleDetectionResult detectionResult;

  const LanguageConfirmationDialog({
    Key? key,
    required this.detectionResult,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required LocaleDetectionResult detectionResult,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LanguageConfirmationDialog(
        detectionResult: detectionResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flag/Icon
            Text(
              detectionResult.languageInfo.flag,
              style: const TextStyle(fontSize: 64),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              'language.detected_language'
                  .tr(namedArgs: {'country': detectionResult.countryName}),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Question
            Text(
              'language.continue_in_language'.tr(namedArgs: {
                'language': detectionResult.languageInfo.nativeName
              }),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // No button - Choose different language
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFF215C5C),
                      ),
                    ),
                    child: Text(
                      'language.choose_different'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF215C5C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Yes button - Continue
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Set the detected language
                      await context.setLocale(
                        Locale(detectionResult.languageCode),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF215C5C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'common.continue'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
