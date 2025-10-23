import '../../widgets/liquid_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import '../../controllers/chat_controller.dart';
import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import 'individual_chat_screen.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatController _chatController;
  final TextEditingController _searchController = TextEditingController();
  bool _isControllerReady = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // ✅ FIX: Try to find existing controller first, only create if not exists
      if (Get.isRegistered<ChatController>()) {
        _chatController = Get.find<ChatController>();
        if (kDebugMode) {
          print('♻️ Reusing existing ChatController');
        }
      } else {
        // ✅ FIX: Use Get.putAsync for safe controller initialization
        _chatController = await Get.putAsync<ChatController>(
          () async => ChatController(), // Controller auto-inits in onInit
          permanent: true,
        );
        if (kDebugMode) {
          print('🆕 Created new permanent ChatController');
        }
      }

      setState(() {
        _isControllerReady = true;
      });

      // ✅ FIX: Wait for next frame to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _safeInitialLoad();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Controller initialization failed: $e');
      }
      // Fallback: try standard initialization
      _chatController = Get.put(ChatController(), permanent: true);
      setState(() {
        _isControllerReady = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safeInitialLoad();
      });
    }
  }

  Future<void> _safeInitialLoad() async {
    if (!mounted) return;

    try {
      // ✅ FIX: Add delay to ensure controller is fully bound
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      _chatController.setOnlineStatus(true);

      // ✅ OPTIMIZATION: Only refresh if this is truly the first load
      // The controller already loads conversations on initialization
      if (_isFirstLoad && _chatController.conversations.isEmpty) {
        if (kDebugMode) {
          print('🔄 First load - refreshing conversations...');
        }

        // ✅ FIX: Use completer to ensure load completes
        final completer = Completer<void>();
        final subscription = _chatController.isLoading.listen((isLoading) {
          if (!isLoading && !completer.isCompleted) {
            completer.complete();
          }
        });

        // Set timeout for the load operation
        final timeout = Future.delayed(const Duration(seconds: 5));

        _chatController.refreshConversations();

        await Future.any([completer.future, timeout]);
        subscription.cancel();

        if (kDebugMode) {
          print('✅ Initial load completed');
          print('   - Conversations: ${_chatController.conversations.length}');
        }
      } else {
        if (kDebugMode) {
          print(
              '✅ Conversations already loaded (${_chatController.conversations.length}) - skipping refresh');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Safe initial load error: $e');
      }
    } finally {
      _isFirstLoad = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isControllerReady) return;

    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _chatController.setOnlineStatus(true);
        // ✅ FIX: Refresh data when app resumes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _chatController.refreshConversations();
          }
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _chatController.setOnlineStatus(false);
        break;
      case AppLifecycleState.detached:
        _chatController.setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Show loading until controller is ready
    if (!_isControllerReady || _isFirstLoad) {
      return Scaffold(
        backgroundColor: const Color(0xFFE9E9E9),
        appBar: AppBar(
          title: Text('chat.chats'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF215C5C),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: _LoaderAnimation.primary(size: 140),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: Text('chat.chats'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF215C5C),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'chat.search_conversations_hint'.tr(),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(() {
                  return _chatController.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _chatController.clearSearch();
                          },
                        )
                      : const SizedBox();
                }),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) {
                _chatController.updateSearchQuery(value);
              },
            ),
          ),

          // Chat List
          Expanded(
            child: Obx(() {
              try {
                // ✅ FIX: Add additional safety check for controller state
                if (!_isControllerReady) {
                  return _buildLoadingState();
                }

                if (_chatController.isLoading.value &&
                    _chatController.conversations.isEmpty) {
                  return _buildLoadingState();
                }

                if (_chatController.error.value.isNotEmpty) {
                  return _buildErrorState();
                }

                final conversations = _chatController.filteredConversations;

                // ✅ FIX: Add stability check for conversation list
                if (conversations.isEmpty &&
                    !_chatController.isLoading.value &&
                    _chatController.searchQuery.value.isEmpty) {
                  return _buildEmptyState();
                }

                if (conversations.isEmpty &&
                    _chatController.searchQuery.value.isNotEmpty) {
                  return _buildEmptySearchState();
                }

                return LiquidRefreshIndicator(
                  onRefresh: () async {
                    try {
                      await _chatController.refreshConversations();
                    } catch (e) {
                      if (kDebugMode) {
                        print('❌ Pull-to-refresh error: $e');
                      }
                      // Don't rethrow to avoid breaking the refresh animation
                    }
                  },
                  child: ListView.builder(
                    // ✅ FIX: Add key to force proper rebuild when data changes
                    key: ValueKey(conversations.length),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      // ✅ ENHANCED: More robust bounds checking
                      if (index < 0 || index >= conversations.length) {
                        return const SizedBox.shrink();
                      }

                      final conversation = conversations[index];
                      // ✅ FIX: Add null check for conversation
                      if (conversation.id.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _buildConversationTile(conversation);
                    },
                  ),
                );
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Chat UI build error: $e');
                }
                return _buildErrorStateWithRetry();
              }
            }),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Extract widget methods for better maintainability
  Widget _buildLoadingState() {
    return Center(
      child: _LoaderAnimation.primary(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('error_messages.error_loading_chats'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _chatController.error.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF215C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('chat.no_chats_yet'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text('common.start_a_conversation_with_someone'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('common.no_conversations_found'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text('common.try_searching_for_something_else'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateWithRetry() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('error_messages.something_went_wrong'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text('chat.please_try_refreshing_the_chat'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF215C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('common.refresh'.tr()),
          ),
        ],
      ),
    );
  }

  void _retryLoading() {
    _chatController.error.value = '';
    _chatController.isLoading.value = true;
    _chatController.refreshConversations();
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    // ✅ FIX: Add additional null safety
    if (!_isControllerReady) {
      return const SizedBox();
    }

    final currentUserId = _chatController.chatService.currentUserId ?? '';
    if (currentUserId.isEmpty) {
      return const SizedBox();
    }

    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final otherUserName = conversation.getOtherParticipantName(currentUserId);
    final otherUserAvatar =
        conversation.getOtherParticipantAvatar(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF215C5C).withOpacity(0.1),
              backgroundImage: otherUserAvatar != null
                  ? NetworkImage(otherUserAvatar)
                  : null,
              child: otherUserAvatar == null
                  ? const Icon(Icons.person, color: Color(0xFF215C5C))
                  : null,
            ),
            if (otherUserId != null)
              Obx(() {
                final isOnline = _chatController.isUserOnline(otherUserId);
                return Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                );
              }),
          ],
        ),
        title: Text(
          otherUserName ?? 'Unknown User',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getLastMessagePreview(conversation),
          style: TextStyle(
            fontSize: 14,
            color: unreadCount > 0 ? Colors.black87 : Colors.grey,
            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatLastMessageTime(conversation.lastActivity),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: Color(
                        0xFF10B981), // Green color matching verification badge in home screen
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        onTap: () async {
          if (conversation.id.isNotEmpty && otherUserId?.isNotEmpty == true) {
            final conversationId = conversation.id;

            await Get.to(() => IndividualChatScreen(
                  conversationId: conversationId,
                  otherUserName: otherUserName ?? 'Unknown User',
                  otherUserId: otherUserId!,
                  otherUserAvatar: otherUserAvatar,
                ));

            // ✅ FIX: Optimistically clear badge and refresh to update from server
            if (mounted) {
              // Immediately clear the unread count locally for instant feedback
              _chatController.clearUnreadCountOptimistically(conversationId);

              // Give Firestore a moment to process the read status update
              // and propagate to server before refreshing
              await Future.delayed(const Duration(milliseconds: 500));
              _chatController.refreshConversations();
            }
          }
        },
      ),
    );
  }

  String _getLastMessagePreview(ChatConversation conversation) {
    if (conversation.lastMessage == null) {
      return 'Start a conversation';
    }

    final lastMessage = conversation.lastMessage!;
    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.content;
      case MessageType.image:
        return '📷 Image';
      // ... rest of your message types
      default:
        return 'New message';
    }
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}

/// Reusable loader animation widget encapsulating the Lottie asset.
class _LoaderAnimation extends StatelessWidget {
  final double size;
  const _LoaderAnimation._({this.size = 120});
  factory _LoaderAnimation.primary({double size = 120}) =>
      _LoaderAnimation._(size: size);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Semantics(
        label: 'chat.loading_chats'.tr(),
        child: Lottie.asset(
          'assets/animations/liquid loader 01.json',
          repeat: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
