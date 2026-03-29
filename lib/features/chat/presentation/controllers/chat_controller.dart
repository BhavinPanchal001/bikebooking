import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/chat/data/models/chat_model.dart';
import 'package:bikebooking/features/chat/data/services/chat_firestore_service.dart';

/// Controller for the Messages List screen.
///
/// Listens to the current user's conversations in real-time
/// and exposes them sorted by most recent activity.
class ChatController extends GetxController {
  final ChatFirestoreService _chatService = ChatFirestoreService();

  List<ChatModel> chats = [];
  bool isLoading = true;
  String? errorMessage;
  int totalUnreadCount = 0;

  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<int>? _unreadSubscription;

  LoginController get _loginController => Get.find<LoginController>();
  String get _currentUserId => _loginController.chatUserId;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  @override
  void onClose() {
    _cancelSubscriptions();
    super.onClose();
  }

  void _cancelSubscriptions() {
    _chatsSubscription?.cancel();
    _unreadSubscription?.cancel();
  }

  Future<void> _startListening() async {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      isLoading = false;
      errorMessage = 'You must be logged in to view messages.';
      update();
      return;
    }

    final hasSession = await _loginController.ensureFirestoreSession();
    if (!hasSession) {
      chats = [];
      totalUnreadCount = 0;
      isLoading = false;
      errorMessage = _loginController.firestoreSessionErrorMessage ??
          'Messages require a valid Firebase sign-in. Please sign in again and try again.';
      update();
      return;
    }

    // Listen to chat list.
    _chatsSubscription = _chatService.getUserChats(userId).listen(
      (chatList) {
        chats = chatList;
        isLoading = false;
        errorMessage = null;
        update();
      },
      onError: (error) {
        chats = [];
        totalUnreadCount = 0;
        isLoading = false;
        errorMessage = _friendlyChatError(error);
        update();
      },
    );

    // Listen to total unread count.
    _unreadSubscription = _chatService.getTotalUnreadCount(userId).listen(
      (unreadTotal) {
        totalUnreadCount = unreadTotal;
        update();
      },
      onError: (error) {
        totalUnreadCount = 0;
        if (chats.isEmpty) {
          isLoading = false;
          errorMessage = _friendlyChatError(error);
        }
        update();
      },
    );
  }

  String _friendlyChatError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission-denied') ||
        message.contains('missing or insufficient permissions') ||
        message.contains('unauthenticated')) {
      return _loginController.hasFirebaseSession
          ? 'Messages are blocked by Firestore permissions. Check your chat rules and try again.'
          : 'Messages require a valid Firebase sign-in. Please sign in again and try again.';
    }

    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code == 'failed-precondition') {
        return 'Messages need an additional Firestore index or backend setup update before they can load.';
      }
      if (code == 'unavailable' || code == 'network-request-failed') {
        return 'Check your internet connection and try again.';
      }
    }

    return 'Unable to load conversations.';
  }

  /// Restart the streams (e.g., after re-login).
  void reloadChats() {
    _cancelSubscriptions();
    chats = [];
    totalUnreadCount = 0;
    isLoading = true;
    errorMessage = null;
    update();
    _startListening();
  }
}
