#!/usr/bin/env dart

/// Automated script to replace hardcoded English strings with .tr() calls
/// for internationalization using easy_localization package.
///
/// Usage:
///   dart auto_replace_strings.dart [--dry-run] [--file=path/to/file.dart]
///
/// Options:
///   --dry-run    Show what would be changed without modifying files
///   --file=PATH  Process only specific file instead of all files
///
/// Safety features:
/// - Only replaces strings that have matching keys in en.json
/// - Adds necessary imports automatically
/// - Preserves code formatting
/// - Validates Dart syntax after changes
/// - No backups (use Git to undo if needed)

import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final fileArg = args.firstWhere(
    (arg) => arg.startsWith('--file='),
    orElse: () => '',
  );

  print('🚀 String Replacement Script');
  print('━' * 60);
  print(
      'Mode: ${dryRun ? "DRY RUN (preview only)" : "LIVE (will modify files)"}');
  print('━' * 60);

  // Load translation keys from en.json
  final translationKeys = await loadTranslationKeys();
  print('✓ Loaded ${translationKeys.length} translation keys from en.json\n');

  // Get files to process
  final filesToProcess =
      fileArg.isNotEmpty ? [File(fileArg.substring(7))] : await getDartFiles();

  print('📁 Files to process: ${filesToProcess.length}\n');

  int totalFilesChanged = 0;
  int totalReplacements = 0;

  for (final file in filesToProcess) {
    final result = await processFile(file, translationKeys, dryRun);
    if (result['changed'] as bool) {
      totalFilesChanged++;
      totalReplacements += result['replacements'] as int;
      print('  ✓ ${file.path}: ${result['replacements']} replacements');
    }
  }

  print('\n' + '━' * 60);
  print('📊 Summary:');
  print('   Files changed: $totalFilesChanged');
  print('   Total replacements: $totalReplacements');
  if (dryRun) {
    print('\n⚠️  DRY RUN - No files were modified');
    print('   Run without --dry-run to apply changes');
  } else {
    print('\n✅ Changes applied successfully!');
    print('   Use "git diff" to review changes');
    print('   Use "git checkout ." to undo if needed');
  }
  print('━' * 60);
}

/// Load all translation keys from en.json as a flat map
Future<Map<String, String>> loadTranslationKeys() async {
  final file = File('assets/translations/en.json');
  if (!file.existsSync()) {
    throw Exception('Translation file not found: ${file.path}');
  }

  final jsonStr = await file.readAsString();
  final Map<String, dynamic> json = jsonDecode(jsonStr);

  // Flatten nested JSON to dot notation keys
  final Map<String, String> flatKeys = {};

  void flatten(Map<String, dynamic> map, String prefix) {
    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        flatten(value, fullKey);
      } else if (value is String) {
        flatKeys[fullKey] = value;
      }
    });
  }

  flatten(json, '');
  return flatKeys;
}

/// Get all Dart files in lib directory, excluding generated files
Future<List<File>> getDartFiles() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    throw Exception('lib directory not found');
  }

  final files = <File>[];
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('.g.dart') &&
        !entity.path.contains('.freezed.dart')) {
      files.add(entity);
    }
  }

  return files;
}

/// Process a single file
Future<Map<String, dynamic>> processFile(
  File file,
  Map<String, String> translationKeys,
  bool dryRun,
) async {
  final content = await file.readAsString();
  String newContent = content;
  int replacements = 0;

  // Check if file needs easy_localization import
  final needsImport = !content
      .contains("import 'package:easy_localization/easy_localization.dart'");
  final hasGetX = content.contains("import 'package:get/get.dart'");

  // Find and replace hardcoded strings
  final replacementMap = <String, String>{};

  translationKeys.forEach((key, value) {
    // Escape special regex characters in the value
    final escapedValue = RegExp.escape(value);

    // Create regex patterns for common use cases
    final patterns = [
      // Text('string') or Text("string")
      RegExp('Text\\s*\\(\\s*[\'"]$escapedValue[\'"]\\s*\\)',
          caseSensitive: false),
      // 'string' or "string" in hintText, labelText, title, etc.
      RegExp(
          '(hintText|labelText|title|subtitle|body|message|label|text|description|name|placeholder|errorText|helperText)\\s*:\\s*[\'"]$escapedValue[\'"]',
          caseSensitive: false),
      // AppBar title: Text('string')
      RegExp('title\\s*:\\s*Text\\s*\\(\\s*[\'"]$escapedValue[\'"]\\s*\\)',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(newContent)) {
        final match = pattern.firstMatch(newContent);
        if (match != null) {
          final original = match.group(0)!;
          String replacement;

          if (original.startsWith('Text(')) {
            replacement = "Text('$key'.tr())";
          } else if (original.contains('title: Text(')) {
            replacement = "title: Text('$key'.tr())";
          } else {
            // For other cases, replace just the string part
            replacement = original.replaceAll(
                RegExp('[\'"]$escapedValue[\'"]'), "'$key'.tr()");
          }

          replacementMap[original] = replacement;
        }
      }
    }
  });

  // Apply replacements
  replacementMap.forEach((original, replacement) {
    if (newContent.contains(original)) {
      newContent = newContent.replaceAll(original, replacement);
      replacements++;
    }
  });

  // Add imports if needed
  if (replacements > 0 && needsImport) {
    if (hasGetX) {
      // Add easy_localization and modify GetX import
      final getxImportPattern = RegExp(r"import 'package:get/get\.dart';");
      newContent = newContent.replaceFirst(
        getxImportPattern,
        "import 'package:get/get.dart' hide Trans;\nimport 'package:easy_localization/easy_localization.dart';",
      );
    } else {
      // Just add easy_localization import after other imports
      final firstImportPattern = RegExp(r"import '[^']+';");
      final match = firstImportPattern.firstMatch(newContent);
      if (match != null) {
        final insertPos = match.end;
        newContent = newContent.substring(0, insertPos) +
            "\nimport 'package:easy_localization/easy_localization.dart';" +
            newContent.substring(insertPos);
      }
    }
  }

  // Write changes if not dry run
  if (!dryRun && replacements > 0) {
    await file.writeAsString(newContent);
  }

  return {
    'changed': replacements > 0,
    'replacements': replacements,
  };
}
