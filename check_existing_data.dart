// Run this script to check your existing Firebase data
// Usage: flutter run check_existing_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase - use your app's initialization
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  print('🔍 Checking existing data...\n');

  // Check deliveryTracking collection
  print('📦 DELIVERY TRACKING RECORDS:');
  final trackingQuery = await firestore
      .collection('deliveryTracking')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  if (trackingQuery.docs.isEmpty) {
    print('❌ No delivery tracking records found');
  } else {
    for (var doc in trackingQuery.docs) {
      final data = doc.data();
      print('ID: ${doc.id}');
      print('  Status: ${data['status'] ?? 'N/A'}');
      print('  TravelerId: ${data['travelerId'] ?? 'N/A'}');
      print('  SenderId: ${data['senderId'] ?? '❌ MISSING'}');
      print('  Created: ${data['createdAt']?.toDate() ?? 'N/A'}');
      print('---');
    }
  }

  print('\n💳 RECENT BOOKINGS:');
  final bookingsQuery = await firestore
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();

  if (bookingsQuery.docs.isEmpty) {
    print('❌ No bookings found');
  } else {
    for (var doc in bookingsQuery.docs) {
      final data = doc.data();
      print('ID: ${doc.id}');
      print('  Status: ${data['status'] ?? 'N/A'}');
      print('  SenderId: ${data['senderId'] ?? 'N/A'}');
      print('  Amount: \$${data['totalAmount'] ?? 'N/A'}');
      print('  Created: ${data['createdAt']?.toDate() ?? 'N/A'}');
      print('---');
    }
  }

  print('\n📊 SUMMARY:');
  final trackingCount = trackingQuery.docs.length;
  final trackingWithSender =
      trackingQuery.docs.where((doc) => doc.data()['senderId'] != null).length;

  print('Total tracking records checked: $trackingCount');
  print('Tracking records with senderId: $trackingWithSender');
  print('Missing senderId: ${trackingCount - trackingWithSender}');

  if (trackingWithSender == 0 && trackingCount > 0) {
    print('\n⚠️  WARNING: No tracking records have senderId field!');
    print(
        '   You may need to migrate existing data or create new test orders.');
  } else if (trackingWithSender > 0) {
    print('\n✅ Good! Some tracking records have senderId field.');
    print('   These should appear in sender\'s Pending tab.');
  }
}
