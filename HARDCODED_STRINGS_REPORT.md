# Hardcoded English Strings Report

Generated: October 24, 2025

This report identifies hardcoded English strings in toasts, alerts, snackbars, and dialogs that need to be wrapped with `.tr()` for translation support.

---

## 🔴 CRITICAL ISSUES - User-Facing Messages

### 1. **lib/widgets/trip_card_widget.dart**
**Line 338:**
```dart
content: Text('Error: ${e.toString()}'),
```
**Should be:**
```dart
content: Text('error.generic'.tr(args: [e.toString()])),
```

---

### 2. **lib/widgets/moderation_widgets.dart**
**Line 244:**
```dart
content: Text('Failed to report content: $e'),
```
**Should be:**
```dart
content: Text('moderation.report_failed'.tr(args: [e.toString()])),
```

**Line 671:**
```dart
content: Text('Review ${status.toString().split('.').last}'),
```
**Should be:**
```dart
content: Text('moderation.review_status'.tr(args: [status.toString().split('.').last])),
```

**Line 678:**
```dart
content: Text('Failed to update status: $e'),
```
**Should be:**
```dart
content: Text('moderation.update_status_failed'.tr(args: [e.toString()])),
```

---

### 3. **lib/widgets/comment_system_widget.dart**
**Line 97:**
```dart
content: Text('Failed to add comment: $e'),
```
**Should be:**
```dart
content: Text('comments.add_failed'.tr(args: [e.toString()])),
```

**Line 131:**
```dart
content: Text('Failed to ${like ? 'like' : 'unlike'} comment: $e'),
```
**Should be:**
```dart
content: Text(like ? 'comments.like_failed'.tr(args: [e.toString()]) : 'comments.unlike_failed'.tr(args: [e.toString()])),
```

**Line 445:**
```dart
content: Text('Failed to report comment: $e'),
```
**Should be:**
```dart
content: Text('comments.report_failed'.tr(args: [e.toString()])),
```

---

### 4. **lib/services/zego_call_service.dart**
**Line 135:**
```dart
SnackBar(content: Text('Voice call failed: $e')),
```
**Should be:**
```dart
SnackBar(content: Text('calls.voice_failed'.tr(args: [e.toString()]))),
```

---

### 5. **lib/presentation/trip_detail/trip_detail_screen.dart**
**Line 1193:**
```dart
content: Text('Match request sent to ${widget.trip.travelerName}!'),
```
**Should be:**
```dart
content: Text('matching.request_sent'.tr(args: [widget.trip.travelerName])),
```

**Line 1314:**
```dart
content: Text('Failed to start chat: ${e.toString()}'),
```
**Should be:**
```dart
content: Text('chat.start_failed'.tr(args: [e.toString()])),
```

---

### 6. **lib/presentation/profile/profile_options_screen.dart**
**Line 1397:**
```dart
content: Text('Failed to remove photo: $e'),
```
**Should be:**
```dart
content: Text('profile.photo_remove_failed'.tr(args: [e.toString()])),
```

**Line 1415:**
```dart
content: Text('Error: $e'),
```
**Should be:**
```dart
content: Text('error.generic'.tr(args: [e.toString()])),
```

---

### 7. **lib/presentation/post_package/widgets/package_details_widget.dart**
**Line 869:**
```dart
SnackBar(content: Text('Failed to pick image: $e')),
```
**Should be:**
```dart
SnackBar(content: Text('image.pick_failed'.tr(args: [e.toString()]))),
```

---

### 8. **lib/presentation/post_package/widgets/location_picker_widget.dart**
**Line 588:**
```dart
SnackBar(content: Text('Failed to get current location: $e')),
```
**Should be:**
```dart
SnackBar(content: Text('location.get_current_failed'.tr(args: [e.toString()]))),
```

**Line 1022:**
```dart
content: Text('Failed to get current location: $e'),
```
**Should be:**
```dart
content: Text('location.get_current_failed'.tr(args: [e.toString()])),
```

**Line 1149:**
```dart
content: Text('Network error: ${response.statusCode}'),
```
**Should be:**
```dart
content: Text('error.network'.tr(args: [response.statusCode.toString()])),
```

**Line 1160:**
```dart
content: Text('Error: $e'),
```
**Should be:**
```dart
content: Text('error.generic'.tr(args: [e.toString()])),
```

**Line 1224:**
```dart
SnackBar(content: Text('Error selecting location: $e')),
```
**Should be:**
```dart
SnackBar(content: Text('location.select_failed'.tr(args: [e.toString()]))),
```

---

