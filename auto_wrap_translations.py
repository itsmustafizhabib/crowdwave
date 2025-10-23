#!/usr/bin/env python3
"""
Automated Translation Wrapper for CrowdWave Flutter Project
This script systematically wraps hardcoded English strings with .tr()
and adds easy_localization import where needed.
"""

import os
import re
import sys

# Mapping of hardcoded strings to translation keys
TRANSLATION_MAP = {
    # Chat strings
    "Search conversations...": "chat.search_conversations_hint",
    "Type a message...": "chat.type_message",
    "Retry": "common.retry",
    "Refresh": "common.refresh",
    "Loading chats": "chat.loading_chats",
    "Camera": "common.camera",
    "Gallery": "common.gallery",
    "Location": "common.location",
    "Voice call failed": "calls.voice_call_failed",
    "Video call failed": "calls.video_call_failed",
    "Failed to accept call": "calls.voice_call_failed",
    
    # Location picker strings
    "Search for location": "location.search_title",
    "Enter an address or place name": "location.search_subtitle",
    "Use current location": "location.use_current",
    "Select on map": "location.select_on_map",
    "Choose location by tapping on map": "location.select_on_map_subtitle",
    "Enter address or place name": "location.enter_address_hint",
    "Location permission denied": "profile.location_permission_denied",
    "Failed to get current location": "profile.failed_to_get_location",
    "Network error": "error_messages.network_error",
    "Error selecting location": "common.error",
    
    # Package details strings
    "Optional": "common.optional",
    "Fragile": "package.fragile",
    "Handle with extra care": "package.fragile_desc",
    "Perishable": "package.perishable",
    "Time-sensitive item": "package.perishable_desc",
    "Requires Refrigeration": "package.requires_refrigeration",
    "Keep cold during transport": "package.refrigeration_desc",
    "Take Photo": "common.take_photo",
    "Use camera to capture package": "package.take_photo_desc",
    "Choose from Gallery": "common.choose_from_gallery",
    "Select existing photo": "common.select_photo_desc",
    "Failed to pick image": "profile.failed_to_pick_image",
    
    # Account strings
    "Account Settings": "account.settings_title",
    "Delivery History": "account.delivery_history",
    "Support": "account.support",
    "Developer Options": "account.developer_options",
    "Email Support": "account.email_support",
    "WhatsApp": "account.whatsapp",
    "Chat with our support team": "account.whatsapp_desc",
    "Help Center": "account.help_center",
    "FAQs and guides": "account.help_center_desc",
    
    # Home screen strings
    "Checking verification status...": "home.checking_verification",
    "Please log in to start chatting.": "chat.login_required",
    "You cannot chat with yourself.": "chat.cannot_chat_self",
    "Failed to start conversation. Please try again.": "chat.start_conversation_failed",
    "An error occurred. Please try again.": "common.error_try_again",
    "Please log in to make an offer.": "offer.login_required",
    "You cannot make an offer on your own package.": "offer.cannot_offer_own",
    "Offer sent successfully!": "offer.sent_success",
    "Notifications": "home.notifications",
    
    # Booking strings
    "Enter your offer price": "booking.enter_offer_price_hint",
    "Confirmation": "booking.confirmation_step",
    "Payment": "booking.payment_step",
    "Complete": "booking.complete_step",
    "Failed to initialize payment service": "payment.failed_init",
    "Payment Method": "payment.method_title",
    
    # Trip strings
    "Departure Location": "post_trip.departure_location",
    "Where are you starting your journey?": "trip.departure_subtitle",
    "Destination Location": "post_trip.destination_location",
    "Where are you going?": "trip.destination_subtitle",
    "Max Weight (kg)": "trip.max_weight_kg",
    "Max Volume (L)": "trip.max_volume_l",
    "Maximum Number of Packages": "trip.max_packages",
    "Departure Date": "post_trip.departure_date",
    "Arrival Date (Optional)": "trip.arrival_date_optional",
    "Maximum Detour (km)": "trip.max_detour_km",
    "Trip posted successfully!": "trip.success_message",
    
    # Package detail strings
    "Pickup": "package.pickup",
    "Destination": "package.destination",
    "Please log in to start chatting.": "chat.login_required",
    "Failed to start chat. Please try again.": "chat.start_failed",
    
    # Forum strings (already done, but keeping for reference)
    "Share": "forum.share",
    "Search posts...": "forum.search_posts_hint",
    "Write a comment...": "forum.write_comment_hint",
}

# Files to process with their patterns
FILES_TO_PROCESS = [
    "lib/presentation/chat/chat_screen.dart",
    "lib/presentation/chat/individual_chat_screen.dart",
    "lib/presentation/post_package/widgets/location_picker_widget.dart",
    "lib/presentation/post_package/widgets/package_details_widget.dart",
    "lib/presentation/home/updated_home_screen.dart",
    "lib/presentation/account/account_screen.dart",
    "lib/presentation/post_trip/post_trip_screen.dart",
    "lib/presentation/post_trip/widgets/trip_capacity_widget.dart",
    "lib/presentation/post_trip/widgets/trip_details_widget.dart",
    "lib/presentation/package_detail/package_detail_screen.dart",
    "lib/presentation/booking/make_offer_screen.dart",
    "lib/presentation/booking/booking_confirmation_screen.dart",
    "lib/presentation/booking/payment_method_screen.dart",
    "lib/presentation/forum/community_forum_screen.dart",
]

def has_easy_localization_import(content):
    """Check if file already has easy_localization import"""
    return 'easy_localization' in content

