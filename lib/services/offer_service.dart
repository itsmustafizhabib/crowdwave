import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/auth_state_service.dart';
import '../models/notification_model.dart';

class OfferService {
  static final OfferService _instance = OfferService._internal();
  factory OfferService() => _instance;
  OfferService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthStateService _authService = AuthStateService();

  // Collection names
  static const String _offersCollection = 'offers';
  static const String _tripsCollection = 'trips';

  // Submit an offer for a trip
  Future<String> submitOffer({
    required String tripId,
    required double offerAmount,
    required String notes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get trip details
      final tripDoc =
          await _firestore.collection(_tripsCollection).doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception(
            'This travel plan is no longer available. Please refresh and try again.');
      }

      final tripData = tripDoc.data()!;

      // Check if trip is still active and accepting offers
      final tripStatus = tripData['status'] as String?;
      if (tripStatus != null &&
          tripStatus != 'active' &&
          tripStatus != 'pending') {
        throw Exception('This trip is no longer accepting offers.');
      }

      final travelerId = tripData['travelerId'];
      final tripTitle =
          '${tripData['departureLocation']['city']} to ${tripData['destinationLocation']['city']}';

      // Create offer document
      final offerId = _firestore.collection(_offersCollection).doc().id;
      final offerData = {
        'id': offerId,
        'tripId': tripId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Unknown User',
        'senderEmail': currentUser.email,
        'travelerId': travelerId,
        'offerAmount': offerAmount,
        'notes': notes,
        'status': 'pending', // pending, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save offer to Firestore
      await _firestore
          .collection(_offersCollection)
          .doc(offerId)
          .set(offerData);

      // Send notification to traveler
      await NotificationService.instance.createNotification(
        userId: travelerId,
        title: 'notifications.new_offer'.tr(),
        body:
            '${currentUser.displayName ?? 'Someone'} made an offer of \$${offerAmount.toStringAsFixed(2)} for your trip to $tripTitle',
        type: NotificationType.offerReceived,
        relatedEntityId: tripId,
        data: {
          'tripId': tripId,
          'offerId': offerId,
          'senderName': currentUser.displayName ?? 'Someone',
          'offerAmount': offerAmount,
          'type': 'offer_received',
        },
      );

      if (kDebugMode) {
        print('Offer submitted successfully: $offerId');
        print('Notification sent to traveler: $travelerId');
      }

      return offerId;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting offer: $e');
      }
      throw Exception('Failed to submit offer: $e');
    }
  }

  // Accept an offer
  Future<void> acceptOffer(String offerId) async {
    try {
      // Get offer details
      final offerDoc =
          await _firestore.collection(_offersCollection).doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      final offerData = offerDoc.data()!;
      final senderId = offerData['senderId'];
      final tripId = offerData['tripId'];

      // Update offer status
      await _firestore.collection(_offersCollection).doc(offerId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get trip details for notification
      final tripDoc =
          await _firestore.collection(_tripsCollection).doc(tripId).get();
      final tripData = tripDoc.data()!;
      final tripTitle =
          '${tripData['departureLocation']['city']} to ${tripData['destinationLocation']['city']}';

      // Get traveler name
      final currentUser = _authService.currentUser;
      final travelerName = currentUser?.displayName ?? 'The traveler';

      // Send notification to sender
      await NotificationService.instance.createNotification(
        userId: senderId,
        title: 'common.offer_accepted'.tr(),
        body: '$travelerName accepted your offer for $tripTitle',
        type: NotificationType.offerAccepted,
        data: {
          'tripId': tripId,
          'offerId': offerId,
          'travelerName': travelerName,
        },
      );

      if (kDebugMode) {
        print('Offer accepted: $offerId');
        print('Notification sent to sender: $senderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting offer: $e');
      }
      throw Exception('Failed to accept offer: $e');
    }
  }

  // Reject an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      // Get offer details
      final offerDoc =
          await _firestore.collection(_offersCollection).doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      final offerData = offerDoc.data()!;
      final senderId = offerData['senderId'];
      final tripId = offerData['tripId'];

      // Update offer status
      await _firestore.collection(_offersCollection).doc(offerId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get trip details for notification
      final tripDoc =
          await _firestore.collection(_tripsCollection).doc(tripId).get();
      final tripData = tripDoc.data()!;
      final tripTitle =
          '${tripData['departureLocation']['city']} to ${tripData['destinationLocation']['city']}';

      // Get traveler name
      final currentUser = _authService.currentUser;
      final travelerName = currentUser?.displayName ?? 'The traveler';

      // Send notification to sender
      await NotificationService.instance.createNotification(
        userId: senderId,
        title: 'notifications.offer_rejected'.tr(),
        body: '$travelerName rejected your offer for $tripTitle',
        type: NotificationType.offerRejected,
        data: {
          'tripId': tripId,
          'offerId': offerId,
          'travelerName': travelerName,
        },
      );

      if (kDebugMode) {
        print('Offer rejected: $offerId');
        print('Notification sent to sender: $senderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error rejecting offer: $e');
      }
      throw Exception('Failed to reject offer: $e');
    }
  }

  // Get offers for a trip (for travelers)
  Stream<List<Map<String, dynamic>>> getOffersForTrip(String tripId) {
    return _firestore
        .collection(_offersCollection)
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get offers made by user (for senders)
  Stream<List<Map<String, dynamic>>> getOffersByUser(String userId) {
    return _firestore
        .collection(_offersCollection)
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
