# POST_PACKAGE_SCREEN.DART - Translation Replacements

## FILE: lib/presentation/post_package/post_package_screen.dart

### LINES 223-247: _getStepTitle() and _getStepDescription()

**REPLACE:**
```dart
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Pickup & Destination';
      case 1:
        return 'Package Details';
      case 2:
        return 'Delivery Preferences';
      case 3:
        return 'Set Compensation';
      default:
        return '';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Where should your package be picked up and delivered?';
      case 1:
        return 'Tell us about your package and upload photos';
      case 2:
        return 'When do you need it delivered and any special requirements?';
      case 3:
        return 'How much are you willing to pay for delivery?';
      default:
        return '';
    }
  }
```

**WITH:**
```dart
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'post_package.step_locations'.tr();
      case 1:
        return 'post_package.step_details'.tr();
      case 2:
        return 'post_package.step_preferences'.tr();
      case 3:
        return 'post_package.step_compensation'.tr();
      default:
        return '';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'post_package.subtitle_locations'.tr();
      case 1:
        return 'post_package.subtitle_details'.tr();
      case 2:
        return 'post_package.subtitle_preferences'.tr();
      case 3:
        return 'post_package.subtitle_compensation'.tr();
      default:
        return '';
    }
  }
```

---

### LINE 442: "Preferred Transport"

**REPLACE:** `_buildSectionTitle('Preferred Transport'),`

**WITH:** `_buildSectionTitle('post_package.preferred_transport'.tr()),`

---

### LINE 448: "Special Instructions"

**REPLACE:** `_buildSectionTitle('Special Instructions'),`

**WITH:** `_buildSectionTitle('post_package.special_instructions'.tr()),`

---

### LINE 453: Hint text

**REPLACE:** 
```dart
hintText: 'Any special handling instructions, delivery notes, or requirements...',
```

**WITH:**
```dart
hintText: 'post_package.special_instructions_hint'.tr(),
```

---

### LINE 474: "Urgent Delivery"

**REPLACE:**
```dart
title: Text(
  'Urgent Delivery',
```

**WITH:**
```dart
title: Text(
  'post_package.urgent_delivery'.tr(),
```

---

### LINE 479: Urgent subtitle

**REPLACE:**
```dart
subtitle: Text(
  'Mark as urgent for priority matching (+\$5 fee)',
```

**WITH:**
```dart
subtitle: Text(
  'post_package.urgent_subtitle'.tr(),
```

---

### LINE 632: "Back" button

**REPLACE:**
```dart
child: Text(
  'Back',
```

**WITH:**
```dart
child: Text(
  'common.back'.tr(),
```

---

### LINE 666: "Next" / "Post Package" button

**REPLACE:**
```dart
Text(
  _currentStep < _totalSteps - 1 ? 'Next' : 'Post Package',
```

**WITH:**
```dart
Text(
  _currentStep < _totalSteps - 1 
    ? 'common.next'.tr() 
    : 'post_package.submit_button'.tr(),
```

---

### LINES 728, 732, 738, 742: Validation error messages

**REPLACE:**
```dart
_showErrorSnackBar('Please select a package size');
```
**WITH:**
```dart
_showErrorSnackBar('post_package.validation_size'.tr());
```

**REPLACE:**
```dart
_showErrorSnackBar('Please enter a valid package weight');
```
**WITH:**
```dart
_showErrorSnackBar('post_package.validation_weight'.tr());
```

**REPLACE:**
```dart
_showErrorSnackBar('Please select a package type');
```
**WITH:**
```dart
_showErrorSnackBar('post_package.validation_type'.tr());
```

**REPLACE:**
```dart
_showErrorSnackBar('Minimum compensation is \$5.00');
```
**WITH:**
```dart
_showErrorSnackBar('post_package.validation_compensation_min'.tr());
```

---

## ADDITIONAL STRINGS TO FIND AND REPLACE:

Use Find & Replace (Ctrl+H) in VS Code:

1. **"Pickup Location"** → **'post_package.pickup_location'.tr()**
2. **"Destination"** → **'post_package.destination'.tr()**
3. **"Delivery Date"** → **'post_package.delivery_date'.tr()**
4. **"Preferred Delivery Date"** → **'post_package.preferred_delivery_date'.tr()**
5. **"Get better matches by allowing flexible delivery dates"** → **'post_package.flexible_hint'.tr()**
6. **"Please sign in to continue"** → **'post_package.validation_signin'.tr()**

---

## TRANSPORT MODES (if in this file):
- "Flight" → 'post_package.transport_flight'.tr()
- "Train" → 'post_package.transport_train'.tr()
- "Bus" → 'post_package.transport_bus'.tr()
- "Car" → 'post_package.transport_car'.tr()
- "Ship" → 'post_package.transport_ship'.tr()

---

## SUCCESS/ERROR MESSAGES (bottom of file):
Search for SnackBar messages and replace with:
- 'post_package.success_message'.tr()
- 'post_package.error_submit'.tr()
- 'post_package.error_location'.tr()

---

## AFTER ALL REPLACEMENTS:
1. Save file
2. Run: `flutter analyze` to check for errors
3. Move to post_trip_screen.dart
