# Translation Keys to Add to en.json

This document contains all the hardcoded English strings found in the project that need to be:
1. Wrapped with `.tr()` in the Dart files
2. Added as keys to `assets/translations/en.json`

## Format
Each entry shows:
- **File**: The source file containing the hardcoded string
- **Original String**: The hardcoded English text
- **Proposed Key**: The suggested translation key
- **English Value**: The value to add in en.json

---

## Debug & Testing Section

### File: `lib/widgets/test_notification_widget.dart` ✅ COMPLETED
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Test Notifications" | `debug.test_notifications` | "Test Notifications" |
| "Which type of notification would you like to test?" | `debug.test_notification_prompt` | "Which type of notification would you like to test?" |
| "New Traveller" | `debug.new_traveller` | "New Traveller" |
| "New Package" | `debug.new_package` | "New Package" |
| "Opportunities" | `debug.opportunities` | "Opportunities" |
| "Dubai to Islamabad: New Traveller Alert!" | `debug.test_traveller_title` | "Dubai to Islamabad: New Traveller Alert!" |
| "Send/Receive your packages now with our new traveller from Dubai to Islamabad. Place your bid now" | `debug.test_traveller_body` | "Send/Receive your packages now with our new traveller from Dubai to Islamabad. Place your bid now" |
| "Check your notifications to see the new traveller alert" | `debug.test_notification_check` | "Check your notifications to see the new traveller alert" |
| "Test Notification Sent!" | `debug.test_notification_sent` | "Test Notification Sent!" |
| "New Package Request in Your Area!" | `debug.test_package_title` | "New Package Request in Your Area!" |
| "Someone needs to send a package from Karachi to Lahore. Accept this delivery request now!" | `debug.test_package_body` | "Someone needs to send a package from Karachi to Lahore. Accept this delivery request now!" |
| "Check your notifications to see the new package request" | `debug.test_package_check` | "Check your notifications to see the new package request" |
| "Opportunities in Your Area!" | `debug.test_opportunity_title` | "Opportunities in Your Area!" |
| "Found 3 travellers and 2 package requests near you. Check them out!" | `debug.test_opportunity_body` | "Found 3 travellers and 2 package requests near you. Check them out!" |
| "Check your notifications to see the opportunities summary" | `debug.test_opportunity_check` | "Check your notifications to see the opportunities summary" |

### File: `lib/utils/debug_menu.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Debug Menu" | `debug.menu_title` | "Debug Menu" |
| "Email Test Screen" | `debug.email_test_screen` | "Email Test Screen" |
| "Test email verification & password reset" | `debug.email_test_description` | "Test email verification & password reset" |
| "Available only in debug mode" | `debug.debug_mode_only` | "Available only in debug mode" |
| "Close" | Already exists in `common.close` | - |

### File: `lib/utils/email_test_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Email Testing & Diagnostics" | `debug.email_testing_title` | "Email Testing & Diagnostics" |
| "Use Cloud Function (Custom SMTP)" | `debug.use_cloud_function` | "Use Cloud Function (Custom SMTP)" |
| "Verification" | `debug.verification` | "Verification" |
| "Password Reset" | `debug.password_reset` | "Password Reset" |
| "Delivery Update" | `debug.delivery_update` | "Delivery Update" |
| "Test Config" | `debug.test_config` | "Test Config" |
| "Run Full Diagnostics" | `debug.run_diagnostics` | "Run Full Diagnostics" |
| "Running test..." | `debug.running_test` | "Running test..." |
| "Clear Results" | `debug.clear_results` | "Clear Results" |

---

## Moderation & Reporting Section

### File: `lib/widgets/moderation_widgets.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Please provide additional information for \"Other\" reports" | `moderation.other_report_info` | "Please provide additional information for \"Other\" reports" |
| "Failed to report content: {error}" | `moderation.report_failed` | "Failed to report content" |
| "Submit Report" | `moderation.submit_report` | "Submit Report" |
| "Review {status}" | `moderation.review_status` | "Review {status}" |
| "Failed to update status: {error}" | `moderation.update_status_failed` | "Failed to update status" |
| "Current Status: " | `moderation.current_status` | "Current Status: " |
| "Approve" | `moderation.approve` | "Approve" |
| "Pending" | Already exists in `status.pending` | - |
| "Reject" | `moderation.reject` | "Reject" |

