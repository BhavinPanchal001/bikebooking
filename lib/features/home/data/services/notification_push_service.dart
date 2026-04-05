import 'dart:async';
import 'dart:convert';

import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:bikebooking/features/home/data/models/notification_preferences_model.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/notification_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationPushService extends GetxController
    with WidgetsBindingObserver {
  NotificationPushService({
    FirebaseMessaging? messaging,
    UserFirestoreService? userFirestoreService,
    NotificationFirestoreService? notificationService,
    ProductFirestoreService? productFirestoreService,
    LoginController? loginController,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userFirestoreService = userFirestoreService ?? UserFirestoreService(),
        _notificationService =
            notificationService ?? NotificationFirestoreService(),
        _productFirestoreService =
            productFirestoreService ?? ProductFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>(),
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidNotificationChannel =
      AndroidNotificationChannel(
    'bikebooking_high_importance',
    'Bikebooking notifications',
    description: 'Alerts for chats, listings, and account activity.',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging;
  final UserFirestoreService _userFirestoreService;
  final NotificationFirestoreService _notificationService;
  final ProductFirestoreService _productFirestoreService;
  final LoginController _loginController;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  Timer? _apnsRetryTimer;

  bool _isInitialized = false;
  bool _localNotificationsInitialized = false;
  bool _isLoadingPreferences = false;
  bool _isUpdatingPreferences = false;
  String? _preferencesErrorMessage;
  String _permissionStatus = 'not_determined';
  NotificationPreferencesModel _preferences =
      NotificationPreferencesModel.defaults;
  String? _preferencesUserId;
  String? _currentToken;
  String? _lastObservedUserId;

  NotificationPreferencesModel get preferences => _preferences;
  bool get isLoadingPreferences => _isLoadingPreferences;
  bool get isUpdatingPreferences => _isUpdatingPreferences;
  String? get preferencesErrorMessage => _preferencesErrorMessage;
  String get permissionStatus => _permissionStatus;
  bool get hasSignedInUser => (_resolveCurrentUserId() ?? '').isNotEmpty;
  bool get isDevicePermissionEnabled =>
      _permissionStatus == 'authorized' || _permissionStatus == 'provisional';
  bool get isNotificationsEnabled =>
      _preferences.allNotifications && isDevicePermissionEnabled;

  String get permissionStatusDescription {
    switch (_permissionStatus) {
      case 'authorized':
        return 'Device notifications are enabled.';
      case 'provisional':
        return 'Device notifications are provisionally enabled.';
      case 'denied':
        return 'Device notifications are blocked right now.';
      default:
        return 'Device notification access has not been granted yet.';
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _loginController.addListener(_handleLoginControllerChanged);

    await _messaging.setAutoInitEnabled(true);
    await _initializeLocalNotifications();
    await _configureForegroundNotifications();
    await _loadPreferencesForCurrentUser(showLoader: false);
    final settings = await _requestPermissionIfNeeded();
    await _syncTokenForCurrentUser(settings: settings);
    await _bindMessageStreams();
    await _handleInitialMessage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshPreferences(showLoader: false));
    }
  }

  Future<void> refreshPreferences({bool showLoader = true}) async {
    await _loadPreferencesForCurrentUser(
      forceRefresh: true,
      showLoader: showLoader,
    );
    await _syncTokenForCurrentUser();
  }

  Future<void> updatePreferences(
    NotificationPreferencesModel nextPreferences, {
    bool requestPermissionOnEnable = false,
  }) async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty) {
      return;
    }

    final previousPreferences = _preferences;
    _isUpdatingPreferences = true;
    _preferencesErrorMessage = null;
    _preferences = nextPreferences;
    _preferencesUserId = userId;
    update();

    try {
      await _userFirestoreService.updateNotificationPreferences(
        userId: userId,
        preferences: nextPreferences,
      );

      NotificationSettings? settings;
      if (requestPermissionOnEnable && nextPreferences.allNotifications) {
        settings = await _requestPermissionIfNeeded();
      }

      await _syncTokenForCurrentUser(settings: settings);
    } catch (error, stackTrace) {
      _preferences = previousPreferences;
      _preferencesErrorMessage =
          'Unable to update notification settings right now.';
      debugPrint(
        'Error updating notification preferences: $error\n$stackTrace',
      );
    } finally {
      _isUpdatingPreferences = false;
      update();
    }
  }

  Future<void> requestDevicePermission() async {
    final settings = await _requestPermissionIfNeeded();
    await _syncTokenForCurrentUser(settings: settings);
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || _localNotificationsInitialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    final androidNotifications =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(
      _androidNotificationChannel,
    );

    _localNotificationsInitialized = true;
  }

  Future<void> _bindMessageStreams() async {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      final trimmedToken = token.trim();
      if (trimmedToken.isNotEmpty) {
        _currentToken = trimmedToken;
      }
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

    _permissionStatus = _permissionStatusLabel(settings.authorizationStatus);
    update();

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

  Future<void> _loadPreferencesForCurrentUser({
    bool forceRefresh = false,
    bool showLoader = false,
  }) async {
    final userId = _resolveCurrentUserId();
    if (userId == null || userId.isEmpty) {
      _preferences = NotificationPreferencesModel.defaults;
      _preferencesUserId = null;
      _preferencesErrorMessage = null;
      _isLoadingPreferences = false;
      update();
      return;
    }

    if (!forceRefresh && _preferencesUserId == userId) {
      return;
    }

    if (showLoader) {
      _isLoadingPreferences = true;
      _preferencesErrorMessage = null;
      update();
    }

    try {
      _preferences = await _userFirestoreService.getNotificationPreferences(
        userId,
      );
      _preferencesUserId = userId;
      _preferencesErrorMessage = null;
    } catch (error, stackTrace) {
      _preferences = NotificationPreferencesModel.defaults;
      _preferencesUserId = userId;
      _preferencesErrorMessage =
          'Unable to load notification settings right now.';
      debugPrint(
        'Error loading notification preferences: $error\n$stackTrace',
      );
    } finally {
      _isLoadingPreferences = false;
      update();
    }
  }

  Future<void> _syncTokenForCurrentUser({
    NotificationSettings? settings,
  }) async {
    final userId = _resolveCurrentUserId();
    final normalizedUserId =
        userId != null && userId.trim().isNotEmpty ? userId.trim() : null;

    if (normalizedUserId != null && _preferencesUserId != normalizedUserId) {
      await _loadPreferencesForCurrentUser(showLoader: false);
    }

    final currentSettings =
        settings ?? await _messaging.getNotificationSettings();
    _permissionStatus =
        _permissionStatusLabel(currentSettings.authorizationStatus);
    final isPermissionEnabled =
        _isPermissionEnabled(currentSettings.authorizationStatus);
    final shouldKeepPushToken =
        isPermissionEnabled && _preferences.allNotifications;

    if (_lastObservedUserId != normalizedUserId &&
        _lastObservedUserId != null &&
        (_currentToken ?? '').trim().isNotEmpty) {
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
    update();

    if (normalizedUserId == null) {
      return;
    }

    final permissionStatus =
        _permissionStatusLabel(currentSettings.authorizationStatus);

    try {
      await _userFirestoreService.updateNotificationPermission(
        userId: normalizedUserId,
        permissionStatus: permissionStatus,
        isEnabled: shouldKeepPushToken,
      );
    } catch (error, stackTrace) {
      debugPrint('Error updating notification permission: $error\n$stackTrace');
    }

    final existingToken = (_currentToken ?? '').trim();
    if (!shouldKeepPushToken) {
      if (existingToken.isNotEmpty) {
        try {
          await _userFirestoreService.removePushToken(
            userId: normalizedUserId,
            token: existingToken,
          );
        } catch (error, stackTrace) {
          debugPrint('Error removing disabled push token: $error\n$stackTrace');
        }
      }
      return;
    }

    final token = (existingToken.isNotEmpty
            ? existingToken
            : (_currentToken ?? await _loadMessagingToken())?.trim() ?? '')
        .trim();
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
          'Error persisting foreground notification: $error\n$stackTrace',
        );
      }
    }

    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final showedLocalNotification =
        await _showForegroundLocalNotification(message);
    if (!showedLocalNotification &&
        _shouldShowNotificationType(
            (message.data['type'] ?? 'system').toString())) {
      AppSnackbar.show(
        title: title.isNotEmpty ? title : 'Notification',
        message: body.isNotEmpty ? body : 'You have a new update.',
        backgroundColor: const Color(0xFF233A66),
      );
    }
  }

  Future<bool> _showForegroundLocalNotification(RemoteMessage message) async {
    if (kIsWeb ||
        !_localNotificationsInitialized ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final type = (message.data['type'] ?? 'system').toString();
    if (!_shouldShowNotificationType(type)) {
      return false;
    }

    final title = _notificationTitle(message);
    final body = _notificationBody(message);
    if (title.isEmpty && body.isEmpty) {
      return false;
    }

    final payload = jsonEncode({
      ...message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      '_notificationTitle': title,
      '_notificationBody': body,
      '_notificationId': _notificationDocumentId(message),
      if (message.sentTime != null)
        '_notificationSentAt': message.sentTime!.millisecondsSinceEpoch,
    });

    await _localNotificationsPlugin.show(
      _localNotificationId(message),
      title.isEmpty ? 'Notification' : title,
      body.isEmpty ? 'You have a new update.' : body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidNotificationChannel.id,
          _androidNotificationChannel.name,
          channelDescription: _androidNotificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );

    return true;
  }

  void _handleLocalNotificationResponse(NotificationResponse response) {
    final rawPayload = response.payload?.trim() ?? '';
    if (rawPayload.isEmpty) {
      return;
    }

    try {
      final decodedPayload = jsonDecode(rawPayload);
      if (decodedPayload is! Map) {
        return;
      }

      final payload = Map<String, dynamic>.from(decodedPayload);
      final title =
          (payload.remove('_notificationTitle') ?? '').toString().trim();
      final body =
          (payload.remove('_notificationBody') ?? '').toString().trim();
      final notificationId =
          (payload.remove('_notificationId') ?? '').toString().trim();
      final sentAtValue = payload.remove('_notificationSentAt');
      final sentAtMilliseconds = sentAtValue is num
          ? sentAtValue.toInt()
          : int.tryParse(sentAtValue?.toString() ?? '');
      final sentAt = sentAtMilliseconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(sentAtMilliseconds);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          _handleNotificationPayload(
            payload,
            title: title,
            body: body,
            sentAt: sentAt,
            fallbackNotificationId: notificationId,
          ),
        );
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Error handling local notification response: $error\n$stackTrace',
      );
    }
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

  Future<void> _handleMessageNavigation(RemoteMessage message) {
    return _handleNotificationPayload(
      message.data,
      title: _notificationTitle(message),
      body: _notificationBody(message),
      sentAt: message.sentTime,
      fallbackNotificationId: _notificationDocumentId(message),
    );
  }

  Future<void> _handleNotificationPayload(
    Map<String, dynamic> data, {
    required String title,
    required String body,
    DateTime? sentAt,
    String? fallbackNotificationId,
  }) async {
    final notification = _notificationFromPayload(
      data,
      title: title,
      body: body,
      sentAt: sentAt,
      fallbackNotificationId: fallbackNotificationId,
    );
    if (notification != null) {
      try {
        await _notificationService.upsertNotification(
          notification,
          documentId: _notificationDocumentIdFromPayload(
            data,
            fallbackNotificationId: fallbackNotificationId,
          ),
        );
      } catch (error, stackTrace) {
        debugPrint('Error persisting opened notification: $error\n$stackTrace');
      }
    }

    final userId = _resolveCurrentUserId();
    final notificationId = _notificationDocumentIdFromPayload(
      data,
      fallbackNotificationId: fallbackNotificationId,
    );
    if (userId != null && userId.isNotEmpty && notificationId.isNotEmpty) {
      try {
        await _notificationService.markAsRead(
          userId: userId,
          notificationId: notificationId,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Error marking push notification as read: $error\n$stackTrace',
        );
      }
    }

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
    return _notificationFromPayload(
      message.data,
      title: _notificationTitle(message),
      body: _notificationBody(message),
      sentAt: message.sentTime,
      fallbackNotificationId: _notificationDocumentId(message),
    );
  }

  AppNotificationModel? _notificationFromPayload(
    Map<String, dynamic> data, {
    required String title,
    required String body,
    DateTime? sentAt,
    String? fallbackNotificationId,
  }) {
    final recipientId = _resolveCurrentUserId();
    if (recipientId == null || recipientId.trim().isEmpty) {
      return null;
    }

    final messageRecipientId = (data['recipientId'] ?? '').toString().trim();
    if (messageRecipientId.isNotEmpty && messageRecipientId != recipientId) {
      return null;
    }

    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    final notificationId = _notificationDocumentIdFromPayload(
      data,
      fallbackNotificationId: fallbackNotificationId,
    );

    return AppNotificationModel(
      id: notificationId.isEmpty ? null : notificationId,
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
      createdAt: sentAt,
      updatedAt: sentAt,
    );
  }

  int _localNotificationId(RemoteMessage message) {
    final source = _notificationDocumentId(message);
    if (source.isNotEmpty) {
      return source.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }

  String _notificationDocumentId(RemoteMessage message) {
    return _notificationDocumentIdFromPayload(
      message.data,
      fallbackNotificationId: message.messageId,
    );
  }

  String _notificationDocumentIdFromPayload(
    Map<String, dynamic> data, {
    String? fallbackNotificationId,
  }) {
    final fromPayload =
        (data['notificationId'] ?? data['id'] ?? data['_notificationId'] ?? '')
            .toString()
            .trim();
    if (fromPayload.isNotEmpty) {
      return fromPayload;
    }
    return fallbackNotificationId?.trim() ?? '';
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

  bool _shouldShowNotificationType(String type) {
    if (!_preferences.allNotifications) {
      return false;
    }
    return _preferences.isTypeEnabled(type);
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
        'Error loading product from push payload: $error\n$stackTrace',
      );
      return null;
    }
  }

  void _handleLoginControllerChanged() {
    final currentUserId = _resolveCurrentUserId();
    if (currentUserId == _lastObservedUserId &&
        currentUserId == _preferencesUserId) {
      return;
    }

    unawaited(refreshPreferences(showLoader: false));
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
