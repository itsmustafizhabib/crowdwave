import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/booking.dart';

/// Status of funds in escrow
enum EscrowStatus {
  held, // Payment held in escrow
  released, // Released to courier
  refunded, // Refunded to customer
  disputed, // Under dispute resolution
  cancelled, // Booking cancelled, refund initiated
}

/// Reason for escrow action
enum EscrowActionReason {
  deliveryConfirmed,
  customerComplaint,
  courierRequest,
  systemTimeout,
  disputeResolved,
  bookingCancelled,
  fraudDetected,
}

/// Result of escrow operation
class EscrowResult {
  final bool success;
  final String? error;
  final EscrowStatus? newStatus;
  final Map<String, dynamic>? metadata;

  EscrowResult({
    required this.success,
    this.error,
    this.newStatus,
    this.metadata,
  });
}

/// Escrow transaction record
class EscrowTransaction {
  final String id;
  final String bookingId;
  final String customerId;
  final String courierId;
  final double amount;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? stripePaymentIntentId;
  final String? stripeTransferId;
  final EscrowActionReason? lastActionReason;
  final String? notes;

  EscrowTransaction({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.courierId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.stripePaymentIntentId,
    this.stripeTransferId,
    this.lastActionReason,
    this.notes,
  });

  factory EscrowTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscrowTransaction(
      id: doc.id,
      bookingId: data['booking_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      courierId: data['courier_id'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: EscrowStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => EscrowStatus.held,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
      stripePaymentIntentId: data['stripe_payment_intent_id'],
      stripeTransferId: data['stripe_transfer_id'],
      lastActionReason: data['last_action_reason'] != null
          ? EscrowActionReason.values.firstWhere(
              (e) => e.toString().split('.').last == data['last_action_reason'],
              orElse: () => EscrowActionReason.systemTimeout,
            )
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'courier_id': courierId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'stripe_transfer_id': stripeTransferId,
      'last_action_reason': lastActionReason?.toString().split('.').last,
      'notes': notes,
    };
  }
}

/// Service for managing escrow payments in courier delivery system
class EscrowService {
  static final EscrowService _instance = EscrowService._internal();
  factory EscrowService() => _instance;
  EscrowService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auto-release timeout (e.g., 24 hours after delivery confirmation)
  static const Duration autoReleaseTimeout = Duration(hours: 24);

  /// Hold payment in escrow after successful payment
  Future<EscrowResult> holdPaymentInEscrow({
    required String bookingId,
    required String customerId,
    required String courierId,
    required double amount,
    required String stripePaymentIntentId,
    String? notes,
  }) async {
    try {
      log('Holding payment in escrow for booking: $bookingId');

      final escrowTransaction = EscrowTransaction(
        id: '', // Will be set by Firestore
        bookingId: bookingId,
        customerId: customerId,
        courierId: courierId,
        amount: amount,
        status: EscrowStatus.held,
        createdAt: DateTime.now(),
        stripePaymentIntentId: stripePaymentIntentId,
        notes: notes,
      );

      final docRef = await _firestore
          .collection('escrow_transactions')
          .add(escrowTransaction.toFirestore());

      log('Escrow transaction created: ${docRef.id}');

      return EscrowResult(
        success: true,
        newStatus: EscrowStatus.held,
        metadata: {'escrow_id': docRef.id},
      );
    } catch (e) {
      log('Error holding payment in escrow: $e');
      return EscrowResult(
        success: false,
        error: 'Failed to hold payment in escrow: $e',
      );
    }
  }

