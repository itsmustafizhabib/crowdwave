#!/usr/bin/env python3
"""
Script to automatically fix hardcoded strings identified in HARDCODED_STRINGS_REPORT.md
This script reads the report and applies the suggested changes to wrap strings with .tr()

Usage:
    python fix_hardcoded_strings_from_report.py
"""

import re
from pathlib import Path
from typing import List, Dict, Tuple

# Mapping of file paths to their changes (line number, old code, new code)
CHANGES = [
    # lib/widgets/trip_card_widget.dart
    {
        'file': 'lib/widgets/trip_card_widget.dart',
        'line': 338,
        'old': "content: Text('Error: ${e.toString()}'),",
        'new': "content: Text('error.generic'.tr(args: [e.toString()])),",
    },
    
    # lib/widgets/moderation_widgets.dart
    {
        'file': 'lib/widgets/moderation_widgets.dart',
        'line': 244,
        'old': "content: Text('Failed to report content: $e'),",
        'new': "content: Text('moderation.report_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/widgets/moderation_widgets.dart',
        'line': 671,
        'old': "content: Text('Review ${status.toString().split('.').last}'),",
        'new': "content: Text('moderation.review_status'.tr(args: [status.toString().split('.').last])),",
    },
    {
        'file': 'lib/widgets/moderation_widgets.dart',
        'line': 678,
        'old': "content: Text('Failed to update status: $e'),",
        'new': "content: Text('moderation.update_status_failed'.tr(args: [e.toString()])),",
    },
    
    # lib/widgets/comment_system_widget.dart
    {
        'file': 'lib/widgets/comment_system_widget.dart',
        'line': 97,
        'old': "content: Text('Failed to add comment: $e'),",
        'new': "content: Text('comments.add_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/widgets/comment_system_widget.dart',
        'line': 131,
        'old': "content: Text('Failed to ${like ? 'like' : 'unlike'} comment: $e'),",
        'new': "content: Text(like ? 'comments.like_failed'.tr(args: [e.toString()]) : 'comments.unlike_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/widgets/comment_system_widget.dart',
        'line': 445,
        'old': "content: Text('Failed to report comment: $e'),",
        'new': "content: Text('comments.report_failed'.tr(args: [e.toString()])),",
    },
    
    # lib/services/zego_call_service.dart
    {
        'file': 'lib/services/zego_call_service.dart',
        'line': 135,
        'old': "SnackBar(content: Text('Voice call failed: $e')),",
        'new': "SnackBar(content: Text('calls.voice_failed'.tr(args: [e.toString()]))),",
    },
    
    # lib/presentation/trip_detail/trip_detail_screen.dart
    {
        'file': 'lib/presentation/trip_detail/trip_detail_screen.dart',
        'line': 1193,
        'old': "content: Text('Match request sent to ${widget.trip.travelerName}!'),",
        'new': "content: Text('matching.request_sent'.tr(args: [widget.trip.travelerName])),",
    },
    {
        'file': 'lib/presentation/trip_detail/trip_detail_screen.dart',
        'line': 1314,
        'old': "content: Text('Failed to start chat: ${e.toString()}'),",
        'new': "content: Text('chat.start_failed'.tr(args: [e.toString()])),",
    },
    
    # lib/presentation/profile/profile_options_screen.dart
    {
        'file': 'lib/presentation/profile/profile_options_screen.dart',
        'line': 1397,
        'old': "content: Text('Failed to remove photo: $e'),",
        'new': "content: Text('profile.photo_remove_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/profile/profile_options_screen.dart',
        'line': 1415,
        'old': "content: Text('Error: $e'),",
        'new': "content: Text('error.generic'.tr(args: [e.toString()])),",
    },
    
    # lib/presentation/post_package/widgets/package_details_widget.dart
    {
        'file': 'lib/presentation/post_package/widgets/package_details_widget.dart',
        'line': 869,
        'old': "SnackBar(content: Text('Failed to pick image: $e')),",
        'new': "SnackBar(content: Text('image.pick_failed'.tr(args: [e.toString()]))),",
    },
    
    # lib/presentation/post_package/widgets/location_picker_widget.dart
    {
        'file': 'lib/presentation/post_package/widgets/location_picker_widget.dart',
        'line': 588,
        'old': "SnackBar(content: Text('Failed to get current location: $e')),",
        'new': "SnackBar(content: Text('location.get_current_failed'.tr(args: [e.toString()]))),",
    },
    {
        'file': 'lib/presentation/post_package/widgets/location_picker_widget.dart',
        'line': 1022,
        'old': "content: Text('Failed to get current location: $e'),",
        'new': "content: Text('location.get_current_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/post_package/widgets/location_picker_widget.dart',
        'line': 1149,
        'old': "content: Text('Network error: ${response.statusCode}'),",
        'new': "content: Text('error.network'.tr(args: [response.statusCode.toString()])),",
    },
    {
        'file': 'lib/presentation/post_package/widgets/location_picker_widget.dart',
        'line': 1160,
        'old': "content: Text('Error: $e'),",
        'new': "content: Text('error.generic'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/post_package/widgets/location_picker_widget.dart',
        'line': 1224,
        'old': "SnackBar(content: Text('Error selecting location: $e')),",
        'new': "SnackBar(content: Text('location.select_failed'.tr(args: [e.toString()]))),",
    },
    
    # lib/presentation/main_navigation/main_navigation_screen.dart
    {
        'file': 'lib/presentation/main_navigation/main_navigation_screen.dart',
        'line': 888,
        'old': "content: Text('Error logging out: $errorMessage'),",
        'new': "content: Text('auth.logout_failed'.tr(args: [errorMessage])),",
    },
    
    # lib/presentation/chat/individual_chat_screen.dart
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1060,
        'old': "content: Text('Voice call failed: $e'),",
        'new': "content: Text('calls.voice_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1086,
        'old': "content: Text('Video call failed: $e'),",
        'new': "content: Text('calls.video_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1136,
        'old': "title: const Text('Send Current Location'),",
        'new': "title: Text('location.send_current'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1137,
        'old': "subtitle: const Text('Share your current location once'),",
        'new': "subtitle: Text('location.send_current_description'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1157,
        'old': "title: const Text('Share Live Location'),",
        'new': "title: Text('location.share_live'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1158,
        'old': "subtitle: const Text('Share your location for 15 minutes'),",
        'new': "subtitle: Text('location.share_live_description'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1233,
        'old': "title: const Text('Location Permission Required'),",
        'new': "title: Text('permissions.location_required'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1263,
        'old': "title: const Text('Location Permission Required'),",
        'new': "title: Text('permissions.location_required'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1369,
        'old': "title: const Text('Location Permission Required'),",
        'new': "title: Text('permissions.location_required'.tr()),",
    },
    {
        'file': 'lib/presentation/chat/individual_chat_screen.dart',
        'line': 1398,
        'old': "title: const Text('Location Permission Required'),",
        'new': "title: Text('permissions.location_required'.tr()),",
    },
    
    # lib/presentation/call/incoming_call_screen.dart
    {
        'file': 'lib/presentation/call/incoming_call_screen.dart',
        'line': 172,
        'old': "SnackBar(content: Text('Failed to accept call: $e')),",
        'new': "SnackBar(content: Text('calls.accept_failed'.tr(args: [e.toString()]))),",
    },
    
    # lib/presentation/booking/payment_method_screen.dart
    {
        'file': 'lib/presentation/booking/payment_method_screen.dart',
        'line': 53,
        'old': "content: Text('Failed to initialize payment service: $e'),",
        'new': "content: Text('payment.init_failed'.tr(args: [e.toString()])),",
    },
    {
        'file': 'lib/presentation/booking/payment_method_screen.dart',
        'line': 361,
        'old': "content: Text('Error: $e'),",
        'new': "content: Text('error.generic'.tr(args: [e.toString()])),",
    },
    
    # lib/presentation/booking/make_offer_screen.dart
    {
        'file': 'lib/presentation/booking/make_offer_screen.dart',
        'line': 500,
        'old': "ToastUtils.show('Submitted');",
        'new': "ToastUtils.show('offer.submitted'.tr());",
    },
    {
        'file': 'lib/presentation/booking/make_offer_screen.dart',
        'line': 539,
        'old': "ToastUtils.show('Submitted');",
        'new': "ToastUtils.show('offer.submitted'.tr());",
    },
    {
        'file': 'lib/presentation/booking/make_offer_screen.dart',
        'line': 556,
        'old': "ToastUtils.show('Error: $errorMessage');",
        'new': "ToastUtils.show('error.generic'.tr(args: [errorMessage]));",
    },
    
    # lib/presentation/tracking/tracking_status_update_screen.dart
    {
        'file': 'lib/presentation/tracking/tracking_status_update_screen.dart',
        'line': 666,
        'old': "ToastUtils.show('Updated');",
        'new': "ToastUtils.show('tracking.updated'.tr());",
    },
    
    # lib/presentation/screens/matching/matching_screen.dart
    {
        'file': 'lib/presentation/screens/matching/matching_screen.dart',
        'line': 647,
        'old': "Get.snackbar('Error', 'No package selected for matching');",
        'new': "Get.snackbar('error.title'.tr(), 'matching.no_package_selected'.tr());",
    },
    {
        'file': 'lib/presentation/screens/matching/matching_screen.dart',
        'line': 655,
        'old': "Get.snackbar('Error', 'No package request provided');",
        'new': "Get.snackbar('error.title'.tr(), 'matching.no_package_request'.tr());",
    },
    {
        'file': 'lib/presentation/screens/matching/matching_screen.dart',
        'line': 679,
        'old': "Get.snackbar('Contact', 'Opening chat with ${trip.travelerName}');",
        'new': "Get.snackbar('contact.title'.tr(), 'contact.opening_chat'.tr(args: [trip.travelerName]));",
    },
    {
        'file': 'lib/presentation/screens/matching/matching_screen.dart',
        'line': 684,
        'old': "Get.snackbar('Details', 'Viewing details for ${suggestion.title}');",
        'new': "Get.snackbar('details.title'.tr(), 'details.viewing'.tr(args: [suggestion.title]));",
    },
    {
        'file': 'lib/presentation/screens/matching/matching_screen.dart',
        'line': 807,
        'old': "Get.snackbar('Error', 'Please enter a valid price');",
        'new': "Get.snackbar('error.title'.tr(), 'validation.invalid_price'.tr());",
    },
    
    # lib/controllers/smart_matching_controller.dart
    {
        'file': 'lib/controllers/smart_matching_controller.dart',
        'line': 100,
        'old': "Get.snackbar('Error', 'Failed to load suggestions: $e');",
        'new': "Get.snackbar('error.title'.tr(), 'matching.load_suggestions_failed'.tr(args: [e.toString()]));",
    },
    {
        'file': 'lib/controllers/smart_matching_controller.dart',
        'line': 190,
        'old': "Get.snackbar('Error', 'Failed to find matches: $e');",
        'new': "Get.snackbar('error.title'.tr(), 'matching.find_matches_failed'.tr(args: [e.toString()]));",
    },
]


