import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  location,
  system,
  package_info,
  deal_offer, // Price negotiation offers
  deal_counter, // Counter offers
  deal_accepted, // Deal acceptance
  deal_rejected, // Deal rejection
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? packageRequestId;
  final Map<String, dynamic>?
      metadata; // For storing additional info like file URLs, location data, etc.
  final String? replyToMessageId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.packageRequestId,
    this.metadata,
    this.replyToMessageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'packageRequestId': packageRequestId,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      packageRequestId: map['packageRequestId'],
      metadata: map['metadata'] as Map<String, dynamic>?,
      replyToMessageId: map['replyToMessageId'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? packageRequestId,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  bool get isRead => status == MessageStatus.read;
  bool get isDelivered => status == MessageStatus.delivered || isRead;
  bool get isSent => status == MessageStatus.sent || isDelivered;
  bool get isFailed => status == MessageStatus.failed;
  bool get isPending => status == MessageStatus.sending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
