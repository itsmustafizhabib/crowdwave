import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import '../core/models/delivery_tracking.dart';
import '../core/models/package_request.dart';
import '../models/notification_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/geocoding_service.dart';
import '../services/payment_service.dart';
import '../services/custom_email_service.dart';

class TrackingService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = Get.find<LocationService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final CustomEmailService _emailService = CustomEmailService();

  // Collection names
  static const String _trackingCollection = 'deliveryTracking';
  static const String _packagesCollection = 'packageRequests';

  // Observable tracking data
  final Rx<DeliveryTracking?> _currentTracking = Rx<DeliveryTracking?>(null);
  final RxList<DeliveryTracking> _userTrackings = <DeliveryTracking>[].obs;
  final RxBool _isLoading = false.obs;

  DeliveryTracking? get currentTracking => _currentTracking.value;
  List<DeliveryTracking> get userTrackings => _userTrackings;
  bool get isLoading => _isLoading.value;

  /// Create a new delivery tracking entry
  Future<String> createTracking({
    required String packageRequestId,
    required String travelerId,
    required String senderId, // Added senderId parameter
    String? notes,
  }) async {
    try {
      _isLoading.value = true;

      final trackingId = _firestore.collection(_trackingCollection).doc().id;
      final now = DateTime.now();

      final tracking = DeliveryTracking(
        id: trackingId,
        packageRequestId: packageRequestId,
        travelerId: travelerId,
        senderId: senderId, // Added senderId argument
        status: DeliveryStatus.pending,
        trackingPoints: [],
        createdAt: now,
        updatedAt: now,
        notes: notes,
      );

      await _firestore
          .collection(_trackingCollection)
          .doc(trackingId)
          .set(tracking.toMap());

      // Update package status
      await _firestore
          .collection(_packagesCollection)
          .doc(packageRequestId)
          .update({
        'status': PackageStatus.confirmed.name,
        'trackingId': trackingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to sender
      await _notificationService.createNotification(
        userId: '', // Will be populated from package data when available
        title: 'notifications.tracking_started'.tr(),
        body: 'post_package.your_package_delivery_tracking_has_been_activated'.tr(),
        type: NotificationType.packageUpdate,
        relatedEntityId: packageRequestId,
        data: {
          'packageRequestId': packageRequestId,
          'trackingId': trackingId,
        },
      );

      return trackingId;
    } catch (e) {
      print('❌ Error creating tracking: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update delivery status with optional location
  Future<void> updateDeliveryStatus({
    required String trackingId,
    required DeliveryStatus status,
    String? notes,
    bool updateLocation = true,
  }) async {
    try {
      _isLoading.value = true;

      final trackingRef =
          _firestore.collection(_trackingCollection).doc(trackingId);
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add notes if provided
      if (notes != null) {
        updateData['notes'] = notes;
      }

      // Add timestamp for specific statuses
      if (status == DeliveryStatus.picked_up) {
        updateData['pickupTime'] = FieldValue.serverTimestamp();
      } else if (status == DeliveryStatus.delivered) {
        updateData['deliveryTime'] = FieldValue.serverTimestamp();
      }

      // Update location if requested
      if (updateLocation) {
        final locationData = await _locationService.getCurrentLocation();
        if (locationData != null) {
          // Fetch human-readable address
          final geocodingService = Get.find<GeocodingService>();
          final address = await geocodingService.getAddressFromCoordinates(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
          );

          final locationPoint = LocationPoint(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
            address: address,
          );

          updateData['currentLocation'] = locationPoint.toMap();

          // Add to tracking points with current timestamp
          final now = DateTime.now();
          updateData['trackingPoints'] = FieldValue.arrayUnion([
            {
              ...locationPoint.toMap(),
              'timestamp': Timestamp.fromDate(now),
              'status': status.name,
            }
          ]);
        }
      }

      await trackingRef.update(updateData);

      // Send status notification
      await _sendStatusNotification(trackingId, status);
    } catch (e) {
      print('❌ Error updating delivery status: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get tracking by ID
  Future<DeliveryTracking?> getTracking(String trackingId) async {
    try {
      final doc = await _firestore
          .collection(_trackingCollection)
          .doc(trackingId)
          .get();

      if (doc.exists) {
        return DeliveryTracking.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting tracking: $e');
      return null;
    }
  }

  /// Stream tracking updates
  Stream<DeliveryTracking?> streamTracking(String trackingId) {
    return _firestore
        .collection(_trackingCollection)
        .doc(trackingId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final tracking = DeliveryTracking.fromMap(doc.data()!);
        _currentTracking.value = tracking;
        return tracking;
      }
      return null;
    });
  }

  /// Get user's tracking history (as sender or traveler)
  Stream<List<DeliveryTracking>> streamUserTrackings() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('⚠️ No current user, returning empty tracking stream');
      return Stream.value([]);
    }

    print('🔍 Starting tracking stream for user: $currentUserId');

    // Create combined stream for both traveler and sender trackings
    final travelerStream = _firestore
        .collection(_trackingCollection)
        .where('travelerId', isEqualTo: currentUserId)
        .snapshots();

    final senderStream = _firestore
        .collection(_trackingCollection)
        .where('senderId', isEqualTo: currentUserId)
        .snapshots();

    // Use CombineLatestStream to combine both streams
    return CombineLatestStream.combine2(
      travelerStream,
      senderStream,
      (QuerySnapshot travelerSnapshot, QuerySnapshot senderSnapshot) {
        try {
          // Parse traveler trackings
          final travelerTrackings = travelerSnapshot.docs
              .map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  print('📄 STREAM Traveler tracking doc ${doc.id}:');
                  print('   - status: ${data['status']}');
                  print('   - packageRequestId: ${data['packageRequestId']}');
                  print('   - senderId: ${data['senderId']}');
                  print('   - travelerId: ${data['travelerId']}');
                  return DeliveryTracking.fromMap(data);
                } catch (e) {
                  print(
                      '❌ Error parsing traveler tracking document ${doc.id}: $e');
                  return null;
                }
              })
              .where((tracking) => tracking != null)
              .cast<DeliveryTracking>()
              .toList();

          // Parse sender trackings
          final senderTrackings = senderSnapshot.docs
              .map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  print('📄 STREAM Sender tracking doc ${doc.id}:');
                  print('   - status: ${data['status']}');
                  print('   - packageRequestId: ${data['packageRequestId']}');
                  print('   - senderId: ${data['senderId']}');
                  print('   - travelerId: ${data['travelerId']}');
                  return DeliveryTracking.fromMap(data);
                } catch (e) {
                  print(
                      '❌ Error parsing sender tracking document ${doc.id}: $e');
                  return null;
                }
              })
              .where((tracking) => tracking != null)
              .cast<DeliveryTracking>()
              .toList();

          // Combine and deduplicate
          final allTrackings = <String, DeliveryTracking>{};
          for (final tracking in travelerTrackings) {
            allTrackings[tracking.id] = tracking;
          }
          for (final tracking in senderTrackings) {
            allTrackings[tracking.id] = tracking;
          }

          final combinedTrackings = allTrackings.values.toList();
          combinedTrackings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('✅ STREAM Loaded ${combinedTrackings.length} tracking records '
              '(${travelerTrackings.length} as traveler, ${senderTrackings.length} as sender)');

          // Debug: Print status of each tracking
          for (var tracking in combinedTrackings) {
            print(
                '  📦 STREAM Tracking ${tracking.id}: status=${tracking.status.name}, packageRequestId=${tracking.packageRequestId}');
          }
          ;

          _userTrackings.value = combinedTrackings;
          return combinedTrackings;
        } catch (e) {
          print('❌ Error processing tracking snapshot: $e');
          return <DeliveryTracking>[];
        }
      },
    ).handleError((error) {
      print('❌ Error in tracking stream: $error');
      return <DeliveryTracking>[];
    });
  }

  /// Get user's tracking history including both sender and traveler trackings
  /// This is a more comprehensive method that can be used later
  Future<List<DeliveryTracking>> getUserTrackingsComplete() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('⚠️ No current user');
      return [];
    }

    try {
      print('🔍 Getting complete tracking history for user: $currentUserId');

      // Get trackings where user is the traveler
      final travelerQuery = await _firestore
          .collection(_trackingCollection)
          .where('travelerId', isEqualTo: currentUserId)
          .get();

      final travelerTrackings = travelerQuery.docs
          .map((doc) {
            try {
              print('📄 Traveler tracking doc ${doc.id}: ${doc.data()}');
              return DeliveryTracking.fromMap(doc.data());
            } catch (e) {
              print('❌ Error parsing traveler tracking document ${doc.id}: $e');
              return null;
            }
          })
          .where((tracking) => tracking != null)
          .cast<DeliveryTracking>()
          .toList();

      // Get trackings where user is the sender - SIMPLIFIED QUERY
      final senderQuery = await _firestore
          .collection(_trackingCollection)
          .where('senderId', isEqualTo: currentUserId)
          .get();

      final senderTrackings = senderQuery.docs
          .map((doc) {
            try {
              print('📄 Sender tracking doc ${doc.id}: ${doc.data()}');
              return DeliveryTracking.fromMap(doc.data());
            } catch (e) {
              print('❌ Error parsing sender tracking document ${doc.id}: $e');
              return null;
            }
          })
          .where((tracking) => tracking != null)
          .cast<DeliveryTracking>()
          .toList();

      // Combine and remove duplicates
      final allTrackings = <String, DeliveryTracking>{};
      for (final tracking in travelerTrackings) {
        allTrackings[tracking.id] = tracking;
      }
      for (final tracking in senderTrackings) {
        allTrackings[tracking.id] = tracking;
      }

      final combinedTrackings = allTrackings.values.toList();
      combinedTrackings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
          '✅ Loaded ${combinedTrackings.length} total tracking records (${travelerTrackings.length} as traveler, ${senderTrackings.length} as sender)');

      // Debug: Print status of each tracking
      for (var tracking in combinedTrackings) {
        print(
            '  📦 Tracking ${tracking.id}: status=${tracking.status.name}, packageRequestId=${tracking.packageRequestId}');
      }

      return combinedTrackings;
    } catch (e) {
      print('❌ Error getting complete tracking history: $e');
      return [];
    }
  }

  /// Get tracking by package request ID
  Future<DeliveryTracking?> getTrackingByPackageId(
      String packageRequestId) async {
    try {
      final query = await _firestore
          .collection(_trackingCollection)
          .where('packageRequestId', isEqualTo: packageRequestId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return DeliveryTracking.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Error getting tracking by package ID: $e');
      return null;
    }
  }

  /// Add location checkpoint
  Future<void> addLocationCheckpoint({
    required String trackingId,
    String? notes,
  }) async {
    try {
      final locationData = await _locationService.getCurrentLocation();
      if (locationData == null) {
        throw Exception('Unable to get current location');
      }

      // Fetch human-readable address using GeocodingService
      final geocodingService = Get.find<GeocodingService>();
      final address = await geocodingService.getAddressFromCoordinates(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      final now = DateTime.now();
      final locationPoint = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'address': address,
        'timestamp': Timestamp.fromDate(now),
        'notes': notes,
      };

      await _firestore.collection(_trackingCollection).doc(trackingId).update({
        'trackingPoints': FieldValue.arrayUnion([locationPoint]),
        'currentLocation': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'address': address,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error adding location checkpoint: $e');
      rethrow;
    }
  }

  /// Cancel delivery
  Future<void> cancelDelivery({
    required String trackingId,
    required String reason,
  }) async {
    try {
      _isLoading.value = true;

      await _firestore.collection(_trackingCollection).doc(trackingId).update({
        'status': DeliveryStatus.cancelled.name,
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send cancellation notification
      await _sendStatusNotification(trackingId, DeliveryStatus.cancelled);
    } catch (e) {
      print('❌ Error cancelling delivery: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Mark as delivered by traveler with photo proof
  Future<void> markAsDeliveredByTraveler({
    required String trackingId,
    required String photoUrl,
    String? notes,
  }) async {
    try {
      _isLoading.value = true;

      final trackingRef =
          _firestore.collection(_trackingCollection).doc(trackingId);

      // Get current location for delivery checkpoint
      final locationData = await _locationService.getCurrentLocation();
      final updateData = <String, dynamic>{
        'status': DeliveryStatus.delivered.name,
        'deliveryTime': FieldValue.serverTimestamp(),
        'deliveryPhotoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      // Add location if available
      if (locationData != null) {
        final geocodingService = Get.find<GeocodingService>();
        final address = await geocodingService.getAddressFromCoordinates(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
        );

        final locationPoint = LocationPoint(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          address: address,
        );

        updateData['currentLocation'] = locationPoint.toMap();

        // Add to tracking points
        final now = DateTime.now();
        updateData['trackingPoints'] = FieldValue.arrayUnion([
          {
            ...locationPoint.toMap(),
            'timestamp': Timestamp.fromDate(now),
            'status': DeliveryStatus.delivered.name,
          }
        ]);
      }

      await trackingRef.update(updateData);

      // Get tracking data to notify sender
      final tracking = await getTracking(trackingId);
      if (tracking != null) {
        // Send in-app notification to sender to confirm delivery
        await _notificationService.createNotification(
          userId: tracking.senderId,
          title: '📦 Package Delivered!',
          body: 'post_package.your_package_has_been_delivered_please_confirm_to_'.tr(),
          type: NotificationType.packageUpdate,
          relatedEntityId: trackingId,
          data: {
            'trackingId': trackingId,
            'packageRequestId': tracking.packageRequestId,
            'photoUrl': photoUrl,
            'action': 'confirm_delivery',
          },
        );

        // Send email notification to sender
        await _sendEmailNotification(
          trackingId: trackingId,
          tracking: tracking,
          status: 'delivered',
          title: '📦 Package Delivered!',
          body:
              'Your package has been delivered. Please confirm to release payment.',
        );
      }

      print('✅ Package marked as delivered by traveler');
    } catch (e) {
      print('❌ Error marking as delivered by traveler: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Confirm delivery as sender
  Future<void> confirmDeliveryAsSender({
    required String trackingId,
    String? notes,
  }) async {
    try {
      _isLoading.value = true;

      final trackingRef =
          _firestore.collection(_trackingCollection).doc(trackingId);

      final updateData = <String, dynamic>{
        'senderConfirmed': true,
        'senderConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updateData['senderFeedback'] = notes;
      }

      await trackingRef.update(updateData);

      // Get tracking data to process payment release
      final tracking = await getTracking(trackingId);
      if (tracking != null) {
        // Find the booking associated with this package
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('packageId', isEqualTo: tracking.packageRequestId)
            .where('travelerId', isEqualTo: tracking.travelerId)
            .limit(1)
            .get();

        if (bookingsSnapshot.docs.isNotEmpty) {
          final bookingDoc = bookingsSnapshot.docs.first;
          final bookingData = bookingDoc.data();

          // Release payment to traveler
          try {
            final PaymentService paymentService = PaymentService();
            await paymentService.releasePayment(
              bookingId: bookingDoc.id,
              travelerId: tracking.travelerId,
              amount: (bookingData['travelerPayout'] ?? 0.0).toDouble(),
              reason: 'delivery_confirmed',
            );

            // Update booking payment status
            await _firestore.collection('bookings').doc(bookingDoc.id).update({
              'paymentHoldStatus': 'released',
              'paymentReleasedAt': FieldValue.serverTimestamp(),
              'paymentReleaseReason': 'Sender confirmed delivery',
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });

            print('✅ Payment released successfully');
          } catch (paymentError) {
            print('⚠️ Failed to release payment: $paymentError');
            // Don't fail the confirmation if payment release fails
            // Payment can be released manually later
          }
        }

        // Notify traveler that payment has been released
        await _notificationService.createNotification(
          userId: tracking.travelerId,
          title: 'notifications.payment_released'.tr(),
          body: 'common.the_sender_confirmed_delivery_payment_has_been_rel'.tr(),
          type: NotificationType.general,
          relatedEntityId: trackingId,
          data: {
            'trackingId': trackingId,
            'packageRequestId': tracking.packageRequestId,
            'action': 'payment_released',
          },
        );
      }

      print('✅ Delivery confirmed by sender');
    } catch (e) {
      print('❌ Error confirming delivery as sender: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Send status notification
  Future<void> _sendStatusNotification(
      String trackingId, DeliveryStatus status) async {
    try {
      final tracking = await getTracking(trackingId);
      if (tracking == null) return;

      String title;
      String body;
      String emailStatus;

      switch (status) {
        case DeliveryStatus.picked_up:
          title = '📦 Package Picked Up';
          body = 'Your package has been picked up and is on its way!';
          emailStatus = 'picked_up';
          break;
        case DeliveryStatus.in_transit:
          title = '🚚 Package In Transit';
          body = 'Your package is currently in transit';
          emailStatus = 'in_transit';
          break;
        case DeliveryStatus.delivered:
          title = '✅ Package Delivered';
          body = 'Your package has been successfully delivered!';
          emailStatus = 'delivered';
          break;
        case DeliveryStatus.cancelled:
          title = '❌ Delivery Cancelled';
          body = 'The delivery has been cancelled';
          emailStatus = 'cancelled';
          break;
        default:
          return;
      }

      // Send in-app notification to the sender
      if (tracking.senderId.isNotEmpty) {
        await _notificationService.createNotification(
          userId: tracking.senderId,
          title: title,
          body: body,
          type: NotificationType.packageUpdate,
          relatedEntityId: tracking.packageRequestId,
          data: {
            'trackingId': trackingId,
            'status': status.name,
          },
        );
        print('✅ In-app notification sent to sender: ${tracking.senderId}');

        // Send email notification to sender
        await _sendEmailNotification(
          trackingId: trackingId,
          tracking: tracking,
          status: emailStatus,
          title: title,
          body: body,
        );
      } else {
        print('⚠️ No sender ID found in tracking data');
      }
    } catch (e) {
      print('❌ Error sending status notification: $e');
    }
  }

  /// Send email notification for tracking updates
  Future<void> _sendEmailNotification({
    required String trackingId,
    required DeliveryTracking tracking,
    required String status,
    required String title,
    required String body,
  }) async {
    try {
      // Get sender's email from Firestore
      final senderDoc =
          await _firestore.collection('users').doc(tracking.senderId).get();

      if (!senderDoc.exists) {
        print('⚠️ Sender user document not found');
        return;
      }

      final senderData = senderDoc.data();
      final senderEmail = senderData?['email'] as String?;

      if (senderEmail == null || senderEmail.isEmpty) {
        print('⚠️ Sender email not found');
        return;
      }

      // Get package details
      final packageDoc = await _firestore
          .collection(_packagesCollection)
          .doc(tracking.packageRequestId)
          .get();

      if (!packageDoc.exists) {
        print('⚠️ Package document not found');
        return;
      }

      final packageData = packageDoc.data()!;

      // Prepare package details for email
      final packageDetails = {
        'packageId': tracking.packageRequestId,
        'trackingNumber': trackingId,
        'from': packageData['fromLocation']?['city'] ?? 'Unknown',
        'to': packageData['toLocation']?['city'] ?? 'Unknown',
        'description': packageData['description'] ?? 'Package',
        'weight': packageData['weight']?.toString() ?? 'N/A',
      };

      // Create tracking URL (adjust to your app's deep link or web URL)
      final trackingUrl = 'https://crowdwave.eu/track/$trackingId';

      // Send email via Cloud Function
      print('📧 Sending email notification to: $senderEmail');
      print('📦 Status: $status');

      await _emailService.sendDeliveryUpdateEmail(
        recipientEmail: senderEmail,
        packageDetails: packageDetails,
        status: status,
        trackingUrl: trackingUrl,
      );

      print('✅ Email notification sent successfully to: $senderEmail');
    } catch (e) {
      print('❌ Error sending email notification: $e');
      // Don't throw - we don't want email failures to break the app
    }
  }

  /// Get status color
  static Color getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.picked_up:
        return Color(0xFF008080);
      case DeliveryStatus.in_transit:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  /// Get status icon
  static IconData getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Icons.pending_actions;
      case DeliveryStatus.picked_up:
        return Icons.flight_takeoff;
      case DeliveryStatus.in_transit:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Get status display text
  static String getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending Pickup';
      case DeliveryStatus.picked_up:
        return 'Picked Up';
      case DeliveryStatus.in_transit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }
}
