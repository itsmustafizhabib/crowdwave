import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/delivery_tracking.dart';
import '../core/models/package_request.dart';
import '../models/notification_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class TrackingService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = Get.find<LocationService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

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
        title: '📦 Tracking Started',
        body: 'Your package delivery tracking has been activated',
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
          final locationPoint = LocationPoint(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
            address:
                'Location: ${locationData.latitude.toStringAsFixed(4)}, ${locationData.longitude.toStringAsFixed(4)}',
          );

          updateData['currentLocation'] = locationPoint.toMap();

          // Add to tracking points
          updateData['trackingPoints'] = FieldValue.arrayUnion([
            {
              ...locationPoint.toMap(),
              'timestamp': FieldValue.serverTimestamp(),
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

    // For now, let's start with just traveler trackings to avoid complexity
    // We can enhance this later once the basic functionality works
    return _firestore
        .collection(_trackingCollection)
        .where('travelerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('❌ Error in tracking stream: $error');
      return [];
    }).map((snapshot) {
      try {
        final travelerTrackings = snapshot.docs
            .map((doc) {
              try {
                return DeliveryTracking.fromMap(doc.data());
              } catch (e) {
                print('❌ Error parsing tracking document ${doc.id}: $e');
                return null;
              }
            })
            .where((tracking) => tracking != null)
            .cast<DeliveryTracking>()
            .toList();

        print(
            '✅ Loaded ${travelerTrackings.length} tracking records as traveler');
        _userTrackings.value = travelerTrackings;
        return travelerTrackings;
      } catch (e) {
        print('❌ Error processing tracking snapshot: $e');
        return <DeliveryTracking>[];
      }
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
              return DeliveryTracking.fromMap(doc.data());
            } catch (e) {
              print('❌ Error parsing traveler tracking document ${doc.id}: $e');
              return null;
            }
          })
          .where((tracking) => tracking != null)
          .cast<DeliveryTracking>()
          .toList();

      // Get packages where user is the sender
      final packageQuery = await _firestore
          .collection(_packagesCollection)
          .where('senderId', isEqualTo: currentUserId)
          .get();

      final packageIds = packageQuery.docs.map((doc) => doc.id).toList();

      List<DeliveryTracking> senderTrackings = [];

      if (packageIds.isNotEmpty) {
        // Process in chunks of 10 to handle Firestore limitations
        for (int i = 0; i < packageIds.length; i += 10) {
          final chunk = packageIds.skip(i).take(10).toList();
          final trackingQuery = await _firestore
              .collection(_trackingCollection)
              .where('packageRequestId', whereIn: chunk)
              .get();

          final chunkTrackings = trackingQuery.docs
              .map((doc) {
                try {
                  return DeliveryTracking.fromMap(doc.data());
                } catch (e) {
                  print(
                      '❌ Error parsing sender tracking document ${doc.id}: $e');
                  return null;
                }
              })
              .where((tracking) => tracking != null)
              .cast<DeliveryTracking>()
              .toList();

          senderTrackings.addAll(chunkTrackings);
        }
      }

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
      return combinedTrackings;
    } catch (e) {
      print('❌ Error getting complete tracking history: $e');
      return [];
    }
  }

  /// DEBUG: Create test tracking data for testing
  Future<void> createTestTrackingData() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      print('⚠️ No current user for test data creation');
      return;
    }

    try {
      print('🧪 Creating test tracking data...');

      // Create a test package request first
      final packageId = _firestore.collection(_packagesCollection).doc().id;
      await _firestore.collection(_packagesCollection).doc(packageId).set({
        'id': packageId,
        'senderId': currentUserId,
        'senderName': 'Test User',
        'senderPhotoUrl': '',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'assignedTravelerId': currentUserId,
        'compensationOffer': 50.0,
        'pickupLocation': {
          'latitude': 37.7749,
          'longitude': -122.4194,
          'address': 'Test Pickup Location',
        },
        'destinationLocation': {
          'latitude': 37.7849,
          'longitude': -122.4094,
          'address': 'Test Destination Location',
        },
        'packageDetails': {
          'description': 'Test Package',
          'weight': 1.0,
          'dimensions': '10x10x10',
        },
        'preferredDeliveryDate':
            DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'insuranceRequired': false,
        'photoUrls': [],
        'isUrgent': false,
        'preferredTransportModes': [],
      });

      // Create a test tracking record
      final trackingId = _firestore.collection(_trackingCollection).doc().id;
      final testTracking = DeliveryTracking(
        id: trackingId,
        packageRequestId: packageId,
        travelerId: currentUserId,
        status: DeliveryStatus.pending,
        trackingPoints: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: 'Test tracking record',
      );

      await _firestore
          .collection(_trackingCollection)
          .doc(trackingId)
          .set(testTracking.toMap());

      print('✅ Test tracking data created successfully');
      print('📦 Package ID: $packageId');
      print('🚚 Tracking ID: $trackingId');
    } catch (e) {
      print('❌ Error creating test data: $e');
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

      final locationPoint = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'address':
            'Location: ${locationData.latitude.toStringAsFixed(4)}, ${locationData.longitude.toStringAsFixed(4)}',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
      };

      await _firestore.collection(_trackingCollection).doc(trackingId).update({
        'trackingPoints': FieldValue.arrayUnion([locationPoint]),
        'currentLocation': {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'address': locationPoint['address'],
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

  /// Send status notification
  Future<void> _sendStatusNotification(
      String trackingId, DeliveryStatus status) async {
    try {
      final tracking = await getTracking(trackingId);
      if (tracking == null) return;

      String title;
      String body;

      switch (status) {
        case DeliveryStatus.picked_up:
          title = '📦 Package Picked Up';
          body = 'Your package has been picked up and is on its way!';
          break;
        case DeliveryStatus.in_transit:
          title = '🚚 Package In Transit';
          body = 'Your package is currently in transit';
          break;
        case DeliveryStatus.delivered:
          title = '✅ Package Delivered';
          body = 'Your package has been successfully delivered!';
          break;
        case DeliveryStatus.cancelled:
          title = '❌ Delivery Cancelled';
          body = 'The delivery has been cancelled';
          break;
        default:
          return;
      }

      await _notificationService.createNotification(
        userId: '', // Will be populated from tracking data when available
        title: title,
        body: body,
        type: NotificationType.packageUpdate,
        relatedEntityId: tracking.packageRequestId,
        data: {
          'trackingId': trackingId,
          'status': status.name,
        },
      );
    } catch (e) {
      print('❌ Error sending status notification: $e');
    }
  }

  /// Get status color
  static Color getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.picked_up:
        return Colors.blue;
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
