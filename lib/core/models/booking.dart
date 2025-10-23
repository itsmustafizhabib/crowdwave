import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_details.dart';

/// Core booking model for CrowdWave delivery confirmations
class Booking {
  final String id;
  final String packageId;
  final String travelerId;
  final String senderId;
  final String dealId;
  final BookingStatus status;
  final PaymentDetails? paymentDetails;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final double totalAmount;
  final double platformFee;
  final double travelerPayout;
  final String? specialInstructions;
  final List<String> attachments;
  final BookingTerms terms;

  // Payment hold and release tracking
  final PaymentHoldStatus paymentHoldStatus;
  final DateTime? paymentHeldAt;
  final DateTime? paymentReleasedAt;
  final String? paymentReleaseReason;

  const Booking({
    required this.id,
    required this.packageId,
    required this.travelerId,
    required this.senderId,
    required this.dealId,
    required this.status,
    this.paymentDetails,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancellationReason,
    this.cancelledAt,
    required this.totalAmount,
    required this.platformFee,
    required this.travelerPayout,
    this.specialInstructions,
    this.attachments = const [],
    required this.terms,
    this.paymentHoldStatus = PaymentHoldStatus.held,
    this.paymentHeldAt,
    this.paymentReleasedAt,
    this.paymentReleaseReason,
  });

