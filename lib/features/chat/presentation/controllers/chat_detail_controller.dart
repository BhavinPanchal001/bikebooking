import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/data/models/message_model.dart';
import 'package:bikebooking/features/chat/data/services/chat_firestore_service.dart';
import 'package:bikebooking/features/chat/data/services/chat_image_storage_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/block_sync_helper.dart';

/// Controller for the Chat Detail (conversation) screen.
///
/// Streams messages in real-time, handles sending messages,
/// read receipts, and the other user's online status.
class ChatDetailController extends GetxController {
  ChatDetailController({
    required this.chatId,
    this.initialChat,
    ChatFirestoreService? chatService,
    SellerActionFirestoreService? sellerActionService,
    ImagePicker? imagePicker,
    ChatImageStorageService? chatImageStorageService,
  })  : _chatService = chatService ?? ChatFirestoreService(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _imagePicker = imagePicker ?? ImagePicker(),
        _chatImageStorageService =
            chatImageStorageService ?? ChatImageStorageService();

  static const String _localMessageIdPrefix = 'local:';

  final String chatId;
  final ChatModel? initialChat;
  final ChatFirestoreService _chatService;
  final SellerActionFirestoreService _sellerActionService;
  final ImagePicker _imagePicker;
  final ChatImageStorageService _chatImageStorageService;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<MessageModel> messages = [];
  final List<MessageModel> _streamMessages = <MessageModel>[];
  final List<MessageModel> _pendingMessages = <MessageModel>[];
  ChatModel? chat;
  bool isLoading = true;
  String? errorMessage;
  bool isChatBlocked = false;
  bool isOtherUserBlockedByCurrentUser = false;
  bool isUpdatingBlockStatus = false;
  bool isResolvingChatAccess = true;
  bool isUploadingImage = false;

  // Other user's online status
  bool isOtherUserOnline = false;
  DateTime? otherUserLastSeen;

  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<Map<String, dynamic>>? _onlineStatusSubscription;
  String? _onlineStatusUserId;
  bool _hasAppliedInitialMessageScroll = false;

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
      isResolvingChatAccess = false;
      errorMessage = 'You must be logged in to view messages.';
      update();
      return;
    }

    final hasSession = await _loginController.ensureFirestoreSession();
    if (!hasSession) {
      isLoading = false;
      isResolvingChatAccess = false;
      errorMessage = _loginController.firestoreSessionErrorMessage ??
          'Messages require a valid Firebase sign-in. Please sign in again and try again.';
      update();
      return;
    }

    if (initialChat != null) {
      chat = initialChat;
      isResolvingChatAccess = false;
      _startOnlineStatusListening(
        initialChat!.otherParticipantId(_currentUserId),
      );
      update();
    }

