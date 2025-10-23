#!/bin/bash
# Translation Wrapping Script for CrowdWave Flutter Project
# This script systematically wraps hardcoded English strings with .tr()

echo "====================================="
echo "CrowdWave Translation Wrapper"
echo "====================================="

# Count total hardcoded strings before
echo ""
echo "📊 Counting hardcoded strings..."
BEFORE=$(grep -r --include="*.dart" -n "Text('.*')\|content: Text\|title: const Text\|label: const Text\|hintText:" lib/presentation/ | grep -v "\.tr()" | grep -v "TextStyle\|TextButton\|TextField\|TextEditingController\|TextCapitalization" | wc -l)
echo "Found $BEFORE hardcoded strings that need translation"

# Define file groups for systematic processing
echo ""
echo "====================================="
echo "Files to Process by Category:"
echo "====================================="

# Forum screens
echo ""
echo "📁 Forum Screens (2 files)"
echo "  - lib/presentation/forum/create_post_screen.dart ✅ DONE"
echo "  - lib/presentation/forum/post_detail_screen.dart"

# Booking screens
echo ""
echo "📁 Booking Screens (3 files)"
echo "  - lib/presentation/booking/payment_failure_screen.dart ✅ DONE"
echo "  - lib/presentation/booking/booking_success_screen.dart ✅ DONE"
echo "  - lib/presentation/booking/make_offer_screen.dart"

# Chat screens
echo ""
echo "📁 Chat Screens (2 files)"
echo "  - lib/presentation/chat/chat_screen.dart"
echo "  - lib/presentation/chat/individual_chat_screen.dart"

# Location & Package widgets
echo ""
echo "📁 Widgets (3 files)"
echo "  - lib/presentation/post_package/widgets/location_picker_widget.dart"
echo "  - lib/presentation/post_package/widgets/package_details_widget.dart"
echo "  - lib/presentation/post_trip/widgets/trip_capacity_widget.dart"

# Home & Account
echo ""
echo "📁 Main Screens (2 files)"
echo "  - lib/presentation/home/updated_home_screen.dart"
echo "  - lib/presentation/account/account_screen.dart"

echo ""
echo "====================================="
echo "Translation Keys Status in en.json:"
echo "====================================="
echo "✅ Added: payment.* keys"
echo "✅ Added: booking.* keys"
echo "✅ Added: forum.* keys"
echo "✅ Added: chat.* keys"
echo "✅ Added: location.* keys"
echo "✅ Added: package.* keys"
echo "✅ Added: account.* keys"
echo "✅ Added: common.* additional keys"
echo ""

echo "====================================="
echo "Next Steps:"
echo "====================================="
echo "1. Continue wrapping strings file by file"
echo "2. Test each file after changes with: flutter analyze"
echo "3. Verify translations with: grep -n '.tr()' [filename]"
echo "4. Run translation script for 29 languages after all wrapping is done"
echo ""
echo "🚀 Ready to continue! Process one screen at a time."
