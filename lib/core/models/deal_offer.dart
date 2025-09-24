enum DealStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled,
}

class DealOffer {
  final String id;
  final String packageId;
  final String conversationId;
  final String travelerId;
  final String senderId;
  final String senderName;
  final double offeredPrice;
  final String? message;
  final DealStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final String? responseMessage;
  final String? originalOfferId; // For counter-offers

  const DealOffer({
    required this.id,
    required this.packageId,
    required this.conversationId,
    required this.travelerId,
    required this.senderId,
    required this.senderName,
    required this.offeredPrice,
    this.message,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.respondedAt,
    this.responseMessage,
    this.originalOfferId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageId': packageId,
      'conversationId': conversationId,
      'travelerId': travelerId,
      'senderId': senderId,
      'senderName': senderName,
      'offeredPrice': offeredPrice,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'responseMessage': responseMessage,
      'originalOfferId': originalOfferId,
    };
  }

  factory DealOffer.fromMap(Map<String, dynamic> map) {
    return DealOffer(
      id: map['id'] ?? '',
      packageId: map['packageId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      travelerId: map['travelerId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      offeredPrice: (map['offeredPrice'] ?? 0.0).toDouble(),
      message: map['message'],
      status: DealStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DealStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt:
          map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
      responseMessage: map['responseMessage'],
      originalOfferId: map['originalOfferId'],
    );
  }

  DealOffer copyWith({
    String? id,
    String? packageId,
    String? conversationId,
    String? travelerId,
    String? senderId,
    String? senderName,
    double? offeredPrice,
    String? message,
    DealStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    String? responseMessage,
    String? originalOfferId,
  }) {
    return DealOffer(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      conversationId: conversationId ?? this.conversationId,
      travelerId: travelerId ?? this.travelerId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
      originalOfferId: originalOfferId ?? this.originalOfferId,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isPending => status == DealStatus.pending && !isExpired;

  bool get canRespond => isPending;

  bool get isCounterOffer => originalOfferId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DealOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DealOffer(id: $id, price: \$${offeredPrice.toStringAsFixed(2)}, status: $status)';
  }
}