    try {
      _startMessageStream();
      unawaited(_loadChatMetadata());
    } catch (error) {
      isLoading = false;
      isResolvingChatAccess = false;
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
    if (!_canSendMessage(userId)) {
      return;
    }

    final sentAt = DateTime.now();
    final clientMessageId = _buildClientMessageId(userId, sentAt);
    final pendingMessage = MessageModel(
      id: clientMessageId,
      clientMessageId: clientMessageId,
      senderId: userId,
      text: text,
      timestamp: sentAt,
      readBy: [userId],
      isPending: true,
    );

    // Clear input immediately for responsive feel.
    messageController.clear();
    _pendingMessages.add(pendingMessage);
    messages = _buildVisibleMessages();
    update();
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: userId,
        text: text,
        otherUserId: chat?.otherParticipantId(userId),
        clientMessageId: clientMessageId,
        sentAt: sentAt,
        verifyChatAvailability: false,
      );
    } catch (error) {
      // If sending fails, restore the text.
      _pendingMessages.removeWhere(
        (message) => message.clientMessageId == clientMessageId,
      );
      messages = _buildVisibleMessages();
      _restoreComposerText(text);
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

  Future<void> pickAndSendImage(ImageSource source) async {
    if (isUploadingImage) {
      return;
    }

    final userId = _currentUserId;
    if (!_canSendMessage(userId)) {
      return;
    }

    String? pendingClientMessageId;
    var pendingCaption = '';
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (pickedFile == null) {
        return;
      }

      final caption = messageController.text.trim();
      pendingCaption = caption;
      final imageBytes = await pickedFile.readAsBytes();
      final sentAt = DateTime.now();
      final clientMessageId = _buildClientMessageId(userId, sentAt);
      pendingClientMessageId = clientMessageId;
      final pendingMessage = MessageModel(
        id: clientMessageId,
        clientMessageId: clientMessageId,
        senderId: userId,
        text: caption,
        type: 'image',
        localImageBytes: imageBytes,
        timestamp: sentAt,
        readBy: [userId],
        isPending: true,
      );

      if (caption.isNotEmpty) {
        messageController.clear();
      }

      isUploadingImage = true;
      _pendingMessages.add(pendingMessage);
      messages = _buildVisibleMessages();
      update();
      _scrollToBottom();

      final imageUrl = await _chatImageStorageService.uploadChatImage(
        chatId: chatId,
        userId: userId,
        imageFile: pickedFile,
      );

      await _chatService.sendMessage(
        chatId: chatId,
        senderId: userId,
        text: caption,
        type: 'image',
        imageUrl: imageUrl,
        previewText: caption.isEmpty ? 'Photo' : 'Photo: $caption',
        otherUserId: chat?.otherParticipantId(userId),
        clientMessageId: clientMessageId,
        sentAt: sentAt,
        verifyChatAvailability: false,
      );
    } catch (error) {
      if (pendingClientMessageId != null) {
        _pendingMessages.removeWhere(
          (message) => message.clientMessageId == pendingClientMessageId,
        );
      }
      messages = _buildVisibleMessages();
      if (pendingCaption.isNotEmpty && messageController.text.trim().isEmpty) {
        _restoreComposerText(pendingCaption);
      }
      await _refreshBlockState();
      update();
      Get.snackbar(
        'Error',
        _friendlyImageUploadError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingImage = false;
      update();
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

  void _jumpToBottomAfterLayout({int remainingFrames = 2}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.jumpTo(scrollController.position.maxScrollExtent);

      if (remainingFrames > 0) {
        _jumpToBottomAfterLayout(remainingFrames: remainingFrames - 1);
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

  bool isPendingMessage(MessageModel message) => message.isPending;

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

  bool get shouldShowComposeBar =>
      !isLoading && !isChatBlocked && errorMessage == null;

  bool get canComposeMessages => shouldShowComposeBar && !isResolvingChatAccess;

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
      isResolvingChatAccess = false;
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
    isResolvingChatAccess = false;
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

  String _friendlyImageUploadError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code == 'permission-denied' ||
          code == 'unauthorized' ||
          code == 'unauthenticated') {
        return 'Image uploads are blocked by Firebase Storage permissions. Check your storage rules and try again.';
      }
      if (code == 'unavailable' || code == 'network-request-failed') {
        return 'Check your internet connection and try again.';
      }
      if (code == 'canceled') {
        return 'Image upload was cancelled before it could finish.';
      }
    }

    return _friendlyChatError(
      error,
      fallback: 'Failed to send image. Please try again.',
    );
  }

  void _startMessageStream() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService.getMessages(chatId).listen(
      (messageList) {
        final shouldApplyInitialScroll =
            !_hasAppliedInitialMessageScroll && messageList.isNotEmpty;

        _streamMessages
          ..clear()
          ..addAll(messageList);
        _reconcilePendingMessages();
        messages = _buildVisibleMessages();
        isLoading = false;
        if (!isChatBlocked) {
          errorMessage = null;
        }
        update();

        if (shouldApplyInitialScroll) {
          _hasAppliedInitialMessageScroll = true;
          _jumpToBottomAfterLayout();
        } else {
          _scrollToBottom();
        }
        _markAsRead();
      },
      onError: (error) {
        _streamMessages.clear();
        messages = _buildVisibleMessages();
        isLoading = false;
        errorMessage = _friendlyChatError(error);
        update();
      },
    );
  }

  Future<void> _loadChatMetadata() async {
    try {
      final fetchedChat = await _chatService.getChatById(chatId);
      if (fetchedChat == null) {
        isResolvingChatAccess = false;
        if (_streamMessages.isEmpty && _pendingMessages.isEmpty) {
          isLoading = false;
          errorMessage = 'Conversation not found.';
        }
        update();
        return;
      }

      chat = fetchedChat;
      _startOnlineStatusListening(
        fetchedChat.otherParticipantId(_currentUserId),
      );
      update();
      if (messages.isNotEmpty) {
        _jumpToBottomAfterLayout();
      }

      await _refreshBlockState();
      update();
    } catch (error) {
      isResolvingChatAccess = false;
      if (_streamMessages.isEmpty && _pendingMessages.isEmpty) {
        isLoading = false;
        errorMessage = _friendlyChatError(
          error,
          fallback: 'Something went wrong.',
        );
      }
      update();
    }
  }

  void _startOnlineStatusListening(String otherUserId) {
    final normalizedOtherUserId = otherUserId.trim();
    if (normalizedOtherUserId.isEmpty ||
        _onlineStatusUserId == normalizedOtherUserId) {
      return;
    }

    _onlineStatusUserId = normalizedOtherUserId;
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription =
        _chatService.getUserOnlineStatus(normalizedOtherUserId).listen(
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

  void _reconcilePendingMessages() {
    if (_pendingMessages.isEmpty) {
      return;
    }

    final deliveredMessageIds = _streamMessages
        .map((message) => message.clientMessageId?.trim() ?? '')
        .where((messageId) => messageId.isNotEmpty)
        .toSet();

    if (deliveredMessageIds.isEmpty) {
      return;
    }

    _pendingMessages.removeWhere((message) {
      final pendingMessageId = message.clientMessageId?.trim() ?? '';
      return pendingMessageId.isNotEmpty &&
          deliveredMessageIds.contains(pendingMessageId);
    });
  }

  List<MessageModel> _buildVisibleMessages() {
    final visibleMessages = <MessageModel>[
      ..._streamMessages,
      ..._pendingMessages,
    ];

    visibleMessages.sort((first, second) {
      final firstTimestamp =
          first.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondTimestamp =
          second.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timestampComparison = firstTimestamp.compareTo(secondTimestamp);
      if (timestampComparison != 0) {
        return timestampComparison;
      }

      if (first.isPending != second.isPending) {
        return first.isPending ? 1 : -1;
      }

      final firstKey = first.clientMessageId ?? first.id ?? '';
      final secondKey = second.clientMessageId ?? second.id ?? '';
      return firstKey.compareTo(secondKey);
    });

    return visibleMessages;
  }

  bool _canSendMessage(String userId) {
    if (userId.isEmpty) {
      return false;
    }

    if (isChatBlocked) {
      Get.snackbar(
        'Chat unavailable',
        errorMessage ??
            'This conversation is unavailable because one of you has blocked the other.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  String _buildClientMessageId(String userId, DateTime sentAt) {
    return '$_localMessageIdPrefix${userId}_${sentAt.microsecondsSinceEpoch}';
  }

  void _restoreComposerText(String text) {
    messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
