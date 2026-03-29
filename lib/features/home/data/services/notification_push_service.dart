import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/notification_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NotificationPushService extends GetxService with WidgetsBindingObserver {
  NotificationPushService({
    FirebaseMessaging? messaging,
    UserFirestoreService? userFirestoreService,
    NotificationFirestoreService? notificationService,
    ProductFirestoreService? productFirestoreService,
    LoginController? loginController,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userFirestoreService = userFirestoreService ?? UserFirestoreService(),
        _notificationService =
            notificationService ?? NotificationFirestoreService(),
        _productFirestoreService =
            productFirestoreService ?? ProductFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final FirebaseMessaging _messaging;
  final UserFirestoreService _userFirestoreService;
  final NotificationFirestoreService _notificationService;
  final ProductFirestoreService _productFirestoreService;
  final LoginController _loginController;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  Timer? _apnsRetryTimer;

  bool _isInitialized = false;
  String? _currentToken;
  String? _lastObservedUserId;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _loginController.addListener(_handleLoginControllerChanged);

    await _messaging.setAutoInitEnabled(true);
    await _configureForegroundNotifications();
    final settings = await _requestPermissionIfNeeded();
    await _syncTokenForCurrentUser(settings: settings);
    await _bindMessageStreams();
    await _handleInitialMessage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncTokenForCurrentUser());
    }
  }

  Future<void> _bindMessageStreams() async {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      _currentToken = token.trim().isEmpty ? _currentToken : token.trim();
      unawaited(_syncTokenForCurrentUser());
    });

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
      unawaited(_handleForegroundMessage(message));
    });

    _openedAppSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromMessageWhenReady(message);
    });
  }

  Future<NotificationSettings> _requestPermissionIfNeeded() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final userId = _resolveCurrentUserId();
    if (userId != null && userId.isNotEmpty) {
      await _userFirestoreService.updateNotificationPermission(
        userId: userId,
        permissionStatus: _permissionStatusLabel(settings.authorizationStatus),
        isEnabled: _isPermissionEnabled(settings.authorizationStatus),
      );
    }

    return settings;
  }

  Future<void> _configureForegroundNotifications() async {
    if (kIsWeb) {
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _syncTokenForCurrentUser({
    NotificationSettings? settings,
  }) async {
    final userId = _resolveCurrentUserId();
    final normalizedUserId =
        userId != null && userId.trim().isNotEmpty ? userId.trim() : null;
    final currentSettings =
        settings ?? await _messaging.getNotificationSettings();
    final permissionStatus =
        _permissionStatusLabel(currentSettings.authorizationStatus);
    final isEnabled = _isPermissionEnabled(currentSettings.authorizationStatus);

    if (_lastObservedUserId != normalizedUserId &&
        _lastObservedUserId != null &&
        _currentToken != null) {
      try {
        await _userFirestoreService.removePushToken(
          userId: _lastObservedUserId!,
          token: _currentToken!,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Error removing push token for previous user: $error\n$stackTrace',
        );
      }
    }

    _lastObservedUserId = normalizedUserId;

    if (normalizedUserId == null) {
      return;
    }

    try {
      await _userFirestoreService.updateNotificationPermission(
        userId: normalizedUserId,
        permissionStatus: permissionStatus,
        isEnabled: isEnabled,
      );
    } catch (error, stackTrace) {
      debugPrint('Error updating notification permission: $error\n$stackTrace');
    }

    if (!isEnabled) {
      return;
    }

    final token = (_currentToken ?? await _loadMessagingToken())?.trim() ?? '';
    if (token.isEmpty) {
      return;
    }

    _currentToken = token;
    try {
      await _userFirestoreService.savePushToken(
        userId: normalizedUserId,
        token: token,
        permissionStatus: permissionStatus,
      );
    } catch (error, stackTrace) {
      debugPrint('Error saving push token: $error\n$stackTrace');
    }
  }

  Future<String?> _loadMessagingToken() async {
    if (kIsWeb) {
      return _messaging.getToken();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _waitForApnsToken();
      if (apnsToken == null || apnsToken.trim().isEmpty) {
        _scheduleApnsRetry();
        debugPrint(
          'Skipping FCM token fetch because the APNS token is not available yet.',
        );
        return null;
      }
    }

    try {
      final token = await _messaging.getToken();
      if ((token ?? '').trim().isNotEmpty) {
        _apnsRetryTimer?.cancel();
        _apnsRetryTimer = null;
      }
      return token;
    } on FirebaseException catch (error, stackTrace) {
      if (error.code.toLowerCase() == 'apns-token-not-set') {
        _scheduleApnsRetry();
        debugPrint(
          'FCM token fetch skipped until APNS finishes registering: $error\n$stackTrace',
        );
        return null;
      }
      rethrow;
    }
  }

  Future<String?> _waitForApnsToken({
    int attempts = 5,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if ((apnsToken ?? '').trim().isNotEmpty) {
        return apnsToken!.trim();
      }
      if (attempt < attempts - 1) {
        await Future<void>.delayed(delay);
      }
    }
    return null;
  }

  void _scheduleApnsRetry() {
    if (_apnsRetryTimer?.isActive == true) {
      return;
    }

    _apnsRetryTimer = Timer(const Duration(seconds: 2), () {
      _apnsRetryTimer = null;
      unawaited(_syncTokenForCurrentUser());
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = _notificationFromRemoteMessage(message);
    if (notification != null) {
      try {
        await _notificationService.upsertNotification(
          notification,
          documentId: _notificationDocumentId(message),
        );
      } catch (error, stackTrace) {
        debugPrint(
            'Error persisting foreground notification: $error\n$stackTrace');
      }
    }

    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    AppSnackbar.show(
      title: title.isNotEmpty ? title : 'Notification',
      message: body.isNotEmpty ? body : 'You have a new update.',
      backgroundColor: const Color(0xFF233A66),
    );
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) {
      return;
    }
    _navigateFromMessageWhenReady(initialMessage);
  }

  void _navigateFromMessageWhenReady(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleMessageNavigation(message));
    });
  }

  Future<void> _handleMessageNavigation(RemoteMessage message) async {
    final notification = _notificationFromRemoteMessage(message);
    if (notification != null) {
      try {
        await _notificationService.upsertNotification(
          notification,
          documentId: _notificationDocumentId(message),
        );
      } catch (error, stackTrace) {
        debugPrint('Error persisting opened notification: $error\n$stackTrace');
      }
    }

    final userId = _resolveCurrentUserId();
    final notificationId = _notificationDocumentId(message);
    if (userId != null && userId.isNotEmpty && notificationId.isNotEmpty) {
      try {
        await _notificationService.markAsRead(
          userId: userId,
          notificationId: notificationId,
        );
      } catch (error, stackTrace) {
        debugPrint(
            'Error marking push notification as read: $error\n$stackTrace');
      }
    }

    final data = message.data;
    final productId = (data['productId'] ?? '').toString().trim();
    if (productId.isNotEmpty) {
      final product = await _loadProduct(productId);
      if (product != null) {
        Get.toNamed('/bike_detail', arguments: product);
        return;
      }
    }

    final route = (data['targetRoute'] ?? '').toString().trim();
    if (route.isNotEmpty) {
      if (route == '/chat_detail') {
        Get.toNamed(route, arguments: _nullableString(data['chatId']));
      } else {
        Get.toNamed(route);
      }
      return;
    }

    final type = (data['type'] ?? '').toString().trim();
    switch (type) {
      case 'message':
        final chatId = _nullableString(data['chatId']);
        if (chatId != null) {
          Get.toNamed('/chat_detail', arguments: chatId);
        } else {
          Get.toNamed('/messages');
        }
        return;
      case 'listing':
      case 'listing_update':
      case 'product_view':
        Get.toNamed('/my_listing');
        return;
      default:
        Get.toNamed('/notifications');
        return;
    }
  }

  AppNotificationModel? _notificationFromRemoteMessage(RemoteMessage message) {
    final recipientId = _resolveCurrentUserId();
    if (recipientId == null || recipientId.trim().isEmpty) {
      return null;
    }

    final data = message.data;
    final messageRecipientId = (data['recipientId'] ?? '').toString().trim();
    if (messageRecipientId.isNotEmpty && messageRecipientId != recipientId) {
      return null;
    }

    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    return AppNotificationModel(
      id: _notificationDocumentId(message).isEmpty
          ? null
          : _notificationDocumentId(message),
      recipientId: recipientId,
      title: title.isEmpty ? 'Notification' : title,
      body: body,
      type: (data['type'] ?? 'system').toString(),
      senderId: _nullableString(data['senderId']),
      senderName: _nullableString(data['senderName']),
      senderPhotoUrl: _nullableString(data['senderPhotoUrl']),
      targetRoute: _nullableString(data['targetRoute']),
      productId: _nullableString(data['productId']),
      chatId: _nullableString(data['chatId']),
      isRead: false,
      createdAt: message.sentTime,
      updatedAt: message.sentTime,
    );
  }

  String _notificationDocumentId(RemoteMessage message) {
    final data = message.data;
    final fromPayload =
        (data['notificationId'] ?? data['id'] ?? '').toString().trim();
    if (fromPayload.isNotEmpty) {
      return fromPayload;
    }
    return message.messageId?.trim() ?? '';
  }

  String _notificationTitle(RemoteMessage message) {
    final payloadTitle = (message.data['title'] ?? '').toString().trim();
    if (payloadTitle.isNotEmpty) {
      return payloadTitle;
    }
    return message.notification?.title?.trim() ?? '';
  }

  String _notificationBody(RemoteMessage message) {
    final payloadBody = (message.data['body'] ?? '').toString().trim();
    if (payloadBody.isNotEmpty) {
      return payloadBody;
    }
    return message.notification?.body?.trim() ?? '';
  }

  String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String? _resolveCurrentUserId() {
    final userId = _loginController.currentUserProfile?.id.trim() ?? '';
    return userId.isEmpty ? null : userId;
  }

  String _permissionStatusLabel(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'authorized';
      case AuthorizationStatus.provisional:
        return 'provisional';
      case AuthorizationStatus.denied:
        return 'denied';
      case AuthorizationStatus.notDetermined:
        return 'not_determined';
    }
  }

  bool _isPermissionEnabled(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<ProductModel?> _loadProduct(String productId) async {
    try {
      return await _productFirestoreService.getProductById(productId);
    } catch (error, stackTrace) {
      debugPrint(
          'Error loading product from push payload: $error\n$stackTrace');
      return null;
    }
  }

  void _handleLoginControllerChanged() {
    final currentUserId = _resolveCurrentUserId();
    if (currentUserId == _lastObservedUserId) {
      return;
    }
    unawaited(_syncTokenForCurrentUser());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _loginController.removeListener(_handleLoginControllerChanged);
    _apnsRetryTimer?.cancel();
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    super.onClose();
  }
}
