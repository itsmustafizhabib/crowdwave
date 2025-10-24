import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import '../core/models/chat_message.dart';
import '../core/models/chat_conversation.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();

  // Public getter for chat service
  ChatService get chatService => _chatService;
  PresenceService get presenceService => _presenceService;

  // Observable variables
  final RxList<ChatConversation> conversations = <ChatConversation>[].obs;
  final RxMap<String, List<ChatMessage>> messagesMap =
      <String, List<ChatMessage>>{}.obs;
  final RxMap<String, bool> onlineStatus = <String, bool>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // ✅ NEW: Track which conversations have received their first Firestore snapshot
  final RxSet<String> _conversationsWithData = <String>{}.obs;

  // ✅ CRITICAL FIX: Flag to prevent duplicate conversation listeners
  bool _conversationListenerStarted = false;

  // ✅ NEW: Completer to track when first data arrives
  Completer<void>? _firstDataCompleter;

  // ✅ NEW: Flag to prevent UI updates during logout/login transitions
  bool _isTransitioning = false;

  // ✅ NEW: Store pending conversations received during transition
  List<ChatConversation>? _pendingConversations;

  // ✅ NEW: Flag to track if chat has been initialized already
  bool _isInitialized = false;

  // ✅ ALTERNATIVE: Create a reactive computed property for filtered conversations
  late final RxList<ChatConversation> _filteredConversations =
      <ChatConversation>[].obs;

  // Getter that returns the reactive filtered list
  RxList<ChatConversation> get filteredConversations => _filteredConversations;

  // Method to update filtered conversations (called when conversations or search changes)
  void _updateFilteredConversations() {
    // ✅ CRITICAL FIX: Skip updates during transitions to prevent UI errors
    if (_isTransitioning) {
      if (kDebugMode) {
        print('⏸️ Skipping filtered conversation update during transition');
      }
      return;
    }

    if (kDebugMode) {
      print('🔍 Updating filtered conversations:');
      print('  - Total conversations: ${conversations.length}');
      print('  - Search query: "${searchQuery.value}"');
    }

    try {
      List<ChatConversation> filtered;
      if (searchQuery.value.isEmpty) {
        filtered = List.from(conversations);
        if (kDebugMode) {
          print('  - No search query, returning all: ${filtered.length}');
        }
      } else {
        filtered = conversations.where((conversation) {
          final otherUserName = conversation
              .getOtherParticipantName(_chatService.currentUserId ?? '');
          return otherUserName
                  ?.toLowerCase()
                  .contains(searchQuery.value.toLowerCase()) ??
              false;
        }).toList();

        if (kDebugMode) {
          print('  - Filtered conversations: ${filtered.length}');
        }
      }

      // ✅ ATOMIC UPDATE: Only update if not transitioning
      if (!_isTransitioning) {
        _filteredConversations.assignAll(filtered);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating filtered conversations: $e');
      }
    }
  }

  // Stream subscriptions
  StreamSubscription<List<ChatConversation>>? _conversationsSubscription;
  final Map<String, StreamSubscription<List<ChatMessage>>>
      _messageSubscriptions = {};
  final Map<String, StreamSubscription<bool>> _onlineStatusSubscriptions = {};

  @override
  void onInit() {
    super.onInit();

    // ✅ FIX: Set up reactive listeners for changes
    ever(searchQuery, (_) {
      _updateFilteredConversations();
    });

    // ✅ REMOVED: Automatic conversation listener to prevent race conditions
    // Manual updates will be called where needed
    // ever(conversations, (_) {
    //   _updateFilteredConversations();
    // });

    _initializeChat();
  }

  @override
  void onClose() {
    // ✅ PROPER STREAM LIFECYCLE - Only dispose on logout/app termination
    if (kDebugMode) {
      print('🔄 ChatController disposing - cleaning up streams...');
      print('📊 Active message subscriptions: ${_messageSubscriptions.length}');
      print(
          '📊 Active online status subscriptions: ${_onlineStatusSubscriptions.length}');
    }

    _conversationsSubscription?.cancel();
    _conversationListenerStarted = false; // ✅ Reset flag on cleanup
    _pendingConversations = null; // ✅ Clear pending conversations

    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();

    for (final subscription in _onlineStatusSubscriptions.values) {
      subscription.cancel();
    }
    _onlineStatusSubscriptions.clear();

    // ✅ FIX: Don't dispose ChatService since it's a singleton that should persist
    // across multiple ChatController instances. Only cancel our own subscriptions.
    // _chatService.dispose(); // REMOVED - singleton should not be disposed
    _presenceService.dispose();

    if (kDebugMode) {
      print('✅ ChatController cleanup completed');
    }

    super.onClose();
  }

  // Initialize chat functionality
  Future<void> _initializeChat() async {
    try {
      // ✅ CRITICAL FIX: Skip if already initialized to prevent re-initialization loops
      if (_isInitialized) {
        if (kDebugMode) {
          print('✅ Chat already initialized - skipping re-initialization');
          print('   - Conversations: ${conversations.length}');
          print('   - Filtered: ${_filteredConversations.length}');
        }
        return;
      }

      if (kDebugMode) {
        print('🚀 STARTING CHAT INITIALIZATION...');
      }

      // ✅ Set transitioning flag during initialization
      _isTransitioning = true;
      isLoading.value = true;
      error.value = '';

      // ✅ FIX: Initialize filtered conversations as empty
      _filteredConversations.clear();

      // Initialize both services
      if (kDebugMode) {
        print('📱 Initializing ChatService...');
      }
      await _chatService.initialize();

      if (kDebugMode) {
        print('👥 Initializing PresenceService...');
      }
      await _presenceService.initialize();

      // Start listening to conversations immediately
      if (kDebugMode) {
        print('👂 Starting conversations listener...');
      }

      // ✅ NEW: Create completer to wait for first data
      _firstDataCompleter = Completer<void>();

      // ✅ NEW: Immediately force refresh to get cached/fresh data
      if (kDebugMode) {
        print('🔄 Triggering immediate force refresh...');
      }
      _chatService.forceRefreshConversations();

      _startListeningToConversations();

      // ✅ FIX: Wait for first data or timeout
      try {
        await _firstDataCompleter!.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            if (kDebugMode) {
              print('⏰ Timeout waiting for first data - proceeding anyway');
            }
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error waiting for first data: $e');
        }
      }

      // Set loading to false after first data or timeout
      isLoading.value = false;

      // ✅ Clear transitioning flag after initialization completes
      _isTransitioning = false;

      // ✅ CRITICAL FIX: Apply pending conversations that arrived during transition
      if (_pendingConversations != null) {
        if (kDebugMode) {
          print(
              '🔄 Applying ${_pendingConversations!.length} pending conversations received during transition');
        }
        conversations.assignAll(_pendingConversations!);
        _pendingConversations = null;
      }

      // ✅ CRITICAL FIX: Update filtered conversations after transition flag is cleared
      if (conversations.isNotEmpty) {
        _updateFilteredConversations();
        if (kDebugMode) {
          print(
              '✅ Updated filtered conversations after initialization: ${_filteredConversations.length}');
        }
      }

      // ✅ Mark as initialized to prevent re-initialization
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Chat initialization completed successfully!');
        print('  - Final conversations count: ${conversations.length}');
        print('  - Final filtered count: ${_filteredConversations.length}');
        print('  - Final loading state: ${isLoading.value}');
        print('  - Transitioning flag cleared');
        print('  - Controller marked as initialized');
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false; // ✅ Always set false on error
      _isTransitioning = false; // ✅ Clear transitioning flag on error

      // ✅ NEW: Complete completer on initialization error
      if (_firstDataCompleter != null && !_firstDataCompleter!.isCompleted) {
        _firstDataCompleter!.complete();
      }

      if (kDebugMode) {
        print('❌ Chat initialization error: $e');
        print('💡 Error details: ${e.toString()}');
        print('  - Transitioning flag cleared due to error');
      }
    }
  }

  // Ensure ChatService is initialized before using it
  Future<void> _ensureChatServiceInitialized() async {
    if (kDebugMode) {
      print('🔍 Checking ChatService initialization...');
      print('  - Current user ID: ${_chatService.currentUserId}');
    }

    if (_chatService.currentUserId == null) {
      if (kDebugMode) {
        print('⚠️ ChatService not initialized - reinitializing...');
      }
      await _chatService.initialize();
      if (!isLoading.value) {
        _startListeningToConversations();
      }
    } else {
      if (kDebugMode) {
        print('✅ ChatService already initialized');
      }
    }
  }

  // Start listening to conversations
  void _startListeningToConversations() {
    // ✅ CRITICAL FIX: Prevent duplicate listeners
    if (_conversationListenerStarted) {
      if (kDebugMode) {
        print(
            '⚠️ Conversation listener already started, skipping duplicate setup');
      }
      return;
    }

    if (kDebugMode) {
      print('👂 Setting up conversations stream listener...');
    }

    _conversationListenerStarted = true;

    // ✅ FIX: Cancel existing subscription to prevent duplicates
    _conversationsSubscription?.cancel();

    // ✅ REMOVED: Don't restart ChatService listener as it creates duplicates
    // The ChatService should already be initialized and listening

    _conversationsSubscription = _chatService.getConversationsStream().listen(
      (conversationsList) {
        if (kDebugMode) {
          print(
              '📊 CONTROLLER DEBUG: Received conversations update: ${conversationsList.length} conversations');
          if (conversationsList.isEmpty) {
            print(
                '🔴 CONTROLLER DEBUG: Received EMPTY list - this may be the problem!');
          } else {
            print(
                '🟢 CONTROLLER DEBUG: Received valid data with ${conversationsList.length} conversations');
          }
          for (int i = 0; i < conversationsList.length; i++) {
            final conv = conversationsList[i];
            print(
                '  - Conversation ${i + 1}: ${conv.id} with ${conv.participantIds.length} participants');
          }
        }

        // ✅ FIX: Immediate and reliable state updates
        try {
          // Check if controller is still active before updating
          if (isClosed) {
            if (kDebugMode) {
              print('⚠️ Controller is closed, skipping update');
            }
            return;
          }

          // ✅ CRITICAL FIX: Don't overwrite existing conversations with empty data
          // This prevents race conditions where an empty stream overwrites good data
          if (conversationsList.isEmpty && conversations.isNotEmpty) {
            if (kDebugMode) {
              print(
                  '🚫 PREVENTING empty data overwrite - keeping ${conversations.length} existing conversations');
            }
            // Still set loading to false but don't clear the conversations
            isLoading.value = false;
            return;
          }

          // ✅ ATOMIC UPDATE: Only update conversations if not transitioning
          if (!_isTransitioning) {
            conversations.assignAll(conversationsList);

            // ✅ FIX: Schedule filtered conversations update for next frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isTransitioning) {
                _updateFilteredConversations();
              }
            });
          } else {
            // ✅ Store pending conversations to apply after transition
            _pendingConversations = conversationsList;
            if (kDebugMode) {
              print(
                  '⏸️ Skipping conversation update during transition - storing ${conversationsList.length} pending conversations');
            }
          }

          // ✅ CRITICAL FIX: Always set loading to false when we receive ANY data (even empty)
          isLoading.value = false;

          // ✅ NEW: Complete the first data completer if it's waiting
          if (_firstDataCompleter != null &&
              !_firstDataCompleter!.isCompleted) {
            _firstDataCompleter!.complete();
            if (kDebugMode) {
              print('✅ First data completer completed');
            }
          }

          if (kDebugMode) {
            print('✅ Loading state set to false - conversations received');
            print('✅ Conversations assigned: ${conversations.length}');
            print(
                '✅ Filtered conversations updated: ${_filteredConversations.length}');
          }

          // Clear any previous errors on successful data load
          if (error.value.isNotEmpty) {
            error.value = '';
            if (kDebugMode) {
              print('✅ Previous errors cleared');
            }
          }

          // ✅ GLOBAL BACKGROUND MESSAGE MONITORING - Start listening to ALL conversations
          _startGlobalMessageMonitoring(conversationsList);

          // Start listening to online status for all participants
          for (final conversation in conversationsList) {
            for (final participantId in conversation.participantIds) {
              if (participantId != _chatService.currentUserId) {
                _startListeningToOnlineStatus(participantId);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error in conversation listener callback: $e');
          }

          // Even on error, ensure loading is set to false
          isLoading.value = false;
          error.value = 'Error updating conversations: $e';

          // ✅ NEW: Complete the first data completer on error too
          if (_firstDataCompleter != null &&
              !_firstDataCompleter!.isCompleted) {
            _firstDataCompleter!.complete();
          }
        }
      },
      onError: (error) {
        try {
          // Check if controller is still active before updating
          if (isClosed) return;

          if (kDebugMode) {
            print('❌ Conversations stream error: $error');
            print('💡 Error type: ${error.runtimeType}');
            print('💡 Error details: ${error.toString()}');
          }

          this.error.value = error.toString();
          isLoading.value = false; // ✅ Always stop loading on error

          // ✅ NEW: Complete the first data completer on stream error too
          if (_firstDataCompleter != null &&
              !_firstDataCompleter!.isCompleted) {
            _firstDataCompleter!.complete();
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error in error handler: $e');
          }
          // Final safety net
          isLoading.value = false;
        }
      },
    );
  }

  // ✅ GLOBAL MESSAGE MONITORING - Monitor ALL conversations in background
  void _startGlobalMessageMonitoring(List<ChatConversation> conversationsList) {
    if (kDebugMode) {
      print(
          '🌍 STARTING GLOBAL MESSAGE MONITORING for ${conversationsList.length} conversations...');
    }

    for (final conversation in conversationsList) {
      final conversationId = conversation.id;

      // Only start if not already monitoring this conversation
      if (!_messageSubscriptions.containsKey(conversationId)) {
        if (kDebugMode) {
          print(
              '👁️ Starting background monitoring for conversation: $conversationId');
        }

        // ✅ CRITICAL FIX: DO NOT initialize messagesMap entry here
        // Wait for actual Firestore data to arrive before setting the key
        // This prevents UI from showing "No messages yet" before data loads

        _messageSubscriptions[conversationId] =
            _chatService.getMessagesStream(conversationId).listen(
          (messagesList) {
            if (kDebugMode) {
              print(
                  '📨 GLOBAL MONITORING: Received ${messagesList.length} messages for $conversationId');
            }

            // Preserve optimistic messages when updating from stream
            final currentMessages = messagesMap[conversationId] ?? [];
            final optimisticMessages = currentMessages
                .where((msg) => msg.id.startsWith('temp_'))
                .toList();

            // Combine real messages with optimistic messages, avoiding duplicates
            final combinedMessages = [...messagesList];
            for (final optimisticMsg in optimisticMessages) {
              // More lenient check - only replace if we have an exact match with very close timestamp
              final hasRealMessage = messagesList.any((realMsg) =>
                  realMsg.content.trim() == optimisticMsg.content.trim() &&
                  realMsg.senderId == optimisticMsg.senderId &&
                  realMsg.timestamp.isAfter(optimisticMsg.timestamp
                      .subtract(const Duration(seconds: 2))) &&
                  realMsg.timestamp.isBefore(optimisticMsg.timestamp
                      .add(const Duration(seconds: 10))));

              if (!hasRealMessage) {
                // Keep optimistic message
                combinedMessages.add(optimisticMsg);
                if (kDebugMode) {
                  print(
                      '🔄 Keeping optimistic message ${optimisticMsg.id} (no real match found)');
                }
              } else if (kDebugMode) {
                print(
                    '🔄 Replacing optimistic message ${optimisticMsg.id} with real message');
              }
            }

            // Sort by timestamp to maintain order
            combinedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

            // Update messages map for real-time access
            messagesMap[conversationId] = combinedMessages;

            // ✅ Mark that this conversation has received Firestore data
            _conversationsWithData.add(conversationId);

            if (kDebugMode) {
              print(
                  '✅ GLOBAL MONITORING: Updated messagesMap[$conversationId] with ${combinedMessages.length} messages');
              print(
                  '� Background message update - Conversation: $conversationId, Messages: ${combinedMessages.length} (${optimisticMessages.length} optimistic)');
            }

            // In-app notifications disabled - preventing repeated notifications
            // _handleNewMessagesInBackground(conversationId, messagesList);
          },
          onError: (error) {
            if (kDebugMode) {
              print(
                  '❌ Background message stream error for $conversationId: $error');
            }
          },
        );
      }
    }

    if (kDebugMode) {
      print(
          '✅ Global message monitoring active for ${_messageSubscriptions.length} conversations');
    }
  }

  // ✅ HANDLE NEW MESSAGES IN BACKGROUND - DISABLED to prevent repeated notifications
  /*
  void _handleNewMessagesInBackground(
      String conversationId, List<ChatMessage> messagesList) {
    if (messagesList.isEmpty) return;

    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    // Find new unread messages from other users
    final newUnreadMessages = messagesList
        .where((message) =>
            message.senderId != currentUserId &&
            message.status != MessageStatus.read)
        .toList();

    if (newUnreadMessages.isNotEmpty) {
      if (kDebugMode) {
        print(
            '🔔 ${newUnreadMessages.length} new unread messages in conversation: $conversationId');
      }

      // ✅ SHOW IN-APP NOTIFICATION FOR NEW MESSAGES
      for (final message in newUnreadMessages) {
        _showInAppMessageNotification(conversationId, message);
      }
    }
  }
  */

  // ✅ SHOW IN-APP MESSAGE NOTIFICATION - DISABLED to prevent repeated notifications
  /*
  void _showInAppMessageNotification(
      String conversationId, ChatMessage message) {
    try {
      // Get sender name from conversation
      final conversation =
          conversations.firstWhereOrNull((c) => c.id == conversationId);
      final senderName =
          conversation?.participantNames[message.senderId] ?? 'Someone';

      // Don't show notification if user is already viewing this conversation
      // In a real app, you'd check if the current screen is the individual chat for this conversation

      if (kDebugMode) {
        print('🎨 SHOWING IN-APP MESSAGE NOTIFICATION...');
        print('👤 From: $senderName');
        print('💬 Message: ${message.content}');
      }

      // Show GetX snackbar notification
      Get.snackbar(
        senderName,
        message.type == MessageType.image ? '📷 Image' : message.content,
        backgroundColor: const Color(0xFF215C5C),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 28,
        ),
        shouldIconPulse: true,
        snackPosition: SnackPosition.TOP,
        onTap: (_) {
          // Navigate to individual chat
          Get.back(); // Close notification
          _navigateToChat(conversationId, senderName, message.senderId);
        },
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // Close notification
            _navigateToChat(conversationId, senderName, message.senderId);
          },
          child: Text('notifications.view'.tr()t(
            'VIEW',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      if (kDebugMode) {
        print('✅ In-app message notification shown!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing in-app message notification: $e');
      }
    }
  }
  */

  // ✅ NAVIGATE TO CHAT FROM NOTIFICATION - DISABLED since notifications are disabled
  /*
  void _navigateToChat(
      String conversationId, String senderName, String senderId) {
    try {
      // Navigate to individual chat screen
      Get.toNamed('/individual-chat', arguments: {
        'conversationId': conversationId,
        'otherUserName': senderName,
        'otherUserId': senderId,
      });

      if (kDebugMode) {
        print('🎯 Navigated to chat: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error navigating to chat: $e');
      }
      // Fallback - navigate to chat screen
      Get.toNamed('/chat');
    }
  }
  */

  // Start listening to messages for a conversation
  Future<void> startListeningToMessages(String conversationId) async {
    // Ensure ChatService is initialized before listening to messages
    await _ensureChatServiceInitialized();

    // ✅ CHECK IF GLOBAL MONITORING IS ALREADY ACTIVE
    if (_messageSubscriptions.containsKey(conversationId)) {
      if (kDebugMode) {
        print(
            '✅ Global monitoring already active for conversation: $conversationId');
        print(
            '👁️ Messages will be marked as read when viewing this conversation');
        print(
            '   📊 Current messagesMap has key: ${messagesMap.containsKey(conversationId)}');
        if (messagesMap.containsKey(conversationId)) {
          print(
              '   📊 Current messages count: ${messagesMap[conversationId]?.length ?? 0}');
        }
      }

      // ✅ FIX: If messages haven't loaded yet, force load them now
      if (!_conversationsWithData.contains(conversationId)) {
        if (kDebugMode) {
          print(
              '⚡ Messages not loaded yet, forcing immediate load for: $conversationId');
        }
        
        try {
          // Force load messages immediately using a one-time fetch
          final messages = await _chatService.getMessagesOnce(conversationId);
          
          // Update messages map
          messagesMap[conversationId] = messages;
          _conversationsWithData.add(conversationId);
          
          if (kDebugMode) {
            print(
                '✅ Force loaded ${messages.length} messages for: $conversationId');
          }
          
          // Mark messages as read
          if (messages.isNotEmpty) {
            _markMessagesAsReadIfNeeded(conversationId, messages);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error force loading messages: $e');
          }
        }
      } else {
        // Messages already loaded, just mark as read
        final currentMessages = messagesMap[conversationId];
        if (currentMessages != null && currentMessages.isNotEmpty) {
          _markMessagesAsReadIfNeeded(conversationId, currentMessages);
        }
      }

      return; // Don't create duplicate stream
    }

    // If not already monitored globally, start individual monitoring
    if (kDebugMode) {
      print('🔄 Starting individual message monitoring for: $conversationId');
    }

    // ✅ CRITICAL FIX: DO NOT initialize empty array here
    // Wait for actual Firestore data before setting the messagesMap key
    // This prevents showing "No messages yet" before data arrives

    _messageSubscriptions[conversationId] =
        _chatService.getMessagesStream(conversationId).listen(
      (messagesList) {
        if (kDebugMode) {
          print(
              '📨 Received ${messagesList.length} messages for conversation: $conversationId');
        }

        // Get current messages (including optimistic ones)
        final currentMessages =
            List<ChatMessage>.from(messagesMap[conversationId] ?? []);

        // Separate optimistic messages
        final optimisticMessages =
            currentMessages.where((msg) => msg.id.startsWith('temp_')).toList();

        // Start with new messages from stream
        final updatedMessages = List<ChatMessage>.from(messagesList);

        // Add optimistic messages that don't have corresponding real messages
        for (final optimisticMsg in optimisticMessages) {
          final hasRealMessage = messagesList.any((realMsg) =>
              realMsg.content.trim() == optimisticMsg.content.trim() &&
              realMsg.senderId == optimisticMsg.senderId &&
              realMsg.timestamp.isAfter(optimisticMsg.timestamp
                  .subtract(const Duration(seconds: 2))) &&
              realMsg.timestamp.isBefore(
                  optimisticMsg.timestamp.add(const Duration(seconds: 10))));

          if (!hasRealMessage) {
            // Keep optimistic message only if no real message matches
            updatedMessages.add(optimisticMsg);
            if (kDebugMode) {
              print(
                  '🔄 Keeping optimistic message ${optimisticMsg.id} (no real match found)');
            }
          } else {
            // Real message found, remove optimistic message
            if (kDebugMode) {
              print(
                  '✅ Replacing optimistic message ${optimisticMsg.id} with real message');
            }
          }
        }

        // Sort by timestamp to maintain order
        updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Update the messages
        messagesMap[conversationId] = updatedMessages;

        // ✅ Mark that this conversation has received Firestore data
        _conversationsWithData.add(conversationId);

        if (kDebugMode) {
          print(
              '✅ Updated messagesMap for conversation: $conversationId with ${updatedMessages.length} messages');
        }

        // Mark messages as read if user is viewing the conversation
        _markMessagesAsReadIfNeeded(conversationId, updatedMessages);
      },
      onError: (error) {
        this.error.value = error.toString();
        if (kDebugMode) {
          print('Messages stream error for $conversationId: $error');
        }
      },
    );
  }

  // Stop listening to messages for a conversation
  void stopListeningToMessages(String conversationId) {
    // ✅ DON'T STOP GLOBAL MONITORING - Keep background streams alive
    // This method is now mainly for UI cleanup when leaving individual chat screens
    if (kDebugMode) {
      print('🔄 Chat screen closed for conversation: $conversationId');
      print(
          '✅ Global monitoring continues in background for real-time updates');
    }

    // Note: We keep the subscription active for global monitoring
    // Messages will continue to be monitored in background
    // Only cleanup happens on controller disposal (logout)
  }

  // Start listening to online status
  void _startListeningToOnlineStatus(String userId) {
    // Cancel existing subscription if any
    if (_onlineStatusSubscriptions.containsKey(userId)) {
      _onlineStatusSubscriptions[userId]?.cancel();
      _onlineStatusSubscriptions.remove(userId);
    }

    // Use PresenceService instead of ChatService for real-time presence
    _onlineStatusSubscriptions[userId] =
        _presenceService.getUserOnlineStatus(userId).listen(
      (isOnline) {
        onlineStatus[userId] = isOnline;
      },
      onError: (error) {
        if (kDebugMode) {
          print('Online status stream error for $userId: $error');
        }
      },
    );
  }

  // Create or get conversation - UNIFIED: One conversation per user pair
  Future<String?> createOrGetConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
    String?
        packageRequestId, // This parameter is kept for compatibility but ignored
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Ensure ChatService is initialized before using it
      await _ensureChatServiceInitialized();

      // ✅ ADDITIONAL VALIDATION: Prevent self-conversations at controller level
      if (otherUserId == _chatService.currentUserId) {
        throw Exception('Cannot start a conversation with yourself.');
      }

      // Validate input
      if (otherUserId.trim().isEmpty) {
        throw Exception('Invalid user ID provided.');
      }

      if (otherUserName.trim().isEmpty) {
        throw Exception('Invalid user name provided.');
      }

      if (kDebugMode) {
        print('🔄 Creating/getting UNIFIED conversation:');
        print('  - Other user: $otherUserName ($otherUserId)');
        print('  - Package context ignored for unified conversations');
      }

      final conversationId = await _chatService.createOrGetConversation(
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
        packageRequestId:
            null, // ✅ UNIFIED: Always null for one conversation per pair
      );

      // ✅ UNIFIED: Force refresh to ensure both users see the conversation immediately
      await _chatService.forceRefreshConversations();

      if (kDebugMode) {
        print('✅ Unified conversation created/retrieved: $conversationId');
      }

      return conversationId;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Create conversation error: $e');
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Send a text message
  Future<bool> sendTextMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      // Ensure ChatService is initialized before sending message
      await _ensureChatServiceInitialized();

      await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: MessageType.text,
        replyToMessageId: replyToMessageId,
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Send message error: $e');
      }
      return false;
    }
  }

  // Send a text message with optimistic UI update
  Future<bool> sendTextMessageWithOptimisticUpdate({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      // Ensure ChatService is initialized before sending message
      await _ensureChatServiceInitialized();

      // Get receiver ID from conversation
      String receiverId = '';
      final conversation = conversations.firstWhereOrNull(
        (conv) => conv.id == conversationId,
      );
      if (conversation != null) {
        receiverId = conversation
                .getOtherParticipantId(_chatService.currentUserId ?? '') ??
            '';
      }

      // Create optimistic message with "sent" status for instant feedback
      final optimisticMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _chatService.currentUserId ?? '',
        receiverId: receiverId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sent, // Start with "sent" for instant feedback
        replyToMessageId: replyToMessageId,
      );

      // Add optimistic message to local list immediately
      final currentMessages = messagesMap[conversationId] ?? [];
      final updatedMessages = [...currentMessages, optimisticMessage];
      messagesMap[conversationId] = updatedMessages;

      if (kDebugMode) {
        print('✨ Added optimistic message: ${optimisticMessage.id}');
      }

      try {
        // Send actual message to server
        final actualMessage = await _chatService.sendMessage(
          conversationId: conversationId,
          content: content,
          type: MessageType.text,
          replyToMessageId: replyToMessageId,
        );

        if (kDebugMode) {
          print('✅ Message sent successfully: ${actualMessage.id}');
          print(
              '⚡ Optimistic message already shows as sent for instant feedback');
        }

        return true;
      } catch (sendError) {
        // Update optimistic message to show failed status instead of removing it
        final updatedOptimisticMessage = optimisticMessage.copyWith(
          status: MessageStatus.failed,
        );

        final failedMessages = [...currentMessages];
        final index =
            failedMessages.indexWhere((msg) => msg.id == optimisticMessage.id);
        if (index != -1) {
          failedMessages[index] = updatedOptimisticMessage;
        }
        messagesMap[conversationId] = failedMessages;

        if (kDebugMode) {
          print('❌ Message send failed: $sendError');
        }

        throw sendError; // Re-throw to be caught by outer catch
      }
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Send message error: $e');
      }
      return false;
    }
  }

  // Send an image message
  Future<bool> sendImageMessage({
    required String conversationId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Ensure ChatService is initialized before sending image
      await _ensureChatServiceInitialized();

      await _chatService.sendImageMessage(
        conversationId: conversationId,
        imageFile: imageFile,
        caption: caption,
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Send image error: $e');
      }
      return false;
    }
  }

  // Send a location message
  Future<bool> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
    bool isLiveLocation = false,
  }) async {
    try {
      // Ensure ChatService is initialized before sending location
      await _ensureChatServiceInitialized();

      await _chatService.sendMessage(
        conversationId: conversationId,
        content: address ?? 'Location',
        type: MessageType.location,
        metadata: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'isLiveLocation': isLiveLocation,
          'sharedAt': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Send location error: $e');
      }
      return false;
    }
  }

  // Mark messages as read if needed
  void _markMessagesAsReadIfNeeded(
      String conversationId, List<ChatMessage> messages) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return;

    final unreadMessages = messages
        .where((msg) => msg.receiverId == currentUserId && !msg.isRead)
        .map((msg) => msg.id)
        .toList();

    if (unreadMessages.isNotEmpty) {
      _chatService.markMessagesAsRead(conversationId, unreadMessages);
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      await _chatService.deleteMessage(conversationId, messageId);
      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        print('Delete message error: $e');
      }
      return false;
    }
  }

  // Search conversations
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
  }

  // Get messages for a conversation
  List<ChatMessage> getMessages(String conversationId) {
    final messages = messagesMap[conversationId] ?? [];
    if (kDebugMode) {
      print(
          '🔍 getMessages() called for $conversationId: ${messages.length} messages');
      if (messages.isEmpty) {
        print('  ⚠️ No messages found in messagesMap');
        print('  📊 messagesMap keys: ${messagesMap.keys.toList()}');
      }
    }
    return messages;
  }

  // ✅ NEW: Check if conversation has received its first Firestore data
  bool hasReceivedMessages(String conversationId) {
    return _conversationsWithData.contains(conversationId);
  }

  // Get unread count for a conversation
  int getUnreadCount(String conversationId) {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return 0;

    final conversation =
        conversations.firstWhereOrNull((c) => c.id == conversationId);
    return conversation?.getUnreadCount(currentUserId) ?? 0;
  }

  // Get total unread count
  int get totalUnreadCount {
    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) return 0;

    return conversations.fold<int>(0, (sum, conversation) {
      return sum + conversation.getUnreadCount(currentUserId);
    });
  }

  // Check if user is online
  bool isUserOnline(String userId) {
    return onlineStatus[userId] ?? false;
  }

  // Set user online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      // Use PresenceService for setting online status
      await _presenceService.setOnlineStatus(isOnline);
    } catch (e) {
      if (kDebugMode) {
        print('Set online status error: $e');
      }
    }
  }

  // ✅ FIX: Refresh user data in all conversations (fixes name/avatar display issues)
  Future<void> refreshUserDataInConversations() async {
    try {
      await _ensureChatServiceInitialized();
      await _chatService.refreshUserDataInConversations();

      if (kDebugMode) {
        print('✅ User data refreshed in all conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing user data: $e');
      }
    }
  }

  // ✅ NEW: Add cooldown to prevent rapid refreshes
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 2);

  // ✅ NEW: Optimistically clear unread count for a conversation
  void clearUnreadCountOptimistically(String conversationId) {
    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) return;

      // Find the conversation in the list
      final index =
          conversations.indexWhere((conv) => conv.id == conversationId);
      if (index == -1) return;

      final conversation = conversations[index];

      // Create updated unread counts map with 0 for current user
      final updatedUnreadCounts =
          Map<String, int>.from(conversation.unreadCounts);
      updatedUnreadCounts[currentUserId] = 0;

      // Create updated conversation with cleared unread count
      final updatedConversation = conversation.copyWith(
        unreadCounts: updatedUnreadCounts,
      );

      // Update the conversation in the list
      conversations[index] = updatedConversation;

      // Also update filtered conversations
      final filteredIndex = _filteredConversations
          .indexWhere((conv) => conv.id == conversationId);
      if (filteredIndex != -1) {
        _filteredConversations[filteredIndex] = updatedConversation;
      }

      if (kDebugMode) {
        print(
            '✨ Optimistically cleared unread count for conversation: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing unread count optimistically: $e');
      }
    }
  }

  // Refresh conversations
  Future<void> refreshConversations() async {
    try {
      // ✅ THROTTLE: Prevent rapid refreshes that cause infinite loops
      final now = DateTime.now();
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!) < _refreshCooldown) {
        if (kDebugMode) {
          print('� Refresh throttled - too soon since last refresh');
        }
        return;
      }
      _lastRefreshTime = now;

      if (kDebugMode) {
        print('�🔄 Refreshing conversations manually...');
        print('   - Current conversations count: ${conversations.length}');
        print('   - Current loading state: ${isLoading.value}');
      }

      // ✅ FIX: Don't set loading to true on manual refresh to avoid UI flickering
      error.value = '';

      // Ensure ChatService is initialized
      await _ensureChatServiceInitialized();

      // ✅ FIX: Just force refresh to get latest data through existing listener
      if (kDebugMode) {
        print('🔄 Force refreshing conversations from server...');
      }
      await _chatService.forceRefreshConversations();

      if (kDebugMode) {
        print('✅ Conversations refresh initiated');
      }
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false; // Always set false on error
      if (kDebugMode) {
        print('❌ Refresh conversations error: $e');
        print('💡 Error type: ${e.runtimeType}');
      }
    }
  }

  // ✅ NEW: Debug method to diagnose stream issues
  void debugControllerState() {
    if (kDebugMode) {
      print('🩺 CHAT CONTROLLER STATE CHECK:');
      print('  - Controller hash: $hashCode');
      print('  - Conversations count: ${conversations.length}');
      print('  - Filtered conversations: ${_filteredConversations.length}');
      print('  - Is loading: ${isLoading.value}');
      print('  - Error: ${error.value}');
      print('  - Search query: "${searchQuery.value}"');
      print('  - Subscription active: ${_conversationsSubscription != null}');
      print('  - Message subscriptions: ${_messageSubscriptions.length}');
      print('  - Controller closed: $isClosed');

      // Check ChatService health
      _chatService.debugStreamHealth();
    }
  }

  // ✅ PROPER CLEANUP ON LOGOUT - Called from AuthStateService
  void cleanupOnLogout() {
    if (kDebugMode) {
      print('🔄 ChatController: Cleaning up on user logout...');
    }

    // ✅ Set transitioning flag to prevent UI updates during cleanup
    _isTransitioning = true;

    // Set user offline before cleanup
    setOnlineStatus(false);

    // Clear observable data
    conversations.clear();
    messagesMap.clear();
    onlineStatus.clear();
    _filteredConversations.clear();
    error.value = '';
    searchQuery.value = '';

    // Reset state flags
    _conversationListenerStarted = false;
    _isInitialized = false; // ✅ Reset initialization flag

    // ✅ Reset transitioning flag after a delay to allow cleanup to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      _isTransitioning = false;
    });

    if (kDebugMode) {
      print('✅ ChatController: User data cleared on logout');
    }
  }
}
