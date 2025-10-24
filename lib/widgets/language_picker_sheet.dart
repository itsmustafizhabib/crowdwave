import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import '../translations/supported_locales.dart';

/// Language Picker Bottom Sheet
/// Shows a beautiful list of all supported languages
class LanguagePickerSheet extends StatelessWidget {
  final Function(String languageCode) onLanguageSelected;

  const LanguagePickerSheet({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Function(String languageCode) onLanguageSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguagePickerSheet(
        onLanguageSelected: onLanguageSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'language.select_language'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 1),

          // Language list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: SupportedLocales.languages.length,
              itemBuilder: (context, index) {
                final langCode = SupportedLocales.supportedLanguageCodes[index];
                final langInfo = SupportedLocales.languages[langCode]!;
                final isSelected = context.locale.languageCode == langCode;

                return ListTile(
                  leading: Text(
                    langInfo.flag,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    langInfo.nativeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    langInfo.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF215C5C),
                        )
                      : null,
                  onTap: () async {
                    // Change language
                    await context.setLocale(Locale(langCode));

                    // Call the callback to save preference
                    onLanguageSelected(langCode);

                    // Pop the bottom sheet
                    if (context.mounted) {
                      Navigator.pop(context);

                      // Force GetX to rebuild by updating the locale
                      Get.updateLocale(Locale(langCode));

                      // Force a complete app rebuild
                      await Future.delayed(const Duration(milliseconds: 100));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
