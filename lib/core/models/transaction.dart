class Transaction {
  final String id;
  final String packageRequestId;
  final String senderId;
  final String travelerId;
  final double amount;
  final double platformFee;
  final double travelerPayout;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? stripePaymentIntentId;
  final String? stripeTransferId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final bool isEscrow;
  final DateTime? escrowReleaseDate;

  Transaction({
    required this.id,
    required this.packageRequestId,
    required this.senderId,
    required this.travelerId,
    required this.amount,
    required this.platformFee,
    required this.travelerPayout,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.stripePaymentIntentId,
    this.stripeTransferId,
    this.completedAt,
    this.failureReason,
    this.isEscrow = true,
    this.escrowReleaseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageRequestId': packageRequestId,
      'senderId': senderId,
      'travelerId': travelerId,
      'amount': amount,
      'platformFee': platformFee,
      'travelerPayout': travelerPayout,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeTransferId': stripeTransferId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failureReason': failureReason,
      'isEscrow': isEscrow,
      'escrowReleaseDate': escrowReleaseDate?.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      packageRequestId: json['packageRequestId'],
      senderId: json['senderId'],
      travelerId: json['travelerId'],
      amount: json['amount'].toDouble(),
      platformFee: json['platformFee'].toDouble(),
      travelerPayout: json['travelerPayout'].toDouble(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status']
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod']
      ),
      stripePaymentIntentId: json['stripePaymentIntentId'],
      stripeTransferId: json['stripeTransferId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      failureReason: json['failureReason'],
      isEscrow: json['isEscrow'] ?? true,
      escrowReleaseDate: json['escrowReleaseDate'] != null 
          ? DateTime.parse(json['escrowReleaseDate']) 
          : null,
    );
  }

  Transaction copyWith({
    String? id,
    String? packageRequestId,
    String? senderId,
    String? travelerId,
    double? amount,
    double? platformFee,
    double? travelerPayout,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? stripePaymentIntentId,
    String? stripeTransferId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? failureReason,
    bool? isEscrow,
    DateTime? escrowReleaseDate,
  }) {
    return Transaction(
      id: id ?? this.id,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      senderId: senderId ?? this.senderId,
      travelerId: travelerId ?? this.travelerId,
      amount: amount ?? this.amount,
      platformFee: platformFee ?? this.platformFee,
      travelerPayout: travelerPayout ?? this.travelerPayout,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeTransferId: stripeTransferId ?? this.stripeTransferId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      isEscrow: isEscrow ?? this.isEscrow,
      escrowReleaseDate: escrowReleaseDate ?? this.escrowReleaseDate,
    );
  }
}

enum TransactionStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
  disputed
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
  bankTransfer
}
