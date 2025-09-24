import 'package:cloud_firestore/cloud_firestore.dart';

/// Cancellation model for booking cancellations
class Cancellation {
  final String id;
  final String bookingId;
  final String cancelledById;
  final CancellationReason reason;
  final String? description;
  final DateTime cancelledAt;
  final double penaltyAmount;
  final double refundAmount;
  final CancellationStatus status;
  final DateTime? refundProcessedAt;
  final String? refundTransactionId;
  final bool isAutomaticCancellation;

  const Cancellation({
    required this.id,
    required this.bookingId,
    required this.cancelledById,
    required this.reason,
    this.description,
    required this.cancelledAt,
    required this.penaltyAmount,
    required this.refundAmount,
    required this.status,
    this.refundProcessedAt,
    this.refundTransactionId,
    this.isAutomaticCancellation = false,
  });

  /// Create cancellation from Firestore document
  factory Cancellation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Cancellation(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      cancelledById: data['cancelledById'] ?? '',
      reason: CancellationReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => CancellationReason.other,
      ),
      description: data['description'],
      cancelledAt: (data['cancelledAt'] as Timestamp).toDate(),
      penaltyAmount: (data['penaltyAmount'] ?? 0.0).toDouble(),
      refundAmount: (data['refundAmount'] ?? 0.0).toDouble(),
      status: CancellationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CancellationStatus.pending,
      ),
      refundProcessedAt: data['refundProcessedAt'] != null
          ? (data['refundProcessedAt'] as Timestamp).toDate()
          : null,
      refundTransactionId: data['refundTransactionId'],
      isAutomaticCancellation: data['isAutomaticCancellation'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'cancelledById': cancelledById,
      'reason': reason.name,
      'description': description,
      'cancelledAt': Timestamp.fromDate(cancelledAt),
      'penaltyAmount': penaltyAmount,
      'refundAmount': refundAmount,
      'status': status.name,
      'refundProcessedAt': refundProcessedAt != null
          ? Timestamp.fromDate(refundProcessedAt!)
          : null,
      'refundTransactionId': refundTransactionId,
      'isAutomaticCancellation': isAutomaticCancellation,
    };
  }

  /// Create a copy with updated fields
  Cancellation copyWith({
    String? id,
    String? bookingId,
    String? cancelledById,
    CancellationReason? reason,
    String? description,
    DateTime? cancelledAt,
    double? penaltyAmount,
    double? refundAmount,
    CancellationStatus? status,
    DateTime? refundProcessedAt,
    String? refundTransactionId,
    bool? isAutomaticCancellation,
  }) {
    return Cancellation(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      cancelledById: cancelledById ?? this.cancelledById,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      refundAmount: refundAmount ?? this.refundAmount,
      status: status ?? this.status,
      refundProcessedAt: refundProcessedAt ?? this.refundProcessedAt,
      refundTransactionId: refundTransactionId ?? this.refundTransactionId,
      isAutomaticCancellation:
          isAutomaticCancellation ?? this.isAutomaticCancellation,
    );
  }

  /// Check if cancellation is processed
  bool get isProcessed => status == CancellationStatus.completed;

  /// Check if refund is pending
  bool get isRefundPending => status == CancellationStatus.refundPending;

  /// Get total amount lost by canceller (penalty)
  double get totalPenalty => penaltyAmount;

  /// Get net refund amount (original amount - penalty)
  double get netRefundAmount => refundAmount - penaltyAmount;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case CancellationStatus.pending:
        return 'Cancellation Pending';
      case CancellationStatus.approved:
        return 'Cancellation Approved';
      case CancellationStatus.refundPending:
        return 'Refund Pending';
      case CancellationStatus.completed:
        return 'Refund Completed';
      case CancellationStatus.rejected:
        return 'Cancellation Rejected';
    }
  }

  /// Get reason display text
  String get reasonDisplayText {
    switch (reason) {
      case CancellationReason.changedPlans:
        return 'Changed Plans';
      case CancellationReason.emergency:
        return 'Emergency';
      case CancellationReason.travelerUnavailable:
        return 'Traveler Unavailable';
      case CancellationReason.packageNotReady:
        return 'Package Not Ready';
      case CancellationReason.weatherConditions:
        return 'Weather Conditions';
      case CancellationReason.safetyyConcerns:
        return 'Safety Concerns';
      case CancellationReason.paymentIssues:
        return 'Payment Issues';
      case CancellationReason.foundBetterOption:
        return 'Found Better Option';
      case CancellationReason.systemError:
        return 'System Error';
      case CancellationReason.other:
        return 'Other';
    }
  }

  @override
  String toString() {
    return 'Cancellation(id: $id, bookingId: $bookingId, reason: $reason, refundAmount: $refundAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cancellation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Cancellation reason enumeration
enum CancellationReason {
  changedPlans, // User changed their plans
  emergency, // Emergency situation
  travelerUnavailable, // Traveler became unavailable
  packageNotReady, // Package is not ready for pickup
  weatherConditions, // Bad weather conditions
  safetyyConcerns, // Safety concerns
  paymentIssues, // Payment related issues
  foundBetterOption, // Found a better delivery option
  systemError, // System error caused cancellation
  other, // Other reason
}

/// Cancellation status enumeration
enum CancellationStatus {
  pending, // Cancellation requested, awaiting approval
  approved, // Cancellation approved
  refundPending, // Refund is being processed
  completed, // Cancellation and refund completed
  rejected, // Cancellation request rejected
}

/// Penalty calculation helper
class CancellationPenaltyCalculator {
  /// Calculate penalty based on time until pickup and reason
  static double calculatePenalty({
    required double originalAmount,
    required Duration timeUntilPickup,
    required CancellationReason reason,
  }) {
    // Base penalty percentages
    double penaltyPercent = 0.0;

    // Penalty based on timing
    if (timeUntilPickup.inHours >= 24) {
      penaltyPercent = 0.0; // No penalty if cancelled 24+ hours before
    } else if (timeUntilPickup.inHours >= 12) {
      penaltyPercent = 10.0; // 10% penalty if 12-24 hours before
    } else if (timeUntilPickup.inHours >= 6) {
      penaltyPercent = 25.0; // 25% penalty if 6-12 hours before
    } else if (timeUntilPickup.inHours >= 2) {
      penaltyPercent = 50.0; // 50% penalty if 2-6 hours before
    } else {
      penaltyPercent = 75.0; // 75% penalty if less than 2 hours before
    }

    // Adjust penalty based on reason
    switch (reason) {
      case CancellationReason.emergency:
      case CancellationReason.safetyyConcerns:
      case CancellationReason.systemError:
        penaltyPercent *=
            0.0; // No penalty for emergencies/safety/system errors
        break;
      case CancellationReason.weatherConditions:
        penaltyPercent *= 0.5; // 50% reduction for weather
        break;
      case CancellationReason.travelerUnavailable:
      case CancellationReason.packageNotReady:
        penaltyPercent *= 0.7; // 30% reduction for logistics issues
        break;
      case CancellationReason.changedPlans:
      case CancellationReason.foundBetterOption:
        penaltyPercent *= 1.2; // 20% increase for convenience cancellations
        break;
      case CancellationReason.paymentIssues:
      case CancellationReason.other:
        // No adjustment
        break;
    }

    return (originalAmount * penaltyPercent / 100).clamp(0.0, originalAmount);
  }

  /// Calculate refund amount after penalty
  static double calculateRefund({
    required double originalAmount,
    required double penaltyAmount,
  }) {
    return (originalAmount - penaltyAmount).clamp(0.0, originalAmount);
  }
}

/// Extension for cancellation status colors and icons
extension CancellationStatusExtension on CancellationStatus {
  /// Get status color for UI
  String get colorHex {
    switch (this) {
      case CancellationStatus.pending:
        return '#FFA500'; // Orange
      case CancellationStatus.approved:
        return '#4CAF50'; // Green
      case CancellationStatus.refundPending:
        return '#2196F3'; // Blue
      case CancellationStatus.completed:
        return '#4CAF50'; // Green
      case CancellationStatus.rejected:
        return '#F44336'; // Red
    }
  }

  /// Get status icon name
  String get iconName {
    switch (this) {
      case CancellationStatus.pending:
        return 'schedule';
      case CancellationStatus.approved:
        return 'check_circle';
      case CancellationStatus.refundPending:
        return 'sync';
      case CancellationStatus.completed:
        return 'done_all';
      case CancellationStatus.rejected:
        return 'cancel';
    }
  }
}

/// Extension for cancellation reason icons and properties
extension CancellationReasonExtension on CancellationReason {
  /// Get reason icon name
  String get iconName {
    switch (this) {
      case CancellationReason.changedPlans:
        return 'event_busy';
      case CancellationReason.emergency:
        return 'emergency';
      case CancellationReason.travelerUnavailable:
        return 'person_off';
      case CancellationReason.packageNotReady:
        return 'inventory_2';
      case CancellationReason.weatherConditions:
        return 'cloud';
      case CancellationReason.safetyyConcerns:
        return 'security';
      case CancellationReason.paymentIssues:
        return 'payment';
      case CancellationReason.foundBetterOption:
        return 'compare_arrows';
      case CancellationReason.systemError:
        return 'error';
      case CancellationReason.other:
        return 'help_outline';
    }
  }

  /// Check if reason qualifies for penalty reduction
  bool get qualifiesForPenaltyReduction {
    switch (this) {
      case CancellationReason.emergency:
      case CancellationReason.safetyyConcerns:
      case CancellationReason.systemError:
      case CancellationReason.weatherConditions:
        return true;
      case CancellationReason.changedPlans:
      case CancellationReason.travelerUnavailable:
      case CancellationReason.packageNotReady:
      case CancellationReason.paymentIssues:
      case CancellationReason.foundBetterOption:
      case CancellationReason.other:
        return false;
    }
  }

  /// Get penalty reduction factor (0.0 = no penalty, 1.0 = full penalty)
  double get penaltyReductionFactor {
    switch (this) {
      case CancellationReason.emergency:
      case CancellationReason.safetyyConcerns:
      case CancellationReason.systemError:
        return 0.0; // No penalty
      case CancellationReason.weatherConditions:
        return 0.5; // 50% penalty reduction
      case CancellationReason.travelerUnavailable:
      case CancellationReason.packageNotReady:
        return 0.7; // 30% penalty reduction
      case CancellationReason.changedPlans:
      case CancellationReason.foundBetterOption:
        return 1.2; // 20% penalty increase
      case CancellationReason.paymentIssues:
      case CancellationReason.other:
        return 1.0; // No adjustment
    }
  }
}
