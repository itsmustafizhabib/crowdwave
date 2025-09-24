import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final ChatMessage? lastMessage;
  final Map<String, int> unreadCounts;
  final DateTime lastActivity;
  final String? packageRequestId;
  final bool isActive;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    required this.unreadCounts,
    required this.lastActivity,
    this.packageRequestId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage?.toMap(),
      'unreadCounts': unreadCounts,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'packageRequestId': packageRequestId,
      'isActive': isActive,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars:
          Map<String, String?>.from(map['participantAvatars'] ?? {}),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      lastActivity:
          (map['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      packageRequestId: map['packageRequestId'],
      isActive: map['isActive'] ?? true,
    );
  }

  ChatConversation copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    ChatMessage? lastMessage,
    Map<String, int>? unreadCounts,
    DateTime? lastActivity,
    String? packageRequestId,
    bool? isActive,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastActivity: lastActivity ?? this.lastActivity,
      packageRequestId: packageRequestId ?? this.packageRequestId,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get the other participant's info (for 1-on-1 chats)
  String? getOtherParticipantName(String currentUserId) {
    final otherParticipantId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherParticipantId];
  }

  String? getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String? getOtherParticipantAvatar(String currentUserId) {
    final otherParticipantId = getOtherParticipantId(currentUserId);
    return participantAvatars[otherParticipantId];
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
