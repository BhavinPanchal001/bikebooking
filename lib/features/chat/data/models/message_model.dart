import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message document inside `chats/{chatId}/messages`.
class MessageModel {
  const MessageModel({
    this.id,
    this.clientMessageId,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.imageUrl,
    this.localImageBytes,
    this.timestamp,
    this.readBy = const [],
    this.isPending = false,
  });

  final String? id;
  final String? clientMessageId;
  final String senderId;
  final String text;
  final String type;
  final String? imageUrl;
  final Uint8List? localImageBytes;
  final DateTime? timestamp;
  final List<String> readBy;
  final bool isPending;

  /// Whether a specific user has read this message.
  bool isReadBy(String userId) => readBy.contains(userId);

  bool get hasImage =>
      type == 'image' &&
      ((imageUrl?.trim().isNotEmpty ?? false) ||
          (localImageBytes?.isNotEmpty ?? false));

  Map<String, dynamic> toMap() {
    return {
      if (clientMessageId != null && clientMessageId!.trim().isNotEmpty)
        'clientMessageId': clientMessageId,
      'senderId': senderId,
      'text': text,
      'type': type,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty) 'imageUrl': imageUrl,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'readBy': readBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      clientMessageId: map['clientMessageId']?.toString(),
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      imageUrl: map['imageUrl']?.toString(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
      isPending: false,
    );
  }
}