---

## Comments Section

### File: `lib/widgets/comment_system_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Comment added successfully!" | `comments.added_successfully` | "Comment added successfully!" |
| "Failed to add comment: {error}" | `comments.add_failed` | "Failed to add comment" |
| "Liked/Unliked comment successfully!" | `comments.like_success` | "Comment liked successfully" / "Comment unliked successfully" |
| "Failed to like/unlike comment: {error}" | `comments.like_failed` | "Failed to update like status" |
| "Report" | `comments.report` | "Report" |
| "Comment reported successfully" | `comments.reported_successfully` | "Comment reported successfully" |
| "Failed to report comment: {error}" | `comments.report_failed` | "Failed to report comment" |
| "Add Comment" | `comments.add_comment` | "Add Comment" |
| "Report Comment" | `comments.report_title` | "Report Comment" |
| "Why are you reporting this comment?" | `comments.report_prompt` | "Why are you reporting this comment?" |

---

## Wallet Section

### File: `lib/presentation/wallet/wallet_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Wallet" | Already exists in `wallet.title` | - |
| "Please login to view your wallet" | `wallet.login_required` | "Please login to view your wallet" |
| "Error: {error}" | `common.error_with_details` | "Error: {error}" |
| "Retry" | Already exists in `common.retry` | - |
| "Wallet not found" | `wallet.not_found` | "Wallet not found" |
| "Error creating wallet: {error}" | `wallet.create_error` | "Error creating wallet" |
| "Create Wallet" | `wallet.create` | "Create Wallet" |
| "Pending Balance" | Already exists in `wallet.pending_balance` | - |
| "Got it" | `common.got_it` | "Got it" |

### File: `lib/presentation/wallet/withdrawal_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Confirm Withdrawal" | `wallet.confirm_withdrawal_title` | "Confirm Withdrawal" |
| "Error" | Already exists in `common.error` | - |
| "Withdraw Money" | `wallet.withdraw_money` | "Withdraw Money" |
| "Please login to withdraw money" | `wallet.login_required_withdraw` | "Please login to withdraw money" |

### File: `lib/presentation/wallet/transaction_history_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Transaction History" | Already exists in `wallet.transaction_history` | - |
| "Please login to view transaction history" | `wallet.login_required_transactions` | "Please login to view transaction history" |
| "All" | Already exists in `common.all` | - |

---

## Tracking Section

### File: `lib/presentation/tracking/tracking_timeline_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Package Confirmed" | `tracking.package_confirmed` | "Package Confirmed" |
| "Ready for pickup" | `tracking.ready_for_pickup` | "Ready for pickup" |
| "Picked Up" | Already exists in `tracking.picked_up` | - |
| "Package collected by traveler" | `tracking.collected_by_traveler` | "Package collected by traveler" |
| "In Transit" | Already exists in `tracking.in_transit` | - |
| "Package is on the way" | `tracking.package_on_the_way` | "Package is on the way" |
| "Delivered" | Already exists in `tracking.delivered` | - |
| "Package successfully delivered" | `tracking.package_delivered_successfully` | "Package successfully delivered" |

### File: `lib/presentation/tracking/tracking_location_widget_simple.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "📍 Pickup Location" | `tracking.pickup_location_icon` | "📍 Pickup Location" |
| "🎯 Destination" | `tracking.destination_icon` | "🎯 Destination" |
| "🚚 Package Location" | `tracking.package_location_icon` | "🚚 Package Location" |

### File: `lib/presentation/tracking/tracking_status_card.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Tracking ID" | `tracking.tracking_id` | "Tracking ID" |
| "Picked up" | `tracking.picked_up_label` | "Picked up" |
| "Delivered" | `tracking.delivered_label` | "Delivered" |
| "Current Location" | `tracking.current_location_label` | "Current Location" |

### File: `lib/presentation/tracking/tracking_status_update_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Update Status" | `tracking.update_status` | "Update Status" |
| "Change Photo" | `tracking.change_photo` | "Change Photo" |
| "Remove" | Already exists in `profile.remove` | - |

### File: `lib/presentation/tracking/tracking_history_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Delivery History" | `tracking.delivery_history` | "Delivery History" |
| "Start Delivering" | `tracking.start_delivering` | "Start Delivering" |

