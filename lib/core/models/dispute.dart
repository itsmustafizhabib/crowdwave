import 'package:cloud_firestore/cloud_firestore.dart';

/// Dispute model for booking conflicts and issues
class Dispute {
  final String id;
  final String bookingId;
  final String reporterId;
  final String reportedUserId;
  final DisputeReason reason;
  final String description;
  final List<String> evidence;
  final DisputeStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminId;
  final String? adminNotes;
  final String? resolution;
  final DisputeResolution? resolutionType;

  const Dispute({
    required this.id,
    required this.bookingId,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.evidence = const [],
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminId,
    this.adminNotes,
    this.resolution,
    this.resolutionType,
  });

  /// Create dispute from Firestore document
  factory Dispute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Dispute(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: DisputeReason.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => DisputeReason.other,
      ),
      description: data['description'] ?? '',
      evidence: List<String>.from(data['evidence'] ?? []),
      status: DisputeStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DisputeStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      adminId: data['adminId'],
      adminNotes: data['adminNotes'],
      resolution: data['resolution'],
      resolutionType: data['resolutionType'] != null
          ? DisputeResolution.values.firstWhere(
              (e) => e.name == data['resolutionType'],
              orElse: () => DisputeResolution.dismissed,
            )
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.name,
      'description': description,
      'evidence': evidence,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminId': adminId,
      'adminNotes': adminNotes,
      'resolution': resolution,
      'resolutionType': resolutionType?.name,
    };
  }

  /// Create a copy with updated fields
  Dispute copyWith({
    String? id,
    String? bookingId,
    String? reporterId,
    String? reportedUserId,
    DisputeReason? reason,
    String? description,
    List<String>? evidence,
    DisputeStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminId,
    String? adminNotes,
    String? resolution,
    DisputeResolution? resolutionType,
  }) {
    return Dispute(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminId: adminId ?? this.adminId,
      adminNotes: adminNotes ?? this.adminNotes,
      resolution: resolution ?? this.resolution,
      resolutionType: resolutionType ?? this.resolutionType,
    );
  }

  /// Check if dispute is resolved
  bool get isResolved => status == DisputeStatus.resolved;

  /// Check if dispute is pending admin action
  bool get isPendingAdmin => status == DisputeStatus.underReview;

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case DisputeStatus.pending:
        return 'Pending Review';
      case DisputeStatus.underReview:
        return 'Under Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.dismissed:
        return 'Dismissed';
      case DisputeStatus.escalated:
        return 'Escalated';
    }
  }

  /// Get reason display text
  String get reasonDisplayText {
    switch (reason) {
      case DisputeReason.noShow:
        return 'No Show';
      case DisputeReason.damagedPackage:
        return 'Damaged Package';
      case DisputeReason.lateDelivery:
        return 'Late Delivery';
      case DisputeReason.inappropriateBehavior:
        return 'Inappropriate Behavior';
      case DisputeReason.paymentIssue:
        return 'Payment Issue';
      case DisputeReason.fraudulentActivity:
        return 'Fraudulent Activity';
      case DisputeReason.safetyyConcern:
        return 'Safety Concern';
      case DisputeReason.other:
        return 'Other';
    }
  }

  @override
  String toString() {
    return 'Dispute(id: $id, bookingId: $bookingId, reason: $reason, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dispute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Dispute reason enumeration
enum DisputeReason {
  noShow, // User didn't show up
  damagedPackage, // Package was damaged
  lateDelivery, // Delivery was late
  inappropriateBehavior, // Inappropriate behavior
  paymentIssue, // Payment related issue
  fraudulentActivity, // Fraudulent activity
  safetyyConcern, // Safety concern
  other, // Other reason
}

/// Dispute status enumeration
enum DisputeStatus {
  pending, // Dispute submitted, awaiting review
  underReview, // Admin is reviewing the dispute
  resolved, // Dispute resolved
  dismissed, // Dispute dismissed
  escalated, // Dispute escalated to higher authority
}

/// Dispute resolution type
enum DisputeResolution {
  favorReporter, // Resolution in favor of reporter
  favorReported, // Resolution in favor of reported user
  partialRefund, // Partial refund given
  fullRefund, // Full refund given
  warningIssued, // Warning issued to user
  accountSuspended, // Account suspended
  dismissed, // Dispute dismissed
}

/// Extension for dispute status colors and icons
extension DisputeStatusExtension on DisputeStatus {
  /// Get status color for UI
  String get colorHex {
    switch (this) {
      case DisputeStatus.pending:
        return '#FFA500'; // Orange
      case DisputeStatus.underReview:
        return '#2196F3'; // Blue
      case DisputeStatus.resolved:
        return '#4CAF50'; // Green
      case DisputeStatus.dismissed:
        return '#757575'; // Grey
      case DisputeStatus.escalated:
        return '#F44336'; // Red
    }
  }

  /// Get status icon name
  String get iconName {
    switch (this) {
      case DisputeStatus.pending:
        return 'schedule';
      case DisputeStatus.underReview:
        return 'visibility';
      case DisputeStatus.resolved:
        return 'check_circle';
      case DisputeStatus.dismissed:
        return 'cancel';
      case DisputeStatus.escalated:
        return 'priority_high';
    }
  }
}

/// Extension for dispute reason icons
extension DisputeReasonExtension on DisputeReason {
  /// Get reason icon name
  String get iconName {
    switch (this) {
      case DisputeReason.noShow:
        return 'person_off';
      case DisputeReason.damagedPackage:
        return 'broken_image';
      case DisputeReason.lateDelivery:
        return 'schedule';
      case DisputeReason.inappropriateBehavior:
        return 'report';
      case DisputeReason.paymentIssue:
        return 'payment';
      case DisputeReason.fraudulentActivity:
        return 'security';
      case DisputeReason.safetyyConcern:
        return 'warning';
      case DisputeReason.other:
        return 'help_outline';
    }
  }

  /// Get reason priority (higher number = higher priority)
  int get priority {
    switch (this) {
      case DisputeReason.fraudulentActivity:
        return 5;
      case DisputeReason.safetyyConcern:
        return 4;
      case DisputeReason.inappropriateBehavior:
        return 3;
      case DisputeReason.paymentIssue:
        return 3;
      case DisputeReason.damagedPackage:
        return 2;
      case DisputeReason.noShow:
        return 2;
      case DisputeReason.lateDelivery:
        return 1;
      case DisputeReason.other:
        return 1;
    }
  }
}
