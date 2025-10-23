import 'package:cloud_firestore/cloud_firestore.dart';

/// Wallet transaction model for tracking financial activities
class WalletTransaction {
  final String id;
  final String userId;
  final WalletTransactionType type;
  final double amount;
  final WalletTransactionStatus status;
  final String? bookingId;
  final String? trackingId;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    this.bookingId,
    this.trackingId,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  /// Create transaction from Firestore document
  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WalletTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => WalletTransactionType.other,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: WalletTransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WalletTransactionStatus.pending,
      ),
      bookingId: data['bookingId'],
      trackingId: data['trackingId'],
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'status': status.name,
      'bookingId': bookingId,
      'trackingId': trackingId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  WalletTransaction copyWith({
    String? id,
    String? userId,
    WalletTransactionType? type,
    double? amount,
    WalletTransactionStatus? status,
    String? bookingId,
    String? trackingId,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      trackingId: trackingId ?? this.trackingId,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if transaction increases balance
  bool get isCredit =>
      type == WalletTransactionType.earning ||
      type == WalletTransactionType.refund ||
      type == WalletTransactionType.release;

  /// Check if transaction decreases balance
  bool get isDebit =>
      type == WalletTransactionType.spending ||
      type == WalletTransactionType.withdrawal ||
      type == WalletTransactionType.hold;

  /// Get formatted amount with sign
  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'WalletTransaction(id: $id, type: ${type.name}, amount: \$$amount, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Transaction type enumeration
enum WalletTransactionType {
  earning, // Received payment for delivery
  spending, // Paid for package delivery
  withdrawal, // Withdrew to bank
  refund, // Refund received
  hold, // Payment held in escrow
  release, // Payment released from hold
  other, // Other transaction types
}

/// Transaction status enumeration
enum WalletTransactionStatus {
  pending, // Transaction initiated but not complete
  completed, // Transaction successfully completed
  failed, // Transaction failed
  cancelled, // Transaction cancelled
}

/// Extension for transaction type display
extension WalletTransactionTypeExtension on WalletTransactionType {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case WalletTransactionType.earning:
        return 'Earning';
      case WalletTransactionType.spending:
        return 'Payment';
      case WalletTransactionType.withdrawal:
        return 'Withdrawal';
      case WalletTransactionType.refund:
        return 'Refund';
      case WalletTransactionType.hold:
        return 'Payment Hold';
      case WalletTransactionType.release:
        return 'Payment Release';
      case WalletTransactionType.other:
        return 'Transaction';
    }
  }

  /// Get icon name for UI
  String get iconName {
    switch (this) {
      case WalletTransactionType.earning:
        return 'arrow_circle_down';
      case WalletTransactionType.spending:
        return 'arrow_circle_up';
      case WalletTransactionType.withdrawal:
        return 'account_balance';
      case WalletTransactionType.refund:
        return 'refresh';
      case WalletTransactionType.hold:
        return 'lock';
      case WalletTransactionType.release:
        return 'lock_open';
      case WalletTransactionType.other:
        return 'swap_horiz';
    }
  }

  /// Get color hex for UI
  String get colorHex {
    switch (this) {
      case WalletTransactionType.earning:
      case WalletTransactionType.refund:
      case WalletTransactionType.release:
        return '#4CAF50'; // Green
      case WalletTransactionType.spending:
      case WalletTransactionType.withdrawal:
        return '#F44336'; // Red
      case WalletTransactionType.hold:
        return '#FF9800'; // Orange
      case WalletTransactionType.other:
        return '#9E9E9E'; // Grey
    }
  }
}
