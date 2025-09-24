import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/models/deal_offer.dart';
import '../core/models/chat_message.dart';
import '../core/models/package_request.dart';
import '../core/models/travel_trip.dart';
import '../core/repositories/trip_repository.dart';
import '../controllers/chat_controller.dart';
import 'chat_service.dart';
import 'admin_service.dart';

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

  // Collections
  static const String _dealsCollection = 'deals';
  static const String _packageRequestsCollection = 'packageRequests';

  // Constants
  static const Duration _defaultOfferExpiration = Duration(hours: 24);

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

      // Create deal offer
      final dealOffer = DealOffer(
        id: _generateDealId(),
        packageId: packageId,
        conversationId: conversationId,
        travelerId: travelerId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown User',
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

      // ✅ FIX: Trigger chat refresh to ensure offer appears immediately
      try {
        if (Get.isRegistered<ChatController>()) {
          final chatController = Get.find<ChatController>();
          // Small delay to allow message to be saved
          await Future.delayed(const Duration(milliseconds: 500));
          await chatController.refreshConversations();
          if (kDebugMode) {
            print('✅ Chat refreshed after sending offer');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Chat refresh failed after offer: $e');
        }
        // Don't fail the offer if chat refresh fails
      }

      // Log admin event
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

      // Create counter offer
      final counterOffer = DealOffer(
        id: _generateDealId(),
        packageId: originalOffer.packageId,
        conversationId: originalOffer.conversationId,
        travelerId: originalOffer.travelerId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown User',
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

      // Get package data
      final packageDoc = await _firestore
          .collection(_packageRequestsCollection)
          .doc(dealOffer.packageId)
          .get();

      if (!packageDoc.exists) {
        throw Exception('Package not found');
      }

      final packageData = packageDoc.data()!;
      final package = PackageRequest.fromJson({
        'id': packageDoc.id,
        ...packageData,
      });

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

      if (kDebugMode) {
        print('✅ Package validation passed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Package validation failed: $e');
      }
      if (e.toString().contains('No active delivery request') ||
          e.toString().contains('no longer accepting offers')) {
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
}
