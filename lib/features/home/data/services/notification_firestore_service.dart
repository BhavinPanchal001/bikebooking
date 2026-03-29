import 'package:bikebooking/features/home/data/models/app_notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationFirestoreService {
  NotificationFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    final snapshot = await _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
              .toList(growable: false),
        );
  }

  Future<void> addNotification(AppNotificationModel notification) async {
    await _notificationsRef(notification.recipientId)
        .add(notification.toCreateMap());
  }

  Future<void> upsertNotification(
    AppNotificationModel notification, {
    String? documentId,
  }) async {
    final resolvedDocumentId = documentId?.trim().isNotEmpty == true
        ? documentId!.trim()
        : notification.id?.trim() ?? '';

    final ref = resolvedDocumentId.isEmpty
        ? _notificationsRef(notification.recipientId).doc()
        : _notificationsRef(notification.recipientId).doc(resolvedDocumentId);

    final payload = resolvedDocumentId.isEmpty
        ? notification.toCreateMap()
        : {
            ...notification.toUpdateMap(),
            'createdAt': notification.createdAt == null
                ? FieldValue.serverTimestamp()
                : Timestamp.fromDate(notification.createdAt!),
          };

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationsRef(userId).doc(notificationId).set({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot =
        await _notificationsRef(userId).where('isRead', isEqualTo: false).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(
          doc.reference,
          {
            'isRead': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }
}
