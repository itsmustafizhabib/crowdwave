import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/models/deal_offer.dart';
import '../core/models/chat_message.dart';
import '../core/models/package_request.dart';
import '../core/models/travel_trip.dart';
import '../core/repositories/trip_repository.dart';
import 'chat_service.dart';
import 'admin_service.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class DealNegotiationService {
  static final DealNegotiationService _instance =
      DealNegotiationService._internal();
  factory DealNegotiationService() => _instance;
  DealNegotiationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final AdminService _adminService = AdminService();
  final TripRepository _tripRepository = TripRepository();
  final NotificationService _notificationService = NotificationService();

  // Collections
  static const String _dealsCollection = 'deals';
  static const String _packageRequestsCollection = 'packageRequests';

  // Constants
  static const Duration _defaultOfferExpiration = Duration(hours: 24);
  static const int maxOffersPerUserPerPackage = 2;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Send a price offer for a package
  Future<DealOffer> sendPriceOffer({
    required String packageId,
    required String conversationId,
    required String travelerId,
    required double offeredPrice,
    String? message,
    Duration? expirationDuration,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to send offers');
      }

      // Validate package exists and is available
      await _validatePackageForOffer(packageId);

      // Get package owner ID
      final packageDoc = await _firestore
          .collection(_packageRequestsCollection)
          .doc(packageId)
          .get();

      if (!packageDoc.exists || packageDoc.data() == null) {
        throw Exception('Package not found');
      }

      final packageOwnerId = packageDoc.data()!['senderId'] as String;

      // Create deal offer
      final dealOffer = DealOffer(
        id: _generateDealId(),
        packageId: packageId,
        conversationId: conversationId,
        travelerId: travelerId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown User',
        packageOwnerId: packageOwnerId,
        offeredPrice: offeredPrice,
        message: message,
        status: DealStatus.pending,
        createdAt: DateTime.now(),
        expiresAt:
            DateTime.now().add(expirationDuration ?? _defaultOfferExpiration),
      );

      // Save to Firestore
      await _firestore
          .collection(_dealsCollection)
          .doc(dealOffer.id)
          .set(dealOffer.toMap());

      // Send chat message
      await _chatService.sendMessage(
        conversationId: conversationId,
        content: _formatOfferMessage(dealOffer),
        type: MessageType.deal_offer,
        metadata: {
          'dealOfferId': dealOffer.id,
          'offeredPrice': offeredPrice,
          'packageId': packageId,
        },
      );

      // ✅ Send notification to package owner about new offer
      try {
        // Get package details
        final packageDoc = await _firestore
            .collection(_packageRequestsCollection)
            .doc(packageId)
            .get();

        if (packageDoc.exists && packageDoc.data() != null) {
          final packageData = packageDoc.data()!;
          final senderId = packageData['senderId'];

          // Safely extract location names
          String packageRoute = 'your package';
          try {
            final pickupLocation =
                packageData['pickupLocation'] as Map<String, dynamic>?;
            final deliveryLocation =
                packageData['deliveryLocation'] as Map<String, dynamic>?;

            if (pickupLocation != null && deliveryLocation != null) {
              final pickupCity = pickupLocation['city'] ??
                  pickupLocation['address'] ??
                  'pickup';
              final deliveryCity = deliveryLocation['city'] ??
                  deliveryLocation['address'] ??
                  'delivery';
              packageRoute = 'your package from $pickupCity to $deliveryCity';
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not parse location data: $e');
            }
          }

          final travelerName = currentUser.displayName ?? 'A traveler';

          if (kDebugMode) {
            print('🔔 CREATING NOTIFICATION FOR OFFER RECEIVED');
            print('  📧 Recipient userId: $senderId');
            print('  👤 Traveler name: $travelerName');
            print('  💰 Offer amount: \$${offeredPrice.toStringAsFixed(2)}');
            print('  📦 Package: $packageRoute');
          }

          await _notificationService.createNotification(
            userId: senderId,
            title: 'notifications.new_offer'.tr(),
            body:
                '$travelerName made an offer of \$${offeredPrice.toStringAsFixed(2)} for $packageRoute',
            type: NotificationType.offerReceived,
            relatedEntityId: packageId,
            data: {
              'dealId': dealOffer.id,
              'packageId': packageId,
              'travelerName': travelerName,
              'offerAmount': offeredPrice,
              'type': 'offer_received',
            },
          );

          if (kDebugMode) {
            print(
                '✅ Notification creation completed for package owner: $senderId');
            print(
                '🔔 Check Firestore "notifications" collection for userId: $senderId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error sending offer notification: $e');
        }
        // Don't throw - notification failure shouldn't block the offer
      }

      // ✅ OPTIMIZED: Fire-and-forget chat refresh (don't block user flow)
      _refreshChatInBackground();

      // ✅ OPTIMIZED: Fire-and-forget admin logging (don't block user flow)
      _logOfferEventInBackground(
        dealOffer: dealOffer,
        packageId: packageId,
        offeredPrice: offeredPrice,
        travelerId: travelerId,
        userId: currentUser.uid,
      );

      if (kDebugMode) {
        print(
            'Deal offer sent: ${dealOffer.id} for \$${offeredPrice.toStringAsFixed(2)}');
      }

      return dealOffer;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending price offer: $e');
      }
      rethrow;
    }
  }

  /// Send a counter offer
  Future<DealOffer> sendCounterOffer({
    required String originalOfferId,
    required double counterPrice,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to send counter offers');
      }

      // Get original offer
      final originalOffer = await getDealOffer(originalOfferId);
      if (originalOffer == null) {
        throw Exception('Original offer not found');
      }

      if (!originalOffer.canRespond) {
        throw Exception(
            'Cannot respond to this offer (expired or already responded)');
      }

      // Create counter offer (keep same packageOwnerId as original)
      final counterOffer = DealOffer(
        id: _generateDealId(),
        packageId: originalOffer.packageId,
        conversationId: originalOffer.conversationId,
        travelerId: originalOffer.travelerId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown User',
        packageOwnerId: originalOffer.packageOwnerId,
        offeredPrice: counterPrice,
        message: message,
        status: DealStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(_defaultOfferExpiration),
        originalOfferId: originalOfferId,
      );

      // Reject original offer
      await _updateDealStatus(
          originalOfferId, DealStatus.rejected, 'Counter offer made');

      // Save counter offer
      await _firestore
          .collection(_dealsCollection)
          .doc(counterOffer.id)
          .set(counterOffer.toMap());

      // Send chat message
      await _chatService.sendMessage(
        conversationId: originalOffer.conversationId,
        content: _formatCounterOfferMessage(
            counterOffer, originalOffer.offeredPrice),
        type: MessageType.deal_counter,
        metadata: {
          'dealOfferId': counterOffer.id,
          'originalOfferId': originalOfferId,
          'counterPrice': counterPrice,
          'originalPrice': originalOffer.offeredPrice,
        },
      );

      if (kDebugMode) {
        print(
            'Counter offer sent: ${counterOffer.id} for \$${counterPrice.toStringAsFixed(2)}');
      }

      return counterOffer;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending counter offer: $e');
      }
      rethrow;
    }
  }

  /// Accept a deal offer and prepare booking data
  Future<Map<String, dynamic>> acceptDealAndGetBookingData(
      String dealOfferId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to accept deals');
      }

      final dealOffer = await getDealOffer(dealOfferId);
      if (dealOffer == null) {
        throw Exception('Deal offer not found');
      }

      if (!dealOffer.canRespond) {
        throw Exception(
            'Cannot accept this offer (expired or already responded)');
      }

      // Accept the deal first
      await acceptDeal(dealOfferId);

      if (kDebugMode) {
        print('🔍 PACKAGE LOOKUP DEBUG:');
        print('  - Deal package ID: ${dealOffer.packageId}');
        print('  - Collection: $_packageRequestsCollection');
      }

      // Get package data
      final packageDoc = await _firestore
          .collection(_packageRequestsCollection)
          .doc(dealOffer.packageId)
          .get();

      if (kDebugMode) {
        print('  - Package document exists: ${packageDoc.exists}');
        if (packageDoc.exists) {
          print('  - Package document ID: ${packageDoc.id}');
          print('  - Package data senderId: ${packageDoc.data()?['senderId']}');
        }
      }

      if (!packageDoc.exists) {
        throw Exception('Package not found');
      }

      final packageData = packageDoc.data()!;

      if (kDebugMode) {
        print('  - Package data preview:');
        print('    - senderId: ${packageData['senderId']}');
        print('    - status: ${packageData['status']}');
        print('    - createdAt: ${packageData['createdAt']}');
        print('    - id in packageData: ${packageData['id']}');
        print('  - Document ID (correct): ${packageDoc.id}');
      }

      // CRITICAL FIX: Remove 'id' from packageData to prevent overwriting document ID
      final cleanedPackageData = Map<String, dynamic>.from(packageData);
      cleanedPackageData.remove('id');

      final package = PackageRequest.fromJson({
        'id': packageDoc.id,
        ...cleanedPackageData,
      });

      if (kDebugMode) {
        print('  - Created PackageRequest object with ID: ${package.id}');
      }

      // Enhanced trip linking - get actual trip data
      TravelTrip? actualTrip;
      try {
        if (kDebugMode) {
          print('🔍 Getting trips for traveler: ${dealOffer.travelerId}');
        }

        // Find the most recent active trip by the traveler
        final tripStream =
            _tripRepository.getTripsByTraveler(dealOffer.travelerId);

        if (kDebugMode) {
          print('📡 Trip stream created, waiting for first emission...');
        }

        final travelerTrips = await tripStream
            .timeout(
              const Duration(seconds: 10),
              onTimeout: (sink) {
                if (kDebugMode) {
                  print('⏱️ Stream timeout, adding empty list');
                }
                sink.add(<TravelTrip>[]);
              },
            )
            .first
            .catchError((error) {
              if (kDebugMode) {
                print('❌ Error getting first stream emission: $error');
              }
              return <TravelTrip>[];
            });

        if (kDebugMode) {
          print(
              '✅ Found ${travelerTrips.length} trips for traveler ${dealOffer.travelerId}');
        }

        if (travelerTrips.isEmpty) {
          if (kDebugMode) {
            print('No trips found for traveler ${dealOffer.travelerId}');
          }
          actualTrip = null;
        } else {
          // Find an active trip that could match this package
          if (kDebugMode) {
            print(
                'Filtering ${travelerTrips.length} trips for active status...');
          }

          final activeTrips = travelerTrips
              .where((trip) => trip.status == TripStatus.active)
              .toList();

          if (kDebugMode) {
            print('Found ${activeTrips.length} active trips');
          }

          if (activeTrips.isEmpty) {
            actualTrip = null;
            if (kDebugMode) {
              print('No active trips found');
            }
          } else {
            final compatibleTrips = activeTrips
                .where((trip) => _isTripCompatibleWithPackage(trip, package))
                .toList();

            if (kDebugMode) {
              print('Found ${compatibleTrips.length} compatible trips');
            }

            actualTrip =
                compatibleTrips.isNotEmpty ? compatibleTrips.first : null;
          }

          if (kDebugMode) {
            print('Compatible trip found: ${actualTrip != null}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching trip data: $e');
        }
        // Continue with fallback trip data
      }

      // Create trip data (use actual trip if found, otherwise create minimal data)
      Map<String, dynamic> tripData;
      if (actualTrip != null) {
        tripData = actualTrip.toJson();
        if (kDebugMode) {
          print('Using actual trip data for trip: ${actualTrip.id}');
        }
      } else {
        if (kDebugMode) {
          print(
              'Creating fallback trip data for traveler: ${dealOffer.travelerId}');
        }

        // Create safe fallback trip data with proper null checks
        final pickupLocation = packageData['pickupLocation'];
        final destinationLocation = packageData['destinationLocation'];
        final deliveryDate = packageData['preferredDeliveryDate'];

        tripData = {
          'id': 'temp_trip_${dealOffer.travelerId}',
          'travelerId': dealOffer.travelerId,
          'travelerName':
              'Traveler', // Will be enhanced when user profiles are linked
          'travelerPhotoUrl': '',
          'departureLocation': pickupLocation ??
              {
                'address': 'Unknown Location',
                'latitude': 0.0,
                'longitude': 0.0,
              },
          'destinationLocation': destinationLocation ??
              {
                'address': 'Unknown Destination',
                'latitude': 0.0,
                'longitude': 0.0,
              },
          'departureDate': deliveryDate ??
              DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'transportMode': 'car',
          'capacity': {
            'maxWeightKg': 10.0,
            'maxVolumeLiters': 50.0,
            'maxPackages': 5,
            'acceptedSizes': ['small', 'medium'],
          },
          'suggestedReward': dealOffer.offeredPrice,
          'acceptedItemTypes': ['other'], // Use valid PackageType enum value
          'routeStops': [],
          'status': 'active', // Use valid TripStatus enum value
          'acceptedPackageIds': [],
          'totalPackagesAccepted': 0,
          'totalEarnings': 0.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'isFlexibleRoute': false,
          'verificationDocuments': [],
        };
      }

      // Create TravelTrip from data with error handling
      TravelTrip trip;
      try {
        trip = TravelTrip.fromJson(tripData);
        if (kDebugMode) {
          print('Successfully created TravelTrip object');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating TravelTrip from JSON: $e');
        }
        throw Exception('Failed to process trip data: $e');
      }

      final result = {
        'dealOffer': dealOffer,
        'package': package,
        'trip': trip,
      };

      if (kDebugMode) {
        print('Successfully prepared booking data for deal: ${dealOffer.id}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting deal and getting booking data: $e');
      }
      rethrow;
    }
  }

  /// Accept a deal offer
  Future<void> acceptDeal(String dealOfferId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to accept deals');
      }

      final dealOffer = await getDealOffer(dealOfferId);
      if (dealOffer == null) {
        throw Exception('Deal offer not found');
      }

      if (!dealOffer.canRespond) {
        throw Exception(
            'Cannot accept this offer (expired or already responded)');
      }

      // DEBUG: Log deal details for permission debugging
      if (kDebugMode) {
        print('🔍 DEAL ACCEPTANCE DEBUG:');
        print('  - Current user: ${currentUser.uid}');
        print('  - Deal ID: ${dealOfferId}');
        print('  - Deal senderId: ${dealOffer.senderId}');
        print('  - Deal travelerId: ${dealOffer.travelerId}');
        print('  - Deal packageId: ${dealOffer.packageId}');
        print('  - Deal conversationId: ${dealOffer.conversationId}');

        // Check package ownership
        try {
          final packageDoc = await _firestore
              .collection(_packageRequestsCollection)
              .doc(dealOffer.packageId)
              .get();
          if (packageDoc.exists) {
            final packageData = packageDoc.data()!;
            print('  - Package owner (senderId): ${packageData['senderId']}');
            print(
                '  - Current user is package owner: ${currentUser.uid == packageData['senderId']}');
          } else {
            print('  - ❌ Package document not found!');
          }
        } catch (e) {
          print('  - ❌ Error checking package: $e');
        }
      }

      // Update deal status
      await _updateDealStatus(
          dealOfferId, DealStatus.accepted, 'Deal accepted');

      // Update package status to matched
      await _firestore
          .collection(_packageRequestsCollection)
          .doc(dealOffer.packageId)
          .update({
        'status': PackageStatus.matched.name,
        'assignedTravelerId': dealOffer.travelerId,
        'finalPrice': dealOffer.offeredPrice,
        'dealId': dealOfferId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send chat message
      await _chatService.sendMessage(
        conversationId: dealOffer.conversationId,
        content: _formatAcceptanceMessage(dealOffer),
        type: MessageType.deal_accepted,
        metadata: {
          'dealOfferId': dealOfferId,
          'finalPrice': dealOffer.offeredPrice,
          'packageId': dealOffer.packageId,
        },
      );

      // ✅ Send notification to the traveler who made the offer
      try {
        // Get package details for notification
        final packageDoc = await _firestore
            .collection(_packageRequestsCollection)
            .doc(dealOffer.packageId)
            .get();

        if (packageDoc.exists && packageDoc.data() != null) {
          final packageData = packageDoc.data()!;

          // Safely extract location names
          String packageRoute = 'the package';
          try {
            final pickupLocation =
                packageData['pickupLocation'] as Map<String, dynamic>?;
            final deliveryLocation =
                packageData['deliveryLocation'] as Map<String, dynamic>?;

            if (pickupLocation != null && deliveryLocation != null) {
              final pickupCity = pickupLocation['city'] ??
                  pickupLocation['address'] ??
                  'pickup';
              final deliveryCity = deliveryLocation['city'] ??
                  deliveryLocation['address'] ??
                  'delivery';
              packageRoute = 'the package from $pickupCity to $deliveryCity';
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not parse location data: $e');
            }
          }

          final senderName = packageData['senderName'] ?? 'Package owner';

          await _notificationService.createNotification(
            userId: dealOffer.travelerId,
            title: 'Offer Accepted! 🎉',
            body:
                '$senderName accepted your offer of \$${dealOffer.offeredPrice.toStringAsFixed(2)} for $packageRoute',
            type: NotificationType.offerAccepted,
            relatedEntityId: dealOffer.packageId,
            data: {
              'dealId': dealOfferId,
              'packageId': dealOffer.packageId,
              'senderName': senderName,
              'finalPrice': dealOffer.offeredPrice,
              'type': 'offer_accepted',
            },
          );

          if (kDebugMode) {
            print('✅ Notification sent to traveler: ${dealOffer.travelerId}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error sending acceptance notification: $e');
        }
        // Don't throw - notification failure shouldn't block the deal
      }

      // Log admin event
      await _adminService.logSystemEvent(
        eventType: 'DEAL_ACCEPTED',
        description:
            'Deal accepted for package ${dealOffer.packageId}: \$${dealOffer.offeredPrice.toStringAsFixed(2)}',
        metadata: {
          'dealId': dealOfferId,
          'packageId': dealOffer.packageId,
          'finalPrice': dealOffer.offeredPrice,
          'travelerId': dealOffer.travelerId,
        },
        userId: currentUser.uid,
      );

      if (kDebugMode) {
        print(
            'Deal accepted: $dealOfferId for \$${dealOffer.offeredPrice.toStringAsFixed(2)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting deal: $e');
      }
      rethrow;
    }
  }

  /// Reject a deal offer
  Future<void> rejectDeal(String dealOfferId, {String? reason}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to reject deals');
      }

      final dealOffer = await getDealOffer(dealOfferId);
      if (dealOffer == null) {
        throw Exception('Deal offer not found');
      }

      if (!dealOffer.canRespond) {
        throw Exception(
            'Cannot reject this offer (expired or already responded)');
      }

      // Update deal status
      await _updateDealStatus(
          dealOfferId, DealStatus.rejected, reason ?? 'Offer declined');

      // Send chat message
      await _chatService.sendMessage(
        conversationId: dealOffer.conversationId,
        content: _formatRejectionMessage(dealOffer, reason),
        type: MessageType.deal_rejected,
        metadata: {
          'dealOfferId': dealOfferId,
          'rejectionReason': reason,
        },
      );

      // ✅ Send notification to the traveler who made the offer
      try {
        // Get package details for notification
        final packageDoc = await _firestore
            .collection(_packageRequestsCollection)
            .doc(dealOffer.packageId)
            .get();

        if (packageDoc.exists && packageDoc.data() != null) {
          final packageData = packageDoc.data()!;

          // Safely extract location names
          String packageRoute = 'the package';
          try {
            final pickupLocation =
                packageData['pickupLocation'] as Map<String, dynamic>?;
            final deliveryLocation =
                packageData['deliveryLocation'] as Map<String, dynamic>?;

            if (pickupLocation != null && deliveryLocation != null) {
              final pickupCity = pickupLocation['city'] ??
                  pickupLocation['address'] ??
                  'pickup';
              final deliveryCity = deliveryLocation['city'] ??
                  deliveryLocation['address'] ??
                  'delivery';
              packageRoute = 'the package from $pickupCity to $deliveryCity';
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not parse location data: $e');
            }
          }

          final senderName = packageData['senderName'] ?? 'Package owner';

          await _notificationService.createNotification(
            userId: dealOffer.travelerId,
            title: 'notifications.offer_declined'.tr(),
            body: '$senderName declined your offer for $packageRoute',
            type: NotificationType.offerRejected,
            relatedEntityId: dealOffer.packageId,
            data: {
              'dealId': dealOfferId,
              'packageId': dealOffer.packageId,
              'senderName': senderName,
              'type': 'offer_rejected',
            },
          );

          if (kDebugMode) {
            print(
                '✅ Rejection notification sent to traveler: ${dealOffer.travelerId}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error sending rejection notification: $e');
        }
        // Don't throw - notification failure shouldn't block the rejection
      }

      if (kDebugMode) {
        print('Deal rejected: $dealOfferId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting deal: $e');
      }
      rethrow;
    }
  }

  /// Get deal offer by ID
  Future<DealOffer?> getDealOffer(String dealOfferId) async {
    try {
      final doc =
          await _firestore.collection(_dealsCollection).doc(dealOfferId).get();
      if (doc.exists && doc.data() != null) {
        return DealOffer.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting deal offer: $e');
      }
      return null;
    }
  }

  /// Get active deals for a package
  Stream<List<DealOffer>> getActiveDealsForPackage(String packageId) {
    return _firestore
        .collection(_dealsCollection)
        .where('packageId', isEqualTo: packageId)
        .where('status', isEqualTo: DealStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DealOffer.fromMap(doc.data()))
            .where((deal) => !deal.isExpired)
            .toList());
  }

  /// Get deal history for a conversation
  Stream<List<DealOffer>> getDealsForConversation(String conversationId) {
    return _firestore
        .collection(_dealsCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DealOffer.fromMap(doc.data())).toList());
  }

  /// Clean up expired deals
  Future<void> cleanupExpiredDeals() async {
    try {
      final expiredDeals = await _firestore
          .collection(_dealsCollection)
          .where('status', isEqualTo: DealStatus.pending.name)
          .where('expiresAt', isLessThan: DateTime.now().toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredDeals.docs) {
        batch.update(doc.reference, {
          'status': DealStatus.expired.name,
          'respondedAt': DateTime.now().toIso8601String(),
          'responseMessage': 'Offer expired',
        });
      }

      await batch.commit();

      if (kDebugMode) {
        print('Cleaned up ${expiredDeals.docs.length} expired deals');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up expired deals: $e');
      }
    }
  }

  // Private helper methods
  String _generateDealId() {
    return 'deal_${DateTime.now().millisecondsSinceEpoch}_${currentUserId?.substring(0, 8) ?? 'anon'}';
  }

  /// Count how many offers a user has made for a specific package
  /// Optimized: Only fetch up to max+1 documents for efficiency
  Future<int> _getUserOfferCountForPackage({
    required String packageId,
    required String userId,
  }) async {
    try {
      // Optimization: Only fetch what we need to make the decision
      // If limit is 2, we only need to know if count >= 2
      final querySnapshot = await _firestore
          .collection(_dealsCollection)
          .where('packageId', isEqualTo: packageId)
          .where('travelerId', isEqualTo: userId)
          .limit(maxOffersPerUserPerPackage + 1) // Only fetch what we need
          .get();

      if (kDebugMode) {
        print(
            'Found ${querySnapshot.docs.length} offers by user $userId for package $packageId');
      }

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error counting user offers: $e');
      }
      return 0; // Return 0 on error to allow the offer attempt
    }
  }

  Future<void> _validatePackageForOffer(String packageId) async {
    try {
      if (kDebugMode) {
        print('=== VALIDATING PACKAGE FOR OFFER ===');
        print('Package ID: $packageId');
      }

      final packageDoc = await _firestore
          .collection(_packageRequestsCollection)
          .doc(packageId)
          .get();

      if (kDebugMode) {
        print('Package document exists: ${packageDoc.exists}');
        if (packageDoc.exists) {
          print('Package data: ${packageDoc.data()}');
        }
      }

      if (!packageDoc.exists) {
        throw Exception(
            'No active delivery request found. Please create a delivery request first.');
      }

      final packageData = packageDoc.data()!;
      final status = PackageStatus.values.firstWhere(
        (e) => e.name == packageData['status'],
        orElse: () => PackageStatus.pending,
      );

      if (kDebugMode) {
        print('Package status: $status');
      }

      if (status != PackageStatus.pending) {
        throw Exception('This delivery request is no longer accepting offers.');
      }

      // Check if user has reached the offer limit for this package
      if (currentUserId != null) {
        final userOfferCount = await _getUserOfferCountForPackage(
          packageId: packageId,
          userId: currentUserId!,
        );

        if (kDebugMode) {
          print(
              'User offer count: $userOfferCount/$maxOffersPerUserPerPackage');
        }

        if (userOfferCount >= maxOffersPerUserPerPackage) {
          throw Exception(
              'You have reached the maximum limit of $maxOffersPerUserPerPackage offers for this package.');
        }
      }

      if (kDebugMode) {
        print('✅ Package validation passed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Package validation failed: $e');
      }
      if (e.toString().contains('No active delivery request') ||
          e.toString().contains('no longer accepting offers') ||
          e.toString().contains('maximum limit')) {
        rethrow;
      }
      throw Exception(
          'Unable to validate delivery request. Please try again or contact support.');
    }
  }

  Future<void> _updateDealStatus(
      String dealOfferId, DealStatus status, String? responseMessage) async {
    await _firestore.collection(_dealsCollection).doc(dealOfferId).update({
      'status': status.name,
      'respondedAt': DateTime.now().toIso8601String(),
      'responseMessage': responseMessage,
    });
  }

  String _formatOfferMessage(DealOffer offer) {
    final baseMessage =
        'I can deliver your package for \$${offer.offeredPrice.toStringAsFixed(2)}';
    return offer.message != null
        ? '$baseMessage\n\n${offer.message}'
        : baseMessage;
  }

  String _formatCounterOfferMessage(
      DealOffer counterOffer, double originalPrice) {
    final baseMessage =
        'Counter offer: \$${counterOffer.offeredPrice.toStringAsFixed(2)} (was \$${originalPrice.toStringAsFixed(2)})';
    return counterOffer.message != null
        ? '$baseMessage\n\n${counterOffer.message}'
        : baseMessage;
  }

  String _formatAcceptanceMessage(DealOffer offer) {
    return 'Deal accepted! I agree to deliver for \$${offer.offeredPrice.toStringAsFixed(2)}. Let\'s proceed with booking confirmation.';
  }

  String _formatRejectionMessage(DealOffer offer, String? reason) {
    final baseMessage =
        'Offer declined for \$${offer.offeredPrice.toStringAsFixed(2)}';
    return reason != null ? '$baseMessage\nReason: $reason' : baseMessage;
  }

  /// Helper method to check if a trip is compatible with a package
  bool _isTripCompatibleWithPackage(TravelTrip trip, PackageRequest package) {
    try {
      // Check if the trip route could accommodate this package
      // For now, we'll use basic proximity and timing checks

      // Check timing - package preferred delivery should be within trip timeframe
      final packageDeliveryDate = package.preferredDeliveryDate;
      final tripDepartureDate = trip.departureDate;

      // Allow some flexibility - package can be delivered within a reasonable window
      final timeDifference =
          packageDeliveryDate.difference(tripDepartureDate).inDays.abs();
      if (timeDifference > 7) {
        // More than 7 days difference
        return false;
      }

      // Check capacity - ensure the trip can handle the package
      // Add null safety checks
      final packageWeight = package.packageDetails.weightKg;
      final tripMaxWeight = trip.capacity.maxWeightKg;

      if (packageWeight > tripMaxWeight) {
        if (kDebugMode) {
          print(
              'Package weight ($packageWeight kg) exceeds trip capacity ($tripMaxWeight kg)');
        }
        return false;
      }

      // Check if item types are compatible
      final packageType = package.packageDetails.type;
      if (!trip.acceptedItemTypes.contains(packageType) &&
          !trip.acceptedItemTypes.contains(PackageType.other)) {
        if (kDebugMode) {
          print('Package type ($packageType) not accepted by trip');
        }
        return false;
      }

      // Basic location compatibility check
      // In a real implementation, you'd use proper geographic distance calculations
      final packagePickup = package.pickupLocation.address.toLowerCase();
      final packageDestination =
          package.destinationLocation.address.toLowerCase();
      final tripDeparture = trip.departureLocation.address.toLowerCase();
      final tripDestination = trip.destinationLocation.address.toLowerCase();

      // Check if package route aligns with trip route
      final pickupMatch = packagePickup.contains(tripDeparture) ||
          tripDeparture.contains(packagePickup);
      final destinationMatch = packageDestination.contains(tripDestination) ||
          tripDestination.contains(packageDestination);

      final isCompatible = pickupMatch && destinationMatch;
      if (kDebugMode) {
        print(
            'Trip compatibility check: pickup=$pickupMatch, destination=$destinationMatch, overall=$isCompatible');
      }

      return isCompatible;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking trip compatibility: $e');
      }
      return true; // Default to compatible if there's an error
    }
  }

  /// Background helper: Refresh chat without blocking user flow
  void _refreshChatInBackground() {
    // Fire-and-forget: The chat will refresh naturally when user navigates
    // No need to explicitly trigger refresh here, avoiding blocking operations
    if (kDebugMode) {
      print('⏩ Chat will refresh naturally on navigation');
    }
  }

  /// Background helper: Log admin event without blocking user flow
  void _logOfferEventInBackground({
    required DealOffer dealOffer,
    required String packageId,
    required double offeredPrice,
    required String travelerId,
    required String userId,
  }) {
    // Fire-and-forget: Run in background, don't await
    Future(() async {
      try {
        await _adminService.logSystemEvent(
          eventType: 'DEAL_OFFER_SENT',
          description:
              'Price offer sent for package $packageId: \$${offeredPrice.toStringAsFixed(2)}',
          metadata: {
            'dealId': dealOffer.id,
            'packageId': packageId,
            'offeredPrice': offeredPrice,
            'travelerId': travelerId,
          },
          userId: userId,
        );
        if (kDebugMode) {
          print('✅ Admin event logged in background');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Background admin logging failed: $e');
        }
      }
    });
  }

  /// Stream all offers received by current user (as package owner)
  /// Stream all offers received by current user (as package owner)
  Stream<List<DealOffer>> streamReceivedOffers() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_dealsCollection)
        .where('packageOwnerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return DealOffer.fromMap(doc.data());
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing offer: $e');
              }
              return null;
            }
          })
          .whereType<DealOffer>()
          .toList();
    });
  }

  /// Stream all offers sent by current user (as traveler)
  Stream<List<DealOffer>> streamSentOffers() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_dealsCollection)
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return DealOffer.fromMap(doc.data());
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing offer: $e');
              }
              return null;
            }
          })
          .whereType<DealOffer>()
          .toList();
    });
  }

  /// Stream all offers for current user (both received and sent)
  Stream<List<DealOffer>> streamAllUserOffers() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    // Query all offers where user is either traveler or sender
    return _firestore
        .collection(_dealsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['travelerId'] == userId || data['senderId'] == userId;
          })
          .map((doc) {
            try {
              return DealOffer.fromMap(doc.data());
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing offer: $e');
              }
              return null;
            }
          })
          .whereType<DealOffer>()
          .toList();
    });
  }

  /// Get count of unseen pending offers (received only)
  /// Stream count of unseen offers received by current user (as package owner)
  Stream<int> streamUnseenOffersCount() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_dealsCollection)
        .where('packageOwnerId', isEqualTo: userId)
        .where('status', isEqualTo: DealStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        try {
          final data = doc.data();
          // Check if offer has been seen (you can add a 'seenAt' field later)
          return data['status'] == DealStatus.pending.name;
        } catch (e) {
          return false;
        }
      }).length;
    });
  }
}
