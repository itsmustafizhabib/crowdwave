import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/locale/locale_detection_service.dart';
import 'language_confirmation_dialog.dart';
import 'language_picker_sheet.dart';

class LocaleInitializer extends StatefulWidget {
  final Widget child;

  const LocaleInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<LocaleInitializer> createState() => _LocaleInitializerState();
}

class _LocaleInitializerState extends State<LocaleInitializer> {
  @override
  void initState() {
    super.initState();
    // Language detection dialog disabled
    // _checkAndShowLanguageDialog();
  }

  Future<void> _checkAndShowLanguageDialog() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final localeService = Get.find<LocaleDetectionService>();
      final shouldShowDialog = await localeService.shouldShowLanguageDialog();

      if (!shouldShowDialog || !mounted) return;

      final detectionResult = await localeService.detectLocale();

      if (!mounted) return;

      final bool? confirmed = await LanguageConfirmationDialog.show(
        context: context,
        detectionResult: detectionResult,
      );

      if (confirmed == true) {
        await localeService.markLanguageDialogShown();
      } else if (confirmed == false) {
        await _showLanguagePicker();
        await localeService.markLanguageDialogShown();
      }
    } catch (e) {
      print('Error checking language dialog: $e');
    }
  }

  Future<void> _showLanguagePicker() async {
    await LanguagePickerSheet.show(
      context: context,
      onLanguageSelected: (String languageCode) async {
        final localeService = Get.find<LocaleDetectionService>();
        await localeService.updateLocale(languageCode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