  /// Create booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      packageId: data['packageId'] ?? '',
      travelerId: data['travelerId'] ?? '',
      senderId: data['senderId'] ?? '',
      dealId: data['dealId'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentDetails: data['paymentDetails'] != null
          ? PaymentDetails.fromMap(data['paymentDetails'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      travelerPayout: (data['travelerPayout'] ?? 0.0).toDouble(),
      specialInstructions: data['specialInstructions'],
      attachments: List<String>.from(data['attachments'] ?? []),
      terms: BookingTerms.fromMap(data['terms'] ?? {}),
      paymentHoldStatus: data['paymentHoldStatus'] != null
          ? PaymentHoldStatus.values.firstWhere(
              (e) => e.name == data['paymentHoldStatus'],
              orElse: () => PaymentHoldStatus.held,
            )
          : PaymentHoldStatus.held,
      paymentHeldAt: data['paymentHeldAt'] != null
          ? (data['paymentHeldAt'] as Timestamp).toDate()
          : null,
      paymentReleasedAt: data['paymentReleasedAt'] != null
          ? (data['paymentReleasedAt'] as Timestamp).toDate()
          : null,
      paymentReleaseReason: data['paymentReleaseReason'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'packageId': packageId,
      'travelerId': travelerId,
      'senderId': senderId,
      'dealId': dealId,
      'status': status.name,
      'paymentDetails': paymentDetails?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancellationReason': cancellationReason,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'travelerPayout': travelerPayout,
      'specialInstructions': specialInstructions,
      'attachments': attachments,
      'terms': terms.toMap(),
      'paymentHoldStatus': paymentHoldStatus.name,
      'paymentHeldAt':
          paymentHeldAt != null ? Timestamp.fromDate(paymentHeldAt!) : null,
      'paymentReleasedAt': paymentReleasedAt != null
          ? Timestamp.fromDate(paymentReleasedAt!)
          : null,
      'paymentReleaseReason': paymentReleaseReason,
    };
  }

  /// Create a copy with updated fields
  Booking copyWith({
    String? id,
    String? packageId,
    String? travelerId,
    String? senderId,
    String? dealId,
    BookingStatus? status,
    PaymentDetails? paymentDetails,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    String? cancellationReason,
    DateTime? cancelledAt,
    double? totalAmount,
    double? platformFee,
    double? travelerPayout,
    String? specialInstructions,
    List<String>? attachments,
    BookingTerms? terms,
    PaymentHoldStatus? paymentHoldStatus,
    DateTime? paymentHeldAt,
    DateTime? paymentReleasedAt,
    String? paymentReleaseReason,
  }) {
    return Booking(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      travelerId: travelerId ?? this.travelerId,
      senderId: senderId ?? this.senderId,
      dealId: dealId ?? this.dealId,
      status: status ?? this.status,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      travelerPayout: travelerPayout ?? this.travelerPayout,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      attachments: attachments ?? this.attachments,
      terms: terms ?? this.terms,
      paymentHoldStatus: paymentHoldStatus ?? this.paymentHoldStatus,
      paymentHeldAt: paymentHeldAt ?? this.paymentHeldAt,
      paymentReleasedAt: paymentReleasedAt ?? this.paymentReleasedAt,
      paymentReleaseReason: paymentReleaseReason ?? this.paymentReleaseReason,
    );
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.pending ||
        status == BookingStatus.confirmed ||
        status == BookingStatus.paymentCompleted;
  }

  /// Check if booking is active
  bool get isActive {
    return status != BookingStatus.cancelled &&
        status != BookingStatus.completed &&
        status != BookingStatus.disputed;
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Confirmation';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.paymentPending:
        return 'Payment Pending';
      case BookingStatus.paymentCompleted:
        return 'Payment Completed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  @override
  String toString() {
    return 'Booking(id: $id, packageId: $packageId, status: $status, amount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Booking status enumeration
enum BookingStatus {
  pending, // Booking created, awaiting confirmation
  confirmed, // Booking confirmed by both parties
  paymentPending, // Payment process initiated
  paymentCompleted, // Payment successful, funds in escrow
  inProgress, // Package pickup/delivery in progress
  completed, // Delivery completed successfully
  cancelled, // Booking cancelled
  disputed, // Dispute raised
}

/// Payment hold status enumeration
enum PaymentHoldStatus {
  held, // Payment held in escrow after booking
  released, // Payment released to traveler
  refunded, // Payment refunded to sender
}

/// Booking terms and conditions
class BookingTerms {
  final bool agreedToTerms;
  final String termsVersion;
  final DateTime agreedAt;
  final bool allowsCancellation;
  final int cancellationWindowHours;
  final double cancellationPenaltyPercent;
  final bool requiresInsurance;
  final double insuranceAmount;

  const BookingTerms({
    required this.agreedToTerms,
    required this.termsVersion,
    required this.agreedAt,
    this.allowsCancellation = true,
    this.cancellationWindowHours = 24,
    this.cancellationPenaltyPercent = 10.0,
    this.requiresInsurance = false,
    this.insuranceAmount = 0.0,
  });

  factory BookingTerms.fromMap(Map<String, dynamic> map) {
    return BookingTerms(
      agreedToTerms: map['agreedToTerms'] ?? false,
      termsVersion: map['termsVersion'] ?? '1.0',
      agreedAt: map['agreedAt'] != null
          ? (map['agreedAt'] as Timestamp).toDate()
          : DateTime.now(),
      allowsCancellation: map['allowsCancellation'] ?? true,
      cancellationWindowHours: map['cancellationWindowHours'] ?? 24,
      cancellationPenaltyPercent:
          (map['cancellationPenaltyPercent'] ?? 10.0).toDouble(),
      requiresInsurance: map['requiresInsurance'] ?? false,
      insuranceAmount: (map['insuranceAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agreedToTerms': agreedToTerms,
      'termsVersion': termsVersion,
      'agreedAt': Timestamp.fromDate(agreedAt),
      'allowsCancellation': allowsCancellation,
      'cancellationWindowHours': cancellationWindowHours,
      'cancellationPenaltyPercent': cancellationPenaltyPercent,
      'requiresInsurance': requiresInsurance,
      'insuranceAmount': insuranceAmount,
    };
  }

  /// Create default terms
  factory BookingTerms.defaultTerms() {
    return BookingTerms(
      agreedToTerms: false,
      termsVersion: '1.0',
      agreedAt: DateTime.now(),
    );
  }

  BookingTerms copyWith({
    bool? agreedToTerms,
    String? termsVersion,
    DateTime? agreedAt,
    bool? allowsCancellation,
    int? cancellationWindowHours,
    double? cancellationPenaltyPercent,
    bool? requiresInsurance,
    double? insuranceAmount,
  }) {
    return BookingTerms(
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      termsVersion: termsVersion ?? this.termsVersion,
      agreedAt: agreedAt ?? this.agreedAt,
      allowsCancellation: allowsCancellation ?? this.allowsCancellation,
      cancellationWindowHours:
          cancellationWindowHours ?? this.cancellationWindowHours,
      cancellationPenaltyPercent:
          cancellationPenaltyPercent ?? this.cancellationPenaltyPercent,
      requiresInsurance: requiresInsurance ?? this.requiresInsurance,
      insuranceAmount: insuranceAmount ?? this.insuranceAmount,
    );
  }
}

/// Extension for booking status colors and icons
extension BookingStatusExtension on BookingStatus {
  /// Get status color for UI
  String get colorHex {
    switch (this) {
      case BookingStatus.pending:
        return '#FFA500'; // Orange
      case BookingStatus.confirmed:
        return '#4CAF50'; // Green
      case BookingStatus.paymentPending:
        return '#2196F3'; // Blue
      case BookingStatus.paymentCompleted:
        return '#4CAF50'; // Green
      case BookingStatus.inProgress:
        return '#FF9800'; // Amber
      case BookingStatus.completed:
        return '#4CAF50'; // Green
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      case BookingStatus.disputed:
        return '#9C27B0'; // Purple
    }
  }

  /// Get status icon name
  String get iconName {
    switch (this) {
      case BookingStatus.pending:
        return 'schedule';
      case BookingStatus.confirmed:
        return 'check_circle';
      case BookingStatus.paymentPending:
        return 'payment';
      case BookingStatus.paymentCompleted:
        return 'paid';
      case BookingStatus.inProgress:
        return 'local_shipping';
      case BookingStatus.completed:
        return 'done_all';
      case BookingStatus.cancelled:
        return 'cancel';
      case BookingStatus.disputed:
        return 'warning';
    }
  }
}