### File: `lib/presentation/tracking/sender_confirmation_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Delivery Confirmation" | `tracking.delivery_confirmation` | "Delivery Confirmation" |
| "Date" | `common.date` | "Date" |
| "Time" | `common.time` | "Time" |
| "Location" | Already exists in `tracking.location` | - |

### File: `lib/presentation/tracking/package_tracking_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Package Tracking" | Already exists in `tracking.title` | - |
| "Go Back" | `common.go_back` | "Go Back" |
| "Update Status" | `tracking.update_status` | "Update Status" |
| "Add Checkpoint" | `tracking.add_checkpoint` | "Add Checkpoint" |
| "Contact Support" | Already exists in `booking.contact_support` | - |
| "Report Issue" | Already exists in `tracking.report_issue` | - |
| "View Full Package Details" | `tracking.view_full_details` | "View Full Package Details" |

### File: `lib/presentation/tracking/delivery_feedback_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Rate Your Experience" | `tracking.rate_experience` | "Rate Your Experience" |

---

## Services Section

### File: `lib/services/zego_call_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Call in Progress" | `calls.call_in_progress` | "Call in Progress" |
| "End Current Call" | `calls.end_current_call` | "End Current Call" |
| "Voice call failed: {error}" | `calls.voice_call_failed` | "Voice call failed" |
| "Video calls coming soon! Starting voice call..." | `calls.video_coming_soon` | "Video calls coming soon! Starting voice call..." |
| "Voice Call" | `calls.voice_call` | "Voice Call" |
| "Video Call" | `calls.video_call` | "Video Call" |

### File: `lib/services/notification_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "New Offer Received!" | Already exists (similar key needed) | "New Offer Received!" |
| "Offer Accepted! 🎉" | Use `notifications.offer_accepted` | - |
| "Offer Update" | `notifications.offer_update` | "Offer Update" |
| "Incoming Call" | `notifications.incoming_call` | "Incoming Call" |

### File: `lib/services/tracking_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "📦 Tracking Started" | `notifications.tracking_started` | "📦 Tracking Started" |
| "📦 Package Delivered!" | Use `notifications.package_delivered` | - |
| "💰 Payment Released!" | `notifications.payment_released` | "💰 Payment Released!" |

### File: `lib/services/offer_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "New Offer Received!" | `notifications.new_offer` | "New Offer Received!" |
| "Offer Accepted!" | `notifications.offer_accepted` | "Offer Accepted!" |
| "Offer Rejected" | `notifications.offer_rejected` | "Offer Rejected" |

### File: `lib/services/location_notification_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "{fromCity} to {toCity}: New Traveller Alert!" | `notifications.new_traveller_location` | "{fromCity} to {toCity}: New Traveller Alert!" |
| "New Package Request in Your Area!" | `notifications.new_package_area` | "New Package Request in Your Area!" |

### File: `lib/services/deal_negotiation_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "New Offer Received!" | Already covered above | - |
| "Offer Accepted! 🎉" | Already covered above | - |
| "Offer Declined" | `notifications.offer_declined` | "Offer Declined" |

### File: `lib/services/chat_service.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Failed to send image" | `chat.failed_to_send_image` | "Failed to send image" |

---

## Settings Section

### File: `lib/presentation/settings/notification_settings_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Manual Actions" | `settings.manual_actions` | "Manual Actions" |
| "Check for opportunities manually" | `settings.manual_actions_subtitle` | "Check for opportunities manually" |

---

## Profile & KYC Section

### File: `lib/presentation/screens/kyc/kyc_completion_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Personal Information" | Already exists in `kyc.personal_info` | - |
| "Contact Information" | `kyc.contact_information` | "Contact Information" |
| "Address Information" | `kyc.address_information` | "Address Information" |
| "Document Verification" | `kyc.document_verification` | "Document Verification" |
| "Full Name" | Already exists in `kyc.full_name` | - |
| "Date of Birth" | Already exists in `kyc.date_of_birth` | - |
| "Gender" | `kyc.gender` | "Gender" |
| "Email Address" | `kyc.email_address` | "Email Address" |
| "Street Address" | Already exists in `kyc.street_address` | - |
| "City" | Already exists in `kyc.city` | - |
| "ZIP" | `kyc.zip_code` | "ZIP" |
| "Country" | Already exists in `kyc.country` | - |
| "Document Type" | `kyc.document_type` | "Document Type" |
| "Upload {documentType}" | `kyc.upload_document` | "Upload {documentType}" |
| "Take Photo" | `kyc.take_photo` | "Take Photo" |
| "KYC Submitted" | `kyc.submitted` | "KYC Submitted" |

