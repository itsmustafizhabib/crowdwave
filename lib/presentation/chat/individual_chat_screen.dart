import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../controllers/chat_controller.dart';
import '../../core/models/chat_message.dart';
import '../../widgets/enhanced_snackbar.dart';
import '../../widgets/chat/deal_offer_message_widget.dart';
import '../../services/zego_call_service.dart';
import '../../services/presence_service.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class IndividualChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserAvatar;

  const IndividualChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserAvatar,
  }) : super(key: key);

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  late final ChatController _chatController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final ZegoCallService _callService = ZegoCallService();
  final PresenceService _presenceService = Get.find<PresenceService>();

  @override
  void initState() {
    super.initState();

    // Safely get or create ChatController
    if (Get.isRegistered<ChatController>()) {
      _chatController = Get.find<ChatController>();
    } else {
      _chatController = Get.put(ChatController(), permanent: true);
    }

    // Start listening to messages for this conversation
    _initializeChat();

    // ✅ ENHANCED: Multiple auto-scroll attempts to ensure we're at bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomForced();
    });

    // Additional scroll attempts with delays to handle async loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scrollToBottomForced();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _scrollToBottomForced();
    });
  }

  Future<void> _initializeChat() async {
    try {
      // ✅ IMMEDIATE: Start listening to the provided conversation ID right away
      // This ensures we show messages immediately without waiting for creation
      await _chatController.startListeningToMessages(widget.conversationId);

      // ✅ FIX: Defer reactive operations to next frame to prevent setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // First, ensure the conversation exists by creating or getting it
          final conversationId = await _chatController.createOrGetConversation(
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName,
            otherUserAvatar: widget.otherUserAvatar,
          );

          // Auto-mark conversation as read when user opens it
          if (conversationId != null) {
            await _chatController.chatService
                .markConversationAsRead(conversationId);

            if (kDebugMode) {
              print('📖 Auto-marked conversation as read: $conversationId');
            }
          }

          // ✅ ENHANCED: Ensure scroll to bottom after messages are loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottomForced();
          });

          // ✅ ENHANCED: Also scroll after a short delay to handle async loading
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _scrollToBottomForced();
            }
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error in deferred chat initialization: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing chat: $e');
      }

      // ✅ ENHANCED: Ensure scroll to bottom even on fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottomForced();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Stop listening to messages when leaving the screen
    _chatController.stopListeningToMessages(widget.conversationId);
    super.dispose();
  }

  // ✅ ENHANCED: Force scroll to bottom - more aggressive approach
  void _scrollToBottomForced() {
    if (_scrollController.hasClients && mounted) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        // First jump immediately, then animate for visual feedback
        _scrollController.jumpTo(maxExtent);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final position = _scrollController.position;
    final threshold = 100.0; // Consider "near bottom" if within 100 pixels

    return (position.maxScrollExtent - position.pixels) <= threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
                  backgroundImage: widget.otherUserAvatar != null
                      ? NetworkImage(widget.otherUserAvatar!)
                      : null,
                  child: widget.otherUserAvatar == null
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF215C5C),
                          size: 20,
                        )
                      : null,
                ),
                // Online status indicator
                Obx(() {
                  final isOnline =
                      _chatController.isUserOnline(widget.otherUserId);
                  return Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Obx(() {
                    final isOnline =
                        _chatController.isUserOnline(widget.otherUserId);

                    if (isOnline) {
                      return Text(
                        'chat.online'.tr(),
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    } else {
                      // Get actual last seen time from presence service
                      return StreamBuilder<DateTime?>(
                        stream: _presenceService
                            .getUserLastSeen(widget.otherUserId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final lastSeen = snapshot.data!;
                            final now = DateTime.now();
                            final difference = now.difference(lastSeen);

                            String lastSeenText;
                            if (difference.inMinutes < 1) {
                              lastSeenText = 'Last seen just now';
                            } else if (difference.inMinutes < 60) {
                              lastSeenText =
                                  'Last seen ${difference.inMinutes}m ago';
                            } else if (difference.inHours < 24) {
                              lastSeenText =
                                  'Last seen ${difference.inHours}h ago';
                            } else if (difference.inDays < 7) {
                              lastSeenText =
                                  'Last seen ${difference.inDays}d ago';
                            } else {
                              lastSeenText =
                                  'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
                            }

                            return Text(
                              lastSeenText,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          } else {
                            return Text(
                              'common.last_seen_recently'.tr(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          }
                        },
                      );
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Only show call buttons if not chatting with yourself
          if (widget.otherUserId !=
              _chatController.chatService.currentUserId) ...[
            IconButton(
              icon: const Icon(Icons.call, color: Colors.black87),
              onPressed: () {
                // Start voice call using Zego
                _startVoiceCall();
              },
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.black87),
              onPressed: () {
                // Start video call using Zego
                _startVideoCall();
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              final messages =
                  _chatController.getMessages(widget.conversationId);
              final isLoading = _chatController.isLoading.value;
              // ✅ FIX: Check if we've actually received Firestore data, not just initialized empty array
              final hasLoadedMessages =
                  _chatController.hasReceivedMessages(widget.conversationId);

              if (kDebugMode) {
                print('🖼️ UI REBUILD:');
                print('  - Conversation ID: ${widget.conversationId}');
                print('  - Messages count: ${messages.length}');
                print('  - Is loading: $isLoading');
                print('  - Has loaded messages: $hasLoadedMessages');
                print(
                    '  - messagesMap keys: ${_chatController.messagesMap.keys.toList()}');
                if (messages.isNotEmpty) {
                  print('  - First message: ${messages.first.content}');
                  print('  - Last message: ${messages.last.content}');
                }
              }

              // Show loading indicator if still loading and no messages loaded yet
              if (isLoading && !hasLoadedMessages) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF215C5C),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'chat.loading_messages'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ FIX: Show loading while waiting for first message batch from active subscription
              if (messages.isEmpty && !hasLoadedMessages) {
                if (kDebugMode) {
                  print(
                      '⏳ Waiting for first message batch from global monitoring...');
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF215C5C),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'chat.loading_chats'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show empty state only when we've loaded but there are no messages
              if (messages.isEmpty && hasLoadedMessages) {
                if (kDebugMode) {
                  print('⚠️ Showing empty state - no messages found');
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'chat.no_messages'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'common.start_the_conversation'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  // Don't auto-scroll if user is manually scrolling
                  return false;
                },
                child: ListView.builder(
                  // ✅ FIX: Add key to force proper rebuild when data changes
                  key: ValueKey(messages.length),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  // ✅ ENHANCED: Reverse the list so newest messages are at bottom
                  reverse: false,
                  itemBuilder: (context, index) {
                    // ✅ ENHANCED: More robust bounds checking
                    if (index < 0 || index >= messages.length) {
                      return const SizedBox.shrink();
                    }
                    final message = messages[index];
                    final isFromCurrentUser = message.senderId ==
                        _chatController.chatService.currentUserId;

                    // ✅ ENHANCED: Auto-scroll when new messages appear
                    if (index == messages.length - 1) {
                      // Use multiple strategies to ensure scroll to bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _scrollToBottomForced();
                        }
                      });

                      // Also try after a short delay for async updates
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted && (isFromCurrentUser || _isNearBottom())) {
                          _scrollToBottomForced();
                        }
                      });
                    }

                    return _buildMessageBubble(message, isFromCurrentUser);
                  },
                ),
              );
            }),
          ),

          // Message Input Area
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    icon:
                        const Icon(Icons.attach_file, color: Color(0xFF215C5C)),
                    onPressed: _showAttachmentOptions,
                  ),

                  // Message input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'chat.type_message'.tr(),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF215C5C),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendTextMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isFromCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF215C5C),
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: message.type == MessageType.image
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                  decoration: BoxDecoration(
                    color: message.type == MessageType.image
                        ? Colors.transparent
                        : (isFromCurrentUser
                            ? const Color(0xFF215C5C)
                            : Colors.white),
                    // Slightly reduced opacity for optimistic messages
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isFromCurrentUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isFromCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: message.type == MessageType.image
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: _buildMessageContent(message, isFromCurrentUser),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a')
                          .format(message.timestamp)
                          .toLowerCase(), // Lowercase am/pm
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isFromCurrentUser) ...[
                      const SizedBox(width: 4),
                      _buildMessageStatusIcon(message),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: Color(0xFF215C5C),
                size: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isFromCurrentUser) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isFromCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );

      case MessageType.image:
        final imageBase64 = message.metadata?['imageBase64'] as String?;
        return imageBase64 != null && imageBase64.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  // Show full screen image
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: InteractiveViewer(
                            child: Image.memory(
                              base64Decode(imageBase64),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: 200,
                    child: Image.memory(
                      base64Decode(imageBase64),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            : Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[300],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'chat.image'.tr(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );

      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        );

      case MessageType.file:
        return Row(
          children: [
            Icon(
              Icons.attach_file,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        );

      case MessageType.location:
        return Row(
          children: [
            Icon(
              Icons.location_on,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        );

      case MessageType.package_info:
        return Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        );

      case MessageType.deal_offer:
      case MessageType.deal_counter:
      case MessageType.deal_accepted:
      case MessageType.deal_rejected:
        // Use the DealOfferMessageWidget for deal-related messages
        return DealOfferMessageWidget(
          message: message,
          isCurrentUser: isFromCurrentUser,
          currentUserId: _chatController.chatService.currentUserId ?? '',
        );
    }
  }

  Widget _buildMessageStatusIcon(ChatMessage message) {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF215C5C);
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear the input immediately for better UX
    _messageController.clear();

    // ✅ ENHANCED: Scroll to bottom immediately to show the new message area
    _scrollToBottomForced();

    // Additional scroll after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scrollToBottomForced();
    });

    // Send message with optimistic UI update
    _chatController
        .sendTextMessageWithOptimisticUpdate(
      conversationId: widget.conversationId,
      content: text,
    )
        .then((success) {
      if (!success) {
        if (mounted) {
          EnhancedSnackBar.showError(context, 'Failed to send message');
        }
      }
      // ✅ ENHANCED: Always scroll to bottom after sending (whether success or failure)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottomForced();
      });

      // Additional scroll attempt for extra reliability
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottomForced();
      });
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'common.camera'.tr(),
                  color: Colors.red,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'common.gallery'.tr(),
                  color: Color(0xFF008080),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'common.location'.tr(),
                  color: Colors.green,
                  onTap: () {
                    Get.back();
                    EnhancedSnackBar.showInfo(
                        context, 'Location sharing coming soon!');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    Get.back(); // Close bottom sheet

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final success = await _chatController.sendImageMessage(
          conversationId: widget.conversationId,
          imageFile: File(pickedFile.path),
          caption: 'Image',
        );

        // ✅ ENHANCED: Scroll to bottom after sending image (success or failure)
        _scrollToBottomForced();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _scrollToBottomForced();
        });

        if (!success) {
          EnhancedSnackBar.showError(context, 'Failed to send image');
        }
      }
    } catch (e) {
      EnhancedSnackBar.showError(context, 'Error picking image: $e');
    }
  }

  // 🚀 Start PRODUCTION Voice Call
  void _startVoiceCall() async {
    print('🎤 VOICE CALL BUTTON CLICKED!');
    print('🔄 Checking call service initialization...');

    try {
      // Initialize call service if needed
      if (!_callService.isInitialized) {
        print('⚡ Initializing ZegoCallService...');
        await _callService.initializeZego();
        print('✅ ZegoCallService initialized successfully');
      } else {
        print('✅ ZegoCallService already initialized');
      }

      print('📞 Starting voice call...');
      print('🎯 Receiver: ${widget.otherUserName} (${widget.otherUserId})');

      // Start voice call
      await _callService.startVoiceCall(
        context: context,
        callID: _callService.generateCallID(),
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        receiverAvatar: widget.otherUserAvatar,
      );

      print('🎉 Voice call initiated successfully!');
    } catch (e) {
      print('❌ Voice call failed with error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice call failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🚀 Start PRODUCTION Video Call
  void _startVideoCall() async {
    try {
      // Initialize call service if needed
      if (!_callService.isInitialized) {
        await _callService.initializeZego();
      }

      // Start video call
      await _callService.startVideoCall(
        context: context,
        callID: _callService.generateCallID(),
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        receiverAvatar: widget.otherUserAvatar,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video call failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