def has_get_import(content):
    """Check if file has GetX import"""
    return "import 'package:get/get.dart'" in content

def add_easy_localization_import(content):
    """Add easy_localization import to the file"""
    lines = content.split('\n')
    
    # Find the last import statement
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    
    if last_import_idx != -1:
        # Check if we need to hide Trans from GetX
        if has_get_import(content):
            # Replace GetX import to hide Trans
            for i, line in enumerate(lines):
                if "import 'package:get/get.dart'" in line and 'hide Trans' not in line:
                    lines[i] = "import 'package:get/get.dart' hide Trans;"
                    break
        
        # Add easy_localization after last import
        import_line = "import 'package:easy_localization/easy_localization.dart';"
        
        # Check if intl is imported (for DateFormat conflict)
        if 'package:intl/intl.dart' in content:
            import_line = "import 'package:easy_localization/easy_localization.dart' hide TextDirection;"
        
        lines.insert(last_import_idx + 1, import_line)
    
    return '\n'.join(lines)

def wrap_string_with_tr(content, original_text, translation_key):
    """Wrap a hardcoded string with .tr()"""
    
    # Patterns to match different contexts
    patterns = [
        # const Text('...')
        (rf"const Text\('{re.escape(original_text)}'\)", f"Text('{translation_key}'.tr())"),
        # Text('...')
        (rf"Text\('{re.escape(original_text)}'\)", f"Text('{translation_key}'.tr())"),
        # content: Text('...')
        (rf"content: const Text\('{re.escape(original_text)}'\)", f"content: Text('{translation_key}'.tr())"),
        (rf"content: Text\('{re.escape(original_text)}'\)", f"content: Text('{translation_key}'.tr())"),
        # title: const Text('...')
        (rf"title: const Text\('{re.escape(original_text)}'\)", f"title: Text('{translation_key}'.tr())"),
        (rf"title: Text\('{re.escape(original_text)}'\)", f"title: Text('{translation_key}'.tr())"),
        # subtitle: const Text('...')
        (rf"subtitle: const Text\('{re.escape(original_text)}'\)", f"subtitle: Text('{translation_key}'.tr())"),
        (rf"subtitle: Text\('{re.escape(original_text)}'\)", f"subtitle: Text('{translation_key}'.tr())"),
        # label: const Text('...')
        (rf"label: const Text\('{re.escape(original_text)}'\)", f"label: Text('{translation_key}'.tr())"),
        (rf"label: Text\('{re.escape(original_text)}'\)", f"label: Text('{translation_key}'.tr())"),
        # child: const Text('...')
        (rf"child: const Text\('{re.escape(original_text)}'\)", f"child: Text('{translation_key}'.tr())"),
        (rf"child: Text\('{re.escape(original_text)}'\)", f"child: Text('{translation_key}'.tr())"),
        # hintText: '...'
        (rf"hintText: '{re.escape(original_text)}'", f"hintText: '{translation_key}'.tr()"),
        # labelText: '...'
        (rf"labelText: '{re.escape(original_text)}'", f"labelText: '{translation_key}'.tr()"),
        # title: '...'
        (rf"title: '{re.escape(original_text)}'", f"title: '{translation_key}'.tr()"),
        # subtitle: '...' (for ListTile, etc.)
        (rf"subtitle: '{re.escape(original_text)}'", f"subtitle: '{translation_key}'.tr()"),
        # label: '...' (for various widgets)
        (rf"label: '{re.escape(original_text)}'", f"label: '{translation_key}'.tr()"),
    ]
    
    modified = False
    for pattern, replacement in patterns:
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            content = new_content
            modified = True
    
    return content, modified

def process_file(file_path):
    """Process a single file to wrap translation strings"""
    
    if not os.path.exists(file_path):
        print(f"⚠️  File not found: {file_path}")
        return False
    
    print(f"\n📝 Processing: {file_path}")
    
    # Read file content
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    modifications = 0
    
    # Add easy_localization import if not present
    if not has_easy_localization_import(content):
        print(f"   ➕ Adding easy_localization import")
        content = add_easy_localization_import(content)
        modifications += 1
    
    # Wrap each string with .tr()
    for original_text, translation_key in TRANSLATION_MAP.items():
        if original_text in content and f"'{translation_key}'.tr()" not in content:
            content, modified = wrap_string_with_tr(content, original_text, translation_key)
            if modified:
                print(f"   ✓ Wrapped: '{original_text[:50]}...' → '{translation_key}'")
                modifications += 1
    
    # Write back if modified
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"   ✅ Saved {modifications} modifications")
        return True
    else:
        print(f"   ℹ️  No changes needed")
        return False

def main():
    """Main execution function"""
    print("=" * 60)
    print("🌍 CrowdWave Automated Translation Wrapper")
    print("=" * 60)
    
    base_path = os.path.dirname(os.path.abspath(__file__))
    
    processed = 0
    modified = 0
    
    for file_path in FILES_TO_PROCESS:
        full_path = os.path.join(base_path, file_path)
        if process_file(full_path):
            modified += 1
        processed += 1
    
    print("\n" + "=" * 60)
    print(f"✅ Completed!")
    print(f"   📁 Processed: {processed} files")
    print(f"   ✏️  Modified: {modified} files")
    print("=" * 60)
    print("\n🔍 Next steps:")
    print("   1. Run: flutter analyze")
    print("   2. Check: bash wrap_translations.sh")
    print("   3. Test the app")
    print("   4. Run translation script for 29 languages")
    print()

if __name__ == "__main__":
    main()
