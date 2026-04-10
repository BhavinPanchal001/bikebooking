import 'dart:async';

import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:bikebooking/features/home/data/services/notification_navigation_service.dart';
import 'package:bikebooking/features/home/data/services/notification_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  NotificationsController({
    NotificationFirestoreService? notificationService,
    UserFirestoreService? userFirestoreService,
    ProductFirestoreService? productFirestoreService,
    LoginController? loginController,
  })  : _notificationService =
            notificationService ?? NotificationFirestoreService(),
        _userFirestoreService = userFirestoreService ?? UserFirestoreService(),
        _productFirestoreService =
            productFirestoreService ?? ProductFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final NotificationFirestoreService _notificationService;
  final UserFirestoreService _userFirestoreService;
  final ProductFirestoreService _productFirestoreService;
  final LoginController _loginController;

  StreamSubscription<List<AppNotificationModel>>? _subscription;
  final Map<String, AppUserModel?> _senderCache = {};

  List<AppNotificationModel> _notifications = [];
  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _boundUserId;
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  Future<void> bindNotifications() async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty) {
      _notifications = [];
      _errorMessage = 'Sign in to view your notifications.';
      _isLoading = false;
      update();
      return;
    }

    if (_boundUserId == userId && _subscription != null) {
      return;
    }

    await _subscription?.cancel();
    _boundUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    update();

    _subscription = _notificationService.watchNotifications(userId).listen(
      (notifications) async {
        _notifications = await _enrichNotifications(notifications);
        _isLoading = false;
        _errorMessage = null;
        update();
      },
      onError: (error, stackTrace) {
        _notifications = [];
        _isLoading = false;
        _errorMessage = 'Unable to load notifications right now.';
        debugPrint('Error watching notifications: $error\n$stackTrace');
        update();
      },
    );
  }

  Future<void> refreshNotifications() async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty) {
      _notifications = [];
      _errorMessage = 'Sign in to view your notifications.';
      update();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      final notifications = await _notificationService.getNotifications(userId);
      _notifications = await _enrichNotifications(notifications);
      _errorMessage = null;
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load notifications right now.';
      debugPrint('Error refreshing notifications: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> markNotificationAsRead(AppNotificationModel notification) async {
    final userId = _resolveCurrentUserId();
    final notificationId = notification.id?.trim() ?? '';
    if (userId == null || notificationId.isEmpty || notification.isRead) {
      return;
    }

    final index =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      update();
    }

    try {
      await _notificationService.markAsRead(
        userId: userId,
        notificationId: notificationId,
      );
    } catch (error, stackTrace) {
      debugPrint('Error marking notification as read: $error\n$stackTrace');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty || unreadCount == 0) {
      return;
    }

    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    update();

    try {
      await _notificationService.markAllAsRead(userId);
    } catch (error, stackTrace) {
      debugPrint(
          'Error marking all notifications as read: $error\n$stackTrace');
    }
  }

  Future<void> handleNotificationTap(AppNotificationModel notification) async {
    await markNotificationAsRead(notification);
    await executeNotificationNavigation(
      productFirestoreService: _productFirestoreService,
      type: notification.type,
      targetRoute: notification.targetRoute,
      productId: notification.productId,
      chatId: notification.chatId,
    );
  }

  Future<List<AppNotificationModel>> _enrichNotifications(
    List<AppNotificationModel> notifications,
  ) async {
    final senderIds = notifications
        .map((notification) => notification.senderId?.trim() ?? '')
        .where((senderId) => senderId.isNotEmpty)
        .toSet();

    for (final senderId in senderIds) {
      if (_senderCache.containsKey(senderId)) {
        continue;
      }
      try {
        _senderCache[senderId] =
            await _userFirestoreService.getUserById(senderId);
      } catch (_) {
        _senderCache[senderId] = null;
      }
    }

    return notifications.map((notification) {
      final senderId = notification.senderId?.trim() ?? '';
      final senderProfile = senderId.isEmpty ? null : _senderCache[senderId];
      return notification.copyWith(
        senderName: (notification.senderName ?? '').trim().isNotEmpty
            ? notification.senderName
            : senderProfile?.displayName,
        senderPhotoUrl: (notification.senderPhotoUrl ?? '').trim().isNotEmpty
            ? notification.senderPhotoUrl
            : senderProfile?.photoUrl,
      );
    }).toList(growable: false);
  }

  String? _resolveCurrentUserId() {
    final profileUserId = _loginController.currentUserProfile?.id.trim() ?? '';
    if (profileUserId.isNotEmpty) {
      return profileUserId;
    }
    return null;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
