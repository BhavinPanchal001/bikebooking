import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/data/models/message_model.dart';
import 'package:bikebooking/features/chat/data/services/chat_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/block_sync_helper.dart';

/// Controller for the Chat Detail (conversation) screen.
///
/// Streams messages in real-time, handles sending messages,
/// read receipts, and the other user's online status.
class ChatDetailController extends GetxController {
  ChatDetailController({required this.chatId});

  final String chatId;
  final ChatFirestoreService _chatService = ChatFirestoreService();
  final SellerActionFirestoreService _sellerActionService =
      SellerActionFirestoreService();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<MessageModel> messages = [];
  ChatModel? chat;
  bool isLoading = true;
  String? errorMessage;
  bool isChatBlocked = false;
  bool isOtherUserBlockedByCurrentUser = false;
  bool isUpdatingBlockStatus = false;

  // Other user's online status
  bool isOtherUserOnline = false;
  DateTime? otherUserLastSeen;

  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<Map<String, dynamic>>? _onlineStatusSubscription;

  LoginController get _loginController => Get.find<LoginController>();
  String get _currentUserId => _loginController.chatUserId;

  @override
  void onInit() {
    super.onInit();
    _loadChatAndStartListening();
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadChatAndStartListening() async {
    if (_currentUserId.isEmpty) {
      isLoading = false;
      errorMessage = 'You must be logged in to view messages.';
      update();
      return;
    }

    final hasSession = await _loginController.ensureFirestoreSession();
    if (!hasSession) {
      isLoading = false;
      errorMessage = _loginController.firestoreSessionErrorMessage ??
          'Messages require a valid Firebase sign-in. Please sign in again and try again.';
      update();
      return;
    }

    try {
      // Load chat document first for participant info.
      chat = await _chatService.getChatById(chatId);
      if (chat == null) {
        isLoading = false;
        errorMessage = 'Conversation not found.';
        update();
        return;
      }

      await _refreshBlockState();
      if (isChatBlocked) {
        isLoading = false;
        update();
        return;
      }

      // Start streaming messages.
      _messagesSubscription = _chatService.getMessages(chatId).listen(
        (messageList) {
          messages = messageList;
          isLoading = false;
          errorMessage = null;
          update();

          // Auto-scroll to bottom when new messages arrive.
          _scrollToBottom();

          // Mark messages as read.
          _markAsRead();
        },
        onError: (error) {
          messages = [];
          isLoading = false;
          errorMessage = _friendlyChatError(error);
          update();
        },
      );

      // Start streaming other user's online status.
      final otherUserId = chat!.otherParticipantId(_currentUserId);
      if (otherUserId.isNotEmpty) {
        _onlineStatusSubscription =
            _chatService.getUserOnlineStatus(otherUserId).listen(
          (statusData) {
            isOtherUserOnline = statusData['isOnline'] ?? false;
            otherUserLastSeen = statusData['lastSeen'] as DateTime?;
            update();
          },
          onError: (_) {
            isOtherUserOnline = false;
            otherUserLastSeen = null;
            update();
          },
        );
      }
    } catch (error) {
      isLoading = false;
      errorMessage = _friendlyChatError(
        error,
        fallback: 'Something went wrong.',
      );
      update();
    }
  }

  /// Sends a text message.
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final userId = _currentUserId;
    if (userId.isEmpty) return;
    if (isChatBlocked) {
      Get.snackbar(
        'Chat unavailable',
        errorMessage ??
            'This conversation is unavailable because one of you has blocked the other.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Clear input immediately for responsive feel.
    messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: userId,
        text: text,
      );
    } catch (error) {
      // If sending fails, restore the text.
      messageController.text = text;
      await _refreshBlockState();
      update();
      Get.snackbar(
        'Error',
        _friendlyChatError(
          error,
          fallback: 'Failed to send message. Please try again.',
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Marks all messages in this chat as read by the current user.
  Future<void> _markAsRead() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;

    try {
      await _chatService.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
      );
    } catch (_) {
      // Silently fail — not critical for UX.
    }
  }

  /// Scrolls to the bottom of the message list.
  void _scrollToBottom() {
    if (!scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Returns a human-readable "last seen" string.
  String get lastSeenText {
    if (isOtherUserOnline) return 'Online';
    if (otherUserLastSeen == null) return '';

    final diff = DateTime.now().difference(otherUserLastSeen!);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen a while ago';
  }

  /// Whether the current user sent a specific message.
  bool isMyMessage(MessageModel message) {
    return message.senderId == _currentUserId;
  }

  /// The other participant's display name.
  String get otherUserName {
    if (chat == null) return '';
    return chat!.otherParticipantDetails(_currentUserId)?.name ?? '';
  }

  /// The other participant's photo URL.
  String get otherUserPhoto {
    if (chat == null) return '';
    return chat!.otherParticipantDetails(_currentUserId)?.photoUrl ?? '';
  }

  /// The product snapshot for this conversation (if any).
  ProductSnapshot? get productSnapshot => chat?.productSnapshot;

  bool get canComposeMessages =>
      !isLoading && !isChatBlocked && errorMessage == null;

  Future<bool> toggleBlockOtherUser() async {
    final currentUserId = _currentUserId;
    final otherUserId = chat?.otherParticipantId(currentUserId).trim() ?? '';
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      return false;
    }

    isUpdatingBlockStatus = true;
    update();

    try {
      if (isOtherUserBlockedByCurrentUser) {
        await _sellerActionService.unblockSeller(
          userId: currentUserId,
          sellerId: otherUserId,
        );
      } else {
        await _sellerActionService.blockSeller(
          userId: currentUserId,
          sellerId: otherUserId,
          sellerName: otherUserName,
          sellerPhotoUrl: otherUserPhoto,
        );
      }

      await _refreshBlockState();
      BlockSyncHelper.refreshAfterBlockChange();
      update();
      return true;
    } catch (_) {
      return false;
    } finally {
      isUpdatingBlockStatus = false;
      update();
    }
  }

  Future<void> _refreshBlockState() async {
    final currentUserId = _currentUserId;
    final otherUserId = chat?.otherParticipantId(currentUserId).trim() ?? '';
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      isChatBlocked = false;
      isOtherUserBlockedByCurrentUser = false;
      return;
    }

    isOtherUserBlockedByCurrentUser =
        await _sellerActionService.isSellerBlocked(
      userId: currentUserId,
      sellerId: otherUserId,
    );
    isChatBlocked = await _sellerActionService.hasBlockingRelationship(
      firstUserId: currentUserId,
      secondUserId: otherUserId,
    );

    if (isChatBlocked) {
      errorMessage = isOtherUserBlockedByCurrentUser
          ? 'You blocked this user. Unblock them to chat again.'
          : 'This conversation is unavailable because one of you has blocked the other.';
    } else if (errorMessage != 'Conversation not found.') {
      errorMessage = null;
    }
  }

  String _friendlyChatError(
    Object error, {
    String fallback = 'Unable to load messages.',
  }) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission-denied') ||
        message.contains('missing or insufficient permissions') ||
        message.contains('unauthenticated')) {
      return _loginController.hasFirebaseSession
          ? 'This conversation is blocked by Firestore permissions. Check your chat rules and try again.'
          : 'Messages require a valid Firebase sign-in. Please sign in again and try again.';
    }

    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code == 'failed-precondition') {
        return 'This conversation needs an additional Firestore index or backend setup update before it can load.';
      }
      if (code == 'unavailable' || code == 'network-request-failed') {
        return 'Check your internet connection and try again.';
      }
    }

    if (error is UserBlockException ||
        message.contains('blocked the other') ||
        message.contains('blocked this user')) {
      return error.toString();
    }

    return fallback;
  }
}