### 9. **lib/presentation/main_navigation/main_navigation_screen.dart**
**Line 888:**
```dart
content: Text('Error logging out: $errorMessage'),
```
**Should be:**
```dart
content: Text('auth.logout_failed'.tr(args: [errorMessage])),
```

---

### 10. **lib/presentation/chat/individual_chat_screen.dart**
**Line 1060:**
```dart
content: Text('Voice call failed: $e'),
```
**Should be:**
```dart
content: Text('calls.voice_failed'.tr(args: [e.toString()])),
```

**Line 1086:**
```dart
content: Text('Video call failed: $e'),
```
**Should be:**
```dart
content: Text('calls.video_failed'.tr(args: [e.toString()])),
```

**Line 1136:**
```dart
title: const Text('Send Current Location'),
```
**Should be:**
```dart
title: Text('location.send_current'.tr()),
```

**Line 1137:**
```dart
subtitle: const Text('Share your current location once'),
```
**Should be:**
```dart
subtitle: Text('location.send_current_description'.tr()),
```

**Line 1157:**
```dart
title: const Text('Share Live Location'),
```
**Should be:**
```dart
title: Text('location.share_live'.tr()),
```

**Line 1158:**
```dart
subtitle: const Text('Share your location for 15 minutes'),
```
**Should be:**
```dart
subtitle: Text('location.share_live_description'.tr()),
```

**Line 1233:**
```dart
title: const Text('Location Permission Required'),
```
**Should be:**
```dart
title: Text('permissions.location_required'.tr()),
```

**Line 1263:**
```dart
title: const Text('Location Permission Required'),
```
**Should be:**
```dart
title: Text('permissions.location_required'.tr()),
```

**Line 1369:**
```dart
title: const Text('Location Permission Required'),
```
**Should be:**
```dart
title: Text('permissions.location_required'.tr()),
```

**Line 1398:**
```dart
title: const Text('Location Permission Required'),
```
**Should be:**
```dart
title: Text('permissions.location_required'.tr()),
```

---

### 11. **lib/presentation/call/incoming_call_screen.dart**
**Line 172:**
```dart
SnackBar(content: Text('Failed to accept call: $e')),
```
**Should be:**
```dart
SnackBar(content: Text('calls.accept_failed'.tr(args: [e.toString()]))),
```

---

### 12. **lib/presentation/booking/payment_method_screen.dart**
**Line 53:**
```dart
content: Text('Failed to initialize payment service: $e'),
```
**Should be:**
```dart
content: Text('payment.init_failed'.tr(args: [e.toString()])),
```

**Line 361:**
```dart
content: Text('Error: $e'),
```
**Should be:**
```dart
content: Text('error.generic'.tr(args: [e.toString()])),
```

---

### 13. **lib/presentation/booking/make_offer_screen.dart**
**Line 500:**
```dart
ToastUtils.show('Submitted');
```
**Should be:**
```dart
ToastUtils.show('offer.submitted'.tr());
```

**Line 539:**
```dart
ToastUtils.show('Submitted');
```
**Should be:**
```dart
ToastUtils.show('offer.submitted'.tr());
```

**Line 556:**
```dart
ToastUtils.show('Error: $errorMessage');
```
**Should be:**
```dart
ToastUtils.show('error.generic'.tr(args: [errorMessage]));
```

---

### 14. **lib/presentation/tracking/tracking_status_update_screen.dart**
**Line 666:**
```dart
ToastUtils.show('Updated');
```
**Should be:**
```dart
ToastUtils.show('tracking.updated'.tr());
```

---

### 15. **lib/presentation/screens/matching/matching_screen.dart**
**Line 647:**
```dart
Get.snackbar('Error', 'No package selected for matching');
```
**Should be:**
```dart
Get.snackbar('error.title'.tr(), 'matching.no_package_selected'.tr());
```

**Line 655:**
```dart
Get.snackbar('Error', 'No package request provided');
```
**Should be:**
```dart
Get.snackbar('error.title'.tr(), 'matching.no_package_request'.tr());
```

**Line 679:**
```dart
Get.snackbar('Contact', 'Opening chat with ${trip.travelerName}');
```
**Should be:**
```dart
Get.snackbar('contact.title'.tr(), 'contact.opening_chat'.tr(args: [trip.travelerName]));
```

**Line 684:**
```dart
Get.snackbar('Details', 'Viewing details for ${suggestion.title}');
```
**Should be:**
```dart
Get.snackbar('details.title'.tr(), 'details.viewing'.tr(args: [suggestion.title]));
```

**Line 807:**
```dart
Get.snackbar('Error', 'Please enter a valid price');
```
**Should be:**
```dart
Get.snackbar('error.title'.tr(), 'validation.invalid_price'.tr());
```

