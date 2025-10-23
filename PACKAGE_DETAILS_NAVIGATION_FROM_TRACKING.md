# Package Details Navigation from Tracking Screen

## Summary
Added the ability to navigate from the package tracking screen to the package details screen, allowing users to view complete information about the package they're tracking.

## Changes Made

### 1. `package_tracking_screen.dart`

#### Added Import
- Imported `PackageDetailScreen` from `../package_detail/package_detail_screen.dart`

#### Added Navigation Method
```dart
void _navigateToPackageDetails() {
  if (_packageRequest == null) return;
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PackageDetailScreen(
        package: _packageRequest!,
      ),
    ),
  );
}
```

#### Updated App Bar
- Added info icon button in the app bar actions (next to refresh button)
- Button only appears when package data is loaded
- Includes tooltip "Package Details"
- Tapping navigates to package detail screen

#### Added Package Details Card
- New prominent card in the tracking screen body
- Positioned after the Status Card
- Shows quick package information:
  - Weight (kg)
  - Size (small/medium/large)
- Includes "View Full Package Details" button
- Clean, modern design with icons and proper spacing

#### Helper Method
```dart
Widget _buildQuickInfoItem({
  required IconData icon,
  required String label,
  required String value,
})
```
Creates quick info display items for weight and size

## Features

### Two Access Points

1. **App Bar Icon Button** (Subtle)
   - Info icon (ℹ️) in the top right
   - Quick access for users who know where to look
   - Tooltip appears on hover/long press

2. **Package Information Card** (Prominent)
   - Visible in the main scrollable content
   - Shows quick preview of package info
   - Clear call-to-action button
   - More discoverable for all users

### Visual Design

The package details card includes:
- Card container with shadow and rounded corners
- Header with package icon and descriptive text
- Two-column layout for weight and size
- Styled info boxes with grey background
- Full-width blue button for navigation
- Proper spacing and typography

### User Experience Benefits

- **Quick Access**: Two convenient ways to access package details
- **Context Awareness**: Button only shows when package data is available
- **Visual Feedback**: Clear icons and labels
- **Responsive Design**: Uses Sizer for responsive sizing
- **Information Preview**: Shows key details before navigation

## Use Cases

1. **Sender**: Check detailed package information while tracking
2. **Traveler**: Review package specs during delivery
3. **Support**: Quick access to package details when helping users
4. **General**: View full package description, photos, special instructions

## Testing Checklist

- [ ] Info icon appears in app bar when package is loaded
- [ ] Info icon is hidden when package data is not available
- [ ] Package details card displays correct weight and size
- [ ] Tapping info icon navigates to package detail screen
- [ ] Tapping "View Full Package Details" button navigates correctly
- [ ] Navigation works smoothly without errors
- [ ] Back button returns to tracking screen
- [ ] Card displays properly on different screen sizes
- [ ] Tooltips appear correctly

## Technical Notes

- Uses conditional rendering (`if (_packageRequest != null)`) to only show elements when data is available
- Navigation uses standard `Navigator.push` for consistency
- Card follows existing design patterns in the app
- Responsive sizing with Sizer package (`.w`, `.h`, `.sp`)
- Null-safe implementation with proper checks
