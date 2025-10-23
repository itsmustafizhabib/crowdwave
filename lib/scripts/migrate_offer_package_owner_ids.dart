import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Migration script to add packageOwnerId to existing deal offers
///
/// Run this ONCE after deploying the packageOwnerId changes.
/// This script updates all existing offers in Firestore.
Future<void> migrateOfferPackageOwnerIds() async {
  try {
    print('🚀 Starting offer migration...');

    // Initialize Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;

    // Get all offers
    final offersSnapshot = await firestore.collection('deal_offers').get();

    print('📦 Found ${offersSnapshot.docs.length} offers to check');

    int updated = 0;
    int skipped = 0;
    int failed = 0;

    for (var offerDoc in offersSnapshot.docs) {
      try {
        final data = offerDoc.data();

        // Skip if already has packageOwnerId
        if (data.containsKey('packageOwnerId') &&
            data['packageOwnerId'] != null &&
            data['packageOwnerId'].toString().isNotEmpty) {
          skipped++;
          if (kDebugMode) {
            print('  ⏭️  Skipping ${offerDoc.id} - already has packageOwnerId');
          }
          continue;
        }

        // Get package to find owner
        final packageId = data['packageId'];
        if (packageId == null || packageId.toString().isEmpty) {
          print('  ⚠️  Offer ${offerDoc.id} has no packageId - skipping');
          failed++;
          continue;
        }

        final packageDoc =
            await firestore.collection('packageRequests').doc(packageId).get();

        if (!packageDoc.exists || packageDoc.data() == null) {
          print(
              '  ⚠️  Package $packageId not found for offer ${offerDoc.id} - skipping');
          failed++;
          continue;
        }

        final packageOwnerId = packageDoc.data()!['senderId'];

        if (packageOwnerId == null || packageOwnerId.toString().isEmpty) {
          print(
              '  ⚠️  Package $packageId has no senderId - skipping offer ${offerDoc.id}');
          failed++;
          continue;
        }

        // Update offer with packageOwnerId
        await offerDoc.reference.update({
          'packageOwnerId': packageOwnerId,
        });

        updated++;
        print(
            '  ✅ Updated offer ${offerDoc.id} with packageOwnerId: $packageOwnerId');
      } catch (e) {
        failed++;
        print('  ❌ Error updating offer ${offerDoc.id}: $e');
      }
    }

    print('\n📊 Migration Summary:');
    print('  ✅ Updated: $updated offers');
    print('  ⏭️  Skipped: $skipped offers (already had packageOwnerId)');
    print('  ❌ Failed: $failed offers');
    print('  📦 Total: ${offersSnapshot.docs.length} offers');

    if (updated > 0) {
      print('\n🎉 Migration completed successfully!');
    } else if (skipped > 0) {
      print('\n✨ All offers already migrated!');
    } else {
      print('\n⚠️  No offers were updated. Check the logs above.');
    }
  } catch (e) {
    print('❌ Migration failed: $e');
    rethrow;
  }
}

void main() async {
  print('═══════════════════════════════════════════════════════════');
  print('📝 Offer Package Owner ID Migration Script');
  print('═══════════════════════════════════════════════════════════');
  print('');
  print('⚠️  WARNING: This script will modify production data!');
  print('');
  print('This script adds the "packageOwnerId" field to all existing');
  print('offers in the deal_offers collection.');
  print('');
  print('Press ENTER to continue or Ctrl+C to cancel...');
  // stdin.readLineSync(); // Uncomment for confirmation prompt

  await migrateOfferPackageOwnerIds();

  print('');
  print('═══════════════════════════════════════════════════════════');
  print('✨ Migration script finished');
  print('═══════════════════════════════════════════════════════════');
}