---

### 16. **lib/controllers/smart_matching_controller.dart**
**Line 100:**
```dart
Get.snackbar('Error', 'Failed to load suggestions: $e');
```
**Should be:**
```dart
Get.snackbar('error.title'.tr(), 'matching.load_suggestions_failed'.tr(args: [e.toString()]));
```

**Line 190:**
```dart
Get.snackbar('Error', 'Failed to find matches: $e');
```
**Should be:**
```dart
Get.snackbar('error.title'.tr(), 'matching.find_matches_failed'.tr(args: [e.toString()]));
```

---

## 🟡 LOWER PRIORITY - Demo/Debug Content

### 17. **lib/presentation/enhanced_ui_showcase_screen.dart**
**Line 188:**
```dart
subtitle: Text('Step-by-step form with smooth animations'),
```
**Note:** This appears to be demo UI. If it's user-facing, should use `.tr()`

---

### 18. **lib/apple_signin_demo.dart**
**Line 38:**
```dart
title: Text('Apple Sign-In Demo'),
```

**Line 81:**
```dart
content: Text('Signed in: ${userCredential.user?.uid}'),
```

**Line 89:**
```dart
content: Text('Apple sign in failed: $e'),
```
**Note:** Demo file, but should still be translated if shown to users.

---

## 📋 Summary

**Total Hardcoded Strings Found:** 47

**By Category:**
- Error Messages: 25
- Success Messages: 4
- Dialog Titles/Labels: 8
- Button Labels: 0 (✅ All appear to use .tr())
- Get.snackbar titles: 7
- Demo/Debug: 3

**Priority:**
- 🔴 High Priority (User-facing): 44 strings
- 🟡 Low Priority (Demo/Debug): 3 strings

---

## 🎯 Recommended Translation Keys to Add

Add these keys to your translation files (e.g., `assets/translations/en.json`):

```json
{
  "error": {
    "title": "Error",
    "generic": "Error: {{0}}",
    "network": "Network error: {{0}}"
  },
  "moderation": {
    "report_failed": "Failed to report content: {{0}}",
    "review_status": "Review {{0}}",
    "update_status_failed": "Failed to update status: {{0}}"
  },
  "comments": {
    "add_failed": "Failed to add comment: {{0}}",
    "like_failed": "Failed to like comment: {{0}}",
    "unlike_failed": "Failed to unlike comment: {{0}}",
    "report_failed": "Failed to report comment: {{0}}"
  },
  "calls": {
    "voice_failed": "Voice call failed: {{0}}",
    "video_failed": "Video call failed: {{0}}",
    "accept_failed": "Failed to accept call: {{0}}"
  },
  "matching": {
    "request_sent": "Match request sent to {{0}}!",
    "no_package_selected": "No package selected for matching",
    "no_package_request": "No package request provided",
    "load_suggestions_failed": "Failed to load suggestions: {{0}}",
    "find_matches_failed": "Failed to find matches: {{0}}"
  },
  "chat": {
    "start_failed": "Failed to start chat: {{0}}"
  },
  "profile": {
    "photo_remove_failed": "Failed to remove photo: {{0}}"
  },
  "image": {
    "pick_failed": "Failed to pick image: {{0}}"
  },
  "location": {
    "get_current_failed": "Failed to get current location: {{0}}",
    "select_failed": "Error selecting location: {{0}}",
    "send_current": "Send Current Location",
    "send_current_description": "Share your current location once",
    "share_live": "Share Live Location",
    "share_live_description": "Share your location for 15 minutes"
  },
  "permissions": {
    "location_required": "Location Permission Required"
  },
  "auth": {
    "logout_failed": "Error logging out: {{0}}"
  },
  "payment": {
    "init_failed": "Failed to initialize payment service: {{0}}"
  },
  "offer": {
    "submitted": "Submitted"
  },
  "tracking": {
    "updated": "Updated"
  },
  "contact": {
    "title": "Contact",
    "opening_chat": "Opening chat with {{0}}"
  },
  "details": {
    "title": "Details",
    "viewing": "Viewing details for {{0}}"
  },
  "validation": {
    "invalid_price": "Please enter a valid price"
  }
}
```

---

## ✅ Next Steps

1. Add the recommended translation keys to all language files
2. Update each hardcoded string with `.tr()` calls
3. Test all error scenarios to ensure translations work correctly
4. Consider creating a utility function for common error message patterns
5. Run the translation verification script again to confirm all strings are wrapped

---

**Note:** All error messages that include exception details should use `e.toString()` rather than just `$e` for consistency.