def read_file_lines(file_path: Path) -> List[str]:
    """Read file and return list of lines."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.readlines()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return []


def write_file_lines(file_path: Path, lines: List[str]) -> bool:
    """Write lines to file."""
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        return True
    except Exception as e:
        print(f"Error writing {file_path}: {e}")
        return False


def apply_change(file_path: Path, line_num: int, old_text: str, new_text: str) -> bool:
    """Apply a single change to a file."""
    lines = read_file_lines(file_path)
    if not lines:
        return False
    
    # Convert to 0-based index
    idx = line_num - 1
    
    if idx < 0 or idx >= len(lines):
        print(f"  ⚠️  Line {line_num} is out of range (file has {len(lines)} lines)")
        return False
    
    # Check if the line contains the old text (flexible matching)
    line = lines[idx]
    
    # Strip whitespace for comparison but preserve original indentation
    if old_text.strip() in line.strip():
        # Get the indentation of the original line
        indent = len(line) - len(line.lstrip())
        # Apply new text with same indentation
        lines[idx] = ' ' * indent + new_text.strip() + '\n'
        
        if write_file_lines(file_path, lines):
            return True
    else:
        print(f"  ⚠️  Line {line_num} doesn't match expected text")
        print(f"     Expected: {old_text.strip()}")
        print(f"     Found:    {line.strip()}")
        return False
    
    return False


def main():
    """Main function to apply all changes."""
    print("=" * 80)
    print("Fixing Hardcoded Strings from HARDCODED_STRINGS_REPORT.md")
    print("=" * 80)
    print()
    
    # Group changes by file
    files_dict: Dict[str, List[Dict]] = {}
    for change in CHANGES:
        file_path = change['file']
        if file_path not in files_dict:
            files_dict[file_path] = []
        files_dict[file_path].append(change)
    
    print(f"Found {len(CHANGES)} changes across {len(files_dict)} files\n")
    
    success_count = 0
    failed_count = 0
    skipped_count = 0
    
    for file_rel_path, file_changes in files_dict.items():
        file_path = Path(file_rel_path)
        
        if not file_path.exists():
            print(f"❌ {file_rel_path} - File not found")
            skipped_count += len(file_changes)
            continue
        
        print(f"📝 {file_rel_path}")
        print(f"   Applying {len(file_changes)} change(s)...")
        
        # Sort changes by line number in descending order to avoid line number shifts
        sorted_changes = sorted(file_changes, key=lambda x: x['line'], reverse=True)
        
        file_success = 0
        for change in sorted_changes:
            if apply_change(file_path, change['line'], change['old'], change['new']):
                file_success += 1
                success_count += 1
                print(f"   ✓ Line {change['line']}")
            else:
                failed_count += 1
                print(f"   ✗ Line {change['line']} - FAILED")
        
        print(f"   Result: {file_success}/{len(file_changes)} changes applied\n")
    
    # Summary
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total changes: {len(CHANGES)}")
    print(f"✓ Successfully applied: {success_count}")
    print(f"✗ Failed: {failed_count}")
    print(f"⊘ Skipped (file not found): {skipped_count}")
    print()
    
    if success_count > 0:
        print("=" * 80)
        print("NEXT STEPS")
        print("=" * 80)
        print("1. Review the changes to ensure they're correct")
        print("2. Run 'flutter pub get' if needed")
        print("3. Test the app to ensure all translations work")
        print("4. Run the app and check for any runtime errors")
        print("5. If translations don't appear, run your translation script:")
        print("   python translate_all_languages.py")
        print()
    
    if failed_count > 0:
        print("⚠️  Some changes failed. This could be because:")
        print("   - The line numbers have changed since the report was generated")
        print("   - The code has already been modified")
        print("   - The file structure is different")
        print()
        print("   You may need to manually apply these changes.")
        print()
    
    return 0 if failed_count == 0 else 1


if __name__ == '__main__':
    exit(main())