### File: `lib/presentation/profile/profile_options_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Camera" | `common.camera` | "Camera" |
| "Gallery" | `common.gallery` | "Gallery" |
| "Retry" | Already exists in `common.retry` | - |

---

## Post Package/Trip Section

### File: `lib/presentation/post_package/widgets/package_details_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Fragile" | `post_package.fragile` | "Fragile" |
| "Handle with extra care" | `post_package.fragile_subtitle` | "Handle with extra care" |
| "Perishable" | `post_package.perishable` | "Perishable" |
| "Time-sensitive item" | `post_package.perishable_subtitle` | "Time-sensitive item" |
| "Requires Refrigeration" | Already exists in `post_package.requires_refrigeration` | - |
| "Keep cold during transport" | `post_package.refrigeration_subtitle` | "Keep cold during transport" |

### File: `lib/presentation/post_package/widgets/location_picker_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Search for location" | `location.search_title` | "Search for location" |
| "Enter an address or place name" | `location.search_subtitle` | "Enter an address or place name" |
| "Use current location" | Already exists in `profile.use_current_location` | - |
| "Select on map" | `location.select_on_map` | "Select on map" |
| "Choose location by tapping on map" | `location.select_on_map_subtitle` | "Choose location by tapping on map" |

### File: `lib/presentation/post_trip/post_trip_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Departure Location" | `post_trip.departure_location` | "Departure Location" |
| "Where are you starting your journey?" | `post_trip.departure_subtitle` | "Where are you starting your journey?" |
| "Destination Location" | `post_trip.destination_location` | "Destination Location" |
| "Where are you going?" | `post_trip.destination_subtitle` | "Where are you going?" |

### File: `lib/presentation/post_trip/widgets/trip_details_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Departure Date" | `post_trip.departure_date` | "Departure Date" |
| "Arrival Date (Optional)" | `post_trip.arrival_date_optional` | "Arrival Date (Optional)" |

### File: `lib/presentation/post_trip/widgets/trip_compensation_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "€{suggestedReward}" | Dynamic content - no translation needed | - |

### File: `lib/presentation/post_package/enhanced_post_package_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Package Title" | `post_package.package_title` | "Package Title" |
| "Description" | `post_package.description_label` | "Description" |
| "Pickup Location" | Already covered | - |
| "Delivery Location" | `post_package.delivery_location` | "Delivery Location" |
| "Weight (kg)" | `post_package.weight_label` | "Weight (kg)" |
| "Price ($)" | `post_package.price_label` | "Price ($)" |

---

## Package/Trip Details Section

### File: `lib/presentation/package_detail/package_detail_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Pickup" | Already exists in `package.pickup` | - |
| "Destination" | Already exists in `package.destination` | - |

### File: `lib/presentation/trip_detail/trip_detail_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Departure" | Already exists in `trip.departure` | - |
| "Arrival" | Already exists in `trip.arrival` | - |
| "Weight" | Already exists in `package.weight` | - |
| "Packages" | `trip.packages_label` | "Packages" |
| "Chat Now" | `detail.chat_now` | "Chat Now" |
| "Match request sent to {travelerName}!" | `detail.match_request_sent` | "Match request sent to {travelerName}!" |
| "Request Sent!" | `detail.request_sent` | "Request Sent!" |
| "Failed to send request. Please try again." | `detail.request_failed` | "Failed to send request. Please try again." |
| "Failed to start chat. Please try again." | `chat.start_failed` | "Failed to start chat. Please try again." |
| "Failed to start chat: {error}" | `chat.start_failed_error` | "Failed to start chat: {error}" |

---

## Travel Screen Section

### File: `lib/presentation/travel/travel_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Minimum Match Percentage" | `travel.minimum_match_percentage` | "Minimum Match Percentage" |
| "Checking verification status..." | `travel.checking_verification` | "Checking verification status..." |

---

## Matching Section

