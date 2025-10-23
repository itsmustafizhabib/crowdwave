# Translation Updates Needed - Dart Files

## ✅ COMPLETED:
- Profile screens (3 files)
- Settings screen  
- Travel screen
- en.json (ALL 395+ keys added)

## 🔴 TODO - Replace hardcoded strings with .tr():

### 1. POST_PACKAGE_SCREEN.DART
**File:** `lib/presentation/post_package/post_package_screen.dart`
**Status:** Import added, title updated
**Remaining strings to replace:**
- Line 226: 'Package Details' → 'post_package.step_details'.tr()
- Line 228: 'Delivery Preferences' → 'post_package.step_preferences'.tr()
- Line 230: 'Set Compensation' → 'post_package.step_compensation'.tr()
- Line 241: 'Tell us about your package...' → 'post_package.subtitle_details'.tr()
- Line 258: 'Pickup Location' → 'post_package.pickup_location'.tr()
- Line 267: 'Destination' → 'post_package.destination'.tr()
- Line 348: 'Delivery Date' → 'post_package.delivery_date'.tr()
- Line 375: 'Preferred Delivery Date' → 'post_package.preferred_delivery_date'.tr()
- Line 427: 'Get better matches...' → 'post_package.flexible_hint'.tr()
- Line 440: 'Preferred Transport' → 'post_package.preferred_transport'.tr()
- Line 446: 'Special Instructions' → 'post_package.special_instructions'.tr()
- Line 475: 'Urgent Delivery' → 'post_package.urgent_delivery'.tr()
- Line 631: 'Back' → 'common.back'.tr()
- Line 667: 'Next' / 'Post Package' → Use ternary with .tr()
- Line 706-735: All validation messages (8 strings)
- Line 803: 'Please sign in to continue' → 'post_package.validation_signin'.tr()
- Line 842: 'Unknown' → Handle dynamically
- Line 894: 'package request' → 'post_package' context

### 2. POST_TRIP_SCREEN.DART
**File:** `lib/presentation/post_trip/post_trip_screen.dart`
**Status:** Not started
**Strings to replace:**
- Line 134: 'Post a Trip' → 'post_trip.title'.tr()
- Line 194: 'Departure Location' → 'post_trip.departure_location'.tr()
- Line 206: 'Destination Location' → 'post_trip.destination_location'.tr()
- Line 298: 'Back' → 'common.back'.tr()
- Line 332: 'Next' / 'Post Trip' → Use ternary with .tr()
- Lines 372-405: All 10 validation messages
- Line 472: 'Please sign in to continue' → 'post_trip.validation_signin'.tr()
- Line 480: 'Unknown' → Handle dynamically

### 3. WALLET_SCREEN.DART
**File:** `lib/presentation/wallet/wallet_screen.dart`
**Strings:** Title, balance labels, buttons, transaction types

### 4. WITHDRAWAL_SCREEN.DART  
**File:** `lib/presentation/wallet/withdrawal_screen.dart`
**Strings:** Form labels, validation, success/error messages

### 5. TRANSACTION_HISTORY_SCREEN.DART
**File:** `lib/presentation/wallet/transaction_history_screen.dart`
**Strings:** Column headers, status labels, empty states

### 6. BOOKING_CONFIRMATION_SCREEN.DART
**File:** `lib/presentation/booking/booking_confirmation_screen.dart`
**Strings:** Section titles, labels, buttons

### 7. PAYMENT_METHOD_SCREEN.DART
**File:** `lib/presentation/booking/payment_method_screen.dart`
**Strings:** Payment options, form fields

### 8. PAYMENT_PROCESSING_SCREEN.DART
**File:** `lib/presentation/booking/payment_processing_screen.dart`
**Strings:** Status messages

### 9. BOOKING_SUCCESS_SCREEN.DART
**File:** `lib/presentation/booking/booking_success_screen.dart`
**Strings:** Success messages, buttons

### 10. PAYMENT_FAILURE_SCREEN.DART
**File:** `lib/presentation/booking/payment_failure_screen.dart`
**Strings:** Error messages, retry button

### 11. MAKE_OFFER_SCREEN.DART
**File:** `lib/presentation/booking/make_offer_screen.dart`
**Strings:** Form labels, buttons

### 12. PACKAGE_DETAIL_SCREEN.DART
**File:** `lib/presentation/package_detail/package_detail_screen.dart`
**Strings:** All detail labels, buttons

### 13. TRIP_DETAIL_SCREEN.DART
**File:** `lib/presentation/trip_detail/trip_detail_screen.dart`
**Strings:** All detail labels, buttons

### 14. CHAT_SCREEN.DART
**File:** `lib/presentation/chat/chat_screen.dart`
**Strings:** Headers, empty states, menu options

### 15. INDIVIDUAL_CHAT_SCREEN.DART
**File:** `lib/presentation/chat/individual_chat_screen.dart`
**Strings:** Status text, send button, typing indicator

### 16. PACKAGE_TRACKING_SCREEN.DART
**File:** `lib/presentation/tracking/package_tracking_screen.dart`
**Strings:** Tracking labels, status updates

### 17. TRACKING_HISTORY_SCREEN.DART
**File:** `lib/presentation/tracking/tracking_history_screen.dart`
**Strings:** Timeline labels

### 18. DELIVERY_FEEDBACK_SCREEN.DART
**File:** `lib/presentation/tracking/delivery_feedback_screen.dart`
**Strings:** Rating labels, submit button

### 19. SENDER_CONFIRMATION_SCREEN.DART
**File:** `lib/presentation/tracking/sender_confirmation_screen.dart`
**Strings:** Confirmation messages

### 20. NOTIFICATION_SCREEN.DART
**File:** `lib/presentation/notifications/notification_screen.dart`
**Strings:** Headers, empty states

### 21. NOTIFICATION_SERVICE.DART ⚠️ CRITICAL
**File:** `lib/services/notification_service.dart`
**Strings:** ALL FCM notification titles and bodies (20+ strings)

### 22. CREATE_REVIEW_SCREEN.DART
**File:** `lib/presentation/reviews/create_review_screen.dart`
**Strings:** Form labels, submit button

### 23. REVIEW_LIST_SCREEN.DART
**File:** `lib/presentation/reviews/review_list_screen.dart`
**Strings:** Headers, empty states

### 24. KYC_COMPLETION_SCREEN.DART
**File:** `lib/presentation/screens/kyc/kyc_completion_screen.dart`
**Strings:** Form labels, upload buttons, status messages

### 25. ONBOARDING_FLOW_SCREEN.DART
**File:** `lib/presentation/onboarding_flow/onboarding_flow_screen.dart`
**Strings:** Welcome messages, step descriptions

### 26. ORDERS_SCREEN.DART (if not already done)
**File:** `lib/presentation/orders/orders_screen.dart`
**Check if already translated in orders section**

## APPROACH:
1. Add easy_localization import to each file
2. Replace ALL hardcoded strings with .tr() calls
3. After ALL files done, run: `python translate_json.py` ONCE
4. Test in app

## PRIORITY ORDER:
1. ⚡ **notification_service.dart** (affects all push notifications)
2. ⚡ **post_package/post_trip** screens (main user flows)
3. 🔸 booking/payment screens (critical transactions)
4. 🔸 detail screens (frequently viewed)
5. 🔹 wallet/tracking/chat (important features)
6. 🔹 reviews/kyc/onboarding (less frequent)
