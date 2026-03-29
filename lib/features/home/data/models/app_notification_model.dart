import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  const AppNotificationModel({
    this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.targetRoute,
    this.productId,
    this.chatId,
    this.isRead = false,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String recipientId;
  final String title;
  final String body;
  final String type;
  final String? senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String? targetRoute;
  final String? productId;
  final String? chatId;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasSenderPhoto =>
      (senderPhotoUrl ?? '').trim().isNotEmpty;

  bool get hasSenderIdentity =>
      (senderName ?? '').trim().isNotEmpty || (senderId ?? '').trim().isNotEmpty;

  AppNotificationModel copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? body,
    String? type,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? targetRoute,
    String? productId,
    String? chatId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      targetRoute: targetRoute ?? this.targetRoute,
      productId: productId ?? this.productId,
      chatId: chatId ?? this.chatId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'targetRoute': targetRoute,
      'productId': productId,
      'chatId': chatId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'targetRoute': targetRoute,
      'productId': productId,
      'chatId': chatId,
      'isRead': isRead,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppNotificationModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return AppNotificationModel(
      id: documentId,
      recipientId: map['recipientId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'system',
      senderId: map['senderId']?.toString(),
      senderName: map['senderName']?.toString(),
      senderPhotoUrl: map['senderPhotoUrl']?.toString(),
      targetRoute: map['targetRoute']?.toString(),
      productId: map['productId']?.toString(),
      chatId: map['chatId']?.toString(),
      isRead: map['isRead'] == true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