### File: `lib/presentation/screens/matching/matching_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Smart Matching" | `matching.title` | "Smart Matching" |
| "Contact Traveler" | `matching.contact_traveler` | "Contact Traveler" |
| "Accept Match" | `matching.accept_match` | "Accept Match" |
| "Negotiate Price" | `matching.negotiate_price` | "Negotiate Price" |
| "Reject Match" | `matching.reject_match` | "Reject Match" |
| "Why are you rejecting this match?" | `matching.reject_reason_prompt` | "Why are you rejecting this match?" |
| "Enter your preferred price for this delivery:" | `matching.enter_preferred_price` | "Enter your preferred price for this delivery:" |
| "Accept with Price" | `matching.accept_with_price` | "Accept with Price" |
| "Find Nearby" | `matching.find_nearby` | "Find Nearby" |
| "Nearby Packages" | `matching.nearby_packages` | "Nearby Packages" |
| "Nearby Trips" | `matching.nearby_trips` | "Nearby Trips" |
| "Filter Matches" | `matching.filter_title` | "Filter Matches" |
| "Verified Travelers Only" | `matching.verified_only` | "Verified Travelers Only" |
| "Urgent Packages Only" | `matching.urgent_only` | "Urgent Packages Only" |

---

## Reviews Section

### File: `lib/presentation/reviews/review_system_demo_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Thank you for the positive feedback!" | `reviews.thank_you_feedback` | "Thank you for the positive feedback!" |
| "Review System Demo" | `reviews.demo_title` | "Review System Demo" |
| "Current Rating: {rating} stars" | `reviews.current_rating` | "Current Rating: {rating} stars" |
| "Helpful ({count})" | `reviews.helpful_count` | "Helpful ({count})" |
| "Comments ({count})" | `reviews.comments_count` | "Comments ({count})" |
| "This is a great service! Highly recommend." | `reviews.demo_content_good` | "This is a great service! Highly recommend." |
| "SPAM SPAM VISIT WWW.FAKE.COM NOW!!!" | `reviews.demo_content_spam` | "SPAM SPAM VISIT WWW.FAKE.COM NOW!!!" |
| "Create Review" | `reviews.create_review` | "Create Review" |
| "View Reviews" | Already exists in `reviews.see_all_reviews` | - |
| "Test Report Dialog" | `reviews.test_report_dialog` | "Test Report Dialog" |

### File: `lib/presentation/reviews/review_list_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "View All" | `common.view_all` | "View All" |
| "Write Review" | Already exists in `reviews.write_review` | - |
| "Reviews - {targetName}" | `reviews.reviews_for` | "Reviews - {targetName}" |
| "Please sign in to mark reviews as helpful" | `reviews.sign_in_helpful` | "Please sign in to mark reviews as helpful" |
| "Failed to update helpful status: {error}" | `reviews.helpful_update_failed` | "Failed to update helpful status" |
| "Report Review" | Already exists in `reviews.report_review` | - |
| "Please sign in to report reviews" | `reviews.sign_in_report` | "Please sign in to report reviews" |
| "Review reported successfully" | `reviews.reported_successfully` | "Review reported successfully" |
| "Failed to report review: {error}" | `reviews.report_failed` | "Failed to report review" |
| "Verified bookings only" | `reviews.verified_bookings_only` | "Verified bookings only" |
| "With photos" | `reviews.with_photos` | "With photos" |
| "With comments" | `reviews.with_comments` | "With comments" |
| "Newest first" | `reviews.sort_newest` | "Newest first" |
| "Oldest first" | `reviews.sort_oldest` | "Oldest first" |
| "Highest rated" | `reviews.sort_highest` | "Highest rated" |
| "Lowest rated" | `reviews.sort_lowest` | "Lowest rated" |
| "Most helpful" | `reviews.sort_helpful` | "Most helpful" |
| "Apply Filters" | `common.apply_filters` | "Apply Filters" |

### File: `lib/presentation/reviews/create_review_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Review submitted successfully!" | `reviews.submitted_successfully` | "Review submitted successfully!" |

---

## Chat Section

### File: `lib/presentation/chat/individual_chat_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Voice call failed: {error}" | Already covered in calls section | - |
| "Video call failed: {error}" | `calls.video_call_failed` | "Video call failed" |
| "Camera" | Already exists in `common.camera` | - |
| "Gallery" | Already exists in `common.gallery` | - |
| "Location" | `chat.location` | "Location" |

### File: `lib/presentation/chat/chat_screen.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Loading chats" | `chat.loading_chats` | "Loading chats" |

