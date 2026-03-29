import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message document inside `chats/{chatId}/messages`.
class MessageModel {
  const MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.timestamp,
    this.readBy = const [],
  });

  final String? id;
  final String senderId;
  final String text;
  final String type;
  final DateTime? timestamp;
  final List<String> readBy;

  /// Whether a specific user has read this message.
  bool isReadBy(String userId) => readBy.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': readBy,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