  /// Release payment to courier after delivery confirmation
  Future<EscrowResult> releasePaymentToCourier({
    required String bookingId,
    required EscrowActionReason reason,
    String? notes,
  }) async {
    try {
      log('Releasing payment to courier for booking: $bookingId');

      final escrow = await _getEscrowByBookingId(bookingId);
      if (escrow == null) {
        return EscrowResult(
          success: false,
          error: 'Escrow transaction not found',
        );
      }

      if (escrow.status != EscrowStatus.held) {
        return EscrowResult(
          success: false,
          error: 'Payment is not in held status (current: ${escrow.status})',
        );
      }

      // Create Stripe transfer to courier
      final transferResult = await _createStripeTransfer(
        amount: escrow.amount,
        courierId: escrow.courierId,
        bookingId: bookingId,
      );

      if (!transferResult.success) {
        return EscrowResult(
          success: false,
          error: 'Failed to transfer payment: ${transferResult.error}',
        );
      }

      // Update escrow status
      await _firestore.collection('escrow_transactions').doc(escrow.id).update({
        'status': EscrowStatus.released.toString().split('.').last,
        'updated_at': Timestamp.fromDate(DateTime.now()),
        'last_action_reason': reason.toString().split('.').last,
        'stripe_transfer_id': transferResult.metadata?['transfer_id'],
        'notes': notes,
      });

      log('Payment released to courier for booking: $bookingId');

      return EscrowResult(
        success: true,
        newStatus: EscrowStatus.released,
        metadata: transferResult.metadata,
      );
    } catch (e) {
      log('Error releasing payment to courier: $e');
      return EscrowResult(
        success: false,
        error: 'Failed to release payment: $e',
      );
    }
  }

  /// Refund payment to customer
  Future<EscrowResult> refundPaymentToCustomer({
    required String bookingId,
    required EscrowActionReason reason,
    double? partialAmount,
    String? notes,
  }) async {
    try {
      log('Refunding payment to customer for booking: $bookingId');

      final escrow = await _getEscrowByBookingId(bookingId);
      if (escrow == null) {
        return EscrowResult(
          success: false,
          error: 'Escrow transaction not found',
        );
      }

      if (escrow.status == EscrowStatus.refunded) {
        return EscrowResult(
          success: false,
          error: 'Payment already refunded',
        );
      }

      final refundAmount = partialAmount ?? escrow.amount;

      // Create Stripe refund
      final refundResult = await _createStripeRefund(
        paymentIntentId: escrow.stripePaymentIntentId!,
        amount: refundAmount,
        reason: reason,
      );

      if (!refundResult.success) {
        return EscrowResult(
          success: false,
          error: 'Failed to process refund: ${refundResult.error}',
        );
      }

      // Update escrow status
      await _firestore.collection('escrow_transactions').doc(escrow.id).update({
        'status': EscrowStatus.refunded.toString().split('.').last,
        'updated_at': Timestamp.fromDate(DateTime.now()),
        'last_action_reason': reason.toString().split('.').last,
        'notes': notes,
      });

      log('Payment refunded to customer for booking: $bookingId');

      return EscrowResult(
        success: true,
        newStatus: EscrowStatus.refunded,
        metadata: refundResult.metadata,
      );
    } catch (e) {
      log('Error refunding payment to customer: $e');
      return EscrowResult(
        success: false,
        error: 'Failed to refund payment: $e',
      );
    }
  }

  /// Handle dispute initiation
  Future<EscrowResult> initiateDispute({
    required String bookingId,
    required String initiatedBy, // customer_id or courier_id
    required String reason,
    String? description,
  }) async {
    try {
      log('Initiating dispute for booking: $bookingId');

      final escrow = await _getEscrowByBookingId(bookingId);
      if (escrow == null) {
        return EscrowResult(
          success: false,
          error: 'Escrow transaction not found',
        );
      }

      if (escrow.status == EscrowStatus.disputed) {
        return EscrowResult(
          success: false,
          error: 'Dispute already initiated',
        );
      }

      // Update escrow to disputed status
      await _firestore.collection('escrow_transactions').doc(escrow.id).update({
        'status': EscrowStatus.disputed.toString().split('.').last,
        'updated_at': Timestamp.fromDate(DateTime.now()),
        'last_action_reason':
            EscrowActionReason.customerComplaint.toString().split('.').last,
        'notes': 'Dispute initiated by $initiatedBy: $reason',
      });

      // Create dispute record
      await _firestore.collection('disputes').add({
        'escrow_id': escrow.id,
        'booking_id': bookingId,
        'initiated_by': initiatedBy,
        'reason': reason,
        'description': description,
        'status': 'open',
        'created_at': Timestamp.fromDate(DateTime.now()),
      });

      log('Dispute initiated for booking: $bookingId');

      return EscrowResult(
        success: true,
        newStatus: EscrowStatus.disputed,
      );
    } catch (e) {
      log('Error initiating dispute: $e');
      return EscrowResult(
        success: false,
        error: 'Failed to initiate dispute: $e',
      );
    }
  }

