import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart' show PaymentMethod;

/// Payment details for booking transactions
class PaymentDetails {
  final String? stripePaymentIntentId;
  final String? stripeCustomerId;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final DateTime? processedAt;
  final String? failureReason;
  final bool isEscrow;
  final DateTime? escrowReleaseDate;
  final String? receiptUrl;
  final Map<String, dynamic> metadata;

  const PaymentDetails({
    this.stripePaymentIntentId,
    this.stripeCustomerId,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    this.currency = 'EUR',
    this.processedAt,
    this.failureReason,
    this.isEscrow = true,
    this.escrowReleaseDate,
    this.receiptUrl,
    this.metadata = const {},
  });

  /// Create from Firestore map
  factory PaymentDetails.fromMap(Map<String, dynamic> map) {
    return PaymentDetails(
      stripePaymentIntentId: map['stripePaymentIntentId'],
      stripeCustomerId: map['stripeCustomerId'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'EUR',
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      failureReason: map['failureReason'],
      isEscrow: map['isEscrow'] ?? true,
      escrowReleaseDate: map['escrowReleaseDate'] != null
          ? (map['escrowReleaseDate'] as Timestamp).toDate()
          : null,
      receiptUrl: map['receiptUrl'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeCustomerId': stripeCustomerId,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'failureReason': failureReason,
      'isEscrow': isEscrow,
      'escrowReleaseDate': escrowReleaseDate != null
          ? Timestamp.fromDate(escrowReleaseDate!)
          : null,
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  PaymentDetails copyWith({
    String? stripePaymentIntentId,
    String? stripeCustomerId,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    double? amount,
    String? currency,
    DateTime? processedAt,
    String? failureReason,
    bool? isEscrow,
    DateTime? escrowReleaseDate,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentDetails(
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      isEscrow: isEscrow ?? this.isEscrow,
      escrowReleaseDate: escrowReleaseDate ?? this.escrowReleaseDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.succeeded;

  /// Check if payment is in escrow
  bool get isInEscrow => isEscrow && status == PaymentStatus.succeeded;

  /// Check if payment can be refunded
  bool get canBeRefunded {
    return status == PaymentStatus.succeeded &&
        (escrowReleaseDate == null ||
            DateTime.now().isBefore(escrowReleaseDate!));
  }

  /// Get payment status display text
  String get statusDisplayText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.processing:
        return 'Processing Payment';
      case PaymentStatus.succeeded:
        return isEscrow ? 'Payment Secured' : 'Payment Completed';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.cancelled:
        return 'Payment Cancelled';
      case PaymentStatus.refunded:
        return 'Payment Refunded';
      case PaymentStatus.disputed:
        return 'Payment Disputed';
    }
  }

  /// Get payment method display text
  String get paymentMethodDisplayText {
    switch (paymentMethod) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  @override
  String toString() {
    return 'PaymentDetails(amount: $amount $currency, status: $status, method: $paymentMethod)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentDetails &&
        other.stripePaymentIntentId == stripePaymentIntentId;
  }

  @override
  int get hashCode => stripePaymentIntentId.hashCode;
}

/// Payment status enumeration
enum PaymentStatus {
  pending, // Payment initiated but not processed
  processing, // Payment being processed by payment gateway
  succeeded, // Payment successful
  failed, // Payment failed
  cancelled, // Payment cancelled by user
  refunded, // Payment refunded
  disputed, // Payment disputed
}

/// Extension for payment status colors and icons
extension PaymentStatusExtension on PaymentStatus {
  /// Get status color for UI
  String get colorHex {
    switch (this) {
      case PaymentStatus.pending:
        return '#FFA500'; // Orange
      case PaymentStatus.processing:
        return '#2196F3'; // Blue
      case PaymentStatus.succeeded:
        return '#4CAF50'; // Green
      case PaymentStatus.failed:
        return '#F44336'; // Red
      case PaymentStatus.cancelled:
        return '#757575'; // Grey
      case PaymentStatus.refunded:
        return '#FF9800'; // Amber
      case PaymentStatus.disputed:
        return '#9C27B0'; // Purple
    }
  }

  /// Get status icon name
  String get iconName {
    switch (this) {
      case PaymentStatus.pending:
        return 'schedule';
      case PaymentStatus.processing:
        return 'sync';
      case PaymentStatus.succeeded:
        return 'check_circle';
      case PaymentStatus.failed:
        return 'error';
      case PaymentStatus.cancelled:
        return 'cancel';
      case PaymentStatus.refunded:
        return 'undo';
      case PaymentStatus.disputed:
        return 'warning';
    }
  }
}

/// Extension for payment method icons
extension PaymentMethodExtension on PaymentMethod {
  /// Get payment method icon name
  String get iconName {
    switch (this) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return 'credit_card';
      case PaymentMethod.paypal:
        return 'paypal'; // Custom icon needed
      case PaymentMethod.applePay:
        return 'apple'; // Custom icon needed
      case PaymentMethod.googlePay:
        return 'google_pay'; // Custom icon needed
      case PaymentMethod.bankTransfer:
        return 'account_balance';
    }
  }

  /// Check if payment method supports instant processing
  bool get supportsInstantProcessing {
    switch (this) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
      case PaymentMethod.applePay:
      case PaymentMethod.googlePay:
        return true;
      case PaymentMethod.paypal:
      case PaymentMethod.bankTransfer:
        return false;
    }
  }

  /// Check if payment method requires additional verification
  bool get requiresVerification {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return true;
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
      case PaymentMethod.paypal:
      case PaymentMethod.applePay:
      case PaymentMethod.googlePay:
        return false;
    }
  }
}
