import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:bikebooking/features/home/data/services/notification_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationDispatchService {
  NotificationDispatchService({
    FirebaseFirestore? firestore,
    NotificationFirestoreService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService =
            notificationService ?? NotificationFirestoreService();

  final FirebaseFirestore _firestore;
  final NotificationFirestoreService _notificationService;

  CollectionReference<Map<String, dynamic>> get _queueRef =>
      _firestore.collection('notification_queue');

  Future<String?> dispatchNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? targetRoute,
    String? productId,
    String? chatId,
    String? documentId,
    DateTime? sentAt,
    bool queuePush = true,
    bool allowSelfNotification = false,
  }) async {
    final normalizedRecipientId = recipientId.trim();
    final normalizedSenderId = senderId?.trim() ?? '';
    if (normalizedRecipientId.isEmpty) {
      return null;
    }

    if (!allowSelfNotification &&
        normalizedSenderId.isNotEmpty &&
        normalizedSenderId == normalizedRecipientId) {
      return null;
    }

    final resolvedDocumentId = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : _firestore
            .collection('users')
            .doc(normalizedRecipientId)
            .collection('notifications')
            .doc()
            .id;
    final createdAt = sentAt ?? DateTime.now();

    final notification = AppNotificationModel(
      id: resolvedDocumentId,
      recipientId: normalizedRecipientId,
      title: title.trim().isNotEmpty ? title.trim() : 'Notification',
      body: body.trim(),
      type: type.trim().isNotEmpty ? type.trim() : 'system',
      senderId: normalizedSenderId.isEmpty ? null : normalizedSenderId,
      senderName: _nullableString(senderName),
      senderPhotoUrl: _nullableString(senderPhotoUrl),
      targetRoute: _nullableString(targetRoute),
      productId: _nullableString(productId),
      chatId: _nullableString(chatId),
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await _notificationService.upsertNotification(
      notification,
      documentId: resolvedDocumentId,
    );

    if (queuePush) {
      await _queueRef.add({
        'notificationId': resolvedDocumentId,
        'recipientId': normalizedRecipientId,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type,
        'senderId': notification.senderId,
        'senderName': notification.senderName,
        'senderPhotoUrl': notification.senderPhotoUrl,
        'targetRoute': notification.targetRoute,
        'productId': notification.productId,
        'chatId': notification.chatId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return resolvedDocumentId;
  }

  String? _nullableString(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