  /// Get escrow status for a booking
  Future<EscrowTransaction?> getEscrowStatus(String bookingId) async {
    return await _getEscrowByBookingId(bookingId);
  }

  /// Get escrow history for a user (customer or courier)
  Future<List<EscrowTransaction>> getEscrowHistory({
    String? customerId,
    String? courierId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('escrow_transactions');

      if (customerId != null) {
        query = query.where('customer_id', isEqualTo: customerId);
      } else if (courierId != null) {
        query = query.where('courier_id', isEqualTo: courierId);
      }

      final snapshot = await query
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => EscrowTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting escrow history: $e');
      return [];
    }
  }

  /// Auto-release payments after timeout (called by scheduled function)
  Future<void> processAutoReleases() async {
    try {
      final cutoffTime = DateTime.now().subtract(autoReleaseTimeout);

      final snapshot = await _firestore
          .collection('escrow_transactions')
          .where('status', isEqualTo: 'held')
          .where('created_at', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      for (final doc in snapshot.docs) {
        final escrow = EscrowTransaction.fromFirestore(doc);

        // Check if delivery was confirmed
        final booking = await _getBookingById(escrow.bookingId);
        if (booking?.status == BookingStatus.completed) {
          await releasePaymentToCourier(
            bookingId: escrow.bookingId,
            reason: EscrowActionReason.systemTimeout,
            notes: 'Auto-released after delivery confirmation timeout',
          );
        }
      }
    } catch (e) {
      log('Error processing auto-releases: $e');
    }
  }

  // Private helper methods

  Future<EscrowTransaction?> _getEscrowByBookingId(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('escrow_transactions')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return EscrowTransaction.fromFirestore(snapshot.docs.first);
    } catch (e) {
      log('Error getting escrow by booking ID: $e');
      return null;
    }
  }

  Future<Booking?> _getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) return null;

      return Booking.fromFirestore(doc);
    } catch (e) {
      log('Error getting booking: $e');
      return null;
    }
  }

  Future<EscrowResult> _createStripeTransfer({
    required double amount,
    required String courierId,
    required String bookingId,
  }) async {
    try {
      // In a real implementation, you would:
      // 1. Get courier's Stripe Connect account ID
      // 2. Create a transfer to their account
      // 3. Handle platform fees

      // For now, we'll simulate this
      log('Creating Stripe transfer of \$${amount.toStringAsFixed(2)} to courier: $courierId');

      // Simulated transfer (replace with actual Stripe transfer)
      await Future.delayed(const Duration(seconds: 1));

      return EscrowResult(
        success: true,
        metadata: {
          'transfer_id': 'tr_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'courier_id': courierId,
        },
      );
    } catch (e) {
      log('Error creating Stripe transfer: $e');
      return EscrowResult(
        success: false,
        error: 'Transfer failed: $e',
      );
    }
  }

  Future<EscrowResult> _createStripeRefund({
    required String paymentIntentId,
    required double amount,
    required EscrowActionReason reason,
  }) async {
    try {
      log('Creating Stripe refund of \$${amount.toStringAsFixed(2)} for PaymentIntent: $paymentIntentId');

      // Note: In a real implementation, you would use Stripe's backend API
      // to create refunds since the Flutter SDK doesn't support refund creation
      // This would typically be done through your backend server

      // For now, we'll simulate this with a delay and mock response
      await Future.delayed(const Duration(seconds: 2));

      final refundId = 're_${DateTime.now().millisecondsSinceEpoch}';
      log('Simulated Stripe refund created: $refundId');

      return EscrowResult(
        success: true,
        metadata: {
          'refund_id': refundId,
          'amount': amount,
          'status': 'succeeded',
          'payment_intent_id': paymentIntentId,
          'reason': reason.toString().split('.').last,
        },
      );
    } catch (e) {
      log('Error creating Stripe refund: $e');
      return EscrowResult(
        success: false,
        error: 'Refund failed: $e',
      );
    }
  }
}
