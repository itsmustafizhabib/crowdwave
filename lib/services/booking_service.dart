import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/models/booking.dart';
import '../core/models/deal_offer.dart';
import '../core/models/package_request.dart';
import '../core/models/travel_trip.dart';
import '../core/models/cancellation.dart';
import '../core/models/payment_details.dart';
import '../core/models/wallet.dart';
import 'wallet_service.dart';

/// 🚀 PRODUCTION-READY Booking Service - CrowdWave
/// Handles all booking operations, confirmations, and lifecycle management
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lazy initialization of WalletService
  WalletService? _walletService;
  WalletService get walletService {
    _walletService ??= Get.find<WalletService>();
    return _walletService!;
  }

  // Collection references
  final String _bookingsCollection = 'bookings';
  final String _packagesCollection = 'packageRequests';
  final String _tripsCollection = 'travelTrips';
  final String _cancellationsCollection = 'cancellations';

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// 📝 Create a new booking from accepted deal
  Future<Booking> createBooking({
    required DealOffer acceptedDeal,
    required PackageRequest package,
    required TravelTrip trip,
    String? specialInstructions,
    bool skipValidation =
        false, // Add flag to skip validation when package is pre-validated
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be logged in to create booking');
    }

    try {
      if (kDebugMode) {
        print('🔍 BOOKING CREATION DEBUG:');
        print('  - Package ID: ${package.id}');
        print('  - Trip ID: ${trip.id}');
        print('  - Deal ID: ${acceptedDeal.id}');
        print('  - Package senderId: ${package.senderId}');
        print('  - Trip travelerId: ${trip.travelerId}');
        print('  - Skip validation: $skipValidation');
      }

      // 🔥 CRITICAL: Validate that referenced documents exist in Firestore
      // Skip validation if package is already pre-validated (e.g., from deal acceptance flow)
      if (!skipValidation) {
        await _validateBookingReferences(package.id, trip.id);
      } else {
        if (kDebugMode) {
          print(
              '⚠️ Skipping validation - package pre-validated from deal acceptance');
          // But let's still do a quick check to understand the discrepancy
          try {
            final packageDoc = await _firestore
                .collection(_packagesCollection)
                .doc(package.id)
                .get();
            print(
                '  - Quick check: Package ${package.id} exists in Firestore: ${packageDoc.exists}');
            if (!packageDoc.exists) {
              print(
                  '  - 🔥 ISSUE: Package was pre-validated but doesn\'t exist in Firestore!');
              print(
                  '  - This suggests the package ID might be incorrect or the document was deleted');
            }
          } catch (e) {
            print('  - Error during quick check: $e');
          }
        }
      }

      // Calculate fees
      final platformFeePercent = 0.1; // 10% platform fee
      final platformFee = acceptedDeal.offeredPrice * platformFeePercent;
      final travelerPayout = acceptedDeal.offeredPrice - platformFee;
      final totalAmount = acceptedDeal.offeredPrice +
          platformFee; // Customer pays service fee + platform fee

      // 💰 WALLET INTEGRATION: Check sender's balance before creating booking
      if (kDebugMode) {
        print('💰 Checking sender wallet balance...');
      }

      bool hasSufficientBalance = false;
      Wallet? senderWallet;

      try {
        senderWallet = await walletService.getWallet(package.senderId);

        if (senderWallet == null) {
          if (kDebugMode) {
            print('⚠️ Sender wallet not found - will require Stripe payment');
          }
          hasSufficientBalance = false;
        } else {
          hasSufficientBalance = senderWallet.hasSufficientBalance(totalAmount);

          if (kDebugMode) {
            if (hasSufficientBalance) {
              print('✅ Sender has sufficient balance');
              print('   Required: €${totalAmount.toStringAsFixed(2)}');
              print(
                  '   Available: €${senderWallet.balance.toStringAsFixed(2)}');
            } else {
              print(
                  '⚠️ Insufficient wallet balance - will require Stripe payment');
              print('   Required: €${totalAmount.toStringAsFixed(2)}');
              print(
                  '   Available: €${senderWallet.balance.toStringAsFixed(2)}');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Wallet balance check error: $e');
          print('⚠️ Will proceed with Stripe payment requirement');
        }
        hasSufficientBalance = false;
      }

      // Create booking with appropriate status based on wallet balance
      // If insufficient balance, create with paymentPending status to allow Stripe payment
      final booking = Booking(
        id: '', // Will be set by Firestore
        packageId: package.id,
        travelerId: trip.travelerId,
        senderId: package.senderId,
        dealId: acceptedDeal.id,
        status: hasSufficientBalance
            ? BookingStatus.pending
            : BookingStatus.paymentPending,
        createdAt: DateTime.now(),
        totalAmount: totalAmount,
        platformFee: platformFee,
        travelerPayout: travelerPayout,
        specialInstructions: specialInstructions,
        terms: BookingTerms.defaultTerms(),
        paymentHoldStatus: PaymentHoldStatus.held,
        paymentHeldAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection(_bookingsCollection)
          .add(booking.toFirestore());

      final bookingId = docRef.id;

      // 💰 WALLET INTEGRATION: Process payment only if sufficient balance
      if (hasSufficientBalance) {
        if (kDebugMode) {
          print('💰 Processing wallet payment for booking: $bookingId');
        }

        try {
          // 1. Deduct from sender's wallet
          await walletService.addSpending(
            userId: package.senderId,
            amount: totalAmount,
            bookingId: bookingId,
            description: 'Payment for booking #$bookingId',
          );

          if (kDebugMode) {
            print(
                '✅ Deducted €${totalAmount.toStringAsFixed(2)} from sender wallet');
          }

          // 2. Hold payment in traveler's pending balance
          await walletService.holdPayment(
            userId: trip.travelerId,
            amount: travelerPayout,
            bookingId: bookingId,
            description: 'Payment held for booking #$bookingId',
          );

          if (kDebugMode) {
            print(
                '✅ Held €${travelerPayout.toStringAsFixed(2)} in traveler pending balance');
          }
        } catch (walletError) {
          // If wallet transaction fails, delete booking and rethrow
          if (kDebugMode) {
            print('❌ Wallet transaction failed: $walletError');
            print('⚠️ Rolling back booking creation...');
          }

          await docRef.delete();
          throw Exception('Payment processing failed: $walletError');
        }
      } else {
        // Insufficient balance - booking created with paymentPending status
        // User will be directed to Stripe payment
        if (kDebugMode) {
          print('💳 Booking created with paymentPending status');
          print(
              '   User will be directed to Stripe payment for €${totalAmount.toStringAsFixed(2)}');
        }
      }

      // Update package and trip status only if not skipping validation
      // (because if we skip validation, the documents might not exist in Firestore)
      if (!skipValidation) {
        await Future.wait([
          _updatePackageStatus(package.id, PackageStatus.matched),
          _updateTripStatus(trip.id, TripStatus.active),
        ]);
      } else {
        if (kDebugMode) {
          print(
              '⚠️ Skipping package/trip status updates due to skipValidation=true');
        }
      }

      final createdBooking = booking.copyWith(id: bookingId);

      if (kDebugMode) {
        print('✅ Booking created: ${createdBooking.id}');
        print('💰 Amount: \$${createdBooking.totalAmount}');
        print('🎯 Platform fee: \$${createdBooking.platformFee}');
        print('👤 Traveler payout: \$${createdBooking.travelerPayout}');
      }

      return createdBooking;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create booking: $e');
      }
      rethrow;
    }
  }

  /// Validate that package and trip documents exist before creating booking
  Future<void> _validateBookingReferences(
      String packageId, String tripId) async {
    final errors = <String>[];

    if (kDebugMode) {
      print('🔍 VALIDATING BOOKING REFERENCES:');
      print('  - Checking package ID: $packageId');
      print('  - Collection: $_packagesCollection');
    }

    // Check if package exists
    try {
      final packageDoc =
          await _firestore.collection(_packagesCollection).doc(packageId).get();

      if (kDebugMode) {
        print('  - Package document exists: ${packageDoc.exists}');
        if (packageDoc.exists) {
          print('  - Package data keys: ${packageDoc.data()?.keys}');
        }
      }

      if (!packageDoc.exists) {
        errors.add('Package document not found: $packageId');
      }
    } catch (e) {
      errors.add('Failed to validate package: $e');
      if (kDebugMode) {
        print('  - Error validating package: $e');
      }
    }

    // Check if trip exists (skip temporary trips)
    if (!tripId.startsWith('temp_trip_')) {
      try {
        final tripDoc =
            await _firestore.collection(_tripsCollection).doc(tripId).get();

        if (!tripDoc.exists) {
          errors.add('Trip document not found: $tripId');
        }
      } catch (e) {
        errors.add('Failed to validate trip: $e');
      }
    } else {
      // For temporary trips, we should create the actual trip document
      if (kDebugMode) {
        print('⚠️ Warning: Booking references temporary trip: $tripId');
        print('🔧 Consider creating permanent trip document before booking');
      }
    }

    // Throw error if validation failed
    if (errors.isNotEmpty) {
      throw Exception('Booking validation failed:\n${errors.join('\n')}');
    }

    if (kDebugMode) {
      print('✅ Booking references validated successfully');
    }
  }

  /// ✅ Confirm booking with terms agreement
  Future<void> confirmBooking({
    required String bookingId,
    required BookingTerms terms,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be logged in to confirm booking');
    }

    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': BookingStatus.confirmed.name,
        'confirmedAt': FieldValue.serverTimestamp(),
        'terms': terms.toMap(),
      });

      if (kDebugMode) {
        print('✅ Booking confirmed: $bookingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to confirm booking: $e');
      }
      rethrow;
    }
  }

  /// 💳 Update booking with payment details
  Future<void> updatePaymentDetails({
    required String bookingId,
    required PaymentDetails paymentDetails,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'paymentDetails': paymentDetails.toMap(),
      };

      // Update status based on payment status
      if (paymentDetails.status == PaymentStatus.processing) {
        updateData['status'] = BookingStatus.paymentPending.name;
      } else if (paymentDetails.status == PaymentStatus.succeeded) {
        updateData['status'] = BookingStatus.paymentCompleted.name;

        // 🔥 FIX: Create wallet transaction for Stripe payments
        // This ensures the payment appears in transaction history
        if (kDebugMode) {
          print('💰 Payment succeeded - creating wallet transaction...');
          print('   Booking ID: $bookingId');
        }

        try {
          // Get booking details to extract sender ID and amount
          final bookingDoc = await _firestore
              .collection(_bookingsCollection)
              .doc(bookingId)
              .get();

          if (kDebugMode) {
            print('📄 Booking document exists: ${bookingDoc.exists}');
          }

          if (bookingDoc.exists) {
            final bookingData = bookingDoc.data()!;
            final senderId = bookingData['senderId'] as String?;
            final totalAmount = (bookingData['totalAmount'] ?? 0.0) as double;

            if (kDebugMode) {
              print('👤 Sender ID: $senderId');
              print('💵 Total Amount: €${totalAmount.toStringAsFixed(2)}');
            }

            if (senderId != null && totalAmount > 0) {
              // Record the spending transaction in wallet
              if (kDebugMode) {
                print('💳 Creating wallet spending transaction...');
              }

              await walletService.addSpendingTransaction(
                userId: senderId,
                amount: totalAmount,
                bookingId: bookingId,
                description: 'Payment via Stripe for booking #$bookingId',
              );

              if (kDebugMode) {
                print('✅ Wallet transaction recorded successfully!');
                print('   User: $senderId');
                print('   Amount: €${totalAmount.toStringAsFixed(2)}');
                print('   Booking: $bookingId');
              }
            } else {
              if (kDebugMode) {
                print(
                    '⚠️ Missing sender ID or invalid amount - transaction NOT created');
              }
            }
          }
        } catch (walletError) {
          // Don't fail the payment update if wallet transaction fails
          // Just log it for monitoring
          if (kDebugMode) {
            print('❌ Failed to create wallet transaction: $walletError');
            print('   Stack trace: ${StackTrace.current}');
          }
        }
      }

      await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .update(updateData);

      if (kDebugMode) {
        print('✅ Payment details updated for booking: $bookingId');
        print('💳 Payment status: ${paymentDetails.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update payment details: $e');
      }
      rethrow;
    }
  }

  /// 🚚 Update booking status (for tracking progress)
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      if (status == BookingStatus.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_bookingsCollection)
          .doc(bookingId)
          .update(updateData);

      if (kDebugMode) {
        print('✅ Booking status updated: $bookingId -> ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update booking status: $e');
      }
      rethrow;
    }
  }

  /// ❌ Cancel booking
  Future<Cancellation> cancelBooking({
    required String bookingId,
    required CancellationReason reason,
    String? description,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be logged in to cancel booking');
    }

    try {
      // Get booking details
      final booking = await getBooking(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      if (!booking.canBeCancelled) {
        throw Exception(
            'Booking cannot be cancelled in current status: ${booking.status}');
      }

      // Calculate penalty and refund
      final timeUntilPickup =
          Duration(hours: 24); // TODO: Calculate actual time
      final penaltyAmount = CancellationPenaltyCalculator.calculatePenalty(
        originalAmount: booking.totalAmount,
        timeUntilPickup: timeUntilPickup,
        reason: reason,
      );
      final refundAmount = CancellationPenaltyCalculator.calculateRefund(
        originalAmount: booking.totalAmount,
        penaltyAmount: penaltyAmount,
      );

      // Create cancellation record
      final cancellation = Cancellation(
        id: '', // Will be set by Firestore
        bookingId: bookingId,
        cancelledById: currentUserId!,
        reason: reason,
        description: description,
        cancelledAt: DateTime.now(),
        penaltyAmount: penaltyAmount,
        refundAmount: refundAmount,
        status: CancellationStatus.pending,
      );

      // Add cancellation record
      final docRef = await _firestore
          .collection(_cancellationsCollection)
          .add(cancellation.toFirestore());

      // Update booking status
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason.name,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      final createdCancellation = cancellation.copyWith(id: docRef.id);

      if (kDebugMode) {
        print('✅ Booking cancelled: $bookingId');
        print('💰 Penalty: \$${createdCancellation.penaltyAmount}');
        print('💸 Refund: \$${createdCancellation.refundAmount}');
      }

      return createdCancellation;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cancel booking: $e');
      }
      rethrow;
    }
  }

  /// 📖 Get booking by ID
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc =
          await _firestore.collection(_bookingsCollection).doc(bookingId).get();

      if (!doc.exists) {
        return null;
      }

      return Booking.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get booking: $e');
      }
      rethrow;
    }
  }

  /// 📱 Watch booking real-time updates
  Stream<Booking?> watchBooking(String bookingId) {
    return _firestore
        .collection(_bookingsCollection)
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Booking.fromFirestore(doc);
    });
  }

  /// 📋 Get user's bookings (as sender)
  Stream<List<Booking>> getUserBookingsAsSender() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_bookingsCollection)
        .where('senderId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  /// 🚚 Get user's bookings (as traveler)
  Stream<List<Booking>> getUserBookingsAsTraveler() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_bookingsCollection)
        .where('travelerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  /// 🔍 Get all user's bookings
  Stream<List<Booking>> getAllUserBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // Combine sender and traveler bookings
    return _firestore
        .collection(_bookingsCollection)
        .where('senderId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((senderSnapshot) async {
      // Get traveler bookings
      final travelerSnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('travelerId', isEqualTo: currentUserId)
          .get();

      // Combine and deduplicate
      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(senderSnapshot.docs);
      allDocs.addAll(travelerSnapshot.docs);

      // Remove duplicates and sort
      final uniqueDocs = allDocs.toSet().toList();
      uniqueDocs.sort((a, b) {
        final aTime =
            (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
        final bTime =
            (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
        return bTime.compareTo(aTime); // Descending order
      });

      return uniqueDocs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// � Check if user has booked a specific trip
  Future<bool> hasUserBookedTrip(String tripId) async {
    if (currentUserId == null) return false;

    try {
      // Check bookings where current user is the sender (package owner)
      final senderBookings = await _firestore
          .collection(_bookingsCollection)
          .where('senderId', isEqualTo: currentUserId)
          .where('tripId', isEqualTo: tripId)
          .limit(1)
          .get();

      return senderBookings.docs.isNotEmpty;
    } catch (e) {
      print('Error checking trip booking status: $e');
      return false;
    }
  }

  /// 🔍 Check if user has booked a specific package
  Future<bool> hasUserBookedPackage(String packageId) async {
    if (currentUserId == null) return false;

    try {
      // Check bookings where current user is the traveler
      final travelerBookings = await _firestore
          .collection(_bookingsCollection)
          .where('travelerId', isEqualTo: currentUserId)
          .where('packageId', isEqualTo: packageId)
          .limit(1)
          .get();

      return travelerBookings.docs.isNotEmpty;
    } catch (e) {
      print('Error checking package booking status: $e');
      return false;
    }
  }

  /// 💳 Get user's bookings with pending payments
  Stream<List<Booking>> getUserPendingPaymentBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_bookingsCollection)
        .where('senderId', isEqualTo: currentUserId)
        .where('status', whereIn: [
          BookingStatus.paymentPending.name,
          BookingStatus.pending.name
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  /// 💳 Get all pending payment bookings for current user (as sender or traveler)
  Future<List<Booking>> getAllPendingPaymentBookings() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      // Get bookings where user is sender with pending payments
      final senderBookings = await _firestore
          .collection(_bookingsCollection)
          .where('senderId', isEqualTo: currentUserId)
          .where('status', whereIn: [
        BookingStatus.paymentPending.name,
        BookingStatus.pending.name
      ]).get();

      // Get bookings where user is traveler with pending payments
      final travelerBookings = await _firestore
          .collection(_bookingsCollection)
          .where('travelerId', isEqualTo: currentUserId)
          .where('status', whereIn: [
        BookingStatus.paymentPending.name,
        BookingStatus.pending.name
      ]).get();

      // Combine and deduplicate
      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(senderBookings.docs);
      allDocs.addAll(travelerBookings.docs);

      // Remove duplicates and sort by creation date
      final uniqueDocs = allDocs.toSet().toList();
      uniqueDocs.sort((a, b) {
        final aTime =
            (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
        final bTime =
            (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      return uniqueDocs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get pending payment bookings: $e');
      }
      return [];
    }
  }

  /// �📊 Get booking statistics for user
  Future<BookingStats> getUserBookingStats() async {
    if (currentUserId == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Get all user bookings
      final senderBookings = await _firestore
          .collection(_bookingsCollection)
          .where('senderId', isEqualTo: currentUserId)
          .get();

      final travelerBookings = await _firestore
          .collection(_bookingsCollection)
          .where('travelerId', isEqualTo: currentUserId)
          .get();

      final allBookings = [
        ...senderBookings.docs.map((doc) => Booking.fromFirestore(doc)),
        ...travelerBookings.docs.map((doc) => Booking.fromFirestore(doc)),
      ];

      // Calculate statistics
      final totalBookings = allBookings.length;
      final completedBookings =
          allBookings.where((b) => b.status == BookingStatus.completed).length;
      final cancelledBookings =
          allBookings.where((b) => b.status == BookingStatus.cancelled).length;
      final totalSpent = allBookings
          .where((b) => b.senderId == currentUserId)
          .fold<double>(0.0, (sum, b) => sum + b.totalAmount);
      final totalEarned = allBookings
          .where((b) =>
              b.travelerId == currentUserId &&
              b.status == BookingStatus.completed)
          .fold<double>(0.0, (sum, b) => sum + b.travelerPayout);

      return BookingStats(
        totalBookings: totalBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        totalSpent: totalSpent,
        totalEarned: totalEarned,
        completionRate:
            totalBookings > 0 ? completedBookings / totalBookings : 0.0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get booking stats: $e');
      }
      rethrow;
    }
  }

  /// 🔧 Private helper methods

  /// Update package status
  Future<void> _updatePackageStatus(
      String packageId, PackageStatus status) async {
    try {
      // Check if document exists before updating
      final docRef = _firestore.collection(_packagesCollection).doc(packageId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('✅ Package status updated: $packageId -> ${status.name}');
        }
      } else {
        if (kDebugMode) {
          print(
              '⚠️ Package document not found: $packageId - skipping status update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update package status: $e');
      }
      // Don't rethrow - this is not critical for booking flow
    }
  }

  /// Update trip status
  Future<void> _updateTripStatus(String tripId, TripStatus status) async {
    try {
      // Skip updating temporary trip IDs that don't exist in Firestore
      if (tripId.startsWith('temp_trip_')) {
        if (kDebugMode) {
          print('⚠️ Skipping status update for temporary trip: $tripId');
        }
        return;
      }

      // Check if document exists before updating
      final docRef = _firestore.collection(_tripsCollection).doc(tripId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'status': status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('✅ Trip status updated: $tripId -> ${status.name}');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Trip document not found: $tripId - skipping status update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update trip status: $e');
      }
      // Don't rethrow - this is not critical for booking flow
    }
  }

  /// 🧹 Dispose resources
  void dispose() {
    if (kDebugMode) {
      print('🛑 Booking Service disposed');
    }
  }
}

/// Booking statistics model
class BookingStats {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalSpent;
  final double totalEarned;
  final double completionRate;

  const BookingStats({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSpent,
    required this.totalEarned,
    required this.completionRate,
  });

  @override
  String toString() {
    return 'BookingStats(total: $totalBookings, completed: $completedBookings, rate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}