### File: `lib/widgets/chat/deal_offer_message_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Counter Offer" | `chat.counter_offer` | "Counter Offer" |

### File: `lib/widgets/chat/price_input_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Error: Invalid price format" | `errors.invalid_price_format` | "Error: Invalid price format" |

---

## Booking Section

### File: `lib/widgets/booking/booking_summary_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Deal Details" | `booking.deal_details` | "Deal Details" |
| "Package Details" | Already exists in `booking.package_details` | - |
| "Trip Details" | `booking.trip_details` | "Trip Details" |
| "Price Breakdown" | `booking.price_breakdown` | "Price Breakdown" |

---

## Auth Section

### File: `lib/presentation/screens/auth/email_verification_screen_old.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Check your inbox" | `auth.check_inbox` | "Check your inbox" |
| "Click the link" | `auth.click_link` | "Click the link" |
| "You're all set!" | `auth.all_set` | "You're all set!" |

---

## Base64 Image Upload Example

### File: `lib/widgets/base64_image_upload_example.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Base64 Image Upload Demo" | `demo.base64_upload_title` | "Base64 Image Upload Demo" |
| "Original Size: {size} MB" | `demo.original_size` | "Original Size: {size} MB" |
| "Storage: Firestore (Base64)" | `demo.storage_firestore` | "Storage: Firestore (Base64)" |
| "Cost: FREE! 🎉" | `demo.cost_free` | "Cost: FREE! 🎉" |
| "1. Pick an image from camera or gallery" | `demo.step_1` | "1. Pick an image from camera or gallery" |
| "2. Image is automatically compressed if needed" | `demo.step_2` | "2. Image is automatically compressed if needed" |
| "3. Converted to Base64 format" | `demo.step_3` | "3. Converted to Base64 format" |
| "4. Stored directly in Firestore document" | `demo.step_4` | "4. Stored directly in Firestore document" |
| "5. No Firebase Storage charges!" | `demo.step_5` | "5. No Firebase Storage charges!" |
| "• Completely FREE storage" | `demo.benefit_1` | "• Completely FREE storage" |
| "• No additional Firebase setup" | `demo.benefit_2` | "• No additional Firebase setup" |
| "• Automatic image optimization" | `demo.benefit_3` | "• Automatic image optimization" |
| "• Works offline once loaded" | `demo.benefit_4` | "• Works offline once loaded" |
| "• Simple implementation" | `demo.benefit_5` | "• Simple implementation" |
| "• Max ~800KB per image (Firestore limit)" | `demo.limitation_1` | "• Max ~800KB per image (Firestore limit)" |
| "• Not ideal for very high-res images" | `demo.limitation_2` | "• Not ideal for very high-res images" |
| "• Slightly slower initial load" | `demo.limitation_3` | "• Slightly slower initial load" |
| "Image saved! Size: {size} MB" | `demo.image_saved` | "Image saved! Size: {size} MB" |
| "Error: {error}" | Already covered | - |
| "Image removed" | `demo.image_removed` | "Image removed" |

---

## Other UI Elements

### File: `lib/widgets/custom_error_widget.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Back" | Already exists in `common.back` | - |

### File: `lib/widgets/animated_card_stack.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Reset Cards" | `common.reset_cards` | "Reset Cards" |

### File: `lib/routes/app_routes.dart`
| Original String | Proposed Key | English Value |
|----------------|--------------|---------------|
| "Route requires arguments" | `errors.route_requires_arguments` | "Route requires arguments" |

---

## Summary Statistics

- **Total Files to Process**: ~458 Dart files
- **Files Completed**: 1 (test_notification_widget.dart)
- **Estimated Hardcoded Strings**: 300-500+
- **New Translation Keys Needed**: ~200-300

## Recommendation

Due to the large scope, I suggest:

1. **Prioritize by Module**: Start with user-facing screens (presentation layer) before utility widgets
2. **Batch Processing**: Process related files together (e.g., all tracking files, all wallet files)
3. **Testing**: Test each module after translation to ensure no broken strings
4. **Use Find & Replace Carefully**: Many strings appear in multiple files with similar patterns

## Next Steps

1. Add all the keys from this document to `assets/translations/en.json`
2. Process files systematically by directory
3. Use `import 'package:get/get.dart' hide Trans;` pattern for files using both GetX and easy_localization
4. Test after each major section is completed
